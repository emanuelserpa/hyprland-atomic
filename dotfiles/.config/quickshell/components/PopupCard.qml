import QtQuick

// Single source of truth for popup surfaces: shared visuals (radius,
// background, border, focus) plus the unified enter animation (fade +
// scale from top). Visual output matches the previous per-popup cards;
// pass cardColor/frameColor/cardClip only where a popup differs.
Rectangle {
    id: root

    required property var theme
    property bool opened: false
    property color cardColor: theme.background
    property color frameColor: theme.borderPopup
    property bool cardClip: false

    clip: cardClip
    radius: theme.radiusPopup
    color: cardColor
    border.width: 1
    border.color: frameColor
    focus: true

    opacity: opened ? 1 : 0
    scale: opened ? 1 : 0.97
    transformOrigin: Item.Top

    Behavior on opacity { enabled: root.theme.qmlAnimationsEnabled; NumberAnimation { duration: root.theme.motionStandard; easing.type: root.theme.motionEasing } }
    Behavior on scale { enabled: root.theme.qmlAnimationsEnabled; NumberAnimation { duration: root.theme.motionStandard; easing.type: root.theme.motionEasing } }
}
