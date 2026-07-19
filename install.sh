#!/usr/bin/env bash
# pretty-claude-cli installer (macOS / Linux / Git Bash).
set -e

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/pretty-claude-cli"
SETTINGS="$HOME/.claude/settings.json"

if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else echo "✗ Python 3 is required but was not found on PATH."; exit 1; fi

echo "▸ Installing pretty-claude-cli → $DEST"
mkdir -p "$DEST"
cp "$SRC_DIR/statusline.py" "$DEST/statusline.py"
cp "$SRC_DIR/statusline.sh" "$DEST/statusline.sh"
cp "$SRC_DIR/statusline.ps1" "$DEST/statusline.ps1"
cp "$SRC_DIR/config.example.ini" "$DEST/config.example.ini"
chmod +x "$DEST/statusline.sh" "$DEST/statusline.py"

if [ -f "$DEST/config.ini" ]; then
  echo "▸ Keeping your existing config: $DEST/config.ini"
else
  cp "$SRC_DIR/config.example.ini" "$DEST/config.ini"
  echo "▸ Wrote starter config: $DEST/config.ini"
fi

"$PY" - "$SETTINGS" "$DEST/statusline.sh" << 'PYEOF'
import json, os, sys
settings_path, cmd = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(settings_path), exist_ok=True)
try:
    with open(settings_path, encoding="utf-8") as f:
        d = json.load(f)
except (FileNotFoundError, ValueError):
    d = {}
d["statusLine"] = {"type": "command", "command": cmd, "refreshInterval": 1}
with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
print(f"▸ statusLine configured in {settings_path} (refreshInterval=1)")
PYEOF

echo "✓ Done. Start a new Claude Code session to see it."
echo "  Customize colors / emojis:  $DEST/config.ini"
