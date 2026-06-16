import matter from 'gray-matter';
import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import type { Dirent } from 'node:fs';
import fs from 'node:fs/promises';
import path from 'node:path';
import { loadEnvFile } from 'node:process';
import { fileURLToPath, pathToFileURL } from 'node:url';

try {
  loadEnvFile();
} catch (error) {
  if (!(error && typeof error === 'object' && 'code' in error && error.code === 'ENOENT')) {
    throw error;
  }
}

const reportSchema = z.object({
  title: z.string(),
  date: z.date(),
  excerpt: z.string().optional(),
});

function resolveResearchDir() {
  const configured = process.env.RESEARCH_DIR?.trim();
  if (!configured) {
    throw new Error('RESEARCH_DIR is not set. Copy .env.example to .env and set RESEARCH_DIR to your reports directory.');
  }

  return path.resolve(configured);
}

function titleFromSlug(slug: string) {
  return slug
    .split('-')
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function inferTitle(body: string, slug: string) {
  const headingMatch = body.match(/^#\s+(.+)$/m);
  if (headingMatch?.[1]) {
    return headingMatch[1].trim();
  }

  return titleFromSlug(slug);
}

function inferDate(raw: string, fallback: Date) {
  const dateMatch = raw.match(/\*\*Date:\*\*\s*(\d{4}-\d{2}-\d{2})/i);
  if (dateMatch?.[1]) {
    const parsed = new Date(`${dateMatch[1]}T00:00:00`);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }

  return fallback;
}

function inferExcerpt(content: string) {
  const plainText = content
    .replace(/^#.*$/gm, '')
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/\*([^*]+)\*/g, '$1')
    .replace(/\[(.*?)\]\((.*?)\)/g, '$1')
    .replace(/^>\s?/gm, '')
    .replace(/\|/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (!plainText) return undefined;
  if (plainText.length <= 220) return plainText;
  return `${plainText.slice(0, 217).trimEnd()}...`;
}

const reports = defineCollection({
  loader: {
    name: 'deep-research-loader',
    async load({ config, logger, store, parseData, renderMarkdown, generateDigest }) {
      const researchDir = resolveResearchDir();
      const rootDir = fileURLToPath(config.root);

      store.clear();

      let dirEntries: Dirent[];
      try {
        dirEntries = await fs.readdir(researchDir, { withFileTypes: true });
      } catch (error) {
        logger.warn(`Research directory not available at ${researchDir}. Set RESEARCH_DIR to override.`);
        return;
      }

      const markdownFiles = dirEntries
        .filter((entry: Dirent) => entry.isFile() && entry.name.endsWith('.md'))
        .map((entry: Dirent) => entry.name)
        .sort((a: string, b: string) => a.localeCompare(b));

      for (const filename of markdownFiles) {
        const absolutePath = path.join(researchDir, filename);
        const raw = await fs.readFile(absolutePath, 'utf8');
        const stats = await fs.stat(absolutePath);
        const slug = filename.replace(/\.md$/i, '');
        const parsed = matter(raw);

        const title = typeof parsed.data.title === 'string' && parsed.data.title.trim()
          ? parsed.data.title.trim()
          : inferTitle(parsed.content, slug);

        const date = parsed.data.date instanceof Date
          ? parsed.data.date
          : typeof parsed.data.date === 'string'
            ? new Date(parsed.data.date)
            : inferDate(raw, stats.mtime);

        const safeDate = Number.isNaN(date.getTime()) ? stats.mtime : date;
        const excerpt = typeof parsed.data.excerpt === 'string' && parsed.data.excerpt.trim()
          ? parsed.data.excerpt.trim()
          : inferExcerpt(parsed.content);

        const data = await parseData({
          id: slug,
          data: {
            title,
            date: safeDate,
            excerpt,
          },
          filePath: path.relative(rootDir, absolutePath),
        });

        const rendered = await renderMarkdown(parsed.content, {
          fileURL: pathToFileURL(absolutePath),
        });

        store.set({
          id: slug,
          data,
          body: parsed.content,
          filePath: path.relative(rootDir, absolutePath),
          digest: generateDigest(raw),
          rendered,
          assetImports: rendered.metadata?.imagePaths,
        });
      }

      logger.info(`Loaded ${markdownFiles.length} research report(s) from ${researchDir}`);
    },
  },
  schema: reportSchema,
});

export const collections = { reports };
