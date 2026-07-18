# pretty-claude-cli

A colorful, animated status line for the [Claude Code](https://code.claude.com) CLI — an at-a-glance bar showing your OS, working directory, a live **context-usage heat bar**, the active model, and time until your session window resets.

![preview](examples/preview.svg)

```
(macOS Sequoia 15.5) ~/projects/acme-api  ┃  🧊 ●●●○○○○○○○○○○○○○○○○○○○○○ 13%  ┃  Claude Pro, Opus 4.8, 4h 43m
```

- **Heat bar** — an animated rainbow progress bar for context-window usage, with an **emoji temperature gauge** (🧊 → 🌡️ → 🔥 → 💥 → ☢️) that heats up as you fill the window.
- **Rainbow model name** — the model name flows the same moving gradient as the bar, its left edge picking up the bar's leading color.
- **Per-device color profiles** — each machine auto-selects its own palette by hostname, so your laptop and your server look different at a glance.
- **Fully themeable** — every color, the separator glyph, the emoji sequence and its thresholds, and the bar's speed/width/vibrancy are set in one config file. The script itself never needs editing.

## Requirements

- [Claude Code](https://code.claude.com) CLI
- `bash` and `python3` (both standard on macOS and Linux)
- A terminal with **24-bit truecolor** and emoji support (iTerm2, Kitty, WezTerm, Alacritty, GNOME Terminal, Windows Terminal, …)

## Install

```bash
git clone https://github.com/srak71/pretty-claude-cli.git
cd pretty-claude-cli
./install.sh
```

The installer copies the status line to `~/.claude/pretty-claude-cli/`, drops a starter config there, and adds a `statusLine` entry to `~/.claude/settings.json` (it preserves any other settings you already have). Start a new Claude Code session to see it.

> Prefer to wire it up yourself? Point `statusLine.command` in `~/.claude/settings.json` at `~/.claude/pretty-claude-cli/statusline.sh` and set `"refreshInterval": 1`.

## What the bar shows

| Segment | Meaning |
| --- | --- |
| `(macOS Sequoia 15.5)` | Operating system + version (auto-detected) |
| `~/projects/acme-api` | Current working directory |
| `🧊 ●●●○… 13%` | Context-window usage: emoji gauge + rainbow bar + percentage |
| `Claude Pro` | Your plan label |
| `Opus 4.8` | Active model for this session |
| `4h 43m` | Time remaining until the 5-hour session window resets |

## Customize

All appearance lives in **`~/.claude/pretty-claude-cli/config.sh`** (a copy of [`config.example.sh`](config.example.sh)). Colors accept either truecolor `"R;G;B"` (e.g. `"135;206;235"`) or a basic SGR code (e.g. `"32"` = green, `"96"` = cyan).

### Colors & per-device profiles

The config picks colors by hostname, so each device gets its own theme automatically:

```bash
case "$(hostname -s 2>/dev/null || hostname)" in
  my-macbook)   PCC_DEVICE_COLOR="135;206;235" ;;  # sky blue
  my-linux-box) PCC_DEVICE_COLOR="32" ;;           # green
  *)            PCC_DEVICE_COLOR="135;206;235" ;;   # default
esac
```

`PCC_DEVICE_COLOR` tints the OS label, the `┃` separators, the `%` sign and the time units — so recoloring one device is a one-line change.

### Emoji temperature sequence

Swap the emojis, move the thresholds, or retint each stage:

```bash
PCC_HEAT_EMOJIS="🌱 🌿 🍂 🔥 🌋"    # 5 stages, cool → critical
PCC_HEAT_THRESHOLDS="20 40 60 80"   # <20→0, <40→1, <60→2, <80→3, ≥80→4
PCC_HEAT_COLORS="96 92 93 91 95"    # tint per stage
```

### Model name & bar

```bash
PCC_MODEL_RAINBOW="1"     # 1 = rainbow flow; 0 = solid PCC_MODEL_COLOR
PCC_BAR_WIDTH="24"        # cells
PCC_BAR_SPEED="0.03"      # hue drift per second (smaller = calmer)
PCC_BAR_NEON_FLOOR="90"   # 0-255 vibrancy lift
PCC_SEP_CHAR="┃"          # separator glyph
PCC_PATH_STYLE="home"     # "home" → ~/projects/app ; "prefix" → literal ~ prepend
```

See [`config.example.sh`](config.example.sh) for every option with inline docs.

## A note on smoothness

The animation is driven by Claude Code's `statusLine.refreshInterval` (in **seconds**; the minimum allowed is **1**). The installer sets it to `1` for the smoothest motion Claude Code permits — the wave drifts gently rather than jumping. Sub-second animation isn't possible through the status-line API.

## Uninstall

```bash
./uninstall.sh          # removes the status line, keeps your config
./uninstall.sh --purge  # also deletes ~/.claude/pretty-claude-cli/
```

## How it works

Claude Code pipes session JSON to `statusLine.command` on every update. `statusline.sh` detects the OS, sources your `config.sh`, and hands off to `render.py`, which reads the context percentage, model, and reset time from the JSON and prints one ANSI-colored line. No daemon, no dependencies beyond `bash` + `python3`.

## License

[MIT](LICENSE) © Saransh Rakshak
