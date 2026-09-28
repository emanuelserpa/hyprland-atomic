import QtQuick
import qs.components

// Etapa 4 do fatiamento do Spotlight: painel de prévia do clipboard.
// Visual puro: recebe o resultado selecionado e o controlador, emite
// deleteRequested/pasteRequested. O Spotlight continua dono do layout
// geral e da seleção.
Item {
    id: root

    required property var palette
    property var result: null
    property var store: null
    property bool active: false
    property string displayedItemId: ""

    signal deleteRequested()
    signal pasteRequested()

    readonly property color launcherForeground: root.palette.foreground
    readonly property color launcherSecondary: root.palette.offWhite
    readonly property color launcherMuted: root.palette.grey
    readonly property color launcherBlue: root.palette.blue
    readonly property color launcherGreen: root.palette.green
    readonly property color launcherPink: root.palette.pink
    readonly property color launcherCyan: root.palette.cyan
    readonly property color launcherRed: root.palette.red

    visible: root.active

    onResultChanged: {
        const nextId = result && result.kind === "clipboard"
                       ? String(result.clipId ?? "") : ""
        if (displayedItemId !== nextId)
            previewFlickable.contentY = 0
        displayedItemId = nextId
    }

        // Preview Header
        Item {
            id: previewHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 28

            // Left: Badge & Info
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: headerActions.left
                anchors.rightMargin: 8
                spacing: 8
                clip: true

                // Badge
                Rectangle {
                    id: badgePill
                    anchors.verticalCenter: parent.verticalCenter
                    height: 20
                    width: badgeText.implicitWidth + 12
                    radius: 6
                    visible: root.result !== null && root.result.kind === "clipboard"

                    readonly property string cType: root.result ? String(root.result.clipType ?? "text") : "text"
                    readonly property string cIcon: root.result ? String(root.result.icon ?? "") : ""

                    color: cType === "image"
                           ? Qt.rgba(245/255, 194/255, 231/255, 0.16)
                           : (cIcon === "󰌷"
                              ? Qt.rgba(148/255, 226/255, 213/255, 0.16)
                              : (cIcon === "󰘐"
                                 ? Qt.rgba(166/255, 227/255, 161/255, 0.16)
                                 : Qt.rgba(137/255, 180/255, 250/255, 0.16)))

                    border.width: 1
                    border.color: cType === "image"
                                  ? Qt.rgba(245/255, 194/255, 231/255, 0.40)
                                  : (cIcon === "󰌷"
                                     ? Qt.rgba(148/255, 226/255, 213/255, 0.40)
                                     : (cIcon === "󰘐"
                                        ? Qt.rgba(166/255, 227/255, 161/255, 0.40)
                                        : Qt.rgba(137/255, 180/255, 250/255, 0.40)))

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: {
                            if (!root.result || root.result.kind !== "clipboard")
                                return ""
                            if (root.result.clipType === "image")
                                return "IMAGEM"
                            if (root.result.icon === "󰌷")
                                return "LINK"
                            if (root.result.icon === "󰘐")
                                return "CÓDIGO"
                            return "TEXTO"
                        }
                        color: {
                            if (!root.result || root.result.kind !== "clipboard")
                                return root.launcherSecondary
                            if (root.result.clipType === "image")
                                return root.launcherPink
                            if (root.result.icon === "󰌷")
                                return root.launcherCyan
                            if (root.result.icon === "󰘐")
                                return root.launcherGreen
                            return root.launcherBlue
                        }
                        font.family: root.palette.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Metadata (lines, chars)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.result !== null && root.result.kind === "clipboard"
                    text: {
                        if (!root.result) return ""
                        if (root.result.clipType === "image") {
                            return String(root.result.mime || "Imagem")
                        }
                        const lines = root.result.lineCount ?? 1
                        const chars = root.result.charCount ?? 0
                        return lines > 1
                            ? (lines + " linhas · " + chars + " caracteres")
                            : (chars + " caracteres")
                    }
                    color: root.launcherSecondary
                    opacity: 0.75
                    font.family: root.palette.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // Right: Action Buttons (Delete & Paste)
            Row {
                id: headerActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                visible: root.result !== null && root.result.kind === "clipboard"

                // Error text if any
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: store.restoreError.length > 0
                    text: store.restoreError
                    color: root.launcherRed
                    font.family: root.palette.fontFamily
                    font.pixelSize: 10
                }

                // Delete Hint / Clickable Action
                Text {
                    id: deleteHint
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰆴 Del"
                    color: deleteMouse.containsMouse ? root.launcherRed : root.launcherMuted
                    opacity: deleteMouse.containsMouse ? 1.0 : 0.45
                    font.family: root.palette.nerdFontFamily
                    font.pixelSize: 11

                    MouseArea {
                        id: deleteMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteRequested()
                    }
                }

                // Separator bullet
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "·"
                    color: root.launcherMuted
                    opacity: 0.35
                    font.family: root.palette.fontFamily
                    font.pixelSize: 11
                }

                // Paste Hint / Clickable Action
                Text {
                    id: pasteHint
                    anchors.verticalCenter: parent.verticalCenter
                    text: (store.restoreRunning || store.deleteRunning)
                          ? (store.restoreRunning ? "Restaurando…" : "Removendo…")
                          : "↵ Colar"
                    color: pasteMouse.containsMouse ? root.launcherBlue : root.launcherMuted
                    opacity: pasteMouse.containsMouse ? 1.0 : 0.65
                    font.family: root.palette.fontFamily
                    font.pixelSize: 11

                    MouseArea {
                        id: pasteMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pasteRequested()
                    }
                }
            }
        }

        // Preview Card Body
        Rectangle {
            id: previewBodyCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: previewHeader.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 4
            radius: 12
            color: Qt.rgba(24/255, 24/255, 37/255, 0.55)
            border.width: 1
            border.color: Qt.rgba(69/255, 71/255, 90/255, 0.35)
            clip: true

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: !root.result || root.result.kind !== "clipboard"
                text: "Nenhum item selecionado"
                color: root.launcherMuted
                font.family: root.palette.fontFamily
                font.pixelSize: 12
            }

            // Image Preview
            Image {
                id: previewImage
                anchors.fill: parent
                anchors.margins: 12
                visible: root.result !== null
                         && root.result.kind === "clipboard"
                         && root.result.clipType === "image"
                source: visible && root.result && root.result.thumbnail
                        ? root.result.thumbnail
                        : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                asynchronous: true
                sourceSize.width: 840
                sourceSize.height: 560
            }

            // Text Preview
            Flickable {
                id: previewFlickable
                anchors.fill: parent
                anchors.margins: 12
                visible: root.result !== null
                         && root.result.kind === "clipboard"
                         && root.result.clipType !== "image"
                contentWidth: width
                contentHeight: previewContent.paintedHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                function scrollWheel(event) {
                    wheelKinetic.handle(event)
                }

                WheelKinetic {
                    id: wheelKinetic
                    target: previewFlickable
                }

                TextEdit {
                    id: previewContent
                    width: previewFlickable.width
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    text: (root.result && root.result.fullText)
                          ? String(root.result.fullText)
                          : (root.result ? String(root.result.title ?? "") : "")
                    color: root.launcherForeground
                    font.family: root.palette.monoFontFamily
                    font.pixelSize: 11
                    selectionColor: Qt.rgba(137/255, 180/255, 250/255, 0.35)
                    selectedTextColor: root.palette.foreground

                    WheelHandler {
                        target: null
                        blocking: true
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            previewFlickable.scrollWheel(event)
                        }
                    }
                }
            }

            // Scroll track for long text
            ScrollBar {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                target: previewFlickable
                theme: root.palette
                wheelController: wheelKinetic
                thumbColor: root.launcherSecondary
                idleOpacity: 0.35
                hoverOpacity: 0.8
                rightInset: 2
            }

        }
    }
