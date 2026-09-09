# hyprland-atomic v2

Personal Fedora Atomic image based on Wayblue Hyprland.

## Architecture

```text
Fedora Atomic
  -> Wayblue Hyprland
       -> hyprland-atomic
            -> small package/tool layer
            -> personal hardware capabilities
            -> signed OCI image

$HOME configuration
  -> versioned in dotfiles/.config
  -> installed into ~/.config
```

The important change from v1 is that this project no longer tries to turn
Bazzite GNOME into a Hyprland distribution by removing GNOME afterward.

Wayblue is the desktop base. This repository only adds what is specific to
this workstation/use case.

## Added by this image

- Ghostty
- Zen Browser (user Flatpak)
- Nemo, Wofi and Rofimoji
- Waypaper + Awww
- Neovim + Zsh helpers
- mpv / yt-dlp
- CopyQ + wob
- EasyEffects
- SwayNotificationCenter
- Swappy screenshot editor
- thinkfan with the validated ThinkPad T14 Gen 1 AMD fan curve
- Fedora sched_ext schedulers: `scx_layered`, `scx_rusty`
- Insync

The image deliberately does not install TLP because Wayblue already ships
`tuned-ppd`.

## What belongs outside the image

Personal files such as:

```text
~/.config/hypr/
~/.config/waybar/
~/.config/swaync/
~/.config/ghostty/
~/.config/zsh/
```

are versioned under `dotfiles/.config/` rather than baked into `/etc/skel`.
See `dotfiles/README.md` for the included files and installation instructions.

This also means changing Waybar CSS or a Hyprland keybind does not require
rebuilding the operating system.

## Build

The image is built with the BlueBuild GitHub Action using:

```text
recipes/recipe.yml
```

Pull requests validate the image, while pushes to `main` and the daily
schedule publish it.

Before opening a pull request, run the repository checks locally:

```bash
./VALIDATE_REPOSITORY.sh
```

The command always checks the repository structure and the Bash, Python,
JSON/JSONC and YAML syntax. When Hyprland and Ghostty are installed, it also
validates their configuration with the applications themselves.

## Image

```text
ghcr.io/emanuelserpa/hyprland-atomic:latest
```

## Rebase

Bootstrap the image and its signing policy:

```bash
rpm-ostree rebase   ostree-unverified-registry:ghcr.io/emanuelserpa/hyprland-atomic:latest

systemctl reboot
```

After the first boot, install the versioned user configuration:

```bash
git clone https://github.com/emanuelserpa/hyprland-atomic.git
cd hyprland-atomic
./INSTALL.sh
```

Log out and back in so UWSM imports the new environment, then verify the
installation:

```bash
./VERIFY_INSTALLATION.sh
```

The installer creates a timestamped backup of existing configuration under
`~/.local/state/hyprland-atomic/backups/`. It includes a default wallpaper;
personal wallpapers can be added to `~/Pictures/Wallpapers`.

After the first boot, move to the signed transport:

```bash
rpm-ostree rebase   ostree-image-signed:docker://ghcr.io/emanuelserpa/hyprland-atomic:latest

systemctl reboot
```

Read `MIGRATION.md` before moving a machine from the old Bazzite-based image.

## Design rules

1. If Wayblue already provides it, do not rebuild it here.
2. System packages and services belong in the image recipe.
3. Hardware-specific tuning must identify its target machine and be validated
   there before it is enabled in the image.
4. Personal desktop configuration is not an OS-layer concern.
5. Avoid overriding Atomic/bootc internals unless there is a demonstrated need.
