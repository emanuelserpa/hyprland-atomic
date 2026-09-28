# Architecture

## Overview

The shell is organized around Quickshell QML components and small Python/shell helpers.

Main areas:

- `shell.qml`
- `bar/`
- `components/`
- `scripts/`
- optional config/state files

## Bar composition

`bar/Bar.qml` is intentionally explicit.

Do not dynamically instantiate the entire bar via `Repeater`/`Loader` without explicit approval.

The explicit layout protects:
- spacing;
- vertical alignment;
- center positioning;
- hover behavior;
- predictable module widths.

## Component philosophy

Spotlight keeps its providers local to `launcher/`: `SpotlightSearchController.qml`
routes app, window and command searches, while `SpotlightResult.qml` gives each
result a common contract. `SpotlightRanking.qml` combines apps, windows and
actions for nonempty root queries; the empty root query still lists apps.
Legacy result fields remain available to the current activation and preview
paths.

A module generally consists of:
- compact bar item;
- optional popup;
- optional helper script;
- state refresh logic.

Keep module boundaries understandable and local.

## Shared UI behavior

- `components/WheelKinetic.qml` owns the common direction and motion for wheel
  input on scrollable `Flickable` and `ListView` surfaces.
- `components/ScrollBar.qml` provides the shared vertical thumb, track click,
  drag, and wheel forwarding for long lists.
- `components/ActionFeedback.qml` shares busy/error state and optional timed
  dismissal while each domain keeps ownership of its action process and text.
- `components/CommandJson.qml` owns polling, process lifetime, and JSON decoding
  for simple status helpers. Use a local `Process` where stdin, output parsing,
  or action lifecycle needs domain-specific handling.
- `services/MotionState.qml` exposes the shared motion policy through
  `Theme.qml`. Quickshell handles visual transitions on every compositor;
  Hyprland continues to animate its own windows and workspaces independently.

## Python helpers

Python is used when shell commands become awkward or when structured JSON is useful.

Common pattern:
- QML starts a process;
- helper returns JSON;
- QML displays structured state.

Prefer small single-purpose helpers over one huge daemon.

## State

Mutable runtime state should go under XDG state/cache locations.

Examples:
- weather city selection:
  `~/.local/state/quickshell/weather.json`
- weather cache:
  XDG cache path

Do not store frequently changing state in tracked config files unless there is a strong reason.

## Process strategy

Subprocesses are acceptable, but:
- avoid excessive polling;
- avoid background scans unless UI is open or explicitly refreshed;
- avoid secrets in argv;
- prefer event/file observation when possible.

## Popup philosophy

Popups should:
- be cohesive;
- avoid dead space;
- avoid redundant cards;
- use visual grouping only where it improves comprehension;
- remain consistent with Catppuccin-inspired styling.

## Error strategy

Prefer contextual inline errors:
- per-row connection state for network;
- lightweight activity text;
- generic OSD only for cross-cutting feedback.

Avoid large technical error dumps in normal UI.

## Compositor Boundary & Agnosticism

The shell UI is decoupled from compositor-specific CLI commands and syntax:
- General UI components use Quickshell APIs or project helpers for compositor actions. `bar/Submap.qml` queries `hyprctl` only while Hyprland is active.
- All compositor dispatch actions (such as switching workspaces or focusing windows) are routed through `scripts/compositor-dispatch.sh`.
- The dispatcher encapsulates multi-format support (e.g. Hyprland Lua dispatch vs classic hyprlang dispatch) without leaking syntax into QML.
- Workspace display and activation use Quickshell's generic `WindowManager` ext-workspace API on labwc. `XDG_CURRENT_DESKTOP` selects the Hyprland-specific model; a stale `HYPRLAND_INSTANCE_SIGNATURE` does not select it.
- Popups utilize native Wayland layer-shell grab (`grabFocus: true`) provided by Quickshell `PopupWindow`, ensuring outside-click dismissal works universally across compositors.
- Compositor agnosticism is continuously guarded by automated checks in `scripts/validate.sh`.

## Theme System & Multi-Theme Architecture

The shell supports dynamic, live-reloading themes across all surfaces without restarting Quickshell:
- **Design Tokens**: `Theme.qml` remains the central design token contract for colors, radiuses, and typography. Its color properties are dynamically bound to `ThemeState.palette`.
- **Reactive State Singleton**: `services/ThemeState.qml` manages the active palette and provides reactive methods (`setTheme(id)` and `nextTheme()`).
- **Persistence**: Theme selection persists across reboots in `~/.local/state/quickshell/theme.json`.
- **Catalog**: Includes 7 popular community color palettes:
  - `catppuccin-mocha` (default dark)
  - `tokyo-night` (dark neon)
  - `nord` (arctic cold dark)
  - `gruvbox` (warm retro dark)
  - `dracula` (high-contrast gothic dark)
  - `rose-pine` (pine & lilac dark)
  - `catppuccin-latte` (clean light mode)
- **Control Points**:
  - **CLI**: `scripts/theme-manager.py [list|get|set <id>|next]`
  - **Chameleon**: `chameleon`, `chameleon-light`, and `chameleon-oled` share a wallpaper source color and use the vendored Python port of Material Color Utilities for Tonal Spot roles (version 3.0.2, 2021 specification; MIT license in `scripts/vendor/MATERIALYOUCOLOR-LICENSE`). Normal and OLED use dark roles; OLED has a black base. Light uses the full light scheme.
  - **Spotlight Launcher**: Quick switcher via `:tema` or `:theme` filter and `: Alternar Tema` system action.
  - **Wallpaper gallery**: `ThemePreviewPane.qml` shows the active wallpaper as a larger preview and lists the remaining images in a virtualized horizontal `ListView` with sized image decode. Thumbnail mouse areas forward wheel events to `WheelKinetic` so horizontal mouse wheels and touchpads glide. A single click marks a thumbnail with a visible border; left/right arrows move that selection, and Enter or a double click applies it. The folder and selected image persist in `~/.local/state/quickshell/wallpaper.json`. Applying a thumbnail uses awww/swww, refreshes `~/.cache/current_wallpaper` and the Chameleon palette. `folder` selects a new directory with zenity; Spotlight unmaps its layer window while the native picker is open and remaps in theme mode afterward so the picker stays visible. `restore` reapplies the saved image at session startup. If no image has been saved yet, restore imports Waypaper's previous selection once.
  - **Adapters**: every `set` / wallpaper-driven `update-wallpaper` also syncs
    Ghostty, Hyprland, hyprlock, GTK, btop, Qt/Kvantum and labwc
    (`~/.config/labwc/themerc-override`, live-reloaded via
    `labwc --reconfigure` inside a labwc session). Manual edits to generated
    adapter files are replaced on the next sync.
  - **No-blur fallback**: labwc has no blur, so `Theme.qml` floors
    `backgroundAlpha` at 0.92 in labwc sessions (`labwcSession`); Hyprland
    caps it at 0.75 so blur stays visible consistently across shell surfaces.
