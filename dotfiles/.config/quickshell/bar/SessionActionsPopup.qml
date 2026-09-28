import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var theme
    required property Item target
    property bool ownerActive: false
    property bool confirmationOnly: false
    property bool confirming: false
    property int selectedIndex: 0
    property int confirmIndex: 0
    property string pendingAction: ""

    signal actionRequested(string action)

    readonly property var actions: [
        { id: "lock", title: "Bloquear", icon: "󰌾", color: root.theme.blue, confirm: false },
        { id: "suspend", title: "Suspender", icon: "󰤄", color: root.theme.cyan, confirm: false },
        { id: "logout", title: "Encerrar sessão", icon: "󰗼", color: root.theme.yellow, confirm: true },
        { id: "reboot", title: "Reiniciar", icon: "󰜉", color: root.theme.orange, confirm: true },
        { id: "poweroff", title: "Desligar", icon: "󰐥", color: root.theme.red, confirm: true }
    ]

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 232
    implicitHeight: confirming ? 176 : 236
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    function open() {
        root.confirming = false
        root.selectedIndex = 0
        root.visible = true
    }

    function openConfirmation(action) {
        root.pendingAction = action
        root.confirmIndex = 0
        root.confirming = true
        root.visible = true
    }

    function cancelConfirmation() {
        root.confirming = false
        root.pendingAction = ""
        if (root.confirmationOnly)
            root.visible = false
    }

    function chooseAction(action) {
        if (action.confirm) {
            root.pendingAction = action.id
            root.confirmIndex = 0
            root.confirming = true
            return
        }
        root.actionRequested(action.id)
        root.visible = false
    }

    function confirmPendingAction() {
        root.actionRequested(root.pendingAction)
        root.pendingAction = ""
        root.confirming = false
        root.visible = false
    }

    function activateSelection() {
        if (!root.confirming) {
            root.chooseAction(root.actions[root.selectedIndex])
        } else if (root.confirmIndex === 0) {
            root.cancelConfirmation()
        } else {
            root.confirmPendingAction()
        }
    }

    onOwnerActiveChanged: {
        if (!ownerActive)
            root.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            menuCard.forceActiveFocus()
        } else {
            root.confirming = false
            root.pendingAction = ""
        }
    }

    Rectangle {
        id: menuCard
        anchors.fill: parent
        radius: root.theme.radiusLg
        color: root.theme.background
        border.width: 1
        border.color: root.theme.borderPopup
        focus: true

        Keys.onEscapePressed: {
            if (root.confirming) {
                root.cancelConfirmation()
            } else {
                root.visible = false
            }
        }
        Keys.onUpPressed: {
            if (root.confirming) {
                root.confirmIndex = 0
            } else {
                root.selectedIndex = (root.selectedIndex + root.actions.length - 1) % root.actions.length
            }
        }
        Keys.onDownPressed: {
            if (root.confirming) {
                root.confirmIndex = 1
            } else {
                root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
            }
        }
        Keys.onLeftPressed: if (root.confirming) root.confirmIndex = 0
        Keys.onRightPressed: if (root.confirming) root.confirmIndex = 1
        Keys.onReturnPressed: root.activateSelection()
        Keys.onEnterPressed: root.activateSelection()

        Column {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 5

            Text {
                width: parent.width
                height: 22
                text: root.confirming ? "Confirmar ação" : "Sessão"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                visible: !root.confirming
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.actions

                    delegate: Item {
                        required property int index
                        required property var modelData
                        width: parent.width
                        height: 34

                        Rectangle {
                            visible: index === 2
                            x: 4
                            y: -2
                            width: parent.width - 8
                            height: 1
                            color: root.theme.glassBorderSubtle
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: root.theme.radiusMd
                            color: root.selectedIndex === index
                                   ? root.theme.cardBackgroundActive
                                   : actionHover.hovered
                                     ? root.theme.cardBackgroundHover
                                     : "transparent"
                            border.width: root.selectedIndex === index ? 1 : 0
                            border.color: root.theme.pillBorderHover

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                spacing: 9

                                Text {
                                    width: 17
                                    height: parent.height
                                    text: modelData.icon
                                    color: modelData.color
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    width: parent.width - 26
                                    height: parent.height
                                    text: modelData.title
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            HoverHandler {
                                id: actionHover
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: if (hovered) root.selectedIndex = index
                            }

                            TapHandler {
                                onTapped: {
                                    root.selectedIndex = index
                                    root.chooseAction(modelData)
                                }
                            }
                        }
                    }
                }
            }

            Column {
                visible: root.confirming
                width: parent.width
                spacing: 9

                Text {
                    width: parent.width
                    height: 48
                    text: root.pendingAction === "logout"
                          ? "Você será desconectado e os aplicativos serão encerrados."
                          : root.pendingAction === "reboot"
                            ? "O computador será reiniciado."
                            : "O computador será desligado."
                    color: root.theme.offWhite
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    width: parent.width
                    height: 32
                    spacing: 8

                    Repeater {
                        model: [
                            { title: "Cancelar", destructive: false },
                            { title: "Confirmar", destructive: true }
                        ]

                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: (parent.width - 8) / 2
                            height: parent.height
                            radius: root.theme.radiusMd
                            color: root.confirmIndex === index
                                   ? (modelData.destructive ? root.theme.red : root.theme.cardBackgroundActive)
                                   : root.theme.cardBackgroundSubtle
                            border.width: 1
                            border.color: root.confirmIndex === index
                                          ? (modelData.destructive ? root.theme.red : root.theme.pillBorderHover)
                                          : root.theme.glassBorderSubtle

                            Text {
                                anchors.centerIn: parent
                                text: modelData.title
                                color: root.confirmIndex === index && modelData.destructive
                                       ? root.theme.backgroundOpaque
                                       : root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: if (hovered) root.confirmIndex = index
                            }
                            TapHandler {
                                onTapped: {
                                    root.confirmIndex = index
                                    root.activateSelection()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
