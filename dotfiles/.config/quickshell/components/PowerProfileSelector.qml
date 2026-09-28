import QtQuick

Row {
    id: root

    property var theme: null
    property var profiles: []
    property string activeProfile: ""
    property bool available: true
    property bool busy: false

    signal profileRequested(string profileId)

    width: parent ? parent.width : 0
    spacing: 6

    readonly property var fallbackProfiles: [
        { id: "power-saver", label: "Economia" },
        { id: "balanced", label: "Balanceado" },
        { id: "performance", label: "Performance" }
    ]

    readonly property var effectiveProfiles:
        (profiles && profiles.length > 0) ? profiles : fallbackProfiles

    Repeater {
        model: root.effectiveProfiles

        delegate: Rectangle {
            id: btn
            required property var modelData

            readonly property bool selected:
                root.activeProfile === String(modelData.id ?? "")

            width: (root.width - (root.spacing * (root.effectiveProfiles.length - 1))) / Math.max(1, root.effectiveProfiles.length)
            height: 28
            radius: 7

            color: selected
                   ? Qt.rgba(137/255, 180/255, 250/255, 0.18)
                   : (profileHover.hovered
                      ? Qt.rgba(69/255, 71/255, 90/255, 0.52)
                      : Qt.rgba(49/255, 50/255, 68/255, 0.45))

            border.width: 1
            border.color: selected
                          ? (root.theme ? root.theme.blue : "#89b4fa")
                          : Qt.rgba(69/255, 71/255, 90/255, 0.48)

            opacity: root.available ? 1.0 : 0.48

            Text {
                anchors.centerIn: parent
                text: String(modelData.label ?? "")
                color: btn.selected
                       ? (root.theme ? root.theme.blue : "#89b4fa")
                       : (root.theme ? root.theme.offWhite : "#bac2de")
                font.family: root.theme ? root.theme.fontFamily : "Noto Sans"
                font.pixelSize: 9
                font.weight: btn.selected ? Font.DemiBold : Font.Medium
            }

            HoverHandler {
                id: profileHover
                cursorShape: root.available && !root.busy ? Qt.PointingHandCursor : Qt.ArrowCursor
            }

            TapHandler {
                enabled: root.available && !root.busy
                onTapped: root.profileRequested(String(modelData.id ?? ""))
            }
        }
    }
}
