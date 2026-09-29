#!/usr/bin/env bash
set -euo pipefail

repo_archive='https://github.com/emanuelserpa/hyprland-atomic/archive/refs/heads/main.tar.gz'
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -fsSL "$repo_archive" | tar -xz --strip-components=1 -C "$tmpdir"

HYPRLAND_ATOMIC_DEFAULTS_DIR="$tmpdir/dotfiles" \
HYPRLAND_ATOMIC_DEFAULTS_VERSION_FILE="$tmpdir/files/system/usr/share/hyprland-atomic/defaults-version" \
  "$tmpdir/files/system/usr/libexec/hyprland-atomic-user-setup"

systemctl --user enable --now quickshell.service
systemctl --user restart quickshell.service
