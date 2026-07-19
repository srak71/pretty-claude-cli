# Contributing to pretty-claude-cli

Thanks for wanting to improve this! Contributions are welcome — new color
themes, emoji sets, bug fixes, and features all land the same way: you work on
**your own branch in your own fork** and open a Pull Request. The maintainer
reviews it and merges the ones they like.

## The workflow

1. **Fork** this repo (top-right "Fork" button on GitHub).
2. **Clone your fork** and create a branch:
   ```bash
   git clone https://github.com/<you>/pretty-claude-cli.git
   cd pretty-claude-cli
   git checkout -b my-change
   ```
3. **Make your change** (see below) and commit it.
4. **Push to your fork** and open a Pull Request against `main`:
   ```bash
   git push origin my-change
   ```
   GitHub will show a "Compare & pull request" button.
5. The maintainer reviews. If it's a good fit, it gets merged. 🎉

You don't need any special access — forking + PR is the whole flow. (If you'd
rather push branches directly to this repo, ask the maintainer to add you as a
collaborator.)

## Project layout

- `statusline.py` — the whole renderer (pure Python 3 standard library, cross-platform).
- `statusline.sh` / `statusline.ps1` — thin launchers that locate Python (bash/Git Bash, and PowerShell).
- `config.example.ini` — every option, documented.
- `install.sh` / `install.ps1`, `uninstall.sh` / `uninstall.ps1` — per-OS setup.

## Testing your change locally

The status line reads session JSON on stdin. You can exercise `statusline.py`
directly without a live Claude Code session:

```bash
printf '%s' '{"context_window":{"used_percentage":75},
  "model":{"display_name":"Opus 4.8"},
  "workspace":{"current_dir":"/home/you/projects/demo"},
  "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":9999999999}}}' \
| python3 statusline.py; echo
```

On Windows (PowerShell):

```powershell
'{"context_window":{"used_percentage":75},"model":{"display_name":"Opus 4.8"},"workspace":{"current_dir":"C:/Users/you/demo"}}' | python statusline.py
```

Handy environment overrides for testing: `PCC_OS_LABEL` (fake the OS string),
`PCC_HOSTNAME` (test a `[host:…]` profile), `PRETTY_CLAUDE_CONFIG` (point at a
specific config file). Tweak the JSON (percentage, model, path) to see states.

## What makes a good PR

- **Keep it config-driven.** Appearance belongs in `config.example.ini` and the
  `PCC_*` / INI keys `statusline.py` already reads — not hard-coded.
- **Cross-platform.** Pure Python standard library; no OS-specific assumptions in
  `statusline.py`. If you touch a launcher or installer, update both the Unix
  (`.sh`) and Windows (`.ps1`) versions.
- **No personal data.** Don't commit real usernames, hostnames, home paths, or
  emails. Use neutral placeholders in examples.
- **Small and focused.** One idea per PR is easiest to review.
- **Describe it.** Say what changed and, for visual changes, paste a screenshot.

## Contributing a color theme

Themes are just a set of INI values. To propose one, open a PR that adds a
short, commented block to the "Alternates to try" notes in `config.example.ini`
(emoji sets, palettes, separator glyphs). A screenshot in the PR helps a lot.

## Reporting bugs / ideas

Open an [issue](https://github.com/srak71/pretty-claude-cli/issues) with your OS,
terminal, and what you saw vs. expected.
