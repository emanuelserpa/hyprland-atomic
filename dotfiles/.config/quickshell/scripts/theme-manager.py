#!/usr/bin/env python3
"""
Theme Manager for Quickshell Desktop Shell.
Manages theme definitions and persistence in ~/.local/state/quickshell/theme.json.
Output envelope adheres strictly to {"ok": bool, "error": str | None, ...}.
"""

import argparse
import colorsys
import configparser
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "quickshell"
STATE_FILE = STATE_DIR / "theme.json"
CHAMELEON_PALETTE_FILE = STATE_DIR / "chameleon-palette.json"
CANONICAL_PALETTE_FILE = STATE_DIR / "current_palette.json"
ADAPTERS_FILE = STATE_DIR / "adapters.json"
DEFAULT_WALLPAPER_PATH = Path.home() / ".cache" / "current_wallpaper"

CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
HYPR_CACHE_DIR = CACHE_DIR / "hypr"
HYPR_THEME_LUA = HYPR_CACHE_DIR / "theme.lua"
HYPRLOCK_COLORS_CONF = HYPR_CACHE_DIR / "hyprlock_colors.conf"

DEFAULT_THEME = "catppuccin-mocha"


def is_hyprland_session() -> bool:
    return (not os.environ.get("LABWC_PID")
            and "hyprland" in os.environ.get("XDG_CURRENT_DESKTOP", "").lower().split(":"))

GHOSTTY_CONFIG_PATH = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "ghostty" / "config"
GHOSTTY_THEMES_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "ghostty" / "themes"
FASTFETCH_CONFIG_PATH = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "fastfetch" / "config.jsonc"
GTK_THEMES_DIR = Path.home() / ".themes"

GHOSTTY_THEME_MAP = {
    "catppuccin-mocha": "Catppuccin Mocha",
    "tokyo-night": "TokyoNight",
    "nord": "Nord",
    "gruvbox": "Gruvbox Dark",
    "dracula": "Dracula",
    "dracula-pro": "dracula-pro",
    "dracula-pro-blade": "dracula-pro-blade",
    "dracula-pro-van-helsing": "dracula-pro-van-helsing",
    "everforest": "Everforest Dark Hard",
    "kanagawa": "Kanagawa Wave",
    "solarized-dark": "iTerm2 Solarized Dark",
    "rose-pine": "Rose Pine",
    "catppuccin-latte": "Catppuccin Latte",
    "ghostty": "Ghostty Default Style Dark",
    "chameleon": "chameleon",
    "chameleon-oled": "chameleon",
    "chameleon-light": "chameleon",
}


THEMES = {
    "catppuccin-mocha": {
        "id": "catppuccin-mocha",
        "name": "Catppuccin Mocha",
        "category": "dark",
        "description": "Suave e moderno (Padrão)",
        "accent": "#89b4fa",
        "colors": {
            "backgroundAlpha": 0.75,
            "backgroundOpaque": "#1e1e2e",
            "surface": "#313244",
            "surfaceHover": "#45475a",
            "foreground": "#cdd6f4",
            "offWhite": "#bac2de",
            "grey": "#585b70",
            "red": "#f38ba8",
            "green": "#a6e3a1",
            "yellow": "#f9e2af",
            "blue": "#89b4fa",
            "pink": "#f5c2e7",
            "cyan": "#94e2d5",
            "orange": "#fab387",
            "accent": "#89b4fa",
            "surfaceVariant": "#45475a",
        },
    },
    "tokyo-night": {
        "id": "tokyo-night",
        "name": "Tokyo Night",
        "category": "dark",
        "description": "Azul escuro e néon vibrante",
        "accent": "#7aa2f7",
        "colors": {
            "backgroundAlpha": 0.78,
            "backgroundOpaque": "#1a1b26",
            "surface": "#24283b",
            "surfaceHover": "#2f3549",
            "foreground": "#c0caf5",
            "offWhite": "#a9b1d6",
            "grey": "#565f89",
            "red": "#f7768e",
            "green": "#9ece6a",
            "yellow": "#e0af68",
            "blue": "#7aa2f7",
            "pink": "#bb9af7",
            "cyan": "#7dcfff",
            "orange": "#ff9e64",
            "accent": "#7aa2f7",
            "surfaceVariant": "#2f3549",
        },
    },
    "nord": {
        "id": "nord",
        "name": "Nord",
        "category": "dark",
        "description": "Tons frios e elegantes do ártico",
        "accent": "#88c0d0",
        "colors": {
            "backgroundAlpha": 0.80,
            "backgroundOpaque": "#2e3440",
            "surface": "#3b4252",
            "surfaceHover": "#434c5e",
            "foreground": "#eceff4",
            "offWhite": "#e5e9f0",
            "grey": "#4c566a",
            "red": "#bf616a",
            "green": "#a3be8c",
            "yellow": "#ebcb8b",
            "blue": "#88c0d0",
            "pink": "#b48ead",
            "cyan": "#8fbcbb",
            "orange": "#d08770",
            "accent": "#88c0d0",
            "surfaceVariant": "#434c5e",
        },
    },
    "gruvbox": {
        "id": "gruvbox",
        "name": "Gruvbox Dark",
        "category": "dark",
        "description": "Cores quentes e retrô terrosas",
        "accent": "#fe8019",
        "colors": {
            "backgroundAlpha": 0.82,
            "backgroundOpaque": "#282828",
            "surface": "#3c3836",
            "surfaceHover": "#504945",
            "foreground": "#ebdbb2",
            "offWhite": "#d5c4a1",
            "grey": "#665c54",
            "red": "#fb4934",
            "green": "#b8bb26",
            "yellow": "#fabd2f",
            "blue": "#83a598",
            "pink": "#d3869b",
            "cyan": "#8ec07c",
            "orange": "#fe8019",
            "accent": "#fe8019",
            "surfaceVariant": "#504945",
        },
    },
    "dracula": {
        "id": "dracula",
        "name": "Dracula",
        "category": "dark",
        "description": "Gótico com roxo e rosa de alto contraste",
        "accent": "#bd93f9",
        "colors": {
            "backgroundAlpha": 0.80,
            "backgroundOpaque": "#282a36",
            "surface": "#343746",
            "surfaceHover": "#44475a",
            "foreground": "#f8f8f2",
            "offWhite": "#e2e2dc",
            "grey": "#6272a4",
            "red": "#ff5555",
            "green": "#50fa7b",
            "yellow": "#f1fa8c",
            "blue": "#bd93f9",
            "pink": "#ff79c6",
            "cyan": "#8be9fd",
            "orange": "#ffb86c",
            "accent": "#bd93f9",
            "surfaceVariant": "#44475a",
        },
    },
    "rose-pine": {
        "id": "rose-pine",
        "name": "Rosé Pine",
        "category": "dark",
        "description": "Madeira de pinho, lilás e rosé suave",
        "accent": "#c4a7e7",
        "colors": {
            "backgroundAlpha": 0.78,
            "backgroundOpaque": "#191724",
            "surface": "#1f1d2e",
            "surfaceHover": "#26233a",
            "foreground": "#e0def4",
            "offWhite": "#908caa",
            "grey": "#6e6a86",
            "red": "#eb6f92",
            "green": "#9ccfd8",
            "yellow": "#f6c177",
            "blue": "#31748f",
            "pink": "#ebbcba",
            "cyan": "#c4a7e7",
            "orange": "#ea9a97",
            "accent": "#c4a7e7",
            "surfaceVariant": "#26233a",
        },
    },
    "catppuccin-latte": {
        "id": "catppuccin-latte",
        "name": "Catppuccin Latte",
        "category": "light",
        "description": "Modo claro suave e agradável aos olhos",
        "accent": "#1e66f5",
        "colors": {
            "backgroundAlpha": 0.94,
            "backgroundOpaque": "#eff1f5",
            "surface": "#e6e9ef",
            "surfaceHover": "#dce0e8",
            "foreground": "#4c4f69",
            "offWhite": "#5c5f77",
            "grey": "#8c8fa1",
            "red": "#d20f39",
            "green": "#40a02b",
            "yellow": "#df8e1d",
            "blue": "#1e66f5",
            "pink": "#ea76cb",
            "cyan": "#179299",
            "orange": "#fe640b",
            "accent": "#1e66f5",
            "surfaceVariant": "#dce0e8",
        },
    },
    "ghostty": {
        "id": "ghostty",
        "name": "Ghostty Dark",
        "category": "dark",
        "description": "Tema escuro padrão oficial do Ghostty",
        "accent": "#82a2be",
        "colors": {
            "backgroundAlpha": 0.78,
            "backgroundOpaque": "#282c34",
            "surface": "#353b45",
            "surfaceHover": "#404754",
            "foreground": "#eaeaea",
            "offWhite": "#c4c8c6",
            "grey": "#7c828d",
            "red": "#d54e53",
            "green": "#b9ca4b",
            "yellow": "#e7c547",
            "blue": "#82a2be",
            "pink": "#c397d8",
            "cyan": "#70c0b1",
            "orange": "#e78c45",
            "accent": "#82a2be",
            "surfaceVariant": "#404754",
        },
    },
    "dracula-pro": {
        "id": "dracula-pro",
        "name": "Dracula Pro",
        "category": "dark",
        "description": "Edição oficial refinada com roxo neon e ardósia escuro",
        "accent": "#9580ff",
        "colors": {
            "backgroundAlpha": 0.78,
            "backgroundOpaque": "#22212c",
            "surface": "#343346",
            "surfaceHover": "#454158",
            "foreground": "#f8f8f2",
            "offWhite": "#e2e2ec",
            "grey": "#7970a9",
            "red": "#ff9580",
            "green": "#8aff80",
            "yellow": "#ffff80",
            "blue": "#9580ff",
            "pink": "#ff80bf",
            "cyan": "#80ffea",
            "orange": "#ffca80",
            "accent": "#9580ff",
            "surfaceVariant": "#343346",
        },
    },
    "dracula-pro-blade": {
        "id": "dracula-pro-blade",
        "name": "Dracula Pro Blade",
        "category": "dark",
        "description": "Edição Dracula Pro com matiz esmeralda escuro e ciano",
        "accent": "#80ffea",
        "colors": {
            "backgroundAlpha": 0.78,
            "backgroundOpaque": "#212c2a",
            "surface": "#313f3c",
            "surfaceHover": "#415854",
            "foreground": "#f8f8f2",
            "offWhite": "#e2e2ec",
            "grey": "#70a99f",
            "red": "#ff9580",
            "green": "#8aff80",
            "yellow": "#ffff80",
            "blue": "#9580ff",
            "pink": "#ff80bf",
            "cyan": "#80ffea",
            "orange": "#ffca80",
            "accent": "#80ffea",
            "surfaceVariant": "#313f3c",
        },
    },
    "dracula-pro-van-helsing": {
        "id": "dracula-pro-van-helsing",
        "name": "Dracula Pro Van Helsing",
        "category": "dark",
        "description": "Edição Dracula Pro midnight com fundo preto profundo",
        "accent": "#9580ff",
        "colors": {
            "backgroundAlpha": 0.85,
            "backgroundOpaque": "#0b0d0f",
            "surface": "#1b232a",
            "surfaceHover": "#2c3742",
            "foreground": "#f8f8f2",
            "offWhite": "#e2e2ec",
            "grey": "#708ca9",
            "red": "#ff9580",
            "green": "#8aff80",
            "yellow": "#ffff80",
            "blue": "#9580ff",
            "pink": "#ff80bf",
            "cyan": "#80ffea",
            "orange": "#ffca80",
            "accent": "#9580ff",
            "surfaceVariant": "#1b232a",
        },
    },
    "everforest": {
        "id": "everforest",
        "name": "Everforest Dark",
        "category": "dark",
        "description": "Verde natural e tons terrosos suaves e confortáveis",
        "accent": "#a7c080",
        "colors": {
            "backgroundAlpha": 0.80,
            "backgroundOpaque": "#2d353b",
            "surface": "#343f44",
            "surfaceHover": "#3d484d",
            "foreground": "#d3c6aa",
            "offWhite": "#e6dfb8",
            "grey": "#7a8478",
            "red": "#e67e80",
            "green": "#a7c080",
            "yellow": "#dbbc7f",
            "blue": "#7fbbb3",
            "pink": "#d699b6",
            "cyan": "#83c092",
            "orange": "#e69875",
            "accent": "#a7c080",
            "surfaceVariant": "#343f44",
        },
    },
    "kanagawa": {
        "id": "kanagawa",
        "name": "Kanagawa Wave",
        "category": "dark",
        "description": "Inspirado em pinturas japonesas clássicas ukiyo-e",
        "accent": "#7e9cd8",
        "colors": {
            "backgroundAlpha": 0.80,
            "backgroundOpaque": "#1f1f28",
            "surface": "#2a2a37",
            "surfaceHover": "#363646",
            "foreground": "#dcd7ba",
            "offWhite": "#c8c093",
            "grey": "#727169",
            "red": "#c34043",
            "green": "#76946a",
            "yellow": "#c0a36e",
            "blue": "#7e9cd8",
            "pink": "#957fb8",
            "cyan": "#7aa89f",
            "orange": "#ffa066",
            "accent": "#7e9cd8",
            "surfaceVariant": "#2a2a37",
        },
    },
    "solarized-dark": {
        "id": "solarized-dark",
        "name": "Solarized Dark",
        "category": "dark",
        "description": "Esquema clássico de precisão cromática com azul e ciano",
        "accent": "#268bd2",
        "colors": {
            "backgroundAlpha": 0.80,
            "backgroundOpaque": "#002b36",
            "surface": "#073642",
            "surfaceHover": "#0f4a59",
            "foreground": "#839496",
            "offWhite": "#93a1a1",
            "grey": "#586e75",
            "red": "#dc322f",
            "green": "#859900",
            "yellow": "#b58900",
            "blue": "#268bd2",
            "pink": "#d33682",
            "cyan": "#2aa198",
            "orange": "#cb4b16",
            "accent": "#268bd2",
            "surfaceVariant": "#073642",
        },
    },
    "chameleon": {
        "id": "chameleon",
        "name": "Chameleon",
        "category": "dark",
        "description": "Paleta dinâmica adaptativa do papel de parede (Equilibrada)",
        "accent": "#4ca8e0",
        "colors": {
            "backgroundAlpha": 0.82,
            "backgroundOpaque": "#07131b",
            "surface": "#13212b",
            "surfaceElevated": "#1e2d38",
            "surfaceHover": "#293a46",
            "surfaceSelected": "#344855",
            "surfaceVariant": "#1e2d38",
            "border": "#2e404e",
            "borderSubtle": "#21303c",
            "foreground": "#ecf3f8",
            "offWhite": "#d6e2ec",
            "grey": "#8d9aa3",
            "textMuted": "#75848e",
            "textDisabled": "#505e68",
            "red": "#e86883",
            "green": "#56c888",
            "yellow": "#d3d166",
            "blue": "#44a6ef",
            "pink": "#d490e6",
            "cyan": "#4fccd8",
            "orange": "#f98b72",
            "accent": "#4ca8e0",
            "accentMuted": "#224b67",
        },
    },
    "chameleon-oled": {
        "id": "chameleon-oled",
        "name": "Chameleon OLED",
        "category": "dark",
        "description": "Paleta dinâmica com fundo preto puro (OLED)",
        "accent": "#3ea9e7",
        "colors": {
            "backgroundAlpha": 0.96,
            "backgroundOpaque": "#000000",
            "surface": "#0c1015",
            "surfaceElevated": "#141a20",
            "surfaceHover": "#1e252c",
            "surfaceSelected": "#28323b",
            "surfaceVariant": "#141a20",
            "border": "#26303a",
            "borderSubtle": "#182028",
            "foreground": "#ffffff",
            "offWhite": "#dce2e8",
            "grey": "#8d9aa3",
            "textMuted": "#707d86",
            "textDisabled": "#4a555e",
            "red": "#e86883",
            "green": "#56c888",
            "yellow": "#d3d166",
            "blue": "#44a6ef",
            "pink": "#d490e6",
            "cyan": "#4fccd8",
            "orange": "#f98b72",
            "accent": "#3ea9e7",
            "accentMuted": "#1a3b50",
        },
    },
    "chameleon-light": {
        "id": "chameleon-light",
        "name": "Chameleon Light",
        "category": "light",
        "description": "Variante clara do matiz do papel de parede",
        "accent": "#4a6fa5",
        "colors": {
            "backgroundAlpha": 0.94,
            "backgroundOpaque": "#eef0f6",
            "surface": "#e6e9f1",
            "surfaceElevated": "#dde1ea",
            "surfaceHover": "#d3d8e3",
            "surfaceSelected": "#c3cbda",
            "surfaceVariant": "#dde1ea",
            "border": "#b9c1d1",
            "borderSubtle": "#cfd5e2",
            "foreground": "#232838",
            "offWhite": "#39415a",
            "grey": "#6b7490",
            "textMuted": "#6b7490",
            "textDisabled": "#9aa2b8",
            "red": "#c94f5e",
            "green": "#3d8a52",
            "yellow": "#9a7414",
            "blue": "#2f6fd0",
            "pink": "#b050a8",
            "cyan": "#1f8a94",
            "orange": "#c25a1e",
            "accent": "#4a6fa5",
            "accentMuted": "#b9c9e4",
        },
    },
}


def rgb_to_hex(r, g, b):
    return f"#{int(round(r)):02x}{int(round(g)):02x}{int(round(b)):02x}"


def hsl_to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h, max(0.0, min(1.0, l)), max(0.0, min(1.0, s)))
    return rgb_to_hex(r * 255, g * 255, b * 255)


def hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
    clean = str(hex_str or "").lstrip("#")
    if len(clean) == 6:
        try:
            return int(clean[0:2], 16), int(clean[2:4], 16), int(clean[4:6], 16)
        except ValueError:
            pass
    return 128, 128, 128


def brighten_hex(hex_str: str, amount: float = 0.08) -> str:
    r, g, b = hex_to_rgb(hex_str)
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return hsl_to_hex(h, s, min(0.95, l + amount))


def darken_hex(hex_str: str, amount: float = 0.06) -> str:
    r, g, b = hex_to_rgb(hex_str)
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return hsl_to_hex(h, s, max(0.02, l - amount))


def desaturate_hex(hex_str: str, factor: float = 0.35) -> str:
    """Reduce saturation, keeping lightness: neutralizes large flat areas
    from strongly tinted wallpapers while the accent stays vivid."""
    r, g, b = hex_to_rgb(hex_str)
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return hsl_to_hex(h, max(0.0, min(1.0, s * factor)), l)


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_srgb(c: float) -> float:
    c_clamped = max(0.0, min(1.0, c))
    return 12.92 * c_clamped if c_clamped <= 0.0031308 else 1.055 * (c_clamped ** (1.0 / 2.4)) - 0.055


def rgb_to_oklch(r: float, g: float, b: float) -> tuple[float, float, float]:
    lr = srgb_to_linear(r / 255.0)
    lg = srgb_to_linear(g / 255.0)
    lb = srgb_to_linear(b / 255.0)

    l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb
    m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb
    s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb

    l_ = max(0.0, l) ** (1.0 / 3.0)
    m_ = max(0.0, m) ** (1.0 / 3.0)
    s_ = max(0.0, s) ** (1.0 / 3.0)

    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    C = math.sqrt(a * a + b_ * b_)
    h = math.degrees(math.atan2(b_, a)) % 360.0
    return L, C, h


def oklch_to_rgb(L: float, C: float, h_deg: float) -> str:
    h_rad = math.radians(h_deg % 360.0)
    a = C * math.cos(h_rad)
    b_ = C * math.sin(h_rad)

    l_ = L + 0.3963377774 * a + 0.2158037573 * b_
    m_ = L - 0.1055613458 * a - 0.0638541728 * b_
    s_ = L - 0.0894841775 * a - 1.2914855480 * b_

    l = l_ ** 3
    m = m_ ** 3
    s = s_ ** 3

    lr = +4.0767434729 * l - 3.3077115913 * m + 0.2309699292 * s
    lg = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    lb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    r = int(round(linear_to_srgb(lr) * 255))
    g = int(round(linear_to_srgb(lg) * 255))
    b = int(round(linear_to_srgb(lb) * 255))
    return f"#{r:02x}{g:02x}{b:02x}"


def generate_harmonized_semantics(dom_h: float, sat_factor: float = 1.0) -> dict[str, str]:
    base_semantics = {
        "red": (0.68, 0.16 * sat_factor, 27.0),
        "orange": (0.75, 0.14 * sat_factor, 55.0),
        "yellow": (0.84, 0.13 * sat_factor, 90.0),
        "green": (0.75, 0.14 * sat_factor, 145.0),
        "cyan": (0.78, 0.11 * sat_factor, 200.0),
        "blue": (0.70, 0.14 * sat_factor, 245.0),
        "pink": (0.75, 0.14 * sat_factor, 330.0),
    }
    res = {}
    for name, (l, c, base_h) in base_semantics.items():
        diff = ((dom_h - base_h + 180.0) % 360.0) - 180.0
        shifted_h = (base_h + diff * 0.12) % 360.0
        res[name] = oklch_to_rgb(l, c, shifted_h)
    return res


def get_chameleon_fallback(variant: str = "chameleon"):
    target = variant if variant in ("chameleon", "chameleon-light", "chameleon-oled") else "chameleon"
    source = "#6750a4"
    light = target == "chameleon-light"
    roles = material_tonal_spot_roles(source, is_dark=not light)
    semantics = generate_harmonized_semantics(280.0, 0.9 if light else 1.1)
    return material_chameleon_variant(target, source, roles, "", 0, 0.85, semantics)


def detect_current_wallpaper() -> str | None:
    """
    Detecta o wallpaper ativo no sistema.
    1. Consulta o daemon awww se estiver rodando
    2. Consulta o daemon swww se estiver rodando
    3. Consulta hyprpaper se estiver rodando
    4. Usa ~/.cache/current_wallpaper
    """
    import shutil
    import subprocess

    # 1. awww query
    if shutil.which("awww"):
        try:
            res = subprocess.run(["awww", "query"], capture_output=True, text=True, timeout=1)
            if res.returncode == 0:
                m = re.search(r"currently displaying:\s*image:\s*(.+)$", res.stdout.strip(), re.MULTILINE)
                if m:
                    p = Path(m.group(1).strip())
                    if p.is_file():
                        return str(p)
        except Exception:
            pass

    # 2. swww query
    if shutil.which("swww"):
        try:
            res = subprocess.run(["swww", "query"], capture_output=True, text=True, timeout=1)
            if res.returncode == 0:
                m = re.search(r"image:\s*(.+)$", res.stdout.strip(), re.MULTILINE)
                if m:
                    p = Path(m.group(1).strip())
                    if p.is_file():
                        return str(p)
        except Exception:
            pass

    # 3. hyprpaper
    if is_hyprland_session() and shutil.which("hyprctl"):
        try:
            res = subprocess.run(["hyprctl", "hyprpaper", "listactive"], capture_output=True, text=True, timeout=1)
            if res.returncode == 0:
                m = re.search(r"=\s*(.+)$", res.stdout.strip(), re.MULTILINE)
                if m:
                    p = Path(m.group(1).strip())
                    if p.is_file():
                        return str(p)
        except Exception:
            pass

    # 4. ~/.cache/current_wallpaper
    if DEFAULT_WALLPAPER_PATH.is_file():
        return str(DEFAULT_WALLPAPER_PATH)

    return None


def compute_top_luminance(im) -> float:
    """
    Calcula a luminância perceptual média da faixa superior (15%) do wallpaper,
    onde a barra do Quickshell se posiciona.
    """
    try:
        top_strip = im.crop((0, 0, im.width, max(1, int(im.height * 0.15))))
        thumb = top_strip.resize((60, 60))
        colors = thumb.getcolors(3600) or []
        if not colors:
            return 0.5
        total_lum = sum((0.2126 * r + 0.7152 * g + 0.0722 * b) * count for count, (r, g, b) in colors)
        total_count = sum(count for count, _ in colors)
        return total_lum / (total_count * 255.0)
    except Exception:
        return 0.5


def material_tonal_spot_roles(source_hex: str, is_dark: bool = True) -> dict:
    """Material Color Utilities Tonal Spot, 2021 specification."""
    vendor_dir = str(Path(__file__).with_name("vendor"))
    if vendor_dir not in sys.path:
        sys.path.insert(0, vendor_dir)
    from materialyoucolor.hct import Hct
    from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
    from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors

    scheme = SchemeTonalSpot(Hct.from_int(int("ff" + source_hex[1:], 16)), is_dark, 0.0, spec_version="2021")
    colors = MaterialDynamicColors(spec="2021")
    roles = (
        "background", "surface", "surfaceContainer", "surfaceContainerHigh",
        "surfaceContainerHighest", "surfaceVariant", "onSurface", "onSurfaceVariant",
        "outline", "primary", "onPrimary", "primaryContainer",
        "onPrimaryContainer", "secondary", "tertiary", "error",
    )
    return {role: getattr(colors, role).get_hex(scheme)[:7].lower() for role in roles}


def material_chameleon_variant(variant_id, source_hex, roles, wallpaper, wallpaper_mtime,
                               alpha, semantics):
    is_light = variant_id == "chameleon-light"
    is_oled = variant_id == "chameleon-oled"
    names = {"chameleon": "Chameleon", "chameleon-light": "Chameleon Light",
             "chameleon-oled": "Chameleon OLED"}
    colors = {
        "backgroundAlpha": 0.96 if is_oled else (0.94 if is_light else alpha),
        "backgroundOpaque": "#000000" if is_oled else roles["background"],
        "surface": "#000000" if is_oled else roles["surface"],
        "surfaceElevated": roles["surfaceContainer"],
        "surfaceHover": roles["surfaceContainerHigh"],
        "surfaceSelected": roles["primaryContainer"],
        "surfaceVariant": roles["surfaceVariant"],
        "border": roles["outline"],
        "borderSubtle": roles["surfaceContainerHigh"],
        "foreground": roles["onSurface"],
        "offWhite": roles["onSurfaceVariant"],
        "grey": roles["outline"],
        "textMuted": roles["onSurfaceVariant"],
        "textDisabled": roles["outline"],
        "accent": roles["primary"],
        "accentMuted": roles["primaryContainer"],
        "primary": roles["primary"],
        "onPrimary": roles["onPrimary"],
        "primaryContainer": roles["primaryContainer"],
        "onPrimaryContainer": roles["onPrimaryContainer"],
        "secondary": roles["secondary"],
        "tertiary": roles["tertiary"],
        "onSurface": roles["onSurface"],
        "outline": roles["outline"],
        **semantics,
    }
    return {
        "id": variant_id, "name": names[variant_id],
        "category": "light" if is_light else "dark",
        "description": "Material Tonal Spot do papel de parede" + (" com fundo preto" if is_oled else ""),
        "wallpaper": str(wallpaper), "wallpaper_mtime": wallpaper_mtime,
        "sourceColor": source_hex, "accent": roles["primary"], "colors": colors,
    }


def extract_chameleon_palette(wallpaper_path=None, target_variant="chameleon"):
    """
    Escolhe uma cor do wallpaper e gera três esquemas Material Tonal Spot:
    normal, claro e OLED. Salva os tokens em
    ~/.local/state/quickshell/chameleon-palette.json.
    """
    target = str(target_variant or "chameleon").strip().lower()
    detected = wallpaper_path or detect_current_wallpaper()
    path = Path(detected) if detected else DEFAULT_WALLPAPER_PATH
    if not path.is_file():
        if CHAMELEON_PALETTE_FILE.is_file():
            try:
                cached = json.loads(CHAMELEON_PALETTE_FILE.read_text(encoding="utf-8"))
                if target in cached.get("variants", {}):
                    return cached["variants"][target]
                return cached
            except Exception:
                pass
        return get_chameleon_fallback(target)

    try:
        from PIL import Image

        img = Image.open(path).convert("RGB")
        top_lum = compute_top_luminance(img)

        # Transparência dinâmica adaptada à luminosidade de fundo
        if top_lum >= 0.65:
            bg_alpha = 0.90
        elif top_lum >= 0.45:
            bg_alpha = 0.86
        elif top_lum >= 0.25:
            bg_alpha = 0.82
        else:
            bg_alpha = 0.78

        thumb = img.resize((160, 160))
        quantized = thumb.quantize(colors=48, method=Image.Quantize.MEDIANCUT)
        palette_raw = quantized.getpalette()[:48 * 3]
        colors_freq = quantized.getcolors(160 * 160) or []

        chromatic_candidates = []
        for count, idx in colors_freq:
            r, g, b = palette_raw[idx * 3], palette_raw[idx * 3 + 1], palette_raw[idx * 3 + 2]
            L, C, h = rgb_to_oklch(r, g, b)
            # Ignora quase-brancos, pretos absolutos e tons desprovidos de croma
            if C >= 0.02 and 0.10 <= L <= 0.90:
                score = C * 3.0 + (1.0 - abs(L - 0.65) * 1.5) + math.log1p(count) * 0.15
                chromatic_candidates.append((score, L, C, h, count, (r, g, b)))

        chromatic_candidates.sort(key=lambda x: x[0], reverse=True)
        if chromatic_candidates:
            best = chromatic_candidates[0]
            dom_h = best[3]
        else:
            dom_h = 220.0  # Fallback: azul ardósia

        sem_tonal = generate_harmonized_semantics(dom_h, 1.1)
        sem_light = generate_harmonized_semantics(dom_h, 0.9)
        source_rgb = chromatic_candidates[0][5] if chromatic_candidates else (90, 130, 170)
        source_hex = "#{:02x}{:02x}{:02x}".format(*source_rgb)
        material_roles = material_tonal_spot_roles(source_hex)
        material_roles_light = material_tonal_spot_roles(source_hex, is_dark=False)
        wp_stat = path.stat()

        variants_map = {
            "chameleon": material_chameleon_variant(
                "chameleon", source_hex, material_roles, path, wp_stat.st_mtime,
                bg_alpha, sem_tonal),
            "chameleon-light": material_chameleon_variant(
                "chameleon-light", source_hex, material_roles_light, path,
                wp_stat.st_mtime, 0.94, sem_light),
            "chameleon-oled": material_chameleon_variant(
                "chameleon-oled", source_hex, material_roles, path,
                wp_stat.st_mtime, 0.96, sem_tonal),
        }

        palette_payload = {
            "wallpaper": str(path),
            "wallpaper_mtime": wp_stat.st_mtime,
            "algorithm": "material-tonal-spot-2021-v1",
            "top_luminance": top_lum,
            "dominant_hue": dom_h,
            "variants": variants_map,
            **variants_map["chameleon"],
        }

        # Also copy to DEFAULT_WALLPAPER_PATH if different so cache stays updated
        if path != DEFAULT_WALLPAPER_PATH:
            try:
                import shutil
                shutil.copy2(path, DEFAULT_WALLPAPER_PATH)
            except Exception:
                pass

        STATE_DIR.mkdir(parents=True, exist_ok=True)
        temp_file = CHAMELEON_PALETTE_FILE.with_suffix(".tmp")
        temp_file.write_text(json.dumps(palette_payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        temp_file.replace(CHAMELEON_PALETTE_FILE)

        curr = read_current_theme_id()
        if curr.startswith("chameleon"):
            active_var = variants_map.get(curr, variants_map["chameleon"])
            try:
                generate_ghostty_chameleon_theme(active_var)
                sync_ghostty_theme(curr, palette=active_var)
            except Exception:
                pass

        return variants_map.get(target, variants_map["chameleon"])
    except Exception:
        return get_chameleon_fallback(target)


def get_chameleon_palette(variant_id: str = "chameleon"):
    v = str(variant_id or "chameleon").strip().lower()
    active_wp = detect_current_wallpaper()
    if active_wp and Path(active_wp).is_file():
        wp_path = Path(active_wp)
        if CHAMELEON_PALETTE_FILE.is_file():
            try:
                cached = json.loads(CHAMELEON_PALETTE_FILE.read_text(encoding="utf-8"))
                if (cached.get("algorithm") == "material-tonal-spot-2021-v1" and
                    cached.get("wallpaper") == str(wp_path) and
                    cached.get("wallpaper_mtime") == wp_path.stat().st_mtime):
                    if v in cached.get("variants", {}):
                        return cached["variants"][v]
                    return cached
            except Exception:
                pass
        return extract_chameleon_palette(wp_path, target_variant=v)
    if CHAMELEON_PALETTE_FILE.is_file():
        try:
            cached = json.loads(CHAMELEON_PALETTE_FILE.read_text(encoding="utf-8"))
            if v in cached.get("variants", {}):
                return cached["variants"][v]
            return cached
        except Exception:
            pass
    return extract_chameleon_palette(target_variant=v)


def generate_ghostty_theme_file(theme_name: str, palette: dict, themes_dir: Path | None = None) -> Path:
    """
    Gera um arquivo de tema customizado para o Ghostty (~/.config/ghostty/themes/<theme_name>).
    """
    c = palette.get("colors", {})
    t_dir = themes_dir if themes_dir is not None else GHOSTTY_THEMES_DIR
    t_dir.mkdir(parents=True, exist_ok=True)
    theme_file = t_dir / theme_name

    bg = c.get("backgroundOpaque", "#07131b")
    fg = c.get("foreground", "#ecf3f8")
    accent = c.get("accent", "#4ca8e0")
    surface = c.get("surface", "#13212b")
    surface_hover = c.get("surfaceHover", "#293a46")
    surface_selected = c.get("surfaceSelected", surface_hover)
    grey = c.get("grey", "#8d9aa3")
    off_white = c.get("offWhite", fg)

    red = c.get("red", "#e86883")
    green = c.get("green", "#56c888")
    yellow = c.get("yellow", "#d3d166")
    blue = c.get("blue", "#44a6ef")
    pink = c.get("pink", "#d490e6")
    cyan = c.get("cyan", "#4fccd8")

    bright_red = brighten_hex(red, 0.08)
    bright_green = brighten_hex(green, 0.08)
    bright_yellow = brighten_hex(yellow, 0.08)
    bright_blue = brighten_hex(blue, 0.08)
    bright_pink = brighten_hex(pink, 0.08)
    bright_cyan = brighten_hex(cyan, 0.08)

    lines = [
        f"palette = 0={surface}",
        f"palette = 1={red}",
        f"palette = 2={green}",
        f"palette = 3={yellow}",
        f"palette = 4={blue}",
        f"palette = 5={pink}",
        f"palette = 6={cyan}",
        f"palette = 7={off_white}",
        f"palette = 8={grey}",
        f"palette = 9={bright_red}",
        f"palette = 10={bright_green}",
        f"palette = 11={bright_yellow}",
        f"palette = 12={bright_blue}",
        f"palette = 13={bright_pink}",
        f"palette = 14={bright_cyan}",
        f"palette = 15={fg}",
        f"background = {bg}",
        f"foreground = {fg}",
        f"cursor-color = {accent}",
        f"cursor-text = {bg}",
        f"selection-background = {surface_selected}",
        f"selection-foreground = {fg}",
    ]
    content = "\n".join(lines) + "\n"
    temp_file = theme_file.with_suffix(".tmp")
    temp_file.write_text(content, encoding="utf-8")
    temp_file.replace(theme_file)
    return theme_file


def generate_ghostty_chameleon_theme(palette: dict | None = None, themes_dir: Path | None = None) -> Path:
    """
    Gera o arquivo de tema customizado do Ghostty (~/.config/ghostty/themes/chameleon)
    com base nas cores extraídas da paleta Chameleon.
    """
    p = palette or get_chameleon_palette(read_current_theme_id())
    return generate_ghostty_theme_file("chameleon", p, themes_dir=themes_dir)


def read_current_theme_id():
    try:
        if STATE_FILE.is_file():
            data = json.loads(STATE_FILE.read_text(encoding="utf-8"))
            theme_id = str(data.get("theme", "")).strip().lower()
            if theme_id in ("chameleon-vibrant", "chameleon-tonal", "chameleon-material"):
                return "chameleon"
            if theme_id in THEMES:
                return theme_id
    except Exception:
        pass
    return DEFAULT_THEME


def write_current_theme_id(theme_id):
    if theme_id not in THEMES:
        raise ValueError(f"Tema desconhecido: '{theme_id}'. Disponíveis: {', '.join(THEMES.keys())}")
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    temp_file = STATE_FILE.with_suffix(".tmp")
    data = {"theme": theme_id}
    temp_file.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    temp_file.replace(STATE_FILE)
    return theme_id


def palette_hash(theme_dict: dict | None) -> str:
    """Stable hash of a theme palette for adapter sync verification."""
    try:
        colors = (theme_dict or {}).get("colors", {})
        canonical = json.dumps(colors, sort_keys=True, ensure_ascii=False)
        return hashlib.sha256(canonical.encode("utf-8")).hexdigest()[:16]
    except Exception:
        return ""


def read_adapter_state() -> dict:
    try:
        if ADAPTERS_FILE.is_file():
            data = json.loads(ADAPTERS_FILE.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                return data
    except Exception:
        pass
    return {}


def record_adapter(name: str, ok: bool, theme_id: str, theme_dict: dict | None = None):
    """Persist per-adapter sync state: file existence alone never counts."""
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        state = read_adapter_state()
        state[str(name)] = {
            "ok": bool(ok),
            "theme": str(theme_id),
            "hash": palette_hash(theme_dict) if ok else "",
        }
        temp_file = ADAPTERS_FILE.with_suffix(".tmp")
        temp_file.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        temp_file.replace(ADAPTERS_FILE)
    except Exception:
        pass


def _read_text_safe(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def _matching_json_brace(text: str, opening: int) -> int:
    """Find a matching JSON/JSONC brace while ignoring strings and comments."""
    depth = 0
    in_string = False
    escaped = False
    line_comment = False
    block_comment = False
    i = opening
    while i < len(text):
        char = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if line_comment:
            if char == "\n":
                line_comment = False
        elif block_comment:
            if char == "*" and nxt == "/":
                block_comment = False
                i += 1
        elif in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
        elif char == "/" and nxt == "/":
            line_comment = True
            i += 1
        elif char == "/" and nxt == "*":
            block_comment = True
            i += 1
        elif char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("Unbalanced JSONC object")


def _jsonc_object_span(text: str, name: str, start: int = 0, end: int | None = None) -> tuple[int, int]:
    limit = len(text) if end is None else end
    match = re.search(r'"' + re.escape(name) + r'"\s*:\s*\{', text[start:limit])
    if not match:
        raise ValueError(f"JSONC object not found: {name}")
    opening = start + match.end() - 1
    return opening, _matching_json_brace(text, opening)


def _set_jsonc_object_values(text: str, object_start: int, object_end: int, values: dict[str, str]) -> str:
    body = text[object_start + 1:object_end]
    for key, value in values.items():
        pattern = re.compile(r'("' + re.escape(key) + r'"\s*:\s*)"(?:\\.|[^"\\])*"')
        body, count = pattern.subn(lambda m: m.group(1) + json.dumps(value), body, count=1)
        if count != 1:
            raise ValueError(f"JSONC color entry not found: {key}")
    return text[:object_start + 1] + body + text[object_end:]


def sync_fastfetch_theme(theme_id: str, theme_dict: dict, config_path: Path | None = None) -> bool:
    """Keep Fastfetch logo and labels aligned with the active desktop palette."""
    path = config_path or FASTFETCH_CONFIG_PATH
    colors = (theme_dict or {}).get("colors", {})
    accent = str(colors.get("accent", "")).lower()
    cyan = str(colors.get("cyan", accent)).lower()
    pink = str(colors.get("pink", accent)).lower()
    if not accent or not re.fullmatch(r"#[0-9a-f]{6}", accent):
        record_adapter("fastfetch", False, theme_id, theme_dict)
        return False
    try:
        text = path.read_text(encoding="utf-8")
        logo_start, logo_end = _jsonc_object_span(text, "logo")
        logo_color_start, logo_color_end = _jsonc_object_span(text, "color", logo_start, logo_end)
        text = _set_jsonc_object_values(text, logo_color_start, logo_color_end, {"1": accent, "2": cyan})
        display_start, display_end = _jsonc_object_span(text, "display")
        display_color_start, display_color_end = _jsonc_object_span(text, "color", display_start, display_end)
        text = _set_jsonc_object_values(text, display_color_start, display_color_end,
                                        {"keys": accent, "title": pink})
        temp = path.with_suffix(path.suffix + ".tmp")
        temp.write_text(text, encoding="utf-8")
        temp.replace(path)
        ok = True
    except (OSError, ValueError):
        ok = False
    record_adapter("fastfetch", ok, theme_id, theme_dict)
    return ok


def verify_adapter(name: str, theme_id: str, theme_dict: dict | None = None) -> bool:
    """Releitura barata dos arquivos de destino. Existência do arquivo
    nunca basta: o conteúdo precisa corresponder à paleta aplicada."""
    tid = str(theme_id or "").strip().lower()
    colors = (theme_dict or {}).get("colors", {})
    accent = str(colors.get("accent", "")).lower()
    home = Path.home()
    cfg_home = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", home / ".cache"))
    try:
        if name == "ghostty":
            mapped = GHOSTTY_THEME_MAP.get(tid, "")
            if not mapped:
                return False
            content = _read_text_safe(GHOSTTY_CONFIG_PATH)
            return f"theme = {mapped}" in content
        if name == "hyprland":
            if not accent:
                return False
            content = _read_text_safe(HYPR_THEME_LUA)
            return to_hyprland_hex_rgba(colors.get("accent", ""), "ee").lower() in content.lower()
        if name == "hyprlock":
            if not accent:
                return False
            content = _read_text_safe(HYPRLOCK_COLORS_CONF)
            return to_hyprlang_rgba(colors.get("accent", ""), 0.60) in content
        if name == "labwc":
            if not accent:
                return False
            content = _read_text_safe(cfg_home / "labwc" / "themerc-override").lower()
            bg = str(colors.get("backgroundOpaque", "")).lower()
            return accent in content and (not bg or bg in content)
        if name == "fastfetch":
            content = _read_text_safe(FASTFETCH_CONFIG_PATH)
            expected = {
                '"1": "' + accent + '"',
                '"2": "' + str(colors.get("cyan", accent)).lower() + '"',
                '"keys": "' + accent + '"',
                '"title": "' + str(colors.get("pink", accent)).lower() + '"',
            }
            return bool(content) and all(value in content.lower() for value in expected)
        if name == "gtk":
            theme_name = "chameleon" if tid.startswith("chameleon") else f"quickshell-{tid}"
            ini = _read_text_safe(cfg_home / "gtk-3.0" / "settings.ini")
            if f"gtk-theme-name = {theme_name}" not in ini \
                    and f"gtk-theme-name={theme_name}" not in ini:
                return theme_name == "Adwaita" and "gtk-theme-name" in ini
            if theme_name == "Adwaita" or not accent:
                return True
            css = _read_text_safe(home / ".themes" / theme_name / "gtk-3.0" / "gtk.css")
            return accent in css.lower()
        if name == "btop":
            conf = _read_text_safe(cfg_home / "btop" / "btop.conf")
            if 'color_theme = "chameleon"' not in conf:
                return False
            if not accent:
                return True
            theme_file = _read_text_safe(cfg_home / "btop" / "themes" / "chameleon.theme")
            return f'hi_fg="{accent}"'.lower() in theme_file.lower()
        if name == "qt":
            qt_conf = _read_text_safe(cfg_home / "qt6ct" / "qt6ct.conf")
            m = re.search(r"^style=(.+)$", qt_conf, flags=re.MULTILINE)
            style = m.group(1).strip() if m else ""
            if style == "breeze":
                if not accent:
                    return False
                r, g, b = hex_to_rgb(accent)
                colors_file = _read_text_safe(cfg_home / "qt6ct" / "colors" / "Chameleon.colors")
                return f"BackgroundNormal={r}, {g}, {b}" in colors_file
            kv = _read_text_safe(home / ".config" / "Kvantum" / "kvantum.kvconfig")
            if "theme=chameleon" not in kv:
                return False
            if not accent:
                return True
            kvcss = _read_text_safe(home / ".config" / "Kvantum" / "chameleon" / "chameleon.kvconfig")
            return accent in kvcss.lower()
    except Exception:
        return False
    return False


def adapter_in_sync(name: str, theme_id: str, theme_dict: dict | None = None) -> bool:
    entry = read_adapter_state().get(str(name), {})
    if not entry.get("ok"):
        return False
    if entry.get("theme") != str(theme_id):
        return False
    expected = palette_hash(theme_dict)
    if not expected or entry.get("hash") != expected:
        return False
    return verify_adapter(name, theme_id, theme_dict)


def get_cached_variants() -> dict | None:
    if CHAMELEON_PALETTE_FILE.is_file():
        try:
            cached = json.loads(CHAMELEON_PALETTE_FILE.read_text(encoding="utf-8"))
            return cached.get("variants")
        except Exception:
            pass
    return None


def cmd_get(theme_id=None):
    current = read_current_theme_id()
    target_id = (theme_id or current).strip().lower()
    if target_id.startswith("chameleon"):
        THEMES[target_id] = get_chameleon_palette(target_id)
    if target_id not in THEMES:
        return {"ok": False, "error": f"Tema '{target_id}' não encontrado", "current": current}
    theme_info = THEMES[target_id]
    return {
        "ok": True,
        "error": None,
        "current": current,
        "theme": theme_info,
        "variants": get_cached_variants(),
        "adapters": {
            "quickshell": True,
            "ghostty": adapter_in_sync("ghostty", target_id, theme_info),
            "hyprland": adapter_in_sync("hyprland", target_id, theme_info),
            "hyprlock": adapter_in_sync("hyprlock", target_id, theme_info),
            "gtk": adapter_in_sync("gtk", target_id, theme_info),
            "btop": adapter_in_sync("btop", target_id, theme_info),
            "qt": adapter_in_sync("qt", target_id, theme_info),
            "labwc": adapter_in_sync("labwc", target_id, theme_info),
            "fastfetch": adapter_in_sync("fastfetch", target_id, theme_info),
        },
    }


def cmd_list():
    current = read_current_theme_id()
    for cid in ["chameleon", "chameleon-light", "chameleon-oled"]:
        THEMES[cid] = get_chameleon_palette(cid)
    items = []
    for tid, info in THEMES.items():
        items.append({
            "id": tid,
            "name": info["name"],
            "category": info["category"],
            "description": info["description"],
            "accent": info["accent"],
            "active": (tid == current),
        })
    items.sort(key=lambda x: x["name"].lower())
    return {
        "ok": True,
        "error": None,
        "current": current,
        "themes": items,
    }


def get_ghostty_ptys() -> list[str]:
    """
    Encontra todos os pseudo-terminais (/dev/pts/*) pertencentes a instâncias do Ghostty.
    """
    ptys = set()
    import subprocess
    try:
        res = subprocess.run(["pgrep", "-u", str(os.getuid()), "ghostty"], capture_output=True, text=True, timeout=1)
        if res.returncode == 0:
            for gpid in res.stdout.strip().split():
                c_res = subprocess.run(["pgrep", "-P", gpid], capture_output=True, text=True, timeout=1)
                if c_res.returncode == 0:
                    for cpid in c_res.stdout.strip().split():
                        for fd in [0, 1, 2]:
                            p = Path(f"/proc/{cpid}/fd/{fd}")
                            try:
                                target = os.readlink(p)
                                if target.startswith("/dev/pts/") and target != "/dev/ptmx":
                                    ptys.add(target)
                            except Exception:
                                pass
    except Exception:
        pass
    return sorted(list(ptys))


def broadcast_osc_palette(palette: dict | None = None) -> int:
    """
    Transmite sequências de controle OSC (OSC 10, 11, 12, 4) para todos os terminais
    Ghostty ativos para atualização visual imediata de superfícies abertas.
    """
    if not palette or "colors" not in palette:
        return 0

    c = palette["colors"]
    bg = c.get("backgroundOpaque", "#07131b")
    fg = c.get("foreground", "#ecf3f8")
    accent = c.get("accent", "#4ca8e0")
    surface = c.get("surface", "#13212b")
    surface_hover = c.get("surfaceHover", "#293a46")
    grey = c.get("grey", "#8d9aa3")
    off_white = c.get("offWhite", "#d6e2ec")

    red = c.get("red", "#e86883")
    green = c.get("green", "#56c888")
    yellow = c.get("yellow", "#d3d166")
    blue = c.get("blue", "#44a6ef")
    pink = c.get("pink", "#d490e6")
    cyan = c.get("cyan", "#4fccd8")

    bright_red = brighten_hex(red, 0.08)
    bright_green = brighten_hex(green, 0.08)
    bright_yellow = brighten_hex(yellow, 0.08)
    bright_blue = brighten_hex(blue, 0.08)
    bright_pink = brighten_hex(pink, 0.08)
    bright_cyan = brighten_hex(cyan, 0.08)

    ansi = [
        surface, red, green, yellow, blue, pink, cyan, off_white,
        grey, bright_red, bright_green, bright_yellow, bright_blue, bright_pink, bright_cyan, fg
    ]

    seqs = [f"\033]10;{fg}\007", f"\033]11;{bg}\007", f"\033]12;{accent}\007"]
    for i, col in enumerate(ansi):
        seqs.append(f"\033]4;{i};{col}\007")
    payload = "".join(seqs)

    count = 0
    for pty in get_ghostty_ptys():
        try:
            with open(pty, "w", encoding="utf-8") as f:
                f.write(payload)
                f.flush()
            count += 1
        except Exception:
            pass
    return count


def reload_ghostty() -> bool:
    """
    Envia sinal SIGUSR2 para todos os processos Ghostty do usuário atual
    para forçar o recarregamento imediato da configuração e do tema.
    """
    import shutil
    import subprocess

    if shutil.which("pkill"):
        try:
            res = subprocess.run(
                ["pkill", "-SIGUSR2", "-u", str(os.getuid()), "ghostty"],
                capture_output=True,
                text=True,
                timeout=2,
            )
            return res.returncode == 0
        except Exception:
            pass
    return False


def sync_ghostty_theme(theme_id: str, config_path: Path | None = None, themes_dir: Path | None = None, palette: dict | None = None) -> bool:
    """
    Sincroniza o tema selecionado com a configuração do Ghostty (~/.config/ghostty/config).
    O Ghostty recebe o sinal SIGUSR2 e recarrega as cores instantaneamente sem fechar os terminais.
    """
    path = config_path if config_path is not None else GHOSTTY_CONFIG_PATH
    if not path.is_file():
        record_adapter("ghostty", False, theme_id)
        return False

    ghostty_theme = GHOSTTY_THEME_MAP.get(theme_id)
    if not ghostty_theme:
        record_adapter("ghostty", False, theme_id)
        return False

    if theme_id.startswith("chameleon"):
        try:
            generate_ghostty_chameleon_theme(palette=palette, themes_dir=themes_dir)
        except Exception:
            pass
    elif theme_id.startswith("dracula-pro"):
        try:
            t_data = palette or THEMES.get(theme_id)
            if t_data:
                generate_ghostty_theme_file(theme_id, t_data, themes_dir=themes_dir)
        except Exception:
            pass

    try:
        content = path.read_text(encoding="utf-8")
        if re.search(r"^\s*theme\s*=.*$", content, flags=re.MULTILINE):
            new_content = re.sub(r"^\s*theme\s*=.*$", f"theme = {ghostty_theme}", content, flags=re.MULTILINE, count=1)
        else:
            new_content = content.rstrip() + f"\ntheme = {ghostty_theme}\n"

        temp_file = path.with_suffix(".tmp")
        temp_file.write_text(new_content, encoding="utf-8")
        temp_file.replace(path)

        active_palette = palette or THEMES.get(theme_id) or (get_chameleon_palette(theme_id) if theme_id.startswith("chameleon") else None)
        if active_palette:
            broadcast_osc_palette(active_palette)
        reload_ghostty()
        record_adapter("ghostty", True, theme_id, active_palette)
        return True
    except Exception:
        record_adapter("ghostty", False, theme_id)
        return False


def hex_to_rgb_tuple(hex_str: str) -> tuple[int, int, int]:
    h = str(hex_str or "#000000").lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    elif len(h) < 6:
        h = h.ljust(6, "0")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def to_hyprlang_rgba(hex_str: str, alpha: float = 1.0) -> str:
    r, g, b = hex_to_rgb_tuple(hex_str)
    return f"rgba({r}, {g}, {b}, {alpha:.2f})"


def to_hyprlang_rgb(hex_str: str) -> str:
    r, g, b = hex_to_rgb_tuple(hex_str)
    return f"rgb({r}, {g}, {b})"


def to_hyprland_hex_rgba(hex_str: str, alpha_hex: str = "ee") -> str:
    h = str(hex_str or "#89b4fa").lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    elif len(h) < 6:
        h = h.ljust(6, "0")
    return f"rgba({h[:6]}{alpha_hex})"


def export_canonical_palette(theme_data: dict) -> Path:
    """
    Salva a paleta canônica central em ~/.local/state/quickshell/current_palette.json.
    Essa paleta serve como Single Source of Truth para todas as integrações.
    """
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        out = {
            "id": theme_data.get("id", ""),
            "name": theme_data.get("name", ""),
            "wallpaper": str(detect_current_wallpaper() or ""),
            "colors": theme_data.get("colors", {}),
        }
        temp = CANONICAL_PALETTE_FILE.with_suffix(".tmp")
        temp.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        temp.replace(CANONICAL_PALETTE_FILE)
    except Exception:
        pass
    return CANONICAL_PALETTE_FILE


def sync_hyprland_theme(palette: dict | None = None, cache_dir: Path | None = None) -> bool:
    """
    Gera ~/.cache/hypr/theme.lua e aplica as cores de borda no Hyprland ao vivo via hyprctl eval.
    """
    if not palette or "colors" not in palette:
        return False
    try:
        target_dir = cache_dir if cache_dir is not None else HYPR_CACHE_DIR
        target_dir.mkdir(parents=True, exist_ok=True)
        target_file = target_dir / "theme.lua"

        colors = palette["colors"]
        accent = colors.get("accent", "#89b4fa")
        surface = colors.get("surface", "#313244")

        active_border = to_hyprland_hex_rgba(accent, "ee")
        inactive_border = to_hyprland_hex_rgba(surface, "88")
        group_border_active = to_hyprland_hex_rgba(accent, "ee")
        group_border_inactive = to_hyprland_hex_rgba(surface, "88")
        groupbar_active = to_hyprland_hex_rgba(accent, "aa")
        groupbar_inactive = to_hyprland_hex_rgba(surface, "aa")

        lua_content = (
            "-- Generated by Quickshell Theme Manager\n"
            "return {\n"
            f'    id = "{palette.get("id", "")}",\n'
            f'    active_border = "{active_border}",\n'
            f'    inactive_border = "{inactive_border}",\n'
            f'    group_border_active = "{group_border_active}",\n'
            f'    group_border_inactive = "{group_border_inactive}",\n'
            f'    groupbar_active = "{groupbar_active}",\n'
            f'    groupbar_inactive = "{groupbar_inactive}",\n'
            "}\n"
        )

        tmp = target_file.with_suffix(".tmp")
        tmp.write_text(lua_content, encoding="utf-8")
        tmp.replace(target_file)

        # Se hyprctl estiver presente, atualiza o compositor ao vivo
        if is_hyprland_session() and shutil.which("hyprctl"):
            eval_cmd = (
                f'hl.config({{ general = {{ col = {{ '
                f'active_border = {{ colors = {{ "{active_border}" }}, angle = 45 }}, '
                f'inactive_border = "{inactive_border}" '
                f'}} }}, group = {{ col = {{ '
                f'border_active = {{ colors = {{ "{group_border_active}" }}, angle = 45 }}, '
                f'border_inactive = "{group_border_inactive}", '
                f'border_locked_active = {{ colors = {{ "{group_border_active}" }}, angle = 45 }}, '
                f'border_locked_inactive = "{group_border_inactive}" '
                f'}}, groupbar = {{ col = {{ '
                f'active = "{groupbar_active}", '
                f'inactive = "{groupbar_inactive}", '
                f'locked_active = "{groupbar_active}", '
                f'locked_inactive = "{groupbar_inactive}" '
                f'}} }} }} }})'
            )
            try:
                subprocess.run(
                    ["hyprctl", "eval", eval_cmd],
                    capture_output=True,
                    text=True,
                    timeout=1,
                )
            except Exception:
                pass
        record_adapter("hyprland", True, str((palette or {}).get("id", "")), palette)
        return True
    except Exception:
        record_adapter("hyprland", False, str((palette or {}).get("id", "")))
        return False


def sync_hyprlock_theme(palette: dict | None = None, cache_dir: Path | None = None) -> bool:
    """
    Gera ~/.cache/hypr/hyprlock_colors.conf com variáveis de cor para o hyprlock.
    """
    if not palette or "colors" not in palette:
        return False
    try:
        target_dir = cache_dir if cache_dir is not None else HYPR_CACHE_DIR
        target_dir.mkdir(parents=True, exist_ok=True)
        target_file = target_dir / "hyprlock_colors.conf"

        colors = palette["colors"]
        accent = colors.get("accent", "#89b4fa")
        surface = colors.get("surface", "#313244")
        foreground = colors.get("foreground", "#cdd6f4")
        green = colors.get("green", "#a6e3a1")
        red = colors.get("red", "#f38ba8")

        conf_content = (
            "# Generated by Quickshell Theme Manager\n"
            f"$accent = {to_hyprlang_rgba(accent, 0.60)}\n"
            f"$surface = {to_hyprlang_rgba(surface, 0.90)}\n"
            f"$font = {to_hyprlang_rgb(foreground)}\n"
            f"$fontAlpha = {to_hyprlang_rgba(foreground, 0.80)}\n"
            f"$check = {to_hyprlang_rgba(green, 1.00)}\n"
            f"$fail = {to_hyprlang_rgba(red, 1.00)}\n"
        )

        tmp = target_file.with_suffix(".tmp")
        tmp.write_text(conf_content, encoding="utf-8")
        tmp.replace(target_file)
        record_adapter("hyprlock", True, str((palette or {}).get("id", "")), palette)
        return True
    except Exception:
        record_adapter("hyprlock", False, str((palette or {}).get("id", "")))
        return False


def reconfigure_labwc() -> bool:
    """Recarrega o labwc ao vivo; só faz sentido dentro da sessão labwc."""
    if not os.environ.get("LABWC_PID"):
        return False
    if not shutil.which("labwc"):
        return False
    try:
        res = subprocess.run(
            ["labwc", "--reconfigure"],
            capture_output=True, text=True, timeout=5,
        )
        return res.returncode == 0
    except Exception:
        return False


def sync_labwc_theme(palette: dict | None = None, config_home: Path | None = None) -> bool:
    """
    Gera ~/.config/labwc/themerc-override a partir da paleta e recarrega
    o labwc ao vivo quando estiver na sessão labwc (LABWC_PID).
    """
    tid = str((palette or {}).get("id", ""))
    if not palette or "colors" not in palette:
        record_adapter("labwc", False, tid)
        return False
    try:
        base = config_home if config_home is not None else Path(
            os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
        target_dir = base / "labwc"
        target_dir.mkdir(parents=True, exist_ok=True)
        target_file = target_dir / "themerc-override"

        colors = palette["colors"]
        accent = colors.get("accent", "#89b4fa")
        bg = colors.get("backgroundOpaque", "#1e1e2e")
        surface_hover = colors.get("surfaceHover", "#45475a")
        foreground = colors.get("foreground", "#cdd6f4")
        grey = colors.get("grey", "#585b70")

        override_content = (
            f"# Generated by Quickshell Theme Manager — tema {tid}.\n"
            "# Regenerado em `set` / `update-wallpaper`. Edições manuais aqui\n"
            "# são substituídas na próxima sincronização de tema.\n"
            "border.width: 2\n"
            f"window.active.border.color: {accent}\n"
            f"window.inactive.border.color: {surface_hover}\n"
            f"window.active.title.bg.color: {bg}\n"
            f"window.inactive.title.bg.color: {darken_hex(bg)}\n"
            f"window.active.label.text.color: {foreground}\n"
            f"window.inactive.label.text.color: {grey}\n"
            f"window.active.button.unpressed.image.color: {foreground}\n"
            f"window.inactive.button.unpressed.image.color: {grey}\n"
            f"window.button.hover.bg.color: {surface_hover}\n"
            "window.button.hover.bg.corner-radius: 6\n"
            f"menu.border.color: {surface_hover}\n"
            f"menu.items.bg.color: {bg}\n"
            f"menu.items.text.color: {foreground}\n"
            f"menu.items.active.bg.color: {surface_hover}\n"
            f"menu.items.active.text.color: {foreground}\n"
            f"menu.separator.color: {grey}\n"
            f"menu.title.bg.color: {accent}\n"
            f"menu.title.text.color: {bg}\n"
            f"osd.bg.color: {bg}\n"
            f"osd.border.color: {surface_hover}\n"
            f"osd.label.text.color: {foreground}\n"
            f"osd.window-switcher.style-classic.item.active.border.color: {accent}\n"
            f"osd.window-switcher.style-classic.item.active.bg.color: {surface_hover}\n"
        )

        tmp = target_file.with_suffix(".tmp")
        tmp.write_text(override_content, encoding="utf-8")
        tmp.replace(target_file)
        # Melhor esforço: falha no reload ao vivo não invalida a escrita.
        try:
            reconfigure_labwc()
        except Exception:
            pass
        record_adapter("labwc", True, tid, palette)
        return True
    except Exception:
        record_adapter("labwc", False, tid)
        return False


def gtk_theme_dirs() -> list[Path]:
    home = Path.home()
    seen = []
    for base in (
        home / ".themes",
        Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "themes",
        Path("/usr/share/themes"),
    ):
        if base.is_dir() and base not in seen:
            seen.append(base)
    return seen


def gtk_theme_installed(name: str) -> bool:
    """Adwaita é embutido; demais temas exigem gtk-3.0 ou gtk-4.0 no disco."""
    if name == "Adwaita":
        return True
    for base in gtk_theme_dirs():
        d = base / name
        if (d / "gtk-3.0" / "gtk.css").is_file() or (d / "gtk-4.0" / "gtk.css").is_file():
            return True
    return False


def pick_gtk_theme(category: str) -> str:
    """Escolhe tema instalado por categoria, com fallback seguro."""
    if category == "light":
        for base in gtk_theme_dirs():
            try:
                names = sorted(p.name for p in base.iterdir() if p.is_dir())
            except OSError:
                continue
            for n in names:
                if n.startswith("catppuccin-latte-") and "hdpi" not in n and "xhdpi" not in n:
                    if gtk_theme_installed(n):
                        return n
        return "Adwaita"
    preferred = "catppuccin-mocha-pink-standard-default"
    if gtk_theme_installed(preferred):
        return preferred
    for base in gtk_theme_dirs():
        try:
            names = sorted(p.name for p in base.iterdir() if p.is_dir())
        except OSError:
            continue
        for n in names:
            if n.startswith("catppuccin-mocha-") and n.endswith("-standard-default") \
                    and "hdpi" not in n and "xhdpi" not in n:
                if gtk_theme_installed(n):
                    return n
    return "Adwaita"


def _write_gtk_settings_ini(gtk_theme: str, dark: bool, config_home: Path | None = None) -> bool:
    base = config_home if config_home is not None else Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    wrote = False
    for version in ("gtk-3.0", "gtk-4.0"):
        ini = base / version / "settings.ini"
        try:
            ini.parent.mkdir(parents=True, exist_ok=True)
            cfg = configparser.ConfigParser()
            if ini.is_file():
                cfg.read(ini, encoding="utf-8")
            if not cfg.has_section("Settings"):
                cfg.add_section("Settings")
            cfg.set("Settings", "gtk-theme-name", gtk_theme)
            cfg.set("Settings", "gtk-application-prefer-dark-theme", "1" if dark else "0")
            tmp = ini.with_suffix(".tmp")
            with tmp.open("w", encoding="utf-8") as f:
                cfg.write(f)
            tmp.replace(ini)
            wrote = True
        except Exception:
            pass
    return wrote


def _chameleon_gtk_css(c: dict) -> str:
    """Flat GTK theme derived from the active palette (v1: core widgets)."""
    bg = c.get("backgroundOpaque", "#1e1e2e")
    surf = c.get("surface", "#313244")
    hover = c.get("surfaceHover", "#45475a")
    fg = c.get("foreground", "#cdd6f4")
    dim = c.get("offWhite", "#bac2de")
    grey = c.get("grey", "#585b70")
    acc = c.get("accent", "#89b4fa")
    red = c.get("red", "#f38ba8")
    green = c.get("green", "#a6e3a1")
    yellow = c.get("yellow", "#f9e2af")
    mantle = darken_hex(surf)
    return f"""@define-color theme_bg_color {bg};
@define-color theme_fg_color {fg};
@define-color theme_base_color {surf};
@define-color theme_text_color {fg};
@define-color theme_selected_bg_color {acc};
@define-color theme_selected_fg_color {bg};
@define-color theme_tooltip_bg_color {hover};
@define-color theme_tooltip_fg_color {fg};
@define-color borders {hover};
@define-color unfocused_borders {surf};
@define-color warning_color {yellow};
@define-color error_color {red};
@define-color success_color {green};
@define-color placeholder_text_color {grey};

* {{
    outline-style: none;
}}

window, dialog, assistant, printdialog {{
    background-color: {bg};
    color: {fg};
}}

headerbar, .titlebar {{
    background-color: {mantle};
    color: {fg};
    border-bottom: 1px solid {hover};
}}

headerbar button, .titlebar button {{
    background-color: transparent;
    color: {dim};
    border: 1px solid transparent;
    border-radius: 6px;
    padding: 4px 8px;
}}

headerbar button:hover, .titlebar button:hover {{
    background-color: {hover};
    color: {fg};
}}

.titlebutton {{
    color: {dim};
    border-radius: 50%;
    min-width: 22px;
    min-height: 22px;
}}

.titlebutton.close:hover {{
    background-color: {red};
    color: {bg};
}}

button {{
    background-color: {surf};
    color: {fg};
    border: 1px solid {hover};
    border-radius: 6px;
    padding: 4px 10px;
}}

button:hover {{
    background-color: {hover};
}}

button:active, button:checked {{
    background-color: {acc};
    color: {bg};
    border-color: {acc};
}}

button.suggested-action {{
    background-color: {acc};
    color: {bg};
    border-color: {acc};
}}

button.destructive-action {{
    background-color: {red};
    color: {bg};
    border-color: {red};
}}

entry, spinbutton, searchbar {{
    background-color: {surf};
    color: {fg};
    border: 1px solid {hover};
    border-radius: 6px;
    padding: 4px 8px;
}}

entry:focus {{
    border-color: {acc};
}}

entry selection, textview text selection, label selection {{
    background-color: {acc};
    color: {bg};
}}

treeview, textview, iconview {{
    background-color: {surf};
    color: {fg};
}}

treeview:selected, iconview:selected {{
    background-color: {acc};
    color: {bg};
}}

menu, menubar, context-menu, popover {{
    background-color: {surf};
    color: {fg};
    border: 1px solid {hover};
}}

menuitem:hover, modelbutton:hover {{
    background-color: {hover};
}}

notebook {{
    background-color: {bg};
}}

notebook tab {{
    background-color: {surf};
    color: {dim};
    padding: 4px 10px;
}}

notebook tab:checked {{
    background-color: {hover};
    color: {fg};
}}

scrollbar slider {{
    background-color: {hover};
    border-radius: 8px;
    min-width: 8px;
    min-height: 8px;
}}

scrollbar slider:hover {{
    background-color: {grey};
}}

check, radio {{
    background-color: {surf};
    border: 1px solid {grey};
}}

check:checked, radio:checked {{
    background-color: {acc};
    border-color: {acc};
    color: {bg};
}}

switch {{
    background-color: {hover};
    border: 1px solid {grey};
    border-radius: 12px;
}}

switch:checked {{
    background-color: {acc};
    border-color: {acc};
}}

switch slider {{
    background-color: {fg};
    border-radius: 50%;
    min-width: 16px;
    min-height: 16px;
}}

list {{
    background-color: {bg};
}}

list row, .view row {{
    background-color: transparent;
    color: {fg};
    padding: 6px 8px;
    border-radius: 6px;
}}

list row:hover, .view row:hover {{
    background-color: {hover};
}}

list row:selected, .view row:selected {{
    background-color: {acc};
    color: {bg};
}}

expander title {{
    color: {dim};
}}

tooltip {{
    background-color: {hover};
    color: {fg};
    border: 1px solid {grey};
    border-radius: 6px;
}}

progressbar trough, scale trough, levelbar trough {{
    background-color: {surf};
    border-radius: 6px;
}}

progressbar progress, scale highlight {{
    background-color: {acc};
    border-radius: 6px;
}}

separator {{
    background-color: {hover};
}}

infobar.info {{
    background-color: {surf};
    color: {fg};
}}

infobar.warning {{
    background-color: {yellow};
    color: {bg};
}}

infobar.error {{
    background-color: {red};
    color: {bg};
}}

spinner:checked {{
    color: {acc};
}}
"""


def _chameleon_derived(c: dict) -> dict:
    bg = c.get("backgroundOpaque", "#1e1e2e")
    surf = c.get("surface", "#313244")
    hover = c.get("surfaceHover", "#45475a")
    fg = c.get("foreground", "#cdd6f4")
    dim = c.get("offWhite", "#bac2de")
    grey = c.get("grey", "#585b70")
    acc = c.get("accent", "#89b4fa")
    red = c.get("red", "#f38ba8")
    green = c.get("green", "#a6e3a1")
    yellow = c.get("yellow", "#f9e2af")
    blue = c.get("blue", "#89b4fa")
    pink = c.get("pink", "#f5c2e7")
    cyan = c.get("cyan", "#94e2d5")
    orange = c.get("orange", "#fab387")
    return {
        "bg": bg, "mantle": darken_hex(bg, 0.035), "crust": darken_hex(bg, 0.07),
        "surface": surf, "surface_hover": hover,
        "surface_bright": brighten_hex(hover, 0.06),
        "fg": fg, "dim": dim, "grey": grey,
        "grey_light": brighten_hex(grey, 0.12),
        "acc": acc, "red": red, "green": green, "yellow": yellow,
        "blue": blue, "pink": pink, "cyan": cyan, "orange": orange,
        "red_dark": darken_hex(red, 0.08), "green_dark": darken_hex(green, 0.08),
        "yellow_dark": darken_hex(yellow, 0.08),
        "blue_light": brighten_hex(blue, 0.08),
    }


def _chameleon_for_template_hex(hx: str, d: dict) -> str | None:
    """Map a Catppuccin Mocha hex to the chameleon equivalent by role,
    falling back to nearest-hue semantic for one-off shades."""
    h = hx.lower()
    explicit = {
        "#1e1e2e": d["bg"], "#181825": d["mantle"], "#11111b": d["crust"],
        "#14141f": d["mantle"], "#0b0b12": d["crust"], "#0a0a0f": d["crust"],
        "#060609": "#000000",
        "#313244": d["surface"], "#393947": d["surface_hover"],
        "#45475a": d["surface_hover"], "#585b70": d["surface_bright"],
        "#282938": d["surface"], "#242434": d["surface"],
        "#292936": d["surface"], "#333342": d["surface_hover"],
        "#34343f": d["surface_hover"], "#35353d": d["surface_hover"],
        "#3d3e4c": d["surface_hover"], "#3e3e5f": d["surface_hover"],
        "#444556": d["surface_hover"], "#4d4d54": d["surface_hover"],
        "#5d5d6a": d["grey"],
        "#cdd6f4": d["fg"], "#eff1f5": d["fg"],
        "#bac2de": d["dim"], "#a6adc8": d["dim"], "#b0b2b9": d["grey"],
        "#9399b2": d["grey_light"], "#7f849c": d["grey"],
        "#6c7086": d["grey"], "#8c7189": d["grey"],
        "#9f9792": d["grey"], "#7b736e": d["grey"], "#605955": d["grey"],
        "#574f4a": d["grey"], "#474341": d["grey"], "#463e39": d["grey"],
        "#403c3a": d["grey"], "#393634": d["grey"], "#342c27": d["grey"],
        "#33302f": d["grey"], "#2b2928": d["grey"],
        "#f5c2e7": d["acc"], "#cba6f7": d["acc"],
        "#f38ba8": d["red"], "#ed547e": d["red_dark"],
        "#fab387": d["orange"], "#f9e2af": d["yellow"],
        "#f5cd76": d["yellow_dark"], "#a6e3a1": d["green"],
        "#79d572": d["green_dark"], "#94e2d5": d["cyan"],
        "#89dceb": d["cyan"], "#89b4fa": d["blue"],
        "#74c7ec": d["blue"], "#b4befe": d["blue_light"],
    }
    if h in explicit:
        return explicit[h]
    try:
        r, g, b = hex_to_rgb(h)
        hh, _, ss = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        if ss < 0.15:
            return None
        deg = hh * 360.0
        if deg < 15 or deg >= 345:
            return d["red"]
        if deg < 45:
            return d["orange"]
        if deg < 70:
            return d["yellow"]
        if deg < 160:
            return d["green"]
        if deg < 195:
            return d["cyan"]
        if deg < 250:
            return d["blue"]
        return d["pink"]
    except Exception:
        return None


def _recolor_css_template(css: str, d: dict) -> str:
    def sub_hex(m):
        mapped = _chameleon_for_template_hex(m.group(0), d)
        return mapped if mapped else m.group(0)

    css = re.sub(r"#[0-9a-fA-F]{6}\b", sub_hex, css)

    rgb_map = {
        (239, 241, 245): hex_to_rgb(d["fg"]),
        (17, 17, 27): hex_to_rgb(d["crust"]),
        (30, 30, 46): hex_to_rgb(d["bg"]),
        (49, 50, 68): hex_to_rgb(d["surface"]),
        (11, 11, 18): hex_to_rgb(d["crust"]),
        (245, 194, 231): hex_to_rgb(d["acc"]),
        (243, 139, 168): hex_to_rgb(d["red"]),
    }

    def sub_rgba(m):
        key = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
        alpha = m.group(4).strip()
        if key in rgb_map:
            r, g, b = rgb_map[key]
            return f"rgba({r}, {g}, {b}, {alpha})"
        return m.group(0)

    return re.sub(r"rgba\((\d+),\s*(\d+),\s*(\d+),([^)]*)\)", sub_rgba, css)


def _find_gtk_template() -> Path | None:
    cands = []
    for base in gtk_theme_dirs():
        try:
            names = sorted(p.name for p in base.iterdir() if p.is_dir())
        except OSError:
            continue
        for n in names:
            d = base / n
            if ((d / "gtk-3.0" / "gtk.css").is_file()
                    and (d / "gtk-4.0" / "gtk.css").is_file()
                    and "hdpi" not in n and "xhdpi" not in n):
                cands.append(d)
    for d in cands:
        if d.name == "catppuccin-mocha-pink-standard-default":
            return d
    for d in cands:
        if d.name.startswith("catppuccin-mocha-"):
            return d
    return cands[0] if cands else None


def _recolor_svg_text(text: str, d: dict) -> str:
    def sub(m):
        mapped = _chameleon_for_template_hex(m.group(0), d)
        return mapped if mapped else m.group(0)

    return re.sub(r"#[0-9a-fA-F]{6}\b", sub, text)


def generate_gtk_chameleon_theme(palette: dict | None = None,
                                 themes_dir: Path | None = None,
                                 name: str = "chameleon") -> Path:
    """Generate ~/.themes/chameleon (GTK 3+4) from the active palette.

    Recolors the installed Catppuccin Mocha template role by role, so the
    structure stays Catppuccin while every color follows the palette.
    Falls back to the flat generator when no template is installed.
    """
    p = palette or get_chameleon_palette(read_current_theme_id())
    c = p.get("colors", {})
    t_dir = themes_dir if themes_dir is not None else GTK_THEMES_DIR
    theme_dir = t_dir / name
    template = None if themes_dir is not None else _find_gtk_template()
    for version in ("gtk-3.0", "gtk-4.0"):
        vdir = theme_dir / version
        vdir.mkdir(parents=True, exist_ok=True)
        if template is not None:
            src = template / version / "gtk.css"
            try:
                css = _recolor_css_template(
                    src.read_text(encoding="utf-8"), _chameleon_derived(c))
            except OSError:
                css = _chameleon_gtk_css(c)
            asrc = template / version / "assets"
            adst = vdir / "assets"
            if asrc.is_dir():
                # Sempre recolorido: assets copiados uma vez manteriam
                # as cores do wallpaper anterior.
                if adst.is_dir():
                    shutil.rmtree(adst, ignore_errors=True)
                try:
                    adst.mkdir(parents=True, exist_ok=True)
                    for svg in sorted(asrc.glob("*.svg")):
                        try:
                            adst.joinpath(svg.name).write_text(
                                _recolor_svg_text(
                                    svg.read_text(encoding="utf-8"),
                                    _chameleon_derived(c)),
                                encoding="utf-8")
                        except OSError:
                            pass
                except OSError:
                    pass
        else:
            css = _chameleon_gtk_css(c)
        for name in ("gtk.css", "gtk-dark.css"):
            tmp = vdir / (name + ".tmp")
            tmp.write_text(css, encoding="utf-8")
            tmp.replace(vdir / name)
    index = (
        "[Desktop Entry]\n"
        "Type=X-GNOME-Metatheme\n"
        f"Name={name}\n"
        "Comment=Dynamic palette (Quickshell)\n"
        "Encoding=UTF-8\n"
        "\n"
        "[X-GNOME-Metatheme]\n"
        f"GtkTheme={name}\n"
    )
    tmp = theme_dir / "index.theme.tmp"
    tmp.write_text(index, encoding="utf-8")
    tmp.replace(theme_dir / "index.theme")
    return theme_dir


def _relative_luminance(hex_str: str) -> float:
    r, g, b = hex_to_rgb(hex_str)
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0


def _accent_color_name(hex_str: str) -> str:
    """Closest org.gnome.desktop.interface accent-color for a hex accent."""
    try:
        r, g, b = hex_to_rgb(hex_str)
        h, _, s = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        if s < 0.18:
            return "slate"
        deg = h * 360.0
        if deg < 15 or deg >= 340:
            return "red"
        if deg < 45:
            return "orange"
        if deg < 70:
            return "yellow"
        if deg < 160:
            return "green"
        if deg < 190:
            return "teal"
        if deg < 250:
            return "blue"
        if deg < 290:
            return "purple"
        return "pink"
    except Exception:
        return "blue"


def libadwaita_recolor_css(theme_dict: dict | None) -> str:
    """gtk.css overrides with libadwaita recoloring vars from the palette."""
    c = (theme_dict or {}).get("colors", {})
    bg = c.get("backgroundOpaque", "#1e1e2e")
    fg = c.get("foreground", "#cdd6f4")
    surf = c.get("surface", "#313244")
    hover = c.get("surfaceHover", "#45475a")
    mantle = darken_hex(bg, 0.035)
    # Large flat libadwaita areas desaturated toward neutral (bar-like);
    # accent and semantic colors keep full saturation.
    surf_n = desaturate_hex(surf)
    hover_n = desaturate_hex(hover)
    mantle_n = desaturate_hex(mantle)
    dim = c.get("offWhite", "#bac2de")
    acc = c.get("accent", "#89b4fa")
    red = c.get("red", "#f38ba8")
    green = c.get("green", "#a6e3a1")
    yellow = c.get("yellow", "#f9e2af")
    acc_fg = "#1e1e2e" if _relative_luminance(acc) > 0.55 else "#ffffff"
    err_fg = "#1e1e2e" if _relative_luminance(red) > 0.55 else "#ffffff"
    return f"""/* Generated by Quickshell Theme Manager: libadwaita recoloring. */
@define-color window_bg_color {bg};
@define-color window_fg_color {fg};
@define-color view_bg_color {surf_n};
@define-color view_fg_color {fg};
@define-color headerbar_bg_color {mantle_n};
@define-color headerbar_fg_color {fg};
@define-color headerbar_border_color {hover_n};
@define-color headerbar_backdrop_color {bg};
@define-color card_bg_color {surf_n};
@define-color card_fg_color {fg};
@define-color dialog_bg_color {surf_n};
@define-color dialog_fg_color {fg};
@define-color popover_bg_color {surf_n};
@define-color popover_fg_color {fg};
@define-color thumbnail_bg_color {hover_n};
@define-color thumbnail_fg_color {dim};
@define-color accent_bg_color {acc};
@define-color accent_fg_color {acc_fg};
@define-color accent_color {acc};
@define-color destructive_bg_color {red};
@define-color destructive_fg_color {err_fg};
@define-color destructive_color {red};
@define-color success_bg_color {green};
@define-color success_fg_color #1e1e2e;
@define-color success_color {green};
@define-color warning_bg_color {yellow};
@define-color warning_fg_color #1e1e2e;
@define-color warning_color {yellow};
@define-color error_bg_color {red};
@define-color error_fg_color {err_fg};
@define-color error_color {red};
"""


def _write_libadwaita_css(theme_dict: dict | None,
                          config_home: Path | None = None) -> bool:
    base = config_home if config_home is not None else Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    css_file = base / "gtk-4.0" / "gtk.css"
    try:
        css_file.parent.mkdir(parents=True, exist_ok=True)
        if css_file.is_file():
            current = css_file.read_text(encoding="utf-8")
            if "Generated by Quickshell Theme Manager" not in current:
                bak = css_file.with_suffix(".css.bak")
                if not bak.is_file():
                    shutil.copy2(css_file, bak)
        tmp = css_file.with_suffix(".css.tmp")
        tmp.write_text(libadwaita_recolor_css(theme_dict), encoding="utf-8")
        tmp.replace(css_file)
        return True
    except Exception:
        return False


def generate_btop_chameleon_theme(palette: dict | None = None,
                                  config_home: Path | None = None) -> Path | None:
    """Generate a btop .theme from the active palette (flat key=value)."""
    p = palette or get_chameleon_palette(read_current_theme_id())
    c = p.get("colors", {})
    bg = c.get("backgroundOpaque", "#1e1e2e")
    fg = c.get("foreground", "#cdd6f4")
    surf = c.get("surface", "#313244")
    hover = c.get("surfaceHover", "#45475a")
    grey = c.get("grey", "#585b70")
    acc = c.get("accent", "#89b4fa")
    red = c.get("red", "#f38ba8")
    green = c.get("green", "#a6e3a1")
    yellow = c.get("yellow", "#f9e2af")
    blue = c.get("blue", "#89b4fa")
    pink = c.get("pink", "#f5c2e7")
    base = Path(config_home) if config_home is not None else Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    tdir = base / "btop" / "themes"
    try:
        tdir.mkdir(parents=True, exist_ok=True)
        grad = ("green", green, "yellow", yellow, "red", red)
        lines = [
            "# Generated by Quickshell Theme Manager: chameleon palette.",
            f'theme_bg="{bg}"',
            f'theme_fg="{fg}"',
            f'title="{fg}"',
            f'hi_fg="{acc}"',
            f'selected_bg="{hover}"',
            f'selected_fg="{acc}"',
            f'inactive_fg="{grey}"',
            f'graph_text="{yellow}"',
            f'meter_bg="{hover}"',
            f'proc_misc="{yellow}"',
            f'cpu_box="{pink}"',
            f'mem_box="{green}"',
            f'net_box="{red}"',
            f'proc_box="{blue}"',
            f'div_line="{surf}"',
        ]
        for box in ("temp", "cpu", "free", "cached", "available",
                    "used", "download", "upload"):
            lines += [f'{box}_start="{green}"', f'{box}_mid="{yellow}"',
                      f'{box}_end="{red}"']
        theme_file = tdir / "chameleon.theme"
        tmp = theme_file.with_suffix(".tmp")
        tmp.write_text("\n".join(lines) + "\n", encoding="utf-8")
        tmp.replace(theme_file)
        return theme_file
    except Exception:
        return None


def _set_btop_theme(theme_name: str, config_home: Path | None = None) -> bool:
    base = Path(config_home) if config_home is not None else Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    conf = base / "btop" / "btop.conf"
    try:
        if not conf.is_file():
            return False
        text = conf.read_text(encoding="utf-8")
        if re.search(r'^\s*color_theme\s*=', text, flags=re.MULTILINE):
            text = re.sub(r'^\s*color_theme\s*=.*$',
                          f'color_theme = "{theme_name}"',
                          text, flags=re.MULTILINE, count=1)
        else:
            text = text.rstrip() + f'\ncolor_theme = "{theme_name}"\n'
        tmp = conf.with_suffix(".tmp")
        tmp.write_text(text, encoding="utf-8")
        tmp.replace(conf)
        return True
    except Exception:
        return False


def _find_kvantum_template(kvantum_dir: Path | None = None) -> Path | None:
    base = kvantum_dir if kvantum_dir is not None else Path.home() / ".config" / "Kvantum"
    if not base.is_dir():
        return None
    cands = []
    try:
        for p in sorted(base.iterdir()):
            if p.is_dir() and next(p.glob("*.kvconfig"), None):
                cands.append(p)
    except OSError:
        return None
    for d in cands:
        if d.name == "catppuccin-mocha-pink":
            return d
    for d in cands:
        if d.name.startswith("catppuccin-mocha-"):
            return d
    return cands[0] if cands else None


def _recolor_kvconfig_text(text: str, d: dict) -> str:
    def sub8(m):
        mapped = _chameleon_for_template_hex("#" + m.group(1), d)
        return (mapped + m.group(2)) if mapped else m.group(0)

    text = re.sub(r"#([0-9a-fA-F]{6})([0-9a-fA-F]{2})\b", sub8, text)

    def sub6(m):
        mapped = _chameleon_for_template_hex(m.group(0), d)
        return mapped if mapped else m.group(0)

    return re.sub(r"#[0-9a-fA-F]{6}\b", sub6, text)


def _triplet(hex_str: str) -> str:
    r, g, b = hex_to_rgb(hex_str)
    return f"{r}, {g}, {b}"


def _readable_on(hex_str: str) -> str:
    return "#1e1e2e" if _relative_luminance(hex_str) > 0.55 else "#ffffff"


def build_breeze_colors(theme_dict: dict | None) -> str:
    """qt6ct color scheme built from Breeze role structure with
    chameleon hues (replaces template recoloring)."""
    c = (theme_dict or {}).get("colors", {})
    bg = c.get("backgroundOpaque", "#1e1e2e")
    surf = c.get("surface", "#313244")
    hover = c.get("surfaceHover", "#45475a")
    mantle = darken_hex(bg, 0.035)
    fg = c.get("foreground", "#cdd6f4")
    dim = c.get("offWhite", "#bac2de")
    grey = c.get("grey", "#585b70")
    acc = c.get("accent", "#89b4fa")
    red = c.get("red", "#f38ba8")
    green = c.get("green", "#a6e3a1")
    yellow = c.get("yellow", "#f9e2af")
    blue = c.get("blue", "#89b4fa")
    pink = c.get("pink", "#f5c2e7")
    acc_fg = _readable_on(acc)

    # Mesma lição do libadwaita: grandes áreas planas dessaturadas.
    surf_n = desaturate_hex(surf)
    hover_n = desaturate_hex(hover)
    mantle_n = desaturate_hex(mantle)

    def section(bg_, alt, fg_, dim_, link, neg, neu, pos, dec_f, dec_h):
        return {
            "BackgroundAlternate": _triplet(alt),
            "BackgroundNormal": _triplet(bg_),
            "DecorationFocus": _triplet(dec_f),
            "DecorationHover": _triplet(dec_h),
            "ForegroundActive": _triplet(fg_),
            "ForegroundInactive": _triplet(dim_),
            "ForegroundLink": _triplet(link),
            "ForegroundNegative": _triplet(neg),
            "ForegroundNeutral": _triplet(neu),
            "ForegroundNormal": _triplet(fg_),
            "ForegroundPositive": _triplet(pos),
            "ForegroundVisited": _triplet(pink),
        }

    sections = {
        "Colors:Window": section(bg, surf, fg, dim, blue, red, yellow, green, acc, hover),
        "Colors:View": section(surf_n, hover_n, fg, dim, blue, red, yellow, green, acc, hover),
        "Colors:Button": section(surf_n, hover_n, fg, dim, blue, red, yellow, green, acc, hover),
        "Colors:Selection": section(acc, acc, acc_fg, acc_fg, acc_fg, acc_fg,
                                    acc_fg, acc_fg, acc, hover),
        "Colors:Tooltip": section(hover_n, hover_n, fg, dim, blue, red, yellow, green, acc, hover),
        "Colors:Complementary": section(hover_n, surf_n, fg, dim, blue, red, yellow, green, acc, hover),
        "Colors:Header": section(mantle_n, mantle_n, fg, dim, blue, red, yellow, green, acc, hover),
    }
    out = ["# Generated by Quickshell Theme Manager: breeze roles, chameleon hues.", ""]
    for name, keys in sections.items():
        out.append(f"[{name}]")
        for k, v in keys.items():
            out.append(f"{k}={v}")
        out.append("")
    return "\n".join(out)


def _recolor_rgb_triplets(text: str, d: dict) -> str:
    def sub(m):
        hx = "#{:02x}{:02x}{:02x}".format(
            int(m.group(1)), int(m.group(2)), int(m.group(3)))
        mapped = _chameleon_for_template_hex(hx, d)
        if not mapped:
            return m.group(0)
        r, g, b = hex_to_rgb(mapped)
        return f"{r}, {g}, {b}"

    return re.sub(r"(\d{1,3}), (\d{1,3}), (\d{1,3})", sub, text)


def _flatten_kvantum_tabs(css: str) -> str:
    """Flat tab style (text + indicator) instead of the inherited
    raised button frame, closer to the bar pill language."""

    def section(name: str, body: str) -> str:
        lines = [l for l in body.splitlines() if not l.startswith("frame=")]
        return f"[{name}]\n" + "\n".join(lines) + "\nframe=false\n"

    def sub_tab(m):
        return section("Tab", m.group(1))

    return re.sub(r"\[Tab\]\n((?:[^\[]*\n)*?)(?=\[|\Z)", sub_tab, css, count=1)


def generate_qt_chameleon_theme(palette: dict | None = None,
                               config_home: Path | None = None,
                               kvantum_dir: Path | None = None) -> Path | None:
    """Generate Kvantum chameleon theme + qt6ct colors from the palette."""
    p = palette or get_chameleon_palette(read_current_theme_id())
    c = p.get("colors", {})
    d = _chameleon_derived(c)
    base = Path(config_home) if config_home is not None else Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    kv_base = kvantum_dir if kvantum_dir is not None else base / "Kvantum"
    template = _find_kvantum_template(kvantum_dir if kvantum_dir is not None else None)
    src_cfg = next(template.glob("*.kvconfig"), None) if template else None
    out_dir = None
    if src_cfg is not None:
        try:
            out_dir = kv_base / "chameleon"
            out_dir.mkdir(parents=True, exist_ok=True)
            css = _recolor_kvconfig_text(src_cfg.read_text(encoding="utf-8"), d)
            css = _flatten_kvantum_tabs(css)
            tmp = out_dir / "chameleon.kvconfig.tmp"
            tmp.write_text(css, encoding="utf-8")
            tmp.replace(out_dir / "chameleon.kvconfig")
            for svg in template.glob("*.svg"):
                dst = out_dir / svg.name
                if not dst.is_file():
                    try:
                        shutil.copy2(svg, dst)
                    except OSError:
                        pass
        except OSError:
            out_dir = None

    # qt6ct color scheme: built from Breeze roles (template only
    # supplies the non-color sections below).
    try:
        qt6ct_conf = base / "qt6ct" / "qt6ct.conf"
        if qt6ct_conf.is_file():
            colors_dir = base / "qt6ct" / "colors"
            colors_dir.mkdir(parents=True, exist_ok=True)
            out_colors = colors_dir / "Chameleon.colors"
            scheme_text = build_breeze_colors(p)
            template_src = Path("/usr/share/color-schemes/CatppuccinMochaPink.colors")
            if template_src.is_file():
                try:
                    raw = template_src.read_text(encoding="utf-8")
                    extra = []
                    keep = False
                    for line in raw.splitlines(keepends=True):
                        if line.startswith("[ColorEffects:") or line.startswith("[General]") \
                                or line.startswith("[KDE]") or line.startswith("[WM]"):
                            keep = True
                        elif line.startswith("["):
                            keep = False
                        if keep:
                            extra.append(line)
                    if extra:
                        scheme_text += "\n" + _recolor_rgb_triplets("".join(extra), d)
                except OSError:
                    pass
            tmp = out_colors.with_suffix(".tmp")
            tmp.write_text(scheme_text, encoding="utf-8")
            tmp.replace(out_colors)
            text = qt6ct_conf.read_text(encoding="utf-8")
            if re.search(r"^color_scheme_path=", text, flags=re.MULTILINE):
                text = re.sub(r"^color_scheme_path=.*$",
                              f"color_scheme_path={out_colors}",
                              text, flags=re.MULTILINE, count=1)
            else:
                text = text.rstrip() + f"\ncolor_scheme_path={out_colors}\n"
            # Breeze carrega a paleta do esquema acima sem relevo herdado;
            # Kvantum continua gerado como alternativa (style=kvantum).
            if re.search(r"^style=", text, flags=re.MULTILINE):
                text = re.sub(r"^style=.*$", "style=breeze",
                              text, flags=re.MULTILINE, count=1)
            else:
                text = text.rstrip() + "\nstyle=breeze\n"
            tmp = qt6ct_conf.with_suffix(".tmp")
            tmp.write_text(text, encoding="utf-8")
            tmp.replace(qt6ct_conf)
    except OSError:
        pass
    return out_dir


def _set_kvantum_theme(theme_name: str, kvantum_dir: Path | None = None) -> bool:
    base = kvantum_dir if kvantum_dir is not None else Path.home() / ".config" / "Kvantum"
    conf = base / "kvantum.kvconfig"
    try:
        if not conf.is_file():
            return False
        text = conf.read_text(encoding="utf-8")
        if re.search(r"^theme=", text, flags=re.MULTILINE):
            text = re.sub(r"^theme=.*$", f"theme={theme_name}",
                          text, flags=re.MULTILINE, count=1)
        else:
            text = text.rstrip() + f"\ntheme={theme_name}\n"
        tmp = conf.with_suffix(".tmp")
        tmp.write_text(text, encoding="utf-8")
        tmp.replace(conf)
        return True
    except Exception:
        return False


def sync_qt_theme(theme_id: str, theme_dict: dict | None = None,
                  config_home: Path | None = None,
                  kvantum_dir: Path | None = None) -> bool:
    """Fase 4: gera tema Kvantum chameleon e seleciona; cores qt6ct junto.

    Só atua quando há Kvantum configurado; caso contrário registra
    fora de sync em vez de falhar silenciosamente.
    """
    tid = str(theme_id or "").strip().lower()
    info = theme_dict or THEMES.get(tid, {})
    active = info if info.get("colors") else None
    kv_base = kvantum_dir if kvantum_dir is not None else Path.home() / ".config" / "Kvantum"
    qt_conf = (Path(config_home) if config_home is not None else Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))) / "qt6ct" / "qt6ct.conf"
    if _find_kvantum_template(kvantum_dir) is None and not kv_base.is_dir() \
            and not qt_conf.is_file():
        record_adapter("qt", False, tid)
        return False
    out = generate_qt_chameleon_theme(palette=active, config_home=config_home,
                                      kvantum_dir=kvantum_dir)
    _base = Path(config_home) if config_home is not None else Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    colors_ok = (_base / "qt6ct" / "colors" / "Chameleon.colors").is_file()
    kv_ok = False
    if out is not None:
        kv_ok = _set_kvantum_theme("chameleon", kvantum_dir=kvantum_dir)
    ok = kv_ok or colors_ok
    if not (_find_kvantum_template(kvantum_dir) is not None
            or (_base / "qt6ct" / "qt6ct.conf").is_file()):
        ok = False
    record_adapter("qt", ok, tid, active if ok else None)
    return ok


def sync_btop_theme(theme_id: str, theme_dict: dict | None = None,
                    config_home: Path | None = None) -> bool:
    """Fase 3: gera chameleon.theme e seleciona no btop.conf."""
    tid = str(theme_id or "").strip().lower()
    info = theme_dict or THEMES.get(tid, {})
    active = info if info.get("colors") else None
    theme_file = generate_btop_chameleon_theme(palette=active,
                                               config_home=config_home)
    if theme_file is None:
        record_adapter("btop", False, tid)
        return False
    ok = _set_btop_theme("chameleon", config_home=config_home)
    record_adapter("btop", ok, tid, active if ok else None)
    return ok


def sync_gtk_theme(theme_id: str, theme_dict: dict | None = None,
                   config_home: Path | None = None,
                   themes_dir: Path | None = None) -> bool:
    """Fase 2+: preferência claro/escuro + tema GTK instalado ou gerado.

    Temas chameleon geram ~/.themes/chameleon a partir da paleta ativa;
    demais temas escolhem entre instalados (fallback Adwaita).
    Espelha em gsettings + settings.ini do GTK 3/4.
    """
    tid = str(theme_id or "").strip().lower()
    info = theme_dict or THEMES.get(tid, {})
    dark = str(info.get("category", "dark")).lower() != "light"
    scheme = "prefer-dark" if dark else "prefer-light"
    if tid.startswith("chameleon"):
        gtk_theme = "chameleon"
        try:
            active = info if info.get("colors") else None
            generate_gtk_chameleon_theme(palette=active, themes_dir=themes_dir,
                                         name=gtk_theme)
        except Exception:
            gtk_theme = pick_gtk_theme("dark" if dark else "light")
    else:
        # Temas estáticos também ganham CSS da própria paleta em vez de
        # herdar um Catppuccin fixo que não os representa.
        gtk_theme = f"quickshell-{tid}"
        try:
            active = info if info.get("colors") else None
            generate_gtk_chameleon_theme(palette=active, themes_dir=themes_dir,
                                         name=gtk_theme)
        except Exception:
            gtk_theme = pick_gtk_theme("dark" if dark else "light")

    gsettings_ok = False
    if shutil.which("gsettings"):
        try:
            r1 = subprocess.run(
                ["gsettings", "set", "org.gnome.desktop.interface",
                 "color-scheme", f"'{scheme}'"],
                capture_output=True, text=True, timeout=5,
            )
            r2 = subprocess.run(
                ["gsettings", "set", "org.gnome.desktop.interface",
                 "gtk-theme", gtk_theme],
                capture_output=True, text=True, timeout=5,
            )
            gsettings_ok = r1.returncode == 0 and r2.returncode == 0
        except Exception:
            gsettings_ok = False

    ini_ok = _write_gtk_settings_ini(gtk_theme, dark, config_home=config_home)
    adw_ok = _write_libadwaita_css(info, config_home=config_home)
    if shutil.which("gsettings"):
        try:
            r3 = subprocess.run(
                ["gsettings", "set", "org.gnome.desktop.interface",
                 "accent-color", _accent_color_name(str(info.get("colors", {}).get("accent", "#89b4fa")))],
                capture_output=True, text=True, timeout=5,
            )
            gsettings_ok = gsettings_ok and r3.returncode == 0
        except Exception:
            pass
    ok = gsettings_ok or ini_ok or adw_ok
    record_adapter("gtk", ok, tid, info if ok else None)
    return ok


def apply_all_adapters(
    theme_id: str,
    theme_dict: dict,
    ghostty_config: Path | None = None,
    ghostty_themes_dir: Path | None = None,
    hypr_cache_dir: Path | None = None,
    gtk_config_home: Path | None = None,
    gtk_themes_dir: Path | None = None,
    btop_config_home: Path | None = None,
    qt_config_home: Path | None = None,
    qt_kvantum_dir: Path | None = None,
    labwc_config_home: Path | None = None,
) -> dict[str, bool]:
    """
    Aplica o tema canônico a todos os adaptadores desacoplados.
    Garante isolamento de falhas entre os adaptadores.
    """
    export_canonical_palette(theme_dict)

    # 1. Ghostty
    ghostty_ok = False
    try:
        if theme_id.startswith("chameleon"):
            generate_ghostty_chameleon_theme(palette=theme_dict, themes_dir=ghostty_themes_dir)
        elif theme_id.startswith("dracula-pro"):
            generate_ghostty_theme_file(theme_id, theme_dict, themes_dir=ghostty_themes_dir)
        ghostty_ok = sync_ghostty_theme(
            theme_id,
            config_path=ghostty_config,
            themes_dir=ghostty_themes_dir,
            palette=theme_dict,
        )
    except Exception:
        ghostty_ok = False

    # 2. Hyprland
    hyprland_ok = False
    try:
        hyprland_ok = sync_hyprland_theme(palette=theme_dict, cache_dir=hypr_cache_dir)
    except Exception:
        hyprland_ok = False

    # 3. hyprlock
    hyprlock_ok = False
    try:
        hyprlock_ok = sync_hyprlock_theme(palette=theme_dict, cache_dir=hypr_cache_dir)
    except Exception:
        hyprlock_ok = False

    # 4. GTK (preferência claro/escuro + tema instalado/gerado)
    gtk_ok = False
    try:
        gtk_ok = sync_gtk_theme(theme_id, theme_dict, config_home=gtk_config_home,
                                themes_dir=gtk_themes_dir)
    except Exception:
        gtk_ok = False

    # 5. btop (tema gerado + seleção no conf)
    btop_ok = False
    try:
        btop_ok = sync_btop_theme(theme_id, theme_dict,
                                  config_home=btop_config_home)
    except Exception:
        btop_ok = False

    # 6. Qt/Kvantum (tema gerado + seleção)
    qt_ok = False
    try:
        qt_ok = sync_qt_theme(theme_id, theme_dict,
                              config_home=qt_config_home,
                              kvantum_dir=qt_kvantum_dir)
    except Exception:
        qt_ok = False

    # 7. labwc (themerc-override gerado + reconfigure ao vivo na sessão)
    labwc_ok = False
    try:
        labwc_ok = sync_labwc_theme(palette=theme_dict, config_home=labwc_config_home)
    except Exception:
        labwc_ok = False

    # 8. Fastfetch colors follow the canonical wallpaper/theme palette.
    fastfetch_ok = False
    try:
        fastfetch_ok = sync_fastfetch_theme(theme_id, theme_dict)
    except Exception:
        fastfetch_ok = False

    return {
        "quickshell": True,
        "ghostty": ghostty_ok,
        "hyprland": hyprland_ok,
        "hyprlock": hyprlock_ok,
        "gtk": gtk_ok,
        "btop": btop_ok,
        "qt": qt_ok,
        "labwc": labwc_ok,
        "fastfetch": fastfetch_ok,
    }


def cmd_set(theme_id):
    tid = str(theme_id or "").strip().lower()
    if tid not in THEMES:
        return {
            "ok": False,
            "error": f"Tema '{tid}' não encontrado. Disponíveis: {', '.join(THEMES.keys())}",
            "current": read_current_theme_id(),
        }
    if tid.startswith("chameleon"):
        THEMES[tid] = extract_chameleon_palette(target_variant=tid)
    new_id = write_current_theme_id(tid)
    theme_dict = THEMES[new_id]
    adapters = apply_all_adapters(new_id, theme_dict)
    return {
        "ok": True,
        "error": None,
        "current": new_id,
        "theme": theme_dict,
        "variants": get_cached_variants(),
        "ghostty_synced": adapters.get("ghostty", False),
        "adapters": adapters,
    }


def cmd_next():
    current = read_current_theme_id()
    keys = sorted(list(THEMES.keys()), key=lambda k: THEMES[k]["name"].lower())
    try:
        idx = keys.index(current)
        next_id = keys[(idx + 1) % len(keys)]
    except ValueError:
        next_id = keys[0]
    return cmd_set(next_id)


def cmd_update_wallpaper(wallpaper_path=None):
    current = read_current_theme_id()
    target_var = current if current.startswith("chameleon") else "chameleon"
    # Sem mudança real de wallpaper e com cache válido: não reextrai
    # (evita loop com o watcher de ~/.cache/current_wallpaper).
    active_wp = wallpaper_path or detect_current_wallpaper()
    if active_wp and Path(active_wp).is_file() and CHAMELEON_PALETTE_FILE.is_file():
        try:
            cached = json.loads(CHAMELEON_PALETTE_FILE.read_text(encoding="utf-8"))
            if cached.get("algorithm") == "material-tonal-spot-2021-v1" and \
                    cached.get("wallpaper") == str(Path(active_wp)) and \
                    cached.get("wallpaper_mtime") == Path(active_wp).stat().st_mtime:
                for cid in ["chameleon", "chameleon-light", "chameleon-oled"]:
                    THEMES[cid] = get_chameleon_palette(cid)
                theme_info = THEMES.get(current, THEMES.get(DEFAULT_THEME))
                return {
                    "ok": True,
                    "error": None,
                    "current": current,
                    "theme": cached.get("variants", {}).get(target_var, cached),
                    "variants": get_cached_variants(),
                    "ghostty_synced": False,
                    "adapters": {
                        "quickshell": True,
                        "ghostty": adapter_in_sync("ghostty", current, theme_info),
                        "hyprland": adapter_in_sync("hyprland", current, theme_info),
                        "hyprlock": adapter_in_sync("hyprlock", current, theme_info),
                        "gtk": adapter_in_sync("gtk", current, theme_info),
                        "btop": adapter_in_sync("btop", current, theme_info),
                        "qt": adapter_in_sync("qt", current, theme_info),
                        "labwc": adapter_in_sync("labwc", current, theme_info),
                        "fastfetch": (
                            adapter_in_sync("fastfetch", current, theme_info)
                            or sync_fastfetch_theme(current, theme_info)
                        ),
                    },
                }
        except Exception:
            pass
    palette = extract_chameleon_palette(wallpaper_path, target_variant=target_var)
    for cid in ["chameleon", "chameleon-light", "chameleon-oled"]:
        THEMES[cid] = get_chameleon_palette(cid)

    if current.startswith("chameleon"):
        write_current_theme_id(current)
        active_pal = THEMES.get(current, palette)
        adapters = apply_all_adapters(current, active_pal)
    else:
        active_theme = THEMES.get(current, THEMES.get(DEFAULT_THEME))
        export_canonical_palette(active_theme)
        # Tema estático: paleta não mudou, só relata estado verificado.
        adapters = {
            "quickshell": True,
            "ghostty": adapter_in_sync("ghostty", current, active_theme),
            "hyprland": adapter_in_sync("hyprland", current, active_theme),
            "hyprlock": adapter_in_sync("hyprlock", current, active_theme),
            "gtk": adapter_in_sync("gtk", current, active_theme),
            "btop": adapter_in_sync("btop", current, active_theme),
            "qt": adapter_in_sync("qt", current, active_theme),
            "labwc": adapter_in_sync("labwc", current, active_theme),
            "fastfetch": adapter_in_sync("fastfetch", current, active_theme),
        }

    return {
        "ok": True,
        "error": None,
        "current": current,
        "theme": palette,
        "variants": get_cached_variants(),
        "ghostty_synced": adapters.get("ghostty", False),
        "adapters": adapters,
    }


def main():
    parser = argparse.ArgumentParser(description="Gerenciador de Temas do Quickshell")
    parser.add_argument("action", nargs="?", default="get", choices=["get", "list", "set", "next", "update-wallpaper"], help="Ação a executar")
    parser.add_argument("theme", nargs="?", default=None, help="ID do tema ou caminho do wallpaper")
    args = parser.parse_args()

    try:
        if args.action == "list":
            res = cmd_list()
        elif args.action == "set":
            if not args.theme:
                res = {"ok": False, "error": "ID do tema obrigatório para a ação 'set'"}
            else:
                res = cmd_set(args.theme)
        elif args.action == "next":
            res = cmd_next()
        elif args.action == "update-wallpaper":
            res = cmd_update_wallpaper(args.theme)
        else:
            res = cmd_get(args.theme)
    except Exception as e:
        res = {"ok": False, "error": str(e)}

    if isinstance(res, dict):
        res.setdefault("version", 1)
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0 if res.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
