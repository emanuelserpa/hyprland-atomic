# Current State — v1.2.0 baseline

This page is a short map of the running shell. Check the referenced source before changing behavior: some components added after v1.2.0 are still being developed. For constraints, read `AGENTS.md` and `docs/stability-contract.md`; for design and implementation, read `docs/architecture.md` and the relevant domain page. History belongs in `docs/version-history.md` and `CHANGELOG.md`.

## Shell composition

`shell.qml` creates one bar, OSD, and notification toast surface per screen, plus the Spotlight launcher and clipboard service. `bar/Bar.qml` defines the bar order explicitly. The bar shows glanceable state; popups contain detail and interaction.

| Area | Mounted components and behavior |
| --- | --- |
| Left | `StartButton` (traditional menu: categories + apps); `Workspaces` (live Hyprland workspaces or live labwc ext-workspace windowsets, with static labwc pills only if the protocol is absent); `Submap` queries `hyprctl` and appears only on Hyprland. |
| Center | `Weather` and `Clock` open `CenterDashboardPopup`, which contains weather, calendar, and `ControlCenterCard`. |
| Right | `Tray`, `Media`, `Network`, `Bluetooth`, `Phone`, `Audio`, `Battery`, `Printer`, `SystemUpdates`, `ScreenRecording`, `NotificationControl`, in that order. Some widgets hide when their state is inactive. |

`Temperature` is mounted invisibly to provide dashboard CPU telemetry. Brightness uses the global OSD; its older bar components are not mounted. The standalone Control Center window and button are disabled. Spotlight remains available through keyboard shortcuts.

## Where to look

| Work area | Current implementation and detail |
| --- | --- |
| Launcher, clipboard & theme studio | `launcher/Spotlight.qml`, `launcher/SpotlightSearchController.qml`, `launcher/SpotlightRanking.qml`, `launcher/SpotlightResult.qml`, `launcher/ThemePreviewPane.qml`, `services/ClipboardService.qml`, `LAUNCHER.md`, `docs/clipboard.md`, `docs/spotlight-raycast-plan.md` |
| Weather | `bar/Weather.qml`, `bar/WeatherCard.qml`, `docs/weather.md` |
| Network | `bar/Network.qml`, `bar/NetworkPopup.qml`, `docs/network.md` |
| Bluetooth | `bar/Bluetooth.qml`, `bar/BluetoothPopup.qml`, `docs/bluetooth.md` |
| Phone (KDE Connect, básico) | `bar/Phone.qml`, `bar/PhonePopup.qml`, `docs/phone.md` |
| Printing | `bar/Printer.qml`, `bar/PrinterPopup.qml`, `bar/PrinterQueueWindow.qml`, `docs/printer.md` |
| Media and audio | `services/MediaState.qml`, `bar/MediaPopup.qml`, `bar/AudioPopup.qml`; stability rules in `docs/stability-contract.md` |
| Notifications | `services/NotificationState.qml`, `notifications/NotificationToasts.qml`, `docs/notifications.md` |
| OSD and screen recording | `osd/Osd.qml`, `bar/ScreenRecording.qml`, `docs/osd.md`, `docs/screen-recording.md` |
| Dashboard and controls | `bar/CenterDashboardPopup.qml`, `bar/ControlCenterCard.qml`, `docs/control-center.md` |
| Running games | `scripts/game-status.py`; the dashboard's `Jogos` tile shows Steam game activity and opens Steam |
| Themes & Material You | `Theme.qml`, `launcher/ThemePreviewPane.qml`, `services/ThemeState.qml`, `scripts/theme-manager.py`, `scripts/wallpaper-action.py`, `docs/architecture.md` |
| Shared interactions | `components/WheelKinetic.qml`, `components/ScrollBar.qml`, `components/ActionFeedback.qml`, `components/CommandJson.qml` |
| Deployment and checks | `scripts/validate.sh`, `docs/deploy-and-validation.md` |

## Maintenance notes

- Keep the explicit `Bar.qml` ordering and the existing popup behavior. `Network` remains after `Tray`.
- The custom network UI prompts for protected Wi-Fi passwords and passes them to `nmcli --ask` over stdin; no session starts `nm-applet`. See `docs/network.md`.
- `SystemUpdates` is mounted and shows a pill only when updates are pending. `Printer`, `Media`, and `Submap` also conditionally hide.
- Update this map when a surface is mounted, removed, or moved. Put interaction details and backend contracts in the relevant domain documentation.
