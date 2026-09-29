#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"

required_files=(
  recipes/recipe.yml
  .github/workflows/build.yml
  files/scripts/import-insync-key.sh
  files/scripts/install-yadm.sh
  files/system/usr/bin/hyprland-atomic-get-dotfiles
  files/system/etc/thinkfan.conf
  files/system/etc/modprobe.d/99-thinkfan.conf
  files/system/etc/yum.repos.d/insync.repo
  files/system/usr/lib/systemd/system/hyprland-atomic-charge-limit.service
  files/system/usr/libexec/hyprland-atomic-charge-limit
  files/system/usr/libexec/hyprland-atomic-user-setup
  files/system/usr/share/hyprland-atomic/defaults-version
  files/systemd/user/quickshell.service
  files/systemd/user/hyprland-atomic-user-setup.service
  dotfiles/.config/hypr/hyprland.lua
  dotfiles/.config/ghostty/config
  dotfiles/.config/kitty/kitty.conf
  dotfiles/.config/quickshell/shell.qml
  dotfiles/.config/quickshell/Theme.qml
  dotfiles/.config/quickshell/scripts/validate.sh
  dotfiles/.config/systemd/user/quickshell.service
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
  files/scripts/install-yadm.sh
  files/system/usr/libexec/hyprland-atomic-charge-limit
  files/system/usr/libexec/hyprland-atomic-user-setup
  files/system/usr/bin/hyprland-atomic-get-dotfiles
  dotfiles/.config/quickshell/scripts/validate.sh
  dotfiles/.local/bin/hypr-screenshot
  dotfiles/.local/bin/elecwhat
)
bash -n "${shell_scripts[@]}"

if command -v zsh >/dev/null 2>&1; then
  zsh -n dotfiles/.zshenv dotfiles/.config/zsh/.zshenv \
  dotfiles/.config/zsh/.zprofile dotfiles/.config/zsh/.zshrc \
    dotfiles/.config/zsh/.zshrc.local
  zsh -n dotfiles/.config/zsh/conf.d/*.zsh
else
  printf 'SKIP Zsh validation: zsh is not installed.\n' >&2
fi

python3 - <<'PY'
import ast
import configparser
import os
import subprocess
import tempfile
from pathlib import Path

for python_file in Path("dotfiles/.config/quickshell/scripts").rglob("*.py"):
    ast.parse(python_file.read_text(encoding="utf-8"), filename=str(python_file))

portal_config = configparser.ConfigParser()
portal_config.read(
    "dotfiles/.config/xdg-desktop-portal/hyprland-portals.conf",
    encoding="utf-8",
)
if portal_config.get("preferred", "default") != "hyprland;gtk":
    raise ValueError("Unexpected Hyprland portal fallback order")

# First-login setup must seed missing files and preserve existing user files.
with tempfile.TemporaryDirectory(prefix="hyprland-atomic-setup-test-") as temp:
    root = Path(temp)
    home = root / "home"
    defaults = root / "defaults"
    state = root / "state"
    fake_bin = root / "bin"
    (defaults / ".config/hypr").mkdir(parents=True)
    (home / ".config/hypr").mkdir(parents=True)
    fake_bin.mkdir()
    (defaults / ".config/hypr/hyprland.lua").write_text("image default\n")
    (defaults / ".config/kitty/kitty.conf").parent.mkdir(parents=True)
    (defaults / ".config/kitty/kitty.conf").write_text("kitty default\n")
    (defaults / ".zshenv").write_text("zsh default\n")
    (home / ".config/hypr/hyprland.lua").write_text("user config\n")
    (fake_bin / "systemctl").write_text("#!/bin/sh\nexit 0\n")
    (fake_bin / "systemctl").chmod(0o755)
    version = root / "defaults-version"
    version.write_text("test\n")
    env = os.environ | {
        "HOME": str(home),
        "XDG_STATE_HOME": str(state),
        "HYPRLAND_ATOMIC_DEFAULTS_DIR": str(defaults),
        "HYPRLAND_ATOMIC_DEFAULTS_VERSION_FILE": str(version),
        "PATH": f"{fake_bin}:{os.environ['PATH']}",
    }
    subprocess.run(
        ["bash", "files/system/usr/libexec/hyprland-atomic-user-setup"],
        check=True,
        env=env,
        capture_output=True,
        text=True,
    )
    if (home / ".config/hypr/hyprland.lua").read_text() != "user config\n":
        raise ValueError("First-login setup overwrote an existing user config")
    if (home / ".config/kitty/kitty.conf").read_text() != "kitty default\n":
        raise ValueError("First-login setup did not seed a missing config")
    if (home / ".zshenv").read_text() != "zsh default\n":
        raise ValueError("First-login setup did not seed a hidden file")
    if not (state / "hyprland-atomic/user-setup-test").is_file():
        raise ValueError("First-login setup did not create its version marker")
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

if command -v quickshell >/dev/null 2>&1; then
  (cd dotfiles/.config/quickshell && ./scripts/validate.sh)
else
  printf 'SKIP QuickShell validation: quickshell is not installed.\n' >&2
fi

printf 'Repository validation passed.\n'
