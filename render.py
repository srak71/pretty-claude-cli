#!/usr/bin/env python3
"""pretty-claude-cli renderer.

Consumes the Claude Code status-line JSON (argv[1]) plus an OS label (argv[2])
and prints one styled line. Appearance is driven entirely by PCC_* environment
variables exported by statusline.sh from the user's config.sh. Nothing here is
machine-specific; edit config.sh, never this file.
"""
import sys
import os
import json
import time


def env(key, default):
    v = os.environ.get(key)
    return v if v not in (None, "") else default


def col(spec):
    """Turn a color spec into an ANSI escape.

    Accepts truecolor "R;G;B" (e.g. "135;206;235") or a raw SGR code
    (e.g. "97" for bright white, "32" for green).
    """
    spec = str(spec).strip()
    if ";" in spec:
        return f"\033[38;2;{spec}m"
    return f"\033[{spec}m"


RESET = "\033[0m"
BOLD = "\033[1m"
WH = "\033[97m"

try:
    data = json.loads(sys.argv[1])
    pct = round(data["context_window"]["used_percentage"])
except Exception:
    print("… ?", end="")
    sys.exit(0)

os_label = sys.argv[2] if len(sys.argv) > 2 else "system"
cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or "?"
model = (data.get("model") or {}).get("display_name", "") or ""

# --- config ----------------------------------------------------------------
device_c = col(env("PCC_DEVICE_COLOR", "135;206;235"))
path_c = col(env("PCC_PATH_COLOR", "97"))
accent_c = col(env("PCC_ACCENT_COLOR", "255;140;80"))
sep_c = col(env("PCC_SEP_COLOR", env("PCC_DEVICE_COLOR", "135;206;235")))
unit_c = col(env("PCC_UNIT_COLOR", env("PCC_DEVICE_COLOR", "135;206;235")))
sep_char = env("PCC_SEP_CHAR", "┃")
path_style = env("PCC_PATH_STYLE", "home")

heat_emojis = env("PCC_HEAT_EMOJIS", "🧊 🌡️ 🔥 💥 ☢️").split()
heat_thresh = [float(x) for x in env("PCC_HEAT_THRESHOLDS", "20 40 60 80").split()]
heat_colors = env("PCC_HEAT_COLORS", "96 92 93 91 95").split()

model_rainbow = env("PCC_MODEL_RAINBOW", "1") == "1"
model_solid_c = col(env("PCC_MODEL_COLOR", "70;130;180"))

bar_w = int(env("PCC_BAR_WIDTH", "24"))
bar_speed = float(env("PCC_BAR_SPEED", "0.03"))
bar_span = float(env("PCC_BAR_SPAN", "24"))
neon_floor = int(env("PCC_BAR_NEON_FLOOR", "90"))
fill_ch = env("PCC_BAR_FILLED", "●")
empty_ch = env("PCC_BAR_EMPTY", "○")
empty_c = col(env("PCC_BAR_EMPTY_COLOR", "90"))

# --- path display ----------------------------------------------------------
home = os.path.expanduser("~")
if path_style == "prefix":
    path_disp = "~" + cwd
elif cwd == home:
    path_disp = "~"
elif home and cwd.startswith(home + "/"):
    path_disp = "~" + cwd[len(home):]
else:
    path_disp = cwd

# --- heat stage ------------------------------------------------------------
stage = 0
for i, thr in enumerate(heat_thresh):
    if pct >= thr:
        stage = i + 1
stage = min(stage, len(heat_emojis) - 1)
emoji = heat_emojis[stage]
emoji_c = col(heat_colors[min(stage, len(heat_colors) - 1)]) if heat_colors else ""

# --- reset countdown (session window) --------------------------------------
reset_ts = ((data.get("rate_limits") or {}).get("five_hour") or {}).get("resets_at", 0)
remaining = max(0, int(reset_ts - time.time())) if reset_ts else 0
d, h, m = remaining // 86400, (remaining % 86400) // 3600, (remaining % 3600) // 60


def tu(n, u):
    return f"{WH}{n}{RESET}{unit_c}{u}{RESET}"


if remaining <= 0:
    reset_str = ""
elif d > 0:
    reset_str = f"{tu(d, 'd')} {tu(h, 'h')} {tu(m, 'm')}"
elif h > 0:
    reset_str = f"{tu(h, 'h')} {tu(m, 'm')}"
else:
    reset_str = f"{tu(m, 'm')}"

# --- animated rainbow bar --------------------------------------------------
_spread = 1.0 / bar_span
filled = pct * bar_w // 100


def hsv_rgb(hue):
    hue %= 1.0
    i = int(hue * 6)
    f = hue * 6 - i
    q = 1 - f
    segs = [(1, f, 0), (q, 1, 0), (0, 1, f), (0, q, 1), (f, 0, 1), (1, 0, q)]
    r, g, b = segs[i % 6]
    fl = neon_floor  # lift dark channels for a neon glow
    return (int(r * (255 - fl)) + fl, int(g * (255 - fl)) + fl, int(b * (255 - fl)) + fl)


def rgbseq(hue):
    r, g, b = hsv_rgb(hue)
    return f"\033[38;2;{r};{g};{b}m"


t = time.time()
bar = "".join(rgbseq(t * bar_speed + i * _spread) + fill_ch for i in range(filled))
bar += f"{empty_c}{empty_ch * (bar_w - filled)}{RESET}"

# --- model name (optionally flows the bar's rainbow) -----------------------
if model:
    if model_rainbow:
        base = t * bar_speed + max(0, filled - 1) * _spread
        model_str = "".join(rgbseq(base + j * _spread) + ch for j, ch in enumerate(model)) + RESET
    else:
        model_str = f"{model_solid_c}{model}{RESET}"
    model_part = f"{WH},{RESET} {model_str}"
else:
    model_part = ""

# --- assemble: three sections split by a single bar ------------------------
device = f"{BOLD}{device_c}({os_label}){RESET}"
dir_str = f"{path_c}{path_disp}{RESET}"
sep = f"{BOLD}{sep_c}{sep_char}{RESET}"
heat = f"{emoji_c}{emoji}{RESET}" if emoji_c else emoji
pct_seg = f"{WH}{pct}{RESET}{unit_c}%{RESET}"

pro = f"{accent_c}Claude Pro{RESET}{model_part}"
if reset_str:
    pro += f"{WH},{RESET} {reset_str}"

print(f"{device} {dir_str}  {sep}  {heat} {bar} {pct_seg}  {sep}  {pro}", end="")
