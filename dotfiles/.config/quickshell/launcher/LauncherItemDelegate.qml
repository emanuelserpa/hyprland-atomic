import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: resultRow

    required property var modelData
    required property int index
    property int currentIndex: -1
    required property var palette
    property bool showProvider: false

    property color launcherForeground: palette.foreground
    property color launcherSecondary: palette.offWhite
    property color launcherMuted: palette.grey
    property color launcherPink: palette.pink
    property color launcherGreen: palette.green
    property color launcherCyan: palette.cyan
    property color launcherRed: palette.red
    property color launcherBlue: palette.blue

    signal activated(int index)

    readonly property bool imageClipboard:
        modelData.kind === "clipboard"
        && String(modelData.thumbnail ?? "").length > 0

    // Selected (non-clipboard) rows expand to show full wrapped text
    // instead of truncating; clipboard already has the preview pane.
    readonly property bool expanded: resultRow.currentIndex === resultRow.index
        && String(modelData.kind ?? "") !== "clipboard"
        && !resultRow.imageClipboard

    width: ListView.view ? ListView.view.width : (parent ? parent.width : 0)
    height: imageClipboard ? 66 : (resultRow.expanded ? Math.min(120, textCol.implicitHeight + 16) : 47)

    TapHandler {
        onTapped: resultRow.activated(resultRow.index)
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        spacing: 9

        Rectangle {
            id: leadingPreview
            width: resultRow.imageClipboard ? 96 : 36
            height: resultRow.imageClipboard ? 56 : 36
            anchors.verticalCenter: parent.verticalCenter
            radius: resultRow.imageClipboard ? 8 : 10

            color: resultRow.palette.isLight
                   ? Qt.rgba(resultRow.palette.surfaceHover.r, resultRow.palette.surfaceHover.g, resultRow.palette.surfaceHover.b, 0.70)
                   : Qt.rgba(resultRow.palette.surface.r, resultRow.palette.surface.g, resultRow.palette.surface.b, 0.52)
            border.width: 1
            border.color: resultRow.palette.borderSubtle
            clip: true

            Image {
                id: thumbPreview
                anchors.fill: parent
                anchors.margins: resultRow.imageClipboard ? 2 : 3
                visible: resultRow.imageClipboard
                source: visible ? String(resultRow.modelData.thumbnail) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                asynchronous: true
                sourceSize.width: 192
                sourceSize.height: 112
            }

            IconImage {
                id: rowIconImage
                anchors.centerIn: parent
                width: 28
                height: 28
                visible: !thumbPreview.visible && source.toString().length > 0
                source: (resultRow.modelData.kind === "app" || resultRow.modelData.kind === "window")
                        && String(resultRow.modelData.icon ?? "").length > 0
                        ? Quickshell.iconPath(resultRow.modelData.icon, true)
                        : ""
            }

            Text {
                anchors.centerIn: parent
                visible: !thumbPreview.visible && !rowIconImage.visible
                text: resultRow.modelData.kind === "window"
                      ? "󰖯"
                      : String(resultRow.modelData.icon ?? "")
                color: resultRow.modelData.color
                       ? resultRow.modelData.color
                       : (resultRow.modelData.kind === "calc"
                          ? resultRow.launcherPink
                          : (resultRow.modelData.kind === "command"
                             ? resultRow.launcherGreen
                             : (resultRow.modelData.kind === "window"
                                ? resultRow.launcherCyan
                                : (resultRow.modelData.kind === "kill"
                                   ? resultRow.launcherRed
                                   : (resultRow.modelData.kind === "theme_select" || resultRow.modelData.kind === "theme_cycle"
                                      ? (resultRow.modelData.accent ?? resultRow.palette.yellow)
                                      : (resultRow.modelData.kind === "clipboard"
                                      ? (resultRow.modelData.icon === "󰌷"
                                         ? resultRow.launcherCyan
                                         : (resultRow.modelData.icon === "󰘐"
                                            ? resultRow.launcherGreen
                                            : (resultRow.modelData.icon === "󰋩"
                                               ? resultRow.launcherPink
                                               : resultRow.launcherBlue)))
                                      : resultRow.launcherBlue))))))
                font.family: resultRow.palette.nerdFontFamily
                font.pixelSize: 17
            }
        }

        Column {
            id: textCol
            width: parent.width - leadingPreview.width - 67
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: String(resultRow.modelData.title ?? "")
                textFormat: Text.PlainText
                color: resultRow.launcherForeground
                opacity: 1.0
                font.family: resultRow.palette.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                wrapMode: resultRow.expanded ? Text.Wrap : Text.NoWrap
                maximumLineCount: resultRow.expanded ? 4 : 1
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: (resultRow.showProvider
                       ? String(resultRow.modelData.section ?? "") + " · " : "")
                      + String(resultRow.modelData.subtitle ?? "")
                textFormat: Text.PlainText
                color: resultRow.launcherSecondary
                opacity: 0.76
                font.family: resultRow.palette.fontFamily
                font.pixelSize: 10
                wrapMode: resultRow.expanded ? Text.Wrap : Text.NoWrap
                maximumLineCount: resultRow.expanded ? 3 : 1
                elide: Text.ElideRight
            }
        }

        Text {
            width: 42
            anchors.verticalCenter: parent.verticalCenter

            text: resultRow.currentIndex === resultRow.index
                  ? "↵"
                  : ""

            color: resultRow.launcherMuted
            font.family: resultRow.palette.fontFamily
            font.pixelSize: 15
            horizontalAlignment: Text.AlignRight
        }
    }
}
