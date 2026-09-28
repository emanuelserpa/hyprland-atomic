# Notification System

## Overview

The notification subsystem is a native Quickshell implementation providing toast popups, a tracked-notification history panel, Do Not Disturb (DND) controls, and status bar integration. It replaces the earlier SwayNC integration.

---

## 1. Components & Architecture

The system is organized into modular QML components connected through a reactive singleton service:

- **`services/NotificationState.qml`**: Central state engine registered via `qs.services`.
  - Connects to Quickshell's native `NotificationServer`.
  - Exposes the server's tracked notifications in newest-first order; it does not implement a separate 50-item or disk-persisted history buffer.
  - Manages in-memory DND state and emits toast events when DND permits them. Critical notifications still emit toast events.
  - Performs HTML entity decoding and markup sanitization (`formatText`).
  - Resolves app icon names and image paths through the shared `resolveIcon` method.
  - Computes relative timestamps (`agora`, `2m`, `1h`, `2d`).
- **`notifications/NotificationToasts.qml`**: Floating HUD toast overlay.
  - Maintains up to three visible toasts; this is separate from notification history.
  - Toasts share the shell's motion tokens with popup surfaces: `motionStandard`
    for opacity, `motionLayout` for height collapse, and `motionFast` for border
    color. Toast entry and dismissal use a subtle fade/collapse without horizontal
    translation.
  - Rendered as a transparent `PanelWindow` anchored to `Edges.Top | Edges.Right`.
  - Configured with `surfaceFormat.opaque: false` for Hyprland background blur.
  - Receives only the toast events allowed by DND, with critical notifications exempted.
- **`bar/NotificationControl.qml`**: Status bar module.
  - Displays glyphs for notification and DND states (`󱅫`, `󰂠`, `󰪓`, `󰂜`).
  - Displays a red count of currently tracked notifications when any exist (`textColor: theme.red`).
  - Pill clicks: Left-click toggles popup history; the popup header holds the DND toggle.
- **`bar/NotificationPopup.qml`**: Detailed history and control panel.
  - Anchored to the bar pill with standard right-cluster geometry.
  - Implements the Unified Popup Behavior (`grabFocus: true`, pill toggle, Escape dismissal).
  - Clicking a notification's main content invokes its default/Open action when available; the close and action buttons keep their own behavior.
  - Uses the shared `ScrollBar.qml` for thumb tracking, track clicks, dragging,
    and wheel forwarding.

The toast overlay follows the same main-content click behavior. Notifications
without an action remain visible and do not launch an unrelated application.

---

## 2. Visual Theme & Consistency Contract

The notification subsystem strictly adheres to the desktop shell's Catppuccin Mocha glass design language:

| UI Element | Design Token / Value | Notes |
| :--- | :--- | :--- |
| **Popup Surface** | `theme.notificationBackground` (same as `theme.background`) | Notification surfaces share the global surface alpha; Hyprland caps it at 75%, while labwc keeps its readability floor because it has no blur. |
| **Outer Border** | `theme.glassBorder` (`rgba(255, 255, 255, 0.12)`) | Translucent glass perimeter rim |
| **Corner Radius** | `theme.radiusPopup` (`14px`) | Standard outer radius for all popups |
| **Notification Cards** | `theme.pillBackground` (`rgba(49, 50, 68, 0.50)`) | Unified with status bar pill background |
| **Card Borders** | `theme.pillBorder` (`rgba(69, 71, 90, 0.35)`) | 1px border matching resting pills |
| **Card Hover** | `theme.pillBackgroundHover` / `theme.pillBorderHover` | Responsive tactile feedback |
| **Action / DND Buttons**| `theme.pillRadius` (`6px`) | Unified interactive chip radius |
| **Compositor Blur** | `surfaceFormat.opaque: false` | Enables native Hyprland window blur |

---

## 3. Interaction & Windowing Behavior

### 3.1 Modal & Dismissal Rules
- **Outside-Click Dismissal**: The popup uses `grabFocus: true`. Clicking anywhere on the screen outside the popup automatically closes it.
- **Pill Click Toggle**: Left-clicking the notification pill on the bar triggers `popup.toggle()`, opening it if closed and closing it if open.
- **Keyboard Dismissal**: Pressing `Escape` immediately dismisses the popup via `Shortcut`.
- **Header Ergonomics**: The header contains **no** redundant `✕` close button. Header space is dedicated to the semantic title, live notification counter, DND toggle pill, and Clear All button.

### 3.2 Scrollbar & Geometry Guarantees
- The history list follows the shell's conventional scroll direction. Mouse wheel
  notches use direct position steps, without momentum that can reverse direction.
- **Conventional Wheel Direction**: Standard scrolling (`angleDelta.y > 0` scrolls up towards top/newest items; `< 0` scrolls down).
- **Proportional Thumb & Track**: Stationary track clicks and direct thumb dragging allow precise navigation.
- **Default Viewport Capacity**: Sized to fit 4 notification items comfortably without scrolling.
- **Last Item Guarantee**: The list view terminates with a dedicated `8px` bottom spacer and explicit parent-child `implicitHeight` sizing to ensure the last card is never clipped by the popup frame.

### 3.3 Text Sanitization & Entity Decoding
- Notification summaries and bodies are sanitized via `NotificationState.formatText()`:
  - HTML entities (`&quot;`, `&amp;`, `&lt;`, `&gt;`, `&#39;`, `&#x27;`, decimal/hex codes) are decoded to proper UTF-8 characters (e.g. quotes in Telegram messages).
  - `<br>` / `<br/>` tags are converted to real newline characters (`\n`).
  - Formatting tags (`<b>`, `<i>`, `<span>`, `<a>`, etc.) are stripped cleanly.
