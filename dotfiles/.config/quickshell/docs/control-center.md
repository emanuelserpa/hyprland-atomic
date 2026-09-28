# Control Center (v0.21.0)

This page describes the historical standalone Control Center. The separate
top-right window and bar button are disabled in the current shell.
`ControlCenterCard` is currently embedded in the center dashboard opened from
Weather or Clock. `SUPER+A` opens Spotlight actions.

Session actions are grouped behind the **Sessão** button beside system updates
in the dashboard's system-controls card. Lock and suspend run directly;
ending the session, rebooting, and powering off require an explicit
confirmation from both this menu and Spotlight. The same actions remain
searchable in Spotlight.

The dashboard's `Jogos` tile occupies the former `Tema` tile position. It
shows whether a Steam game is running and opens Steam on click. Its status
helper polls only while the dashboard is open. Theme switching remains in
Spotlight's `:tema` / `:theme` actions.

The v0.21.0 Control Center was an upstream-Quickshell-only top-right `PanelWindow`.

Architecture choices:
- native Quickshell PipeWire for audio;
- native Quickshell UPower for battery;
- native MPRIS for media;
- existing NetworkManager and Bluetooth helper scripts are reused instead of
  duplicating system integration;
- existing energy-profile and printer helpers are reused;
- simple energy-profile and night-light status JSON is polled and decoded by
  the shared `CommandJson.qml` component;
- shared runtime idle-inhibit state lives in `qs.services.IdleState`;
- the UI has no exclusive zone and does not resize client windows.

Historical shortcut:
- `SUPER+A` -> `quickshell:control-center`
- right-clicking the former bar Control Center button opened the launcher `:` actions.

The first version intentionally keeps Wi-Fi/Bluetooth as fast toggles. Detailed
network/device selection remains in the existing dedicated bar popups, avoiding
two competing implementations of the same management UI.


## v0.21.1 refinements

MPRIS player selection is now centralized in `qs.services.MediaState`. The bar
and Control Center therefore cannot drift to different media sessions. A manual
player choice from the bar selector is reflected immediately in the Control
Center, and the selected/sticky player remains preferred while it still exists.

Compact action/profile labels use explicit Control Center color properties to
avoid delegate-scope palette ambiguity.


## v0.21.1-mousefix

This build is intentionally based on v0.21.1. The only added behavior is
outside-click dismissal for the Control Center. It does not include the later
compact-bar consolidation.
