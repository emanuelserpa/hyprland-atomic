# Desktop dotfiles

These are the versioned user configurations for the desktop. Quickshell is
copied into `/etc/xdg/quickshell` as a system default; the first graphical
login seeds missing files from this snapshot into the user's home. Existing
files are preserved, so yadm-managed settings keep precedence.

Included configurations:

- `hypr`: current Hyprland Lua configuration, Hypridle, Hyprlock, and shader
- `quickshell`: shell default in the image plus user-overridable bar,
  notifications, OSD, launcher, services,
  helper scripts, and tests
- `systemd/user/quickshell.service`: starts QuickShell with the graphical session
- `kitty/kitty.conf`: terminal configuration
- `wofi`: selector used by Rofimoji
- `uwsm`: portable graphical-session environment
- `waypaper`: wallpaper selector configured with the included default background
- `zsh`: modular Zinit setup, Deja, FZF, syntax highlighting, history search,
  and Powerlevel10k
- `xdg-desktop-portal`: Hyprland-specific portal routing with GTK fallback
- `.local/share/backgrounds`: default generated desktop wallpaper
- `.local/bin/elecwhat`: portable launcher for `~/AppImages/elecwhat.appimage`

Install them for the current user with the repository installer. It creates a
timestamped backup under `~/.local/state/hyprland-atomic/backups/` before it
copies anything.

```bash
./INSTALL.sh
```

The ElecWhat binary is intentionally not versioned. Put the executable
AppImage at `~/AppImages/elecwhat.appimage`; the installer provides its
launcher and desktop entry.

The image enables the setup and `quickshell.service` units globally for user
graphical sessions. The setup service runs once per packaged defaults version.
When changing the bundled defaults, increment
`files/system/usr/share/hyprland-atomic/defaults-version`; the next session
will seed newly added files without replacing existing ones.
`./INSTALL.sh` remains available for manual replacement and creates a backup
before copying files.

The retired Waybar, SwayNC, and Wob configurations are not included.
Quickshell provides the active bar and notifications. The repository excludes
shell history, secrets, and prebuilt application binaries. Wayblue provides
`tuned-ppd`, so the active desktop configuration must not start or control TLP.
