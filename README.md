# Deep Research

A small Astro site that renders markdown reports from a local directory for comfortable reading on desktop or mobile.

## Requirements

- Node.js 22.12+
- npm
- Tailscale (optional, only for tailnet serving)

## Install

```bash
npm install
cp .env.example .env
```

Then edit `.env` and set `RESEARCH_DIR` to the absolute path of your reports directory.

## Development

The app requires `RESEARCH_DIR` to be set in `.env`.

```bash
npm run dev
```

Open http://localhost:4321

## Build

```bash
npm run build
npm run check
```

The static output is written to `dist/`.

## Configure the report directory

Point `RESEARCH_DIR` at any local markdown directory, such as an Obsidian vault export or research notes folder.

Example `.env`:

```bash
RESEARCH_DIR=/absolute/path/to/reports
```

## Serve over Tailscale

One-shot build + serve:

```bash
npm run tailscale:serve
```

Auto-rebuild watcher for new/updated reports:

```bash
npm run watch:reports
```

Managed watcher commands:

```bash
npm run watch:start
npm run watch:status
npm run watch:stop
```

Raw scripts still exist if you want them directly:

```bash
./scripts/build-and-serve.sh
./scripts/start-watch.sh
./scripts/watch-status.sh
./scripts/stop-watch.sh
```

The watcher polls your configured report directory every few seconds, waits for a short quiet period so partially-written reports can finish, then rebuilds the Astro app automatically.
It calls the same `build-and-serve.sh` script, so the static site and Tailscale-served view stay fresh as new reports arrive.

The build/serve script starts a local Python static server on `127.0.0.1:${LOCAL_PORT:-3000}` and exposes that via Tailscale Serve.
This avoids the macOS sandbox restriction that prevents direct path-serving on the App Store variant of Tailscale.
If Serve has not been enabled for the node yet, the script exits cleanly and prints the Tailscale admin URL you need to visit first.

Optional tuning in `.env` or your shell:

```bash
WATCH_POLL_SECONDS=2 WATCH_QUIET_SECONDS=4 npm run watch:reports
```

## Notes

- Report titles are taken from frontmatter when available, otherwise from the first `# Heading` in the markdown.
- Report dates come from frontmatter, then a `**Date:** YYYY-MM-DD` line, then the file modification time.
- The loader requires `RESEARCH_DIR` and fails fast with a clear message if it is missing.
