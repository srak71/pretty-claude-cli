#!/usr/bin/env bash
# pretty-claude-cli uninstaller.
# Removes the statusLine key from settings.json and deletes the install dir.
# Your config.sh is left in place unless you pass --purge.
set -e

DEST="$HOME/.claude/pretty-claude-cli"
SETTINGS="$HOME/.claude/settings.json"
PURGE=0
[ "$1" = "--purge" ] && PURGE=1

if [ -f "$SETTINGS" ]; then
  python3 - "$SETTINGS" << 'PYEOF'
import json, sys
p = sys.argv[1]
try:
    with open(p) as f:
        d = json.load(f)
except (FileNotFoundError, ValueError):
    sys.exit(0)
if d.pop("statusLine", None) is not None:
    with open(p, "w") as f:
        json.dump(d, f, indent=2)
        f.write("\n")
    print(f"▸ Removed statusLine from {p}")
PYEOF
fi

if [ "$PURGE" = "1" ]; then
  rm -rf "$DEST"
  echo "▸ Purged $DEST (including your config)"
else
  rm -f "$DEST/statusline.sh" "$DEST/render.py"
  echo "▸ Removed program files; kept your config at $DEST/config.sh"
  echo "  (run with --purge to delete everything)"
fi
echo "✓ Uninstalled. Restart Claude Code."
