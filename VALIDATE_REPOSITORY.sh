#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"

required_files=(
  recipes/recipe.yml
  .github/workflows/build.yml
  files/scripts/import-insync-key.sh
  files/system/etc/thinkfan.conf
  files/system/etc/modprobe.d/99-thinkfan.conf
  files/system/etc/yum.repos.d/insync.repo
  dotfiles/.config/hypr/hyprland.lua
  dotfiles/.config/ghostty/config
  dotfiles/.config/waybar/config
  dotfiles/.config/swaync/config.json
  dotfiles/.config/zsh/.zshrc
  dotfiles/.config/xdg-desktop-portal/hyprland-portals.conf
  dotfiles/.zshenv
  dotfiles/.local/bin/elecwhat
  dotfiles/.local/share/applications/elecwhat.desktop
  dotfiles/.local/share/backgrounds/hyprland-atomic.png
)

for required_file in "${required_files[@]}"; do
  [[ -f "$required_file" ]] || {
    printf 'MISSING repository file: %s\n' "$required_file" >&2
    exit 1
  }
done

shell_scripts=(
  INSTALL.sh
  VERIFY_INSTALLATION.sh
  APPLY_TO_EXISTING_REPO.sh
  files/scripts/import-insync-key.sh
  dotfiles/.config/waybar/scripts/flatpak-updates.sh
  dotfiles/.config/waybar/scripts/mpris-safe.sh
  dotfiles/.local/bin/hypr-screenshot
  dotfiles/.local/bin/elecwhat
)
bash -n "${shell_scripts[@]}"

if command -v zsh >/dev/null 2>&1; then
  zsh -n dotfiles/.zshenv dotfiles/.config/zsh/.zshenv \
    dotfiles/.config/zsh/.zprofile dotfiles/.config/zsh/.zshrc \
    dotfiles/.config/zsh/.zshrc.local
else
  printf 'SKIP Zsh validation: zsh is not installed.\n' >&2
fi

python3 - <<'PY'
import ast
import configparser
import json
import re
from pathlib import Path

python_file = Path("dotfiles/.config/waybar/scripts/waybar-wttr.py")
ast.parse(python_file.read_text(encoding="utf-8"), filename=str(python_file))

json.loads(Path("dotfiles/.config/swaync/config.json").read_text(encoding="utf-8"))

waybar = Path("dotfiles/.config/waybar/config").read_text(encoding="utf-8")
waybar = re.sub(r"^\s*//.*$", "", waybar, flags=re.MULTILINE)
json.loads(waybar)

portal_config = configparser.ConfigParser()
portal_config.read(
    "dotfiles/.config/xdg-desktop-portal/hyprland-portals.conf",
    encoding="utf-8",
)
if portal_config.get("preferred", "default") != "hyprland;gtk":
    raise ValueError("Unexpected Hyprland portal fallback order")
PY

if command -v ruby >/dev/null 2>&1; then
  ruby -e 'require "yaml"; ARGV.each { |file| YAML.load_file(file) }' \
    recipes/recipe.yml .github/workflows/build.yml
else
  printf 'SKIP YAML parsing: ruby is not installed.\n' >&2
fi

if command -v Hyprland >/dev/null 2>&1; then
  Hyprland --verify-config -c "$project_dir/dotfiles/.config/hypr/hyprland.lua"
else
  printf 'SKIP Hyprland validation: Hyprland is not installed.\n' >&2
fi

if command -v ghostty >/dev/null 2>&1; then
  ghostty +validate-config \
    --config-file="$project_dir/dotfiles/.config/ghostty/config"
else
  printf 'SKIP Ghostty validation: Ghostty is not installed.\n' >&2
fi

printf 'Repository validation passed.\n'
