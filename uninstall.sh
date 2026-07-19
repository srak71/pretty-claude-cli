#!/usr/bin/env bash
# pretty-claude-cli uninstaller (macOS / Linux / Git Bash).
# Removes the statusLine key from settings.json and deletes program files.
# Keeps your config.ini unless you pass --purge.
set -e

DEST="$HOME/.claude/pretty-claude-cli"
SETTINGS="$HOME/.claude/settings.json"
PURGE=0
[ "$1" = "--purge" ] && PURGE=1

if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else PY=""; fi

if [ -n "$PY" ] && [ -f "$SETTINGS" ]; then
  "$PY" - "$SETTINGS" << 'PYEOF'
import json, sys
p = sys.argv[1]
try:
    with open(p, encoding="utf-8") as f:
        d = json.load(f)
except (FileNotFoundError, ValueError):
    sys.exit(0)
if d.pop("statusLine", None) is not None:
    with open(p, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2)
        f.write("\n")
    print(f"▸ Removed statusLine from {p}")
PYEOF
fi

if [ "$PURGE" = "1" ]; then
  rm -rf "$DEST"
  echo "▸ Purged $DEST (including your config)"
else
  rm -f "$DEST/statusline.py" "$DEST/statusline.sh" "$DEST/statusline.ps1" "$DEST/config.example.ini"
  echo "▸ Removed program files; kept your config at $DEST/config.ini"
  echo "  (run with --purge to delete everything)"
fi
echo "✓ Uninstalled. Restart Claude Code."
