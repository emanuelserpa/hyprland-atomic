import QtQuick
import Quickshell
import qs.services

QtObject {
    id: root

    readonly property string currentTheme: ThemeState.currentTheme
    readonly property var palette: ThemeState.palette

    readonly property bool isLight: (palette.category ?? "dark") === "light"

    readonly property bool hyprlandSession: MotionState.hyprlandSession
    // Visual transitions stay in Quickshell across compositors.
    readonly property bool qmlAnimationsEnabled: MotionState.qmlAnimationsEnabled

    // labwc has no blur: translucent surfaces show the raw background.
    // Floor the base alpha there so the shell stays readable. Hyprland
    // caps surface alpha so blur remains visible across all shell popups.
    readonly property bool labwcSession: {
        if ((Quickshell.env("LABWC_PID") ?? "") !== "")
            return true
        const desktop = (Quickshell.env("XDG_CURRENT_DESKTOP") ?? "").toLowerCase()
        return desktop.split(":").includes("labwc")
    }
    readonly property real backgroundAlpha: {
        const base = palette.backgroundAlpha ?? (isLight ? 0.94 : 0.78)
        return root.labwcSession ? Math.min(1.0, Math.max(base, 0.92)) : Math.min(base, 0.75)
    }
    readonly property color backgroundOpaque: palette.backgroundOpaque ?? (isLight ? "#eff1f5" : "#1e1e2e")
    readonly property color background: Qt.rgba(backgroundOpaque.r, backgroundOpaque.g, backgroundOpaque.b, backgroundAlpha)
    readonly property color notificationBackground: background
    readonly property color surface: palette.surface ?? (isLight ? "#e6e9ef" : "#313244")
    readonly property color surfaceHover: palette.surfaceHover ?? (isLight ? "#dce0e8" : "#45475a")
    readonly property color foreground: palette.foreground ?? (isLight ? "#4c4f69" : "#cdd6f4")
    readonly property color offWhite: palette.offWhite ?? (isLight ? "#5c5f77" : "#bac2de")
    readonly property color grey: palette.grey ?? (isLight ? "#8c8fa1" : "#585b70")
    readonly property color red: palette.red ?? (isLight ? "#d20f39" : "#f38ba8")
    readonly property color green: palette.green ?? (isLight ? "#40a02b" : "#a6e3a1")
    readonly property color yellow: palette.yellow ?? (isLight ? "#df8e1d" : "#f9e2af")
    readonly property color blue: palette.blue ?? (isLight ? "#1e66f5" : "#89b4fa")
    readonly property color pink: palette.pink ?? (isLight ? "#ea76cb" : "#f5c2e7")
    readonly property color cyan: palette.cyan ?? (isLight ? "#179299" : "#94e2d5")
    readonly property color orange: palette.orange ?? (isLight ? "#fe640b" : "#fab387")
    readonly property color accent: palette.accent ?? blue
    readonly property color surfaceVariant: palette.surfaceVariant ?? surfaceHover
    readonly property color surfaceElevated: palette.surfaceElevated ?? (isLight ? "#ffffff" : surfaceHover)
    readonly property color surfaceSelected: palette.surfaceSelected ?? accent
    readonly property color border: palette.border ?? borderRegular
    readonly property color accentMuted: palette.accentMuted ?? Qt.rgba(accent.r, accent.g, accent.b, 0.25)
    readonly property color textMuted: palette.textMuted ?? grey
    readonly property color textDisabled: palette.textDisabled ?? Qt.rgba(grey.r, grey.g, grey.b, 0.50)

    // Material Design 3 / Material You Tokens
    readonly property color primary: palette.primary ?? accent
    readonly property color onPrimary: palette.onPrimary ?? (isLight ? "#ffffff" : backgroundOpaque)
    readonly property color primaryContainer: palette.primaryContainer ?? accentMuted
    readonly property color onPrimaryContainer: palette.onPrimaryContainer ?? foreground
    readonly property color surfaceContainer: palette.surfaceContainer ?? surface
    readonly property color surfaceContainerHigh: palette.surfaceContainerHigh ?? surfaceHover
    readonly property color onSurface: palette.onSurface ?? foreground
    readonly property color outline: palette.outline ?? border


    // Design Tokens - Radiuses
    readonly property int radiusSm: 6
    readonly property int radiusMd: 8
    readonly property int radiusLg: 10
    readonly property int radiusXl: 12
    readonly property int radiusPopup: 14

    // Shared motion tokens for transient surfaces and notification toasts.
    readonly property int motionFast: 120
    readonly property int motionStandard: 170
    readonly property int motionLayout: 180
    readonly property int motionEasing: Easing.OutCubic

    // Design Tokens - Surfaces & Cards
    readonly property color cardBackground: isLight
        ? Qt.rgba(1.0, 1.0, 1.0, 0.78)
        : (palette.surfaceElevated ? Qt.rgba(surfaceElevated.r, surfaceElevated.g, surfaceElevated.b, 0.70) : Qt.rgba(surface.r, surface.g, surface.b, 0.35))

    readonly property color cardBackgroundSubtle: isLight
        ? Qt.rgba(1.0, 1.0, 1.0, 0.50)
        : (palette.surface ? Qt.rgba(surface.r, surface.g, surface.b, 0.45) : Qt.rgba(surface.r, surface.g, surface.b, 0.22))

    readonly property color cardBackgroundHover: isLight
        ? Qt.rgba(1.0, 1.0, 1.0, 0.95)
        : (palette.surfaceHover ? Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.80) : Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.55))

    readonly property color cardBackgroundActive: isLight
        ? Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.70)
        : (palette.surfaceSelected ? Qt.rgba(surfaceSelected.r, surfaceSelected.g, surfaceSelected.b, 0.85) : Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.80))

    // Design Tokens - Borders & Glass Rims
    readonly property color borderSubtle: isLight
        ? Qt.rgba(grey.r, grey.g, grey.b, 0.22)
        : Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.30)

    readonly property color borderRegular: isLight
        ? Qt.rgba(grey.r, grey.g, grey.b, 0.32)
        : Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.45)

    readonly property color borderPopup: isLight
        ? Qt.rgba(grey.r, grey.g, grey.b, 0.40)
        : Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.72)

    readonly property color glassBorder: isLight
        ? Qt.rgba(grey.r, grey.g, grey.b, 0.22)
        : Qt.rgba(1.0, 1.0, 1.0, 0.12)

    readonly property color glassBorderSubtle: isLight
        ? Qt.rgba(grey.r, grey.g, grey.b, 0.14)
        : Qt.rgba(1.0, 1.0, 1.0, 0.08)

    // Design Tokens - Pills & Chips (harmonized with Media pill)
    readonly property int pillHeight: 25
    readonly property int pillRadius: 6

    readonly property color pillBackground: isLight
        ? Qt.rgba(1.0, 1.0, 1.0, 0.85)
        : Qt.rgba(surface.r, surface.g, surface.b, 0.50)

    readonly property color pillBackgroundHover: isLight
        ? Qt.rgba(1.0, 1.0, 1.0, 0.98)
        : Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.65)

    readonly property color pillBorder: isLight
        ? Qt.rgba(grey.r, grey.g, grey.b, 0.28)
        : Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0.35)

    readonly property color pillBorderHover: isLight
        ? Qt.rgba(grey.r, grey.g, grey.b, 0.50)
        : Qt.rgba(grey.r, grey.g, grey.b, 0.55)

    // Mixed text + icons: keep proportional spacing like the original Waybar.
    readonly property string fontFamily: "Noto Sans"
    readonly property string nerdFontFamily: "Noto Sans Nerd Font"
    // Pure icon labels can use the symbol font directly.
    readonly property string iconFontFamily: "Symbols Nerd Font"
    readonly property string monoFontFamily: "JetBrainsMono Nerd Font"

    readonly property int fontSize: 13
}
