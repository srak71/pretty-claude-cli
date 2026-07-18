#!/usr/bin/env bash
# pretty-claude-cli — an animated context/heat status line for Claude Code.
# Reads session JSON on stdin, prints a single styled line on stdout.
# All appearance is controlled by config.sh (see config.example.sh).

input=$(cat)

# --- locate this script so we can find a co-located config -------------------
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- load user config (first match wins) -------------------------------------
for _cfg in \
  "$PRETTY_CLAUDE_CONFIG" \
  "$HOME/.config/pretty-claude-cli/config.sh" \
  "$HOME/.claude/pretty-claude-cli/config.sh" \
  "$SELF_DIR/config.sh"; do
  if [ -n "$_cfg" ] && [ -f "$_cfg" ]; then
    # shellcheck source=/dev/null
    source "$_cfg"
    break
  fi
done

export PCC_DEVICE_COLOR PCC_PATH_COLOR PCC_ACCENT_COLOR PCC_SEP_COLOR PCC_UNIT_COLOR \
       PCC_SEP_CHAR PCC_PATH_STYLE PCC_HEAT_EMOJIS PCC_HEAT_THRESHOLDS PCC_HEAT_COLORS \
       PCC_MODEL_RAINBOW PCC_MODEL_COLOR PCC_BAR_WIDTH PCC_BAR_SPEED PCC_BAR_SPAN \
       PCC_BAR_NEON_FLOOR PCC_BAR_FILLED PCC_BAR_EMPTY PCC_BAR_EMPTY_COLOR

# --- OS label ---------------------------------------------------------------
if command -v sw_vers &>/dev/null; then
  os_version=$(sw_vers -productVersion 2>/dev/null || echo "?")
  codename=$(grep -oa 'macOS [A-Z][a-z]*' \
    "/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf" \
    2>/dev/null | grep -v '^macOS$' | head -1 | awk '{print $2}')
  if [ -z "$codename" ]; then
    case "$(echo "$os_version" | cut -d. -f1)" in
      11) codename="Big Sur" ;;  12) codename="Monterey" ;;
      13) codename="Ventura" ;;  14) codename="Sonoma" ;;
      15) codename="Sequoia" ;;  26) codename="Tahoe" ;;
    esac
  fi
  [ -n "$codename" ] && os_label="macOS $codename $os_version" || os_label="macOS $os_version"
elif [ -f /etc/os-release ]; then
  . /etc/os-release
  os_label="${NAME:-Linux} ${VERSION_ID:-}"
else
  os_label="$(uname -s) $(uname -r)"
fi

python3 "$SELF_DIR/render.py" "$input" "$os_label"
