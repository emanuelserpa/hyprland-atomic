#!/usr/bin/env bash
set -euo pipefail

missing=0
required_commands=(
  Hyprland awww-daemon brightnessctl copyq easyeffects flatpak ghostty grim
  hyprctl hypridle hyprlock nemo nm-applet playerctl rofimoji slurp swappy
  swaync-client trash-put waybar waypaper wl-copy wl-paste wob wofi wpctl
)

for command_name in "${required_commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'MISSING command: %s\n' "$command_name" >&2
    missing=1
  fi
done

required_files=(
  "$HOME/.config/hypr/hyprland.lua"
  "$HOME/.config/waybar/config"
  "$HOME/.config/swaync/config.json"
  "$HOME/.config/wofi/config"
  "$HOME/.config/uwsm/env"
  "$HOME/.config/ghostty/config"
  "$HOME/.config/waypaper/config.ini"
  "$HOME/.config/wob/wob.ini"
  "$HOME/.config/zsh/.zshrc"
  "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
  "$HOME/.zshenv"
  "$HOME/.local/bin/hypr-screenshot"
  "$HOME/.local/bin/elecwhat"
  "$HOME/.local/share/backgrounds/hyprland-atomic.png"
  "/etc/thinkfan.conf"
  "/etc/modprobe.d/99-thinkfan.conf"
  "/usr/libexec/hyprland-atomic-charge-limit"
)

for required_file in "${required_files[@]}"; do
  if [[ ! -f "$required_file" ]]; then
    printf 'MISSING file: %s\n' "$required_file" >&2
    missing=1
  fi
done

if [[ ! -x "$HOME/AppImages/elecwhat.appimage" ]]; then
  printf 'PENDING AppImage: %s\n' "$HOME/AppImages/elecwhat.appimage" >&2
  missing=1
fi

if ! flatpak info app.zen_browser.zen >/dev/null 2>&1; then
  printf 'PENDING Flatpak: app.zen_browser.zen (run bluebuild-flatpak-manager)\n' >&2
  missing=1
fi

if ! systemctl is-enabled --quiet thinkfan.service; then
  printf 'DISABLED service: thinkfan.service\n' >&2
  missing=1
fi

if ! systemctl is-enabled --quiet hyprland-atomic-charge-limit.service; then
  printf 'DISABLED service: hyprland-atomic-charge-limit.service\n' >&2
  missing=1
fi

if [[ -r /sys/class/power_supply/BAT0/charge_control_start_threshold &&
      -r /sys/class/power_supply/BAT0/charge_control_end_threshold ]]; then
  charge_start="$(< /sys/class/power_supply/BAT0/charge_control_start_threshold)"
  charge_end="$(< /sys/class/power_supply/BAT0/charge_control_end_threshold)"
  if [[ "$charge_start" != 75 || "$charge_end" != 80 ]]; then
    printf 'WRONG charge thresholds: %s-%s%% (expected 75-80%%)\n' \
      "$charge_start" "$charge_end" >&2
    missing=1
  fi
else
  printf 'MISSING ThinkPad charge-threshold interface for BAT0\n' >&2
  missing=1
fi

Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua"
ghostty +validate-config --config-file="$HOME/.config/ghostty/config"

if ! fc-match 'NotoSansM Nerd Font Mono' | grep -qi 'NotoSansM'; then
  printf 'MISSING font: NotoSansM Nerd Font Mono\n' >&2
  missing=1
fi

if (( missing != 0 )); then
  printf 'Installation verification failed. See the items above.\n' >&2
  exit 1
fi

printf 'Installation verification passed.\n'
