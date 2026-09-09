#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d .git ]]; then
  echo "Run this from the root of your existing hyprland-atomic git checkout." >&2
  exit 1
fi

echo "Removing v1 image-build files..."
rm -f Containerfile
rm -f files/scripts/build.sh
rm -rf files/system/etc/skel
rm -rf files/system/etc/zsh
rm -rf files/system/usr/share/ublue-os/firstboot
rm -f files/system/usr/share/ublue-os/cosign.pub

echo
echo "Now copy the contents of this v2 ZIP (except this helper if desired)"
echo "into the repository root, then review with:"
echo
echo "  git status"
echo "  git diff"
echo
echo "Suggested branch:"
echo "  git switch -c refactor/wayblue-v2"
echo
echo "Suggested commit:"
echo "  git add -A && git commit -m 'Refactor image v2 on top of Wayblue Hyprland'"
