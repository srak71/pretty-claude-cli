# pretty-claude-cli

A colorful, animated status line for the [Claude Code](https://code.claude.com) CLI — an at-a-glance bar showing your OS, working directory, a live **context-usage heat bar**, the active model, and time until your session window resets.

![preview](examples/preview.svg)

- **Heat bar** — an animated rainbow progress bar for context-window usage, with an **emoji temperature gauge** (🧊 → 🌡️ → 🔥 → 💥 → ☢️) that heats up as you fill the window.
- **Rainbow model name** — the model name flows the same moving gradient as the bar, its left edge picking up the bar's leading color.
- **Per-device color profiles** — each machine auto-selects its own palette by hostname, so your laptop and your server look different at a glance.
- **Cross-platform** — one pure-Python core runs on **macOS, Linux, and Windows 11**.
- **Fully themeable** — every color, the separator glyph, the emoji sequence and its thresholds, and the bar's speed/width/vibrancy live in one config file. The script itself never needs editing.

## Requirements

- [Claude Code](https://code.claude.com) CLI
- **Python 3** on your `PATH` (`python3`, `python`, or the Windows `py` launcher)
- A terminal with **24-bit truecolor** and emoji support (iTerm2, Kitty, WezTerm, Alacritty, GNOME Terminal, Windows Terminal, …)

No other dependencies — the renderer is pure Python standard library.

## Install

**macOS / Linux**

```bash
git clone https://github.com/srak71/pretty-claude-cli.git
cd pretty-claude-cli
./install.sh
```

**Windows 11 (PowerShell)**

```powershell
git clone https://github.com/srak71/pretty-claude-cli.git
cd pretty-claude-cli
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer copies the status line to `~/.claude/pretty-claude-cli/`, drops a starter config there, and adds a `statusLine` entry to `~/.claude/settings.json` (preserving any other settings you already have). Start a new Claude Code session to see it.

> On Windows, Claude Code runs status line commands through **Git Bash** if it's installed, otherwise **PowerShell** — the installer wires up a `powershell -File …statusline.ps1` command that works with either.

## What the bar shows

| Segment | Meaning |
| --- | --- |
| `(macOS Tahoe 26.5.2)` | Operating system + version (auto-detected; also `Windows 11`, `Ubuntu 24.04`, …) |
| `~/Users/sar-mac/pretty-claude-cli` | Current working directory |
| `💥 ●●●●●●●●●●●●●●●●●●○○○○○○ 75%` | Context-window usage: emoji gauge + rainbow bar + percentage |
| `Claude Pro` | Your plan label |
| `Opus 4.8` | Active model for this session |
| `4h 43m` | Time remaining until the 5-hour session window resets |

## Customize

All appearance lives in **`~/.claude/pretty-claude-cli/config.ini`** (a copy of [`config.example.ini`](config.example.ini)). It's a plain INI file that works the same on every OS. Colors accept either truecolor `R;G;B` (e.g. `135;206;235`) or a basic SGR code (e.g. `32` = green, `96` = cyan).

### Colors & per-device profiles

Set your defaults in `[default]`, then add a `[host:<hostname>]` section to override colors on a specific machine — it's selected automatically by hostname:

```ini
[default]
device_color = 135;206;235     # sky blue

[host:my-linux-box]
device_color = 32              # green

[host:my-windows-pc]
device_color = 170;120;255     # violet
```

Find your hostname with `hostname -s` (macOS/Linux) or `$env:COMPUTERNAME` (Windows). `device_color` tints the OS label, the `┃` separators, the `%` sign, and the time units — recoloring a device is a one-line change.

### Emoji temperature sequence

```ini
heat_emojis     = 🌱 🌿 🍂 🔥 🌋     # 5 stages, cool → critical
heat_thresholds = 20 40 60 80        # <20→0, <40→1, <60→2, <80→3, ≥80→4
heat_colors     = 96 92 93 91 95     # tint per stage
```

### Model name & bar

```ini
model_rainbow = 1            # 1 = rainbow flow; 0 = solid model_color
bar_width     = 24           # cells
bar_speed     = 0.03         # hue drift per second (smaller = calmer)
bar_neon_floor = 90          # 0-255 vibrancy lift
sep_char      = ┃            # separator glyph
path_style    = home         # home → ~/projects/app ; prefix → literal ~ prepend
```

See [`config.example.ini`](config.example.ini) for every option with inline docs.

## A note on smoothness

The animation is driven by Claude Code's `statusLine.refreshInterval` (in **seconds**; the minimum allowed is **1**). The installer sets it to `1` for the smoothest motion Claude Code permits — the wave drifts gently rather than jumping. Sub-second animation isn't possible through the status-line API.

## Uninstall

**macOS / Linux**

```bash
./uninstall.sh          # removes the status line, keeps your config
./uninstall.sh --purge  # also deletes ~/.claude/pretty-claude-cli/
```

**Windows**

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1          # keeps your config
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Purge   # deletes everything
```

## How it works

Claude Code pipes session JSON to `statusLine.command` on every update. A thin launcher (`statusline.sh` on macOS/Linux/Git Bash, `statusline.ps1` on Windows) locates Python and hands the JSON to **`statusline.py`**, which detects the OS, loads your `config.ini`, and prints one ANSI-colored line. No daemon, no dependencies beyond Python 3.

## Contributing

Ideas, themes, and fixes are welcome. Fork the repo, make your change on a
branch in your fork, and open a Pull Request against `main` — I review and
merge the ones I like. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full
workflow and a one-liner to test the bar locally. Bugs and theme ideas can go
in [Issues](https://github.com/srak71/pretty-claude-cli/issues).

## License

[MIT](LICENSE) © Saransh Rakshak
