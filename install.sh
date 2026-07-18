#!/usr/bin/env bash
# pretty-claude-cli installer.
# Copies the status line into ~/.claude/pretty-claude-cli/, drops a starter
# config (if none exists), and wires statusLine into ~/.claude/settings.json.
set -e

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/pretty-claude-cli"
SETTINGS="$HOME/.claude/settings.json"

echo "▸ Installing pretty-claude-cli → $DEST"
mkdir -p "$DEST"
cp "$SRC_DIR/statusline.sh" "$DEST/statusline.sh"
cp "$SRC_DIR/render.py" "$DEST/render.py"
chmod +x "$DEST/statusline.sh"

if [ -f "$DEST/config.sh" ]; then
  echo "▸ Keeping your existing config: $DEST/config.sh"
else
  cp "$SRC_DIR/config.example.sh" "$DEST/config.sh"
  echo "▸ Wrote starter config: $DEST/config.sh"
fi

# Wire up settings.json (create or patch) without disturbing other keys.
python3 - "$SETTINGS" "$DEST/statusline.sh" << 'PYEOF'
import json, os, sys
settings_path, cmd = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(settings_path), exist_ok=True)
try:
    with open(settings_path) as f:
        d = json.load(f)
except (FileNotFoundError, ValueError):
    d = {}
d["statusLine"] = {"type": "command", "command": cmd, "refreshInterval": 1}
with open(settings_path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
print(f"▸ statusLine configured in {settings_path} (refreshInterval=1)")
PYEOF

echo "✓ Done. Start a new Claude Code session to see it."
echo "  Customize colors / emojis:  $DEST/config.sh"
