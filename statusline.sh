#!/usr/bin/env bash
# pretty-claude-cli launcher (macOS / Linux / Git Bash on Windows).
# Locates Python and hands stdin to statusline.py.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  printf 'pretty-claude-cli: python 3 not found on PATH'
  exit 0
fi

exec "$PY" "$DIR/statusline.py"
