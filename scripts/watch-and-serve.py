#!/usr/bin/env python3
import os
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, Tuple

ROOT_DIR = Path(__file__).resolve().parent.parent
if 'RESEARCH_DIR' not in os.environ or not os.environ['RESEARCH_DIR'].strip():
    raise SystemExit('RESEARCH_DIR is not set. Copy .env.example to .env and start the watcher via scripts/start-watch.sh or export RESEARCH_DIR manually.')

RESEARCH_DIR = Path(os.environ['RESEARCH_DIR']).expanduser().resolve()
BUILD_SCRIPT = ROOT_DIR / 'scripts' / 'build-and-serve.sh'
POLL_SECONDS = float(os.environ.get('WATCH_POLL_SECONDS', '2'))
QUIET_SECONDS = float(os.environ.get('WATCH_QUIET_SECONDS', '4'))

running = True


def handle_signal(signum, frame):
    global running
    running = False


signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)


def snapshot_markdown_tree(base: Path) -> Dict[str, Tuple[int, int]]:
    if not base.exists():
        return {}

    snap: Dict[str, Tuple[int, int]] = {}
    for path in sorted(base.glob('*.md')):
        try:
            stat = path.stat()
        except FileNotFoundError:
            continue
        snap[path.name] = (stat.st_mtime_ns, stat.st_size)
    return snap


def run_build() -> int:
    env = os.environ.copy()
    env['RESEARCH_DIR'] = str(RESEARCH_DIR)
    print(f'[watch] running build script for {RESEARCH_DIR}', flush=True)
    proc = subprocess.run([str(BUILD_SCRIPT)], cwd=ROOT_DIR, env=env)
    print(f'[watch] build exit code: {proc.returncode}', flush=True)
    return proc.returncode


def main() -> int:
    print(f'[watch] repo: {ROOT_DIR}', flush=True)
    print(f'[watch] watching: {RESEARCH_DIR}', flush=True)
    print(f'[watch] poll interval: {POLL_SECONDS}s, quiet period: {QUIET_SECONDS}s', flush=True)

    if not BUILD_SCRIPT.exists():
        print(f'[watch] missing build script: {BUILD_SCRIPT}', file=sys.stderr, flush=True)
        return 1

    last_snapshot = snapshot_markdown_tree(RESEARCH_DIR)
    last_change_seen_at = None
    pending_snapshot = None

    initial_rc = run_build()
    if initial_rc != 0:
        print('[watch] initial build failed; continuing to watch for future changes', flush=True)

    while running:
        current_snapshot = snapshot_markdown_tree(RESEARCH_DIR)

        if current_snapshot != last_snapshot:
            pending_snapshot = current_snapshot
            last_snapshot = current_snapshot
            last_change_seen_at = time.time()
            print('[watch] detected markdown change; waiting for quiet period before rebuild', flush=True)

        if pending_snapshot is not None and last_change_seen_at is not None:
            if time.time() - last_change_seen_at >= QUIET_SECONDS:
                run_build()
                pending_snapshot = None
                last_change_seen_at = None

        time.sleep(POLL_SECONDS)

    print('[watch] stopping', flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
