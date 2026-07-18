#!/usr/bin/env bash
# pretty-claude-cli configuration.
#
# Copy this to one of (first found wins):
#   $PRETTY_CLAUDE_CONFIG            (any path you point the env var at)
#   ~/.config/pretty-claude-cli/config.sh
#   ~/.claude/pretty-claude-cli/config.sh
#   <repo>/config.sh                 (next to statusline.sh)
#
# The installer copies it to ~/.claude/pretty-claude-cli/config.sh for you.
# Edit freely and start a new Claude Code session (or wait a refresh tick).
#
# COLOR FORMAT — every *_COLOR accepts either:
#   • truecolor  "R;G;B"   e.g. "135;206;235"  (24-bit, recommended)
#   • an SGR code "N"      e.g. "97"=bright white, "32"=green, "96"=cyan

# ─────────────────────────────────────────────────────────────────────────
#  PER-DEVICE COLOR PROFILES
#  The bar auto-selects colors by machine hostname. Add a branch per device
#  so each of your computers gets its own look automatically.
# ─────────────────────────────────────────────────────────────────────────
case "$(hostname -s 2>/dev/null || hostname)" in
  # my-macbook)
  #   PCC_DEVICE_COLOR="135;206;235" ;;   # sky blue
  # my-linux-box)
  #   PCC_DEVICE_COLOR="32" ;;            # green
  *)
    PCC_DEVICE_COLOR="135;206;235" ;;      # default profile: sky blue
esac

# ─────────────────────────────────────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────────────────────────────────────
# PCC_DEVICE_COLOR is set per-device above. These derive from it by default:
PCC_SEP_COLOR="$PCC_DEVICE_COLOR"    # the ┃ section separators
PCC_UNIT_COLOR="$PCC_DEVICE_COLOR"   # the % symbol and h / m / d time units

PCC_PATH_COLOR="97"                  # working directory — bright white
PCC_ACCENT_COLOR="255;140;80"        # the "Claude Pro" label — warm orange

# Path display: "home"  → substitute $HOME with ~   (e.g. ~/projects/app)
#               "prefix"→ literally prepend ~        (e.g. ~/Users/you)
PCC_PATH_STYLE="home"

# ─────────────────────────────────────────────────────────────────────────
#  MODEL NAME
# ─────────────────────────────────────────────────────────────────────────
# 1 = the model name flows the same animated rainbow as the loading bar,
#     picking up the bar's leading color at its left edge.
# 0 = paint the model name a single solid color (PCC_MODEL_COLOR).
PCC_MODEL_RAINBOW="1"
PCC_MODEL_COLOR="70;130;180"         # steel blue — used only when rainbow is off

# ─────────────────────────────────────────────────────────────────────────
#  SEPARATOR
# ─────────────────────────────────────────────────────────────────────────
PCC_SEP_CHAR="┃"                     # try: │ ┆ ║ • · | ⋮

# ─────────────────────────────────────────────────────────────────────────
#  EMOJI TEMPERATURE SEQUENCE
#  Five stages selected by context-window usage. Edit the emojis, the
#  thresholds, and the per-stage tint colors to taste. Keep the three lists
#  the same length as each other (emojis == colors, thresholds == count-1).
# ─────────────────────────────────────────────────────────────────────────
PCC_HEAT_EMOJIS="🧊 🌡️ 🔥 💥 ☢️"       # stage 0 → 4 (cool → critical)
PCC_HEAT_THRESHOLDS="20 40 60 80"    # <20→0, <40→1, <60→2, <80→3, ≥80→4
PCC_HEAT_COLORS="96 92 93 91 95"     # emoji tint per stage (cyan/green/yellow/red/magenta)
#  Fun alternates to try:
#   PCC_HEAT_EMOJIS="🌱 🌿 🍂 🔥 🌋"
#   PCC_HEAT_EMOJIS="😌 🙂 😅 😰 🥵"
#   PCC_HEAT_EMOJIS="🟢 🟡 🟠 🔴 ⚫"

# ─────────────────────────────────────────────────────────────────────────
#  RAINBOW LOADING BAR
# ─────────────────────────────────────────────────────────────────────────
PCC_BAR_WIDTH="24"                   # number of cells
PCC_BAR_SPEED="0.03"                 # hue drift per second (smaller = calmer)
PCC_BAR_SPAN="24"                    # cells the rainbow spans (smaller = tighter)
PCC_BAR_NEON_FLOOR="90"              # 0-255 vibrancy lift (higher = pastel glow)
PCC_BAR_FILLED="●"                   # filled cell glyph
PCC_BAR_EMPTY="○"                    # empty cell glyph
PCC_BAR_EMPTY_COLOR="90"             # dim gray for empty cells

# NOTE ON SMOOTHNESS: motion is driven by settings.json "refreshInterval"
# (seconds; Claude Code minimum is 1). The installer sets it to 1 for the
# smoothest allowed animation.
