# Quickshell Desktop Shell

A complete Linux desktop shell built on [Quickshell](https://quickshell.org/) +
Hyprland: glanceable top bar, detail-rich popups, native notifications, OSD,
and a Spotlight-style launcher with native Wayland clipboard manager.

Evolved from a Waybar migration into a self-contained shell. Currently in
daily use on Arch Linux (Hyprland, UWSM session).

## Features

- **Top bar** — explicit compact layout (Catppuccin Mocha, Noto Sans / Nerd
  Fonts): workspaces, weather + clock center cluster with dashboard popup
  (forecast, calendar, hardware controls), tray, media, audio, network,
  Bluetooth, battery, conditional updates pill, screen recording, and
  notification center.
- **Spotlight launcher** (`SUPER+D`) — apps with usage ranking, files (`@`),
  windows (`~`), clipboard history (`#`), session/system actions (`:`),
  emoji (`;`), kill-by-PID (`!`), shell commands (`>`), calculator (`=`).
- **Native clipboard manager** — `wl-clipboard` + persistent Python daemon +
  SQLite (WAL) + blob storage with thumbnails. No CopyQ dependency
  (one-shot importer in `scripts/clipboard-import-copyq.py`).
- **Dynamic themes** — 17 palettes (Catppuccin, Dracula family, Kanagawa,
  Everforest, Solarized, …) plus wallpaper-adaptive `Chameleon` variants,
  synced live to the Ghostty adapter (if installed), Hyprland borders/groupbar,
  and hyprlock.
- **Native notifications** (Quickshell NotificationServer), volume/mic/
  brightness OSD, night light, power profiles, multi-city Open-Meteo weather.

## Requirements

Quickshell 0.3.x, Hyprland or labwc, PipeWire, `wl-clipboard`, Python 3
(`requests`, `Pillow`), Noto Sans / Nerd Fonts, Kitty. Ghostty is optional and
only enables its theme adapter.
For a new machine, see the requirements above and use the upstream Quickshell
installation instructions.

Per-feature helpers: `nmcli`, `bluetoothctl`, `checkupdates`
(`pacman-contrib`), `curl`, `fd`, `brightnessctl`, `upower`,
`power-profiles-daemon`, `grim`, `slurp`, `grimblast` (Hyprland), `swappy`, `blueberry`,
`nm-connection-editor`, `pwvucontrol`, `htop`.

## Install

This project includes a snapshot of the active Quickshell configuration under
`dotfiles/.config/quickshell`. The image installs it as the system default at
`/etc/xdg/quickshell` and starts it with the graphical session. A user config
at `~/.config/quickshell` overrides that default. Run the repository's
`./INSTALL.sh` to copy the snapshot into your home together with the companion
desktop settings; the installer backs up existing files first.

For standalone use outside this project, the upstream setup is:

```bash
git clone git@github.com:emanuelserpa/quickshell.git ~/.config/quickshell
systemctl --user restart quickshell.service
```

Companion system config (Hyprland bindings, Flatpak theming, CUPS notes)
lives in `git@github.com:emanuelserpa/dotfiles.git` (yadm); its
`.config/yadm/bootstrap` clones this repo on `yadm clone`.

Keybindings live in `~/.config/hypr/hyprland.lua`:

| Shortcut | Action |
|---|---|
| `SUPER+D` | Spotlight launcher |
| `SUPER+C` | Clipboard history |
| `SUPER+A` | Actions / settings |
| `SUPER+SHIFT+E` | Emoji picker |
| `SUPER+TAB` | Window switcher |
| `SUPER+K` | Kill app |

Validate before deploying:

```bash
./scripts/validate.sh
python3 -B -m unittest discover -s tests -p "test_*.py"
```

## Layout

```text
shell.qml
├── bar/            # Bar modules + popups (explicit layout in Bar.qml)
├── launcher/       # Spotlight + per-mode modules
├── notifications/  # Native toasts
├── osd/            # Volume / mic / brightness overlay
├── services/       # Shared singletons (Theme, Media, Notifications, …)
├── components/     # Shared visuals (Pill, PopupCard, …)
├── scripts/        # Python/shell backends (JSON contracts)
└── tests/          # Python unit tests
```

## History

See `CHANGELOG.md` for the shell's evolution (Waybar migration → Control Center
→ native clipboard → current shell).
