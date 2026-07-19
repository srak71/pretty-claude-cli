#!/usr/bin/env python3
"""pretty-claude-cli — cross-platform status line for the Claude Code CLI.

Pure standard-library Python (works on macOS, Linux, and Windows). Reads the
Claude Code session JSON on stdin and prints one styled line on stdout.

Appearance is driven by a config file (INI). Nothing here is machine-specific;
edit config.ini, never this file. See config.example.ini for every option.
"""
import sys
import os
import io
import json
import time
import socket
import platform

# --- force UTF-8 I/O (Windows defaults to cp1252 → emoji/non-ASCII paths break)
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8",
                                      errors="replace")
    except Exception:
        pass
try:
    sys.stdin.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

RESET = "\033[0m"
BOLD = "\033[1m"
WH = "\033[97m"

DEFAULTS = {
    "device_color": "135;206;235",
    "sep_color": "",          # empty → falls back to device_color
    "unit_color": "",         # empty → falls back to device_color
    "path_color": "97",
    "accent_color": "255;140;80",
    "path_style": "home",     # "home" → ~/dir ; "prefix" → literal ~ prepend
    "model_rainbow": "1",
    "model_color": "70;130;180",
    "sep_char": "┃",
    "heat_emojis": "🧊 🌡️ 🔥 💥 ☢️",
    "heat_thresholds": "20 40 60 80",
    "heat_colors": "96 92 93 91 95",
    "bar_width": "24",
    "bar_speed": "0.03",
    "bar_span": "24",
    "bar_neon_floor": "90",
    "bar_filled": "●",
    "bar_empty": "○",
    "bar_empty_color": "90",
}


def short_hostname():
    name = os.environ.get("PCC_HOSTNAME") or socket.gethostname() or ""
    return name.split(".")[0].strip().lower()


def load_config():
    """Return a dict of settings: DEFAULTS, overlaid with [default] and the
    matching [host:<hostname>] section from the first config file found."""
    import configparser
    cfg = dict(DEFAULTS)
    here = os.path.dirname(os.path.abspath(__file__))
    candidates = [
        os.environ.get("PRETTY_CLAUDE_CONFIG", ""),
        os.path.join(os.path.expanduser("~"), ".config", "pretty-claude-cli", "config.ini"),
        os.path.join(os.path.expanduser("~"), ".claude", "pretty-claude-cli", "config.ini"),
        os.path.join(here, "config.ini"),
    ]
    path = next((p for p in candidates if p and os.path.isfile(p)), None)
    if not path:
        return cfg
    # '#' is the only comment char (full-line and inline) so that ';' inside
    # color values like "135;206;235" is never treated as a comment.
    parser = configparser.ConfigParser(
        interpolation=None,
        comment_prefixes=("#",),
        inline_comment_prefixes=("#",),
    )
    parser.optionxform = str  # keep keys as-written (all lowercase anyway)
    try:
        with open(path, encoding="utf-8") as f:
            parser.read_file(f)
    except Exception:
        return cfg
    if parser.has_section("default"):
        cfg.update({k.lower(): v for k, v in parser.items("default")})
    host_sec = "host:" + short_hostname()
    for sec in parser.sections():
        if sec.lower() == host_sec:
            cfg.update({k.lower(): v for k, v in parser.items(sec)})
            break
    return cfg


def col(spec):
    """Truecolor 'R;G;B' or a raw SGR code 'N' → ANSI escape. Blank → ''."""
    spec = str(spec).strip()
    if not spec:
        return ""
    if ";" in spec:
        return f"\033[38;2;{spec}m"
    return f"\033[{spec}m"


def os_label():
    override = os.environ.get("PCC_OS_LABEL")
    if override:
        return override
    system = platform.system()
    if system == "Darwin":
        ver = platform.mac_ver()[0] or ""
        if not ver:
            try:
                import subprocess
                ver = subprocess.run(["sw_vers", "-productVersion"],
                                     capture_output=True, text=True,
                                     timeout=2).stdout.strip()
            except Exception:
                ver = ""
        names = {"11": "Big Sur", "12": "Monterey", "13": "Ventura",
                 "14": "Sonoma", "15": "Sequoia", "26": "Tahoe"}
        name = names.get(ver.split(".")[0], "") if ver else ""
        if name and ver:
            return f"macOS {name} {ver}"
        return f"macOS {ver}".strip() or "macOS"
    if system == "Windows":
        try:
            build = sys.getwindowsversion().build
        except Exception:
            build = 0
        return "Windows 11" if build >= 22000 else "Windows 10"
    if system == "Linux":
        data = {}
        try:
            with open("/etc/os-release", encoding="utf-8") as f:
                for line in f:
                    if "=" in line:
                        k, v = line.rstrip("\n").split("=", 1)
                        data[k] = v.strip().strip('"')
        except Exception:
            pass
        return f"{data.get('NAME', 'Linux')} {data.get('VERSION_ID', '')}".strip()
    return f"{system} {platform.release()}".strip()


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
        pct = round(data["context_window"]["used_percentage"])
    except Exception:
        sys.stdout.write("… ?")
        return

    cfg = load_config()

    def g(k):
        return cfg.get(k, DEFAULTS.get(k, ""))

    device_c = col(g("device_color"))
    path_c = col(g("path_color"))
    accent_c = col(g("accent_color"))
    sep_c = col(g("sep_color") or g("device_color"))
    unit_c = col(g("unit_color") or g("device_color"))
    sep_char = g("sep_char")
    path_style = g("path_style")

    heat_emojis = g("heat_emojis").split()
    try:
        heat_thresh = [float(x) for x in g("heat_thresholds").split()]
    except Exception:
        heat_thresh = [20, 40, 60, 80]
    heat_colors = g("heat_colors").split()

    model_rainbow = g("model_rainbow").strip() == "1"
    model_solid_c = col(g("model_color"))

    def as_int(k, d):
        try:
            return int(float(g(k)))
        except Exception:
            return d

    def as_float(k, d):
        try:
            return float(g(k))
        except Exception:
            return d

    bar_w = max(1, as_int("bar_width", 24))
    bar_speed = as_float("bar_speed", 0.03)
    bar_span = as_float("bar_span", 24) or 24
    neon_floor = as_int("bar_neon_floor", 90)
    fill_ch = g("bar_filled") or "●"
    empty_ch = g("bar_empty") or "○"
    empty_c = col(g("bar_empty_color"))

    os_lbl = os_label()
    cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or "?"
    model = (data.get("model") or {}).get("display_name", "") or ""

    # --- path display -------------------------------------------------------
    home = os.path.expanduser("~")
    if path_style == "prefix":
        path_disp = "~" + cwd
    else:
        sep = os.sep
        if cwd == home:
            path_disp = "~"
        elif home and cwd.startswith(home + sep):
            path_disp = "~" + cwd[len(home):]
        else:
            path_disp = cwd

    # --- heat stage ---------------------------------------------------------
    stage = sum(1 for t in heat_thresh if pct >= t)
    if heat_emojis:
        stage = min(stage, len(heat_emojis) - 1)
        emoji = heat_emojis[stage]
        emoji_c = col(heat_colors[min(stage, len(heat_colors) - 1)]) if heat_colors else ""
    else:
        emoji, emoji_c = "", ""

    # --- session reset countdown -------------------------------------------
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

    # --- animated rainbow bar ----------------------------------------------
    _spread = 1.0 / bar_span
    filled = pct * bar_w // 100

    def hsv_rgb(hue):
        hue %= 1.0
        i = int(hue * 6)
        f = hue * 6 - i
        q = 1 - f
        segs = [(1, f, 0), (q, 1, 0), (0, 1, f), (0, q, 1), (f, 0, 1), (1, 0, q)]
        r, g_, b = segs[i % 6]
        fl = neon_floor
        return (int(r * (255 - fl)) + fl, int(g_ * (255 - fl)) + fl, int(b * (255 - fl)) + fl)

    def rgbseq(hue):
        r, g_, b = hsv_rgb(hue)
        return f"\033[38;2;{r};{g_};{b}m"

    t = time.time()
    bar = "".join(rgbseq(t * bar_speed + i * _spread) + fill_ch for i in range(filled))
    bar += f"{empty_c}{empty_ch * (bar_w - filled)}{RESET}"

    # --- model name (optionally flows the bar's rainbow) -------------------
    if model:
        if model_rainbow:
            base = t * bar_speed + max(0, filled - 1) * _spread
            model_str = "".join(rgbseq(base + j * _spread) + ch for j, ch in enumerate(model)) + RESET
        else:
            model_str = f"{model_solid_c}{model}{RESET}"
        model_part = f"{WH},{RESET} {model_str}"
    else:
        model_part = ""

    # --- assemble: three sections split by a single bar --------------------
    device = f"{BOLD}{device_c}({os_lbl}){RESET}"
    dir_str = f"{path_c}{path_disp}{RESET}"
    sep = f"{BOLD}{sep_c}{sep_char}{RESET}"
    heat = f"{emoji_c}{emoji}{RESET}" if (emoji and emoji_c) else emoji
    pct_seg = f"{WH}{pct}{RESET}{unit_c}%{RESET}"

    pro = f"{accent_c}Claude Pro{RESET}{model_part}"
    if reset_str:
        pro += f"{WH},{RESET} {reset_str}"

    heat_seg = (heat + " ") if heat else ""
    sys.stdout.write(f"{device} {dir_str}  {sep}  {heat_seg}{bar} {pct_seg}  {sep}  {pro}")


if __name__ == "__main__":
    main()
