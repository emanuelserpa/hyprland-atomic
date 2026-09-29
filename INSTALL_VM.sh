#!/usr/bin/env bash
set -euo pipefail

repo_archive='https://github.com/emanuelserpa/hyprland-atomic/archive/refs/heads/main.tar.gz'
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/dotfiles"
if GIT_SSH_COMMAND='ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8' \
    git clone --quiet --depth 1 git@github.com:emanuelserpa/dotfiles.git "$tmpdir/yadm-repo" \
    && git -C "$tmpdir/yadm-repo" archive HEAD | tar -x -C "$tmpdir/dotfiles"; then
  # Apply the private YADM snapshot first, keeping any files already in the VM.
  cp -a --no-clobber "$tmpdir/dotfiles/." "$HOME/"
else
  printf 'Private YADM dotfiles not downloaded (no usable GitHub SSH key); continuing with public defaults.\n' >&2
fi

mkdir -p "$tmpdir/hyprland-atomic"
curl -fsSL "$repo_archive" -o "$tmpdir/hyprland-atomic.tar.gz"
tar -xzf "$tmpdir/hyprland-atomic.tar.gz" --strip-components=1 -C "$tmpdir/hyprland-atomic"

HYPRLAND_ATOMIC_DEFAULTS_DIR="$tmpdir/hyprland-atomic/dotfiles" \
HYPRLAND_ATOMIC_DEFAULTS_VERSION_FILE="$tmpdir/hyprland-atomic/files/system/usr/share/hyprland-atomic/defaults-version" \
  "$tmpdir/hyprland-atomic/files/system/usr/libexec/hyprland-atomic-user-setup"

systemctl --user enable --now quickshell.service
systemctl --user restart quickshell.service
