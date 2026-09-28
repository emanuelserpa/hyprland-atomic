# Visual Regression Checklist

This checklist establishes the visual contract for the Quickshell desktop shell. The user is sensitive to visual regressions (geometry, spacing, alignment, typography, and popup anchoring).

Before deploying or finalizing any structural or UI changes, verify each section against this checklist.

---

## 1. Top Bar Geometry & Alignment (`bar/Bar.qml`)

- [ ] **Bar Dimensions**: Height is exactly `37px` (`implicitHeight: 37`, `exclusiveZone: 37`).
- [ ] **Window Insets**: Screen margins are `3px`, with corner radius `9px` and subtle glass border (`palette.glassBorder`).
- [ ] **Component Clusters**:
  - **Left Cluster**: `Workspaces` -> `Submap` (visible only when Hyprland submap is active). Left margin `8px`, spacing `5px`.
  - **Center Cluster**: `Weather` -> `·` (dot separator) -> `Clock`. Centered horizontally on the bar. Spacing `7px`.
  - **Right Cluster**: `Tray` -> `Media` -> `Audio` -> `Network` -> `Bluetooth` -> `Battery` -> `ScreenRecording` -> `NotificationControl`. Right margin `8px`, spacing `4px`.
- [ ] **Invariant Ordering**: `Network` **must** remain after `Tray`. Do not swap cluster ordering.
- [ ] **Pill Metrics**: All pills have height `25px`, radius `6px` (`theme.pillRadius`), and vertical alignment centered within the 37px bar.

---

## 2. Central Dashboard Popup (`bar/CenterDashboardPopup.qml`)

- [ ] **Anchoring**: Centered directly below `centerCluster` with top margin `6px`.
- [ ] **Layout**: 3 distinct cards in a row without excessive card-in-card nesting:
  - **Column 1 — Weather & Cities (`WeatherCard.qml`)**:
    - Current temperature, condition icon, city name, high/low, hourly forecast strip, saved city drawer.
  - **Column 2 — Calendar & System (`CalendarCard.qml`)**:
    - Current month grid, active date highlight, CPU temperature pill, fan speed, package update badge.
  - **Column 3 — Quick Controls & Stats (`ControlCenterCard.qml`)**:
    - Volume slider, Brightness slider with interactive hover thumb.
    - 2×3 QuickTiles: Wi-Fi, Bluetooth, Não Perturbe (DND), Inibir Bloqueio (Idle inhibit), Luz Noturna (Solar / night light), Tema (Theme cycler).
    - Memory RAM progress bar and Uptime indicator.
    - System updates shortcut with status badge.
- [ ] **Responsive Scaling**:
  - Screen width >= 840px: 3 columns scale proportionally without scrollbars.
  - Screen width < 840px: Smooth horizontal scroll with page indicator dots (Clima / Calendário / Controles).
- [ ] **Dismissal**:
  - Pressing `Escape` closes the popup.
  - Clicking outside the popup closes it.
  - Clicking the center cluster again toggles it closed.

---

## 3. Spotlight Launcher & Clipboard Manager (`launcher/Spotlight.qml`)

- [ ] **Application Mode (`SUPER+D`)**:
  - Centered modal dialog with width `560px`.
  - Search input automatically focused on open.
  - Application items render icon + title + category description.
  - Keyboard navigation: `Up`/`Down` select items, `Enter` launches application, `Escape` dismisses.
- [ ] **Clipboard Mode (`SUPER+C` or `#`)**:
  - Smooth animation expanding modal to `820×500px` split-view.
  - **Left Pane (360px)**: Scrollable list of recent items, semantic type badges (`TEXTO`, `LINK`, `CÓDIGO`, `IMAGEM`).
  - **Right Pane**: Live preview pane with monospace font for text/code and aspect-ratio preserved thumbnails for images.
  - **Actions**: `Enter` copies to clipboard and pastes into active window; `Shift+Delete` or `Del` icon permanently deletes item without reappearing.

---

## 4. Hardware & Status Popups

### 4.1 Network (`bar/NetworkPopup.qml`)
- [ ] Anchored directly below Network pill.
- [ ] Active connection highlighted at the top (Wi-Fi SSID, IP, frequency 2.4/5GHz).
- [ ] Available Wi-Fi networks sorted by signal strength with 5-level icon (`󰤨`, `󰤥`, `󰤢`, `󰤟`, `󰤯`).
- [ ] Speedtest button runs inline test without freezing UI.
- [ ] Wi-Fi password prompt opens dedicated modal (`NetworkPasswordDialog.qml`) without leaking credentials into argv.
- [ ] Wi-Fi QR code button displays scan modal in high contrast.

### 4.2 Bluetooth (`bar/BluetoothPopup.qml`)
- [ ] Anchored below Bluetooth pill.
- [ ] Power switch toggles controller state with immediate feedback.
- [ ] Device sections: Connected devices (top, with battery percentage badge when available), Paired devices, Discovered nearby devices.
- [ ] Discovery spinner visible while scanning.

### 4.3 Audio (`bar/AudioPopup.qml`)
- [ ] Sinks (Output) and Sources (Input) separated into clean sections.
- [ ] Volume and microphone sliders responsive with percentage readouts, 18px expanded hit area, and hover thumb.
- [ ] Mute icons toggle audio mute state immediately.
- [ ] Device dropdown selectors allow switching default PipeWire nodes.

### 4.4 Media (`bar/MediaPopup.qml`)
- [ ] Opens on hover over the media pill without stealing focus; closes when mouse exits (unless clicked to pin open).
- [ ] Album artwork background blur rendered smoothly.
- [ ] Title and artist text truncated with ellipsis if exceeding container width.
- [ ] Seek progress bar advances smoothly during active playback (250ms interval), with play/pause and next/previous responsive.

### 4.5 Battery & Energy (`bar/BatteryPopup.qml`)
- [ ] Battery level percentage, charge status (charging/discharging), remaining time estimate.
- [ ] Energy profile selector (Economia, Balanceado, Performance) with active profile highlighted.

### 4.6 Printer (`bar/PrinterPopup.qml`)
- [ ] Only visible when CUPS destinations are configured and reachable.
- [ ] Shows queue job count, printer status (Pronta, Imprimindo, Parada), and cancel job action.

---

## 5. Notifications & OSD Overlays

- [ ] **Notification Toasts (`notifications/NotificationToasts.qml`)**:
  - Slide in smoothly at top-right with `12px` screen margins.
  - App icon, title, body, and action buttons properly padded.
  - Auto-dismisses after 5000ms; manual dismiss via `×` button.
  - Zero empty or ghost notifications (filtered by `NotificationState`).
- [ ] **Notification History (`bar/NotificationPopup.qml`)**:
  - Anchored below notification bell pill.
  - 4-item comfortable viewport with smooth mousewheel scroll.
  - "Limpar tudo" button and "Não Perturbe" toggle.
  - Empty state message ("Nenhuma notificação") when history is empty.
- [ ] **On-Screen Display (`osd/Osd.qml`)**:
  - Centered at the bottom of the screen.
  - Displays icon, progress bar, and value percentage for Volume, Microphone, and Brightness changes.
  - Auto-hides after 1500ms of inactivity.

---

## 6. Typography & Color Palette Standards

- [ ] **Font Families**:
  - Primary UI: `Noto Sans` (DemiBold for headings/pills, Regular for body).
  - Monospace & Code: `JetBrainsMono Nerd Font` (strictly for code previews, terminal commands, and system metrics).
  - Icons: `Noto Sans Nerd Font` or `JetBrainsMono Nerd Font` symbols.
- [ ] **Catppuccin Mocha Palette**:
  - Background: `rgba(30, 30, 46, 0.75)` with blur.
  - Foreground Text: `#cdd6f4` (high contrast, easy to read).
  - Secondary Text: `#bac2de` / `#585b70`.
  - Blue Accent: `#89b4fa`.
  - Green (Connected / Success): `#a6e3a1`.
  - Yellow / Orange (Warning): `#f9e2af` / `#fab387`.
  - Red (Error / Critical): `#f38ba8`.

---

## 7. Wayland Layer-Shell & Multi-Monitor

- [ ] Run `hyprctl layers` and verify:
  - Namespace `quickshell` is attached at Layer 2 (top).
  - Dimensions match monitor resolution width × 37px height (e.g. `0 0 1600 37`).
- [ ] On multi-monitor setups:
  - Top bar renders on each output.
  - Popups anchor to the bar instance on the screen where clicked.
  - Spotlight launcher appears centered on the currently focused screen.
