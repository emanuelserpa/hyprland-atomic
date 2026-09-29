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
  -> safe defaults bundled in the image from dotfiles/
  -> copied to each user's ~/.config on first graphical login
  -> existing files are kept as user overrides
```

The important change from v1 is that this project no longer tries to turn
Bazzite GNOME into a Hyprland distribution by removing GNOME afterward.

Wayblue is the desktop base. This repository only adds what is specific to
this workstation/use case.

## Added by this image

- QuickShell (bar, notifications, OSD, clipboard and Spotlight launcher)
- Kitty
- Zen Browser (user Flatpak)
- Nemo, Wofi and Rofimoji
- Waypaper + Awww
- Neovim + Zsh helpers
- mpv / yt-dlp
- EasyEffects
- Swappy screenshot editor
- thinkfan with the validated ThinkPad T14 Gen 1 AMD fan curve
- persistent ThinkPad battery protection (start at 75%, stop at 80%)
- Fedora sched_ext schedulers: `scx_layered`, `scx_rusty`
- Insync
- YADM and GnuPG for private dotfiles

The image deliberately does not install TLP because Wayblue already ships
`tuned-ppd`. Its standard `balanced`/`balanced-battery` mapping is retained;
only battery charge protection is managed separately through `thinkpad_acpi`.

## User configuration

Personal files such as:

```text
~/.config/hypr/
~/.config/kitty/
~/.config/ghostty/
~/.config/zsh/
```

are versioned under `dotfiles/` and bundled as defaults in the image. On the
first graphical login, a user service copies missing files into the home
directory and preserves anything already there. The Quickshell configuration
is also available at `/etc/xdg/quickshell`, and its service starts globally for
graphical sessions. Retired
Waybar, SwayNC, and Wob configurations are not included. See `dotfiles/README.md`
for included files and setup.

To fetch the separate private YADM repository and the latest Quickshell, run
`hyprland-atomic-get-dotfiles`. The command uses GitHub's browser login for the
private repository, then asks for the YADM archive passphrase. YADM clone
conflicts are preserved for review with `yadm status` and `yadm diff`.

After provisioning, users can edit their home copies without rebuilding the
image. Updating the defaults distributed to new or unprovisioned users requires
an image rebuild. The user dotfiles retain some Arch-specific update
integrations from the current desktop setup.

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
JSON/JSONC and YAML syntax. It also validates Hyprland and Quickshell when
installed; Ghostty validation is optional because the image does not include it.

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

The first graphical login automatically installs missing Hyprland, Kitty,
Zsh, and other user settings from the image. No clone is needed for a new user.
To manually apply the repository snapshot later, clone it and run the installer;
it backs up existing files before replacing them:

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
