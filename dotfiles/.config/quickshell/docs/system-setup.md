# System Setup (outside Quickshell)

Notes about the surrounding system this shell expects. The shell never
manages these; they live in Hyprland config, Flatpak overrides, and CUPS.

## Hyprland bindings (`~/.config/hypr/hyprland.lua`)

- `SUPER+D` Spotlight, `SUPER+C` / `SUPER+V` clipboard history (`#`),
  `SUPER+A` actions, `SUPER+SHIFT+E` emoji, `SUPER+K` kill window.
- `SUPER+SHIFT+C` reads a screen QR Code into the clipboard
  (`scripts/scan-qr.sh`: slurp → grim → zbarimg → wl-copy).
- `Print` / `SHIFT+Print` save to `~/Imagens/Screenshots` + clipboard
  (grimblast `copysave`); `SUPER+Print` opens the newest shot in swappy
  (`scripts/screenshot-edit.sh last`).
- OTPClient floats centered (`otpclient-float` rule).

## labwc screenshot bindings (`~/.config/labwc/rc.xml`)

`Print` captures the full display and `SHIFT+Print` selects a region. Both use
`scripts/screenshot.sh` (`grim`, `slurp`, `wl-copy`) to save to
`~/Imagens/Screenshots` and copy the PNG. `SUPER+Print` opens the newest shot
in swappy. `screenshot-edit.sh` uses the same helper for new captures.

## labwc keyboard layout

The labwc `rc.xml` retains the Hyprland launchers (`SUPER+Q/T/E/D/C/V/A`,
`SUPER+SHIFT+E/C`), 1–0 desktop switching and Shift+1–0 window sending,
media keys, screenshots, and session shortcuts. `SUPER+N` opens notifications
and `SUPER+L` locks with hyprlock.

Stacking controls use the familiar remaining keys: `SUPER+Tab` opens the
spotlight window picker (Shift reverses window cycling in the native
`PreviousWindow` on `SUPER+SHIFT+Tab`); `SUPER+Arrow` snaps left/right, maximizes up, and restores
down; `SUPER+SHIFT+Arrow` moves to a screen edge. `SUPER+R` starts interactive
resize, `SUPER+M` starts interactive move, `SUPER+P` toggles always-on-top,
`SUPER+SHIFT+Space` toggles maximization, and `SUPER+CTRL+Space` toggles
visibility on every desktop. `SUPER+SHIFT+K` opens labwc's native
client menu.
`SUPER+Scroll` and `SUPER+PageUp/PageDown` switch desktops.

For a 50/25/25 layout, snap one window left with `SUPER+Left`, the upper-right
window with `SUPER+CTRL+Up`, and the lower-right window with
`SUPER+CTRL+Down`. The corner bindings use labwc's native `SnapToEdge` action.
`SUPER+K` opens the spotlight kill picker, `SUPER+TAB` the window picker
(`~`, via ToplevelManager), and `SUPER+L` locks with hyprlock
(wallpaper + fingerprint).
`SUPER+Scroll` and `SUPER+PageUp/PageDown` switch desktops.

## Flatpak theming

Per-user overrides (apply to all user Flatpaks):

```
flatpak override --user \
  --filesystem=xdg-config/gtk-3.0:ro \
  --filesystem=xdg-config/gtk-4.0:ro \
  --filesystem=$HOME/.themes:ro \
  --filesystem=xdg-data/icons:ro
```

- Never force `GTK_THEME`/`ICON_THEME` env overrides: a stale value makes
  every Flatpak fall back to Adwaita. Unset them and let `gtk-settings`
  (`chameleon` + `breeze-dark` + Noto Sans) apply.
- `/usr/share` cannot be exposed to sandboxes (reserved path): system icon
  themes must be copied (not symlinked) into `~/.local/share/icons`.
  Host fonts are shared automatically.

## Printing (CUPS, EPSON L4150 via `lpd://`)

- Queue default is portrait A4; the shell only monitors the queue and
  cancels jobs — it never sets options.
- Landscape documents need the orientation in the job ticket:
  `lp -o landscape -o fit-to-page file.pdf`. App previews lie: Okular and
  Zen/Firefox have both sent portrait tickets with landscape UI selected
  (verified per-job via `python3 -c "import cups"` attributes).
- Reliable flow for problem documents: app → print to PDF → `lp`.

## Clipboard

CopyQ is retired (native `wl-clipboard` + SQLite backend since v1.2.0).
Do not autostart `copyq --start-server`; its crashed helpers spam error
toasts through the shell. `scripts/clipboard-import-copyq.py` remains only
as the one-shot migration importer.

## Secrets and agents

The labwc session no longer starts `nm-applet`. Quickshell prompts for
protected Wi-Fi passwords and passes them to `nmcli --ask` over stdin.
Passwords never travel via command-line argv (see `docs/network.md`).

## Phone (KDE Connect)

The bar pill only appears with the `kdeconnect` package installed and the
daemon reachable: `sudo pacman -S kdeconnect`, pair on the same network
via the mobile app, `kdeconnect-cli --refresh`.

## labwc (daily-driver ready)

`~/.config/labwc/` carries `rc.xml`, `menu.xml`, `autostart`,
`environment`, `shutdown` and `themerc-override`. Spotlight is driven
via `quickshell ipc call spotlight <toggle|clipboard|actions|emoji|kill|
windows>` (`IpcHandler` in `launcher/Spotlight.qml`), since labwc has no
GlobalShortcut protocol. The shell user service starts through
`labwc-session.target` — never launch a second `quickshell` manually.
Workspaces use live ext-workspace windowsets, lock/idle is
swayidle + hyprlock, and the labwc theme follows the shell palette
(see `docs/labwc-install.md` for fresh-machine setup).
