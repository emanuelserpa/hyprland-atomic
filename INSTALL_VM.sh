#!/usr/bin/env bash
set -euo pipefail

dotfiles_archive='https://github.com/emanuelserpa/dotfiles/archive/refs/heads/main.tar.gz'
repo_archive='https://github.com/emanuelserpa/hyprland-atomic/archive/refs/heads/main.tar.gz'
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/dotfiles"
curl -fsSL "$dotfiles_archive" | tar -xz --strip-components=1 -C "$tmpdir/dotfiles"

# Apply the personal YADM snapshot first, keeping any files already in the VM.
cp -a --no-clobber "$tmpdir/dotfiles/." "$HOME/"

mkdir -p "$tmpdir/hyprland-atomic"
curl -fsSL "$repo_archive" | tar -xz --strip-components=1 -C "$tmpdir/hyprland-atomic"

HYPRLAND_ATOMIC_DEFAULTS_DIR="$tmpdir/hyprland-atomic/dotfiles" \
HYPRLAND_ATOMIC_DEFAULTS_VERSION_FILE="$tmpdir/hyprland-atomic/files/system/usr/share/hyprland-atomic/defaults-version" \
  "$tmpdir/hyprland-atomic/files/system/usr/libexec/hyprland-atomic-user-setup"

systemctl --user enable --now quickshell.service
systemctl --user restart quickshell.service
