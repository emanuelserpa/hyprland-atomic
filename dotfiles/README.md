# Desktop dotfiles

These are the versioned user configurations for the desktop. They are kept in
this repository for backup and review, but are not copied into the operating
system image or `/etc/skel`.

Included configurations:

- `hypr`: current Hyprland Lua configuration, Hypridle, Hyprlock, and shader
- `quickshell`: current shell, bar, notifications, OSD, launcher, services,
  helper scripts, and tests
- `systemd/user/quickshell.service`: starts QuickShell with the graphical session
- `kitty/kitty.conf` and `ghostty/config`: both terminal configurations
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

The installer also enables `quickshell.service` in the user systemd session.
Log out and back in after installing so the graphical-session target starts it.

The retired Waybar, SwayNC, and Wob configurations are not included.
Quickshell provides the active bar and notifications. The repository excludes
shell history, secrets, and prebuilt application binaries. Wayblue provides
`tuned-ppd`, so the active desktop configuration must not start or control TLP.
