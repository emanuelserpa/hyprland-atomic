#!/usr/bin/env bash
set -euo pipefail

repo_archive='https://github.com/emanuelserpa/hyprland-atomic/archive/refs/heads/main.tar.gz'
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/hyprland-atomic"
curl -fsSL "$repo_archive" -o "$tmpdir/hyprland-atomic.tar.gz"
tar -xzf "$tmpdir/hyprland-atomic.tar.gz" --strip-components=1 -C "$tmpdir/hyprland-atomic"

HYPRLAND_ATOMIC_DEFAULTS_DIR="$tmpdir/hyprland-atomic/dotfiles" \
HYPRLAND_ATOMIC_DEFAULTS_VERSION_FILE="$tmpdir/hyprland-atomic/files/system/usr/share/hyprland-atomic/defaults-version" \
  "$tmpdir/hyprland-atomic/files/system/usr/libexec/hyprland-atomic-user-setup"

systemctl --user enable --now quickshell.service
systemctl --user restart quickshell.service
