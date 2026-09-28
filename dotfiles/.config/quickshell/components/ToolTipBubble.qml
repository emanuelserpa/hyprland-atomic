import QtQuick
import Quickshell

PopupWindow {
    id: root

    property var theme: null
    required property Item target
    property string text: ""
    property bool openLeft: false

    readonly property bool autoOpenLeft: {
        if (!target) return false
        try {
            var rootItem = target
            while (rootItem.parent) {
                rootItem = rootItem.parent
            }
            var pt = target.mapToItem(rootItem, 0, 0)
            return (pt.x + root.implicitWidth + 12) > rootItem.width
        } catch (e) {
            return false
        }
    }

    readonly property bool effectiveOpenLeft: root.openLeft || autoOpenLeft

    anchor.item: target
    anchor.edges: root.effectiveOpenLeft
                  ? (Edges.Bottom | Edges.Right)
                  : (Edges.Bottom | Edges.Left)
    anchor.gravity: root.effectiveOpenLeft
                    ? (Edges.Bottom | Edges.Left)
                    : (Edges.Bottom | Edges.Right)
    anchor.margins.top: 6

    implicitWidth: Math.min(340, body.implicitWidth + 18)
    implicitHeight: body.implicitHeight + 10
    color: "transparent"
    surfaceFormat.opaque: false

    Rectangle {
        anchors.fill: parent
        radius: 6

        color: root.theme
               ? Qt.rgba(root.theme.backgroundOpaque.r, root.theme.backgroundOpaque.g, root.theme.backgroundOpaque.b, 0.94)
               : Qt.rgba(24/255, 24/255, 37/255, 0.94)

        border.width: 1
        border.color: root.theme
                      ? root.theme.surfaceHover
                      : "#45475a"

        Text {
            id: body

            anchors.centerIn: parent
            width: Math.min(320, implicitWidth)

            text: root.text
            color: root.theme ? root.theme.foreground : "#cdd6f4"

            font.family: root.theme
                         ? root.theme.fontFamily
                         : "Noto Sans"
            font.pixelSize: 11
            font.weight: Font.Medium

            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.2
        }
    }
}
