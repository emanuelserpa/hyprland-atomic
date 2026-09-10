# Desktop dotfiles

These are the versioned user configurations for the desktop. They are kept in
this repository for backup and review, but are not copied into the operating
system image or `/etc/skel`.

Included configurations:

- `hypr`: Hyprland Lua configuration, Hypridle, Hyprlock, and the active shader
- `waybar`: bar configuration, theme, and referenced helper scripts
- `swaync`: notification-center configuration and theme
- `wofi`: launcher configuration and theme
- `uwsm`: portable graphical-session environment
- `ghostty`: terminal configuration
- `waypaper`: wallpaper selector configured with the included default background
- `wob`: on-screen volume and brightness bar
- `zsh`: Fedora-adapted interactive shell configuration and native Git prompt
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

The repository intentionally excludes old configurations, backup files, TLP
helpers, and prebuilt binaries. Wayblue provides `tuned-ppd`, so the active
desktop configuration must not start or control TLP.
