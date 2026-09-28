# Network Module

## Architecture

Quickshell UI -> helper scripts -> `nmcli` -> NetworkManager.

This architecture is intentionally pragmatic.

## Secret handling

Wi-Fi passwords are not passed via command-line argv. Manual password entry,
QR generation, and copy actions send sensitive text to helpers via stdin.
The generated QR image is stored with mode `0600` inside a mode `0700`
directory under `XDG_RUNTIME_DIR`, with a system temporary directory fallback.
It can contain the Wi-Fi password, so exclude it from shared archives.

Selecting a protected Wi-Fi network
opens Quickshell's password dialog, which sends the password to
`nmcli --ask` on stdin. No session starts `nm-applet`. The Tray still filters any stale nm-applet item to
avoid the animated icon path that previously crashed KIconLoader.

## Features

- Wi-Fi state & active connection telemetry;
- Wi-Fi list with signal strength and security indicators;
- Connect/disconnect and a compact password dialog for protected networks;
- Wi-Fi radio toggle;
- VPN/WireGuard state and toggle;
- Built-in live Speedtest (latency ping, download, upload throughput with progress);
- Wi-Fi QR Code sharing with toggleable password visibility;
- Contextual activity, inline errors, and captive portal detection.
- Busy state, contextual error target, and timed error dismissal use the shared
  `ActionFeedback.qml`; Wi-Fi input and action process handling remain local to
  the network module.

## Scanning rule

Do not continuously rescan Wi-Fi.

Normal state polling should be cheap.

Actual radio scan should happen only when useful:
- popup open;
- explicit refresh;
- relevant action while popup is open.

## Placement

Network appears after Tray in the right-side bar order.

This is a user preference and should be preserved.

## Error presentation

Prefer:
- per-row `Conectando…`
- `Desconectando…`
- contextual error in the network row or password dialog
- auto-clear after a short delay

Avoid raw command output in the UI.

## Architecture comparison note

A more direct Quickshell.Networking / NetworkManager D-Bus approach was considered.

It is not currently preferred because the existing nmcli + secret-agent setup is simpler, stable, and sufficient.
