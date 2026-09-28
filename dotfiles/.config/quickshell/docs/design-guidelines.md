# Design Guidelines & System Specification

This document defines the visual language, design tokens, component architecture, and interaction patterns for the Quickshell desktop shell.

---

## 1. Core Design Philosophy

**Scroll preference:** the user uses conventional wheel direction, not macOS-style natural scrolling. In horizontal galleries, vertical wheel down advances right and wheel up returns left. On the touchpad, fingers moving down advance right and fingers moving up return left. Touchpad gestures use their dominant axis so slight diagonal jitter does not change direction. Verify this mapping when changing scroll handlers.

Every scrollable `Flickable` and `ListView` uses `components/WheelKinetic.qml`.
Keep wheel steps, touchpad scaling, and release momentum in that shared handler;
individual surfaces may select an axis but must not override scroll speed or direction.

The desktop shell is designed around three fundamental principles:

1. **Glanceable Bar, Rich Popups**:
   - The top bar communicates essential, low-latency status at a glance without cluttering the screen or shifting widths unpredictably.
   - Secondary information, controls, lists, and sliders belong in dedicated popups.
2. **Compact Density & Calm Geometry**:
   - Compact spacing (`height: 25px` pills, `spacing: 4px` clusters).
   - Avoid "card-inside-card-inside-card" nesting and avoid giving every single raw metric its own container.
   - Clean, harmonized corner radii (`radius: 6px` for pills, `radius: 14px` for popups).
3. **Restrained Color Hierarchy**:
   - Built on Catppuccin Mocha.
   - Dark, translucent surfaces with subtle glass borders.
   - Accent colors have strict semantic roles (never used purely as rainbow decoration).

---

## 2. Color System & Design Tokens (`Theme.qml`)

All styling properties must resolve through `Theme.qml` (or the `palette` object passed from the root window). Do not hardcode ad-hoc hex values in component files.

### 2.1 Palette & Semantic Accents

| Token | Hex / Value | Semantic Role |
| :--- | :--- | :--- |
| `background` | `rgba(30, 30, 46, 0.75)` | Floating bar and standard window background (75% alpha) |
| `backgroundOpaque` | `#1e1e2e` | Opaque base for layered cards and blur backdrops |
| `surface` | `#313244` | Elevated containers, cards, and dropdown drawers |
| `surfaceHover` | `#45475a` | Hovered interactive items, active dropdown rows |
| `foreground` | `#cdd6f4` | Primary high-contrast typography and titles |
| `offWhite` | `#bac2de` | Secondary typography, default icon fills |
| `grey` | `#585b70` | Timestamps, inactive states, subtitled metadata, separators |
| `blue` | `#89b4fa` | Primary accent, focused states, general interactions |
| `pink` | `#f5c2e7` | Media highlight, playing status, music iconography |
| `green` | `#a6e3a1` | Positive/connected status (Wi-Fi, Bluetooth connected, Spotify accent) |
| `yellow` / `orange` | `#f9e2af` / `#fab387` | Warnings, intermediate battery, Firefox/Zen accent |
| `red` | `#f38ba8` | Critical battery, errors, destructive actions |

### 2.2 Design Tokens

#### Radiuses
- `pillRadius`: `6px` — Unified radius for all bar pills and small tags.
- `radiusSm`: `6px` — Micro chips, sub-badges, time badges.
- `radiusMd`: `8px` — Inner containers, slider tracks, dropdown lists.
- `radiusLg`: `10px` — Intermediate cards and dialogue items.
- `radiusXl`: `12px` — Artwork containers, hero cards.
- `radiusPopup`: `14px` — Root outer card radius for all popup windows.

#### Surfaces & Cards
- `cardBackground`: `rgba(49, 50, 68, 0.28)` — Subtle card surface.
- `cardBackgroundSubtle`: `rgba(49, 50, 68, 0.20)` — Nested list backgrounds.
- `cardBackgroundHover`: `rgba(69, 71, 90, 0.45)` — Hover state for cards/items.
- `cardBackgroundActive`: `rgba(69, 71, 90, 0.70)` — Active/selected list item.

#### Borders & Glass Rims
- `pillBorder`: `rgba(69, 71, 90, 0.35)` — Subtle resting border on bar pills.
- `pillBorderHover`: `rgba(88, 91, 112, 0.55)` — Clear feedback border on hover.
- `borderPopup`: `rgba(69, 71, 90, 0.72)` — Outer boundary border for popups.
- `glassBorder`: `rgba(255, 255, 255, 0.12)` — Glass highlight border on dark surfaces.
- `glassBorderSubtle`: `rgba(255, 255, 255, 0.08)` — Internal dividing lines and separators.

---

## 3. Typography & Iconography

- **Primary Font**: `Noto Sans` (fallback: system sans-serif).
- **Icon Font**: `Noto Sans Nerd Font` / `Symbols Nerd Font`.
- **Monospace Font**: `JetBrainsMono Nerd Font` (token `monoFontFamily` in `Theme.qml`) for raw code, terminal commands, and clipboard full-text previews.
- **Text Rendering**: `renderType: Text.NativeRendering` or standard antialiased glyphs. Avoid heavy monospace styling for general UI labels.
- **Sizes & Weights**:
  - Bar text: `12px` to `13px`, `Font.Medium` or `Font.DemiBold`.
  - Popup titles / track titles: `14px` to `15px`, `Font.Bold`.
  - Subtitles / artists: `11px` to `12px`, `Font.Medium`.
  - Captions / timestamps / telemetry: `9px` to `10px`, `Font.Normal`.

---

## 4. Bar Architecture & Component Specifications

The bar is a floating `PanelWindow` with an implicit height of `37px` and subtle margin from screen edges.

### 4.1 Cluster Order

1. **Left Cluster**:
   - `Workspaces`: clean active/inactive indicator without heavy boxy micro-borders.
   - `Submap`: Hyprland modal submap indicator (conditional visibility).
2. **Center Cluster**:
   - `Weather`: compact weather icon + temperature pill.
   - Subtle dot separator (`·`).
   - `Clock`: date and time pill; clicking toggles the center dashboard popup.
3. **Right Cluster**:
   - `Tray`: StatusNotifierItem icons (e.g. apps, communication).
   - `Media`: compact `31px` music note pill (``). Only visible when a titled MPRIS session exists.
   - `Audio`: unified volume + mic status pill.
   - `Network`: Wi-Fi / Ethernet status pill.
   - `Bluetooth`: connection state and active devices.
   - `Battery`: battery percentage and charging indicator.
   - `NotificationControl`: DND toggle and notification hub trigger.

### 4.2 Unified Pill Specification

Every pill on the bar adheres to the same physical dimensions and interactive behavior:

```qml
height: theme.pillHeight      // 25px
radius: theme.pillRadius      // 6px
color: mouse.containsMouse ? theme.pillBackgroundHover : theme.pillBackground
border.width: 1
border.color: mouse.containsMouse ? theme.pillBorderHover : theme.pillBorder
```

#### Pill Interactions:
- **Cursor**: `cursorShape: Qt.PointingHandCursor` via `MouseArea`.
- **Left-Click**: Toggles the corresponding detailed popup or modal.
- **Right-Click**: Context action (DND on Notifications, caffeine on Clock, power toggle on Bluetooth, refresh on Network/Printer/Weather, ping on Phone, mute per half on Audio). Other pills carry no right-click action; settings live behind the popup header gear.
- **Middle-Click**: No bar action; only tray icons forward it to their apps.
- **Scroll Wheel**: Contextual increment/decrement (e.g., volume up/down on Audio; next/previous track on Media).
- **Tooltips**: Delayed hover tooltips (`400ms` debounce) to prevent flashing during rapid cursor movement across the bar.

---

## 5. Popup Architecture & Layout Guidelines

All popups inherit from Quickshell's `PopupWindow` with transparent backgrounds.
Popups opened by click grab focus (`grabFocus: true`). The Media popup does not grab focus while
opened as a hover preview (`grabFocus: !hoverPreview`), so showing it does not interrupt the pill's hover.

### 5.1 Anchoring Rules

Popups must be anchored to their initiating bar widget (`target`) so they never overflow the display edges:

- **Right-Cluster Widgets** (`Media`, `Audio`, `Network`, `Bluetooth`, `Battery`):
  ```qml
  anchor.item: target
  anchor.edges: Edges.Bottom | Edges.Right
  anchor.gravity: Edges.Bottom | Edges.Left
  anchor.margins.top: 6
  ```
- **Center-Cluster Widgets** (`Clock`, `Weather`):
  ```qml
  anchor.item: target
  anchor.gravity: Edges.Bottom
  anchor.margins.top: 6
  ```
- **Left-Cluster Widgets** (`Workspaces`, `Submap`):
  ```qml
  anchor.item: target
  anchor.edges: Edges.Bottom | Edges.Left
  anchor.gravity: Edges.Bottom | Edges.Right
  anchor.margins.top: 6
  ```

### 5.2 Core Window Configuration & Dismissal Behavior

All popups follow an identical interaction and windowing contract:

```qml
PopupWindow {
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true
    focus: true

    function toggle() {
        root.visible = !root.visible
    }

    onVisibleChanged: {
        if (visible) card.forceActiveFocus()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
```

#### Dismissal Rules (Unified Contract):
1. **Outside Click Dismissal**: Managed natively by Wayland layer-shell grab focus (`grabFocus: true`). Clicking anywhere outside the popup automatically dismisses it.
2. **Pill Toggle**: Clicking the initiating bar pill toggles the popup (opens if closed, closes if open) via `popup.toggle()` or `popup.visible = !popup.visible`.
3. **Keyboard Dismissal**: Pressing the `Escape` key immediately closes the popup (`Shortcut` / `Keys.onEscapePressed`).
4. **Header Cleanliness**: Popups do **not** carry redundant "✕" close buttons in their headers. Dismissal is purely modeless through outside-clicks, pill clicks, or Escape. Header space is exclusively reserved for semantic titles, status indicators, and contextual action tools (e.g. DND, clear, refresh).


### 5.3 Scrollable Surfaces & Lists Specification

When a popup contains dynamic lists (e.g. notification history, audio streams, Bluetooth devices, Wi-Fi networks):

1. **Standard Scroll Mechanics**:
   - Scroll wheel direction: Conventional wheel delta (`angleDelta.y > 0` scrolls up towards top/newer items; `angleDelta.y < 0` scrolls down).
   - Stationary track interaction: Clicking anywhere along the scrollbar track or dragging the thumb directly repositions the scroll position smoothly.
2. **Viewport & Geometry Protection**:
   - Sizing must be calculated from internal child items (`implicitHeight`) without forcing awkward layout clipping.
   - **Last Item Guarantee**: Scrollable lists must include bottom padding or a spacer (`8px` to `12px`) so the final card is never cropped by the container radius or scroll boundary.
   - Minimum comfortable viewport: For high-frequency items (like notifications), sizing accommodates at least 4 items without scroll before activating the scrollbar.

### 5.4 Text Sanitization & Entity Decoding Contract

UI elements ingesting external or third-party text (such as notification titles and bodies from Telegram, web browsers, Discord, or terminal tools):

1. **Entity Decoding**: Entities such as `&quot;`, `&#39;`, `&amp;`, `&lt;`, `&gt;`, and arbitrary decimal/hex entities (`&#NN;`, `&#xNN;`) must be decoded to their literal UTF-8 glyphs prior to rendering.
2. **Markup Stripping & Normalization**:
   - `<br>` and `<br/>` tags must be converted to standard line breaks (`\n`).
   - HTML/XML tags (`<b>`, `<i>`, `<span>`, `<a>`, etc.) must be sanitized/stripped to prevent raw tag leakage in text components.

---

## 6. Media System: "Hero Glass" Pattern

The media subsystem operates in two distinct tiers:

### 6.1 Bar Presence (`Media.qml`)
- **Icon**: `` (Nerd Font).
- **Accent**: `theme.pink` when playing; `theme.offWhite` when paused.
- **Visibility**: Strictly conditional on `player !== null && title.length > 0`. Idle background players without active tracks remain hidden.
- **Interactions**:
  - `Hover`: Opens `MediaPopup` after 250ms without taking focus. It remains
    open while the pointer crosses into the panel and closes after a 300ms
    delay once the pointer leaves both surfaces.
  - `Left-Click`: Opens or closes `MediaPopup`; clicking a hover preview keeps
    it open with focus. Playback is controlled from the popup hero controls.
  - `Wheel`: Advances to next track (up) or previous track (down).

### 6.2 Popup Presentation (`MediaPopup.qml` — Hero Glass)

The popup features an immersive glass layout highlighting the currently playing album artwork:

```
┌────────────────────────────────────────────────────────┐
│ [ Spotify ▾]                                     [✕] │  <- Header & Switcher
├────────────────────────────────────────────────────────┤
│ ┌─────────┐  Track Title (Bold 14px)                   │
│ │         │  Artist Name (Accent color 12px)           │  <- Hero Artwork
│ │ Artwork │  Album Name (Grey 10px)                    │     (80x80, r:12)
│ └─────────┘                                            │
├────────────────────────────────────────────────────────┤
│ ────●───────────────────────────────────────────────── │  <- Interactive
│ 1:24                                              3:45 │     Seek Scrubber
├────────────────────────────────────────────────────────┤
│             [  ]     ((  ))     [  ]                │  <- Centered Controls
│             (36px)    (46px Hero) (36px)               │
└────────────────────────────────────────────────────────┘
```

#### Hero Glass Visual Stack:
1. **Ambient Blurred Artwork**:
   - `Image` loading `trackArtUrl` in background.
   - `MultiEffect` with `blur: 1.0`, `blurMax: 48`, `saturation: 1.20`, and `opacity: 0.35`.
   - Alpha-masked to the rounded card bounds (`radius: 14px`).
2. **Gradient Vignette Overlay**:
   - Vertical gradient from `rgba(24, 24, 37, 0.72)` to `rgba(17, 17, 27, 0.92)` ensuring typography readability and contrast against bright album covers.
3. **Artwork Container**:
   - Size: `80x80px`, `radius: 12px`, with a subtle border (`rgba(255, 255, 255, 0.18)`).
   - Graceful fallback icon (``) when artwork is loading or unavailable.
4. **Interactive Seek Scrubber**:
   - Drag or click to seek (`seekToFraction(mouse.x / width)`).
   - Filled progress bar in player accent color.
   - Glowing circular handle visible on hover or during drag.
5. **Centered Hero Playback Controls**:
   - Hero play/pause circular button (`46x46px`) with micro-scale click animation (`scale: 0.92` on press, `90ms` duration).
   - Previous and Next buttons (`36x36px`) with hover highlight and `0.35` opacity when disabled.
6. **Multi-Player Drawer Switcher**:
   - Header badge shows the current player identity (Spotify, Zen Browser, Chromium, etc.).
   - If more than 1 titled player exists, clicking the badge reveals a drawer: the active player as a big accent-tinted card ("Tocando agora" + check) and the rest as small grey cards. Tapping a grey card promotes it with a ~140ms swap animation.

---

## 7. Audio & Stream Management Pattern

The audio interface (`bar/AudioPopup.qml`) balances master device control with granular per-app audio routing:

1. **Master Volume & Mic Sliders**:
   - Full-width draggable sliders with percentage indicators and mute toggles.
2. **Device Selectors**:
   - Output sinks and Input sources listed with clear active checkmarks (`󰄬`).
3. **Application Streams Hierarchy**:
   - Every active application stream displays:
     - Application icon (`󰈹` Firefox/Zen, `󰓇` Spotify, `󰊯` Chrome, `󰙯` Discord).
     - Application name in primary foreground (`Font.DemiBold`).
     - **Media Title Subtitle**: If the stream represents a media player, the current track title is rendered underneath in `theme.grey` (e.g. YouTube video title or Spotify song).
     - Dedicated volume slider and mute toggle per application.

---

## 8. Spotlight Launcher & Modal Architecture

The desktop launcher (`launcher/Spotlight.qml`) serves as the central command palette:

### 8.1 Modal Geometries & Transitions
- **Standard Mode** (Apps, Commands, Calc, Files, Actions, Emoji, Kill, Windows):
  - Fixed compact width: `560px`.
  - Dynamic height: calculated from results count (`Math.min(results.length, 6) * 52px + 120px`).
- **Clipboard Mode (`#` or `SUPER+C`)**:
  - Dynamically expands to **`820px` width** and **`500px` height**.
  - Animated with smooth easing transitions (`NumberAnimation { duration: 160; easing.type: Easing.OutCubic }`).

### 8.2 Split-View Layout (Raycast / Alfred Style)
- **Left Column (`360px`)**:
  - Filterable `ListView` showing up to 50 matching results.
  - Highlights active item (`radius: 12px`, Catppuccin surface active background).
  - Semantic iconography with color coding:
    - `󰌷` Links: `theme.cyan`
    - `󰘐` Code snippets: `theme.green`
    - `󰋩` Images: `theme.pink`
    - `󰅇` Standard text: `theme.blue`
- **Center Divider**: 1px subtle glass boundary (`glassBorderSubtle` / `rgba(88, 91, 112, 0.38)`).
- **Right Column (Preview Pane, `~460px`)**:
  - **Header Bar**: Type badge pill (`TEXTO`, `LINK`, `CÓDIGO`, `IMAGEM`), real-time line/char counters, and action shortcut hint (`↵ Colar`).
  - **Preview Card (`rgba(24, 24, 37, 0.55)`, `radius: 12px`)**:
    - Multi-line text preserving raw indentation, formatting, and newlines up to 8,000 characters.
    - Rendered in `monoFontFamily` (`JetBrainsMono Nerd Font`) with selection enabled.
    - Image previews preserve proportional aspect-ratio (`Image.PreserveAspectFit`).
    - Smooth scrolling with mouse wheel (`WheelHandler`), thin scroll indicator, and keyboard navigation (`Shift+Up`/`Shift+Down`, `PageUp`/`PageDown`).
    - Scroll position automatically resets to the top when navigating between items.

---

## 9. Micro-Interactions & Animation Guidelines

Animations should be snappy, subtle, and tactile:

- **Button Press Feedback**: Scale transitions using `Easing.OutQuad` with durations between `80ms` and `120ms` (e.g., `scale: pressed ? 0.92 : 1.0`).
- **Color Fades**: Hover background transitions with `duration: 120ms` to `160ms`.
- **Opacity Transitions**: Expanding elements or dropdown drawers with `duration: 150ms` using `Easing.OutCubic`.
- **Shared Motion Tokens**: Transient surfaces use `Theme.motionFast`,
  `Theme.motionStandard`, `Theme.motionLayout`, and `Theme.motionEasing` so
  components share timing and easing while keeping interaction-specific motion.
- **Motion**: `MotionState.qml` exposes the shared `qmlAnimationsEnabled`
  policy through `Theme.qml`. Quickshell handles its visual transitions on
  every compositor; Hyprland handles its own window and workspace motion.
- **Rules**:
  - Never use spring physics or bounce animations that delay user interaction.
  - Never animate layout geometry that causes jitter in adjacent bar pills.
  - When closing a popup via Escape or focus loss, dismiss immediately without lingering state.

---

## 10. Empty & Fallback States

Components must degrade gracefully when data is unavailable:

- **No Media**: The bar pill hides completely; the popup closes cleanly.
- **No Bluetooth / Disconnected**: Compact pill showing `󰂲` with muted grey tone; popup lists available devices without oversized blank placeholders.
- **No System Updates**: `Sistema atualizado` in subtle grey footer text rather than an intrusive warning badge.
- **No Wi-Fi / Offline**: Reverts to offline glyph (`󰤭`) with neutral styling.

---

## 11. Checklist for New Components

Before introducing or modifying a component, verify that it complies with the guidelines:

- [ ] Does it use tokens from `Theme.qml` instead of raw color literals?
- [ ] If placed on the bar, does it strictly adhere to `height: 25px` and `radius: 6px`?
- [ ] Does it use `MouseArea` with `cursorShape: Qt.PointingHandCursor`?
- [ ] If it opens a popup, is the popup anchored correctly according to its cluster position?
- [ ] Does the popup close cleanly on `Escape` and outside clicks?
- [ ] Does it maintain high contrast against Catppuccin Mocha surfaces?
- [ ] Does it avoid cluttered sub-nesting ("card-inside-card")?
- [ ] Does it hide or remain understated when idle/empty?

---

## 12. Decisões estéticas do usuário (registradas 2026-09)

Preferências explícitas que valem como regra, acima do gosto padrão:

- **Escuro primeiro**: fundo escuro translúcido como padrão; modo claro só
  via variante chameleon gerada do wallpaper, nunca como padrão.
- **Sem blur, com opacidade**: labwc não tem blur — compensa com alfa alto
  (`backgroundAlpha` ≥ 0.92 no labwc, opacidade 0.93 no Ghostty) em vez de
  imitar vidro.
- **Acento por contexto, nunca enfeite**: teal do wallpaper no lugar de azul
  fixo quando o chameleon está ativo; destaque selecionado sempre sólido
  (nada de translúcido sobre translúcido).
- **Menos é mais nas listas**: sem seletores duplicados (uma via por ação);
  índice do spotlight enxuto (4 categorias); fileira inferior única que
  alterna entre modos e ações.
- **Teclado antes do mouse**: toda superfície nova precisa de navegação
  completa por teclado (setas + Enter + Esc) desde o primeiro commit.
- **Texto curto e sem corte**: subtítulos que trunquem com `…` devem ser
  reescritos, não apenas tolerados.
