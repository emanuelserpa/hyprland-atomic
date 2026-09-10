#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$project_dir/dotfiles"
timestamp="$(date +'%Y%m%d-%H%M%S')"
backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-atomic/backups/$timestamp"

if [[ ! -d "$source_dir/.config" ]]; then
  printf 'Dotfiles not found under %s\n' "$source_dir" >&2
  exit 1
fi

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/Pictures/Wallpapers"
mkdir -p "$backup_dir"

for relative_path in .config/hypr .config/waybar .config/swaync .config/wofi \
                     .config/uwsm .config/ghostty .config/waypaper .config/wob \
                     .config/zsh .zshenv; do
  destination="$HOME/$relative_path"
  if [[ -e "$destination" || -L "$destination" ]]; then
    mkdir -p "$backup_dir/$(dirname -- "$relative_path")"
    cp -a -- "$destination" "$backup_dir/$relative_path"
  fi
done

cp -a -- "$source_dir/.config/." "$HOME/.config/"
cp -a -- "$source_dir/.local/." "$HOME/.local/"
cp -a -- "$source_dir/.zshenv" "$HOME/.zshenv"
chmod +x "$HOME/.local/bin/hypr-screenshot" "$HOME/.local/bin/elecwhat"

printf 'Dotfiles installed. Previous files were backed up to:\n%s\n' "$backup_dir"
printf 'A default wallpaper was installed. Add personal wallpapers to %s if desired.\n' "$HOME/Pictures/Wallpapers"
printf 'Log out and back in so UWSM loads the new environment.\n'
printf 'After logging in, run %s to verify the installation.\n' "$project_dir/VERIFY_INSTALLATION.sh"
