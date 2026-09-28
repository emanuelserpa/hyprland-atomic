import QtQuick
import Quickshell
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target
    property var rootMenu: null
    property var currentMenu: rootMenu
    property bool canGoBack: currentMenu !== rootMenu

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 310
    implicitHeight: Math.min(460, menuContent.implicitHeight + 12)
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    onVisibleChanged: {

        if (visible) menuCard.forceActiveFocus()
    }

    function open(menu) {
        root.rootMenu = menu
        root.currentMenu = menu
        root.visible = menu !== null
    }

    function closeMenu() {
        root.visible = false
        root.currentMenu = root.rootMenu
    }

    QsMenuOpener {
        id: opener
        menu: root.currentMenu
    }

    Rectangle {
        id: menuCard
        anchors.fill: parent
        radius: 8
        color: root.theme.background
        border.width: 1
        border.color: root.theme.surfaceHover
        focus: true
        Keys.onEscapePressed: root.closeMenu()

        Flickable {
            id: menuFlick
            anchors.fill: parent
            anchors.margins: 6
            contentWidth: width
            contentHeight: menuContent.implicitHeight
            clip: true

            WheelKinetic { target: menuFlick }

            Column {
                id: menuContent
                width: parent.width
                spacing: 2

                Rectangle {
                    visible: root.canGoBack
                    width: parent.width
                    height: visible ? 30 : 0
                    radius: 5
                    color: backMouse.containsMouse
                           ? root.theme.cardBackgroundHover
                           : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: "  Voltar"
                        color: root.theme.isLight ? root.theme.foreground : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.currentMenu = root.rootMenu
                    }
                }

                Repeater {
                    model: opener.children

                    delegate: Item {
                        id: menuItem
                        required property var modelData

                        width: menuContent.width
                        height: modelData.isSeparator ? 7 : 30
                        visible: true

                        Rectangle {
                            visible: modelData.isSeparator
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            height: 1
                            color: root.theme.borderSubtle
                        }

                        Rectangle {
                            visible: !modelData.isSeparator
                            anchors.fill: parent
                            radius: 5
                            color: itemMouse.containsMouse
                                   ? root.theme.cardBackgroundHover
                                   : "transparent"
                            opacity: modelData.enabled ? 1.0 : 0.45

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Item {
                                    width: 18
                                    height: 22

                                    Image {
                                        anchors.centerIn: parent
                                        width: 15
                                        height: 15
                                        sourceSize.width: 15
                                        sourceSize.height: 15
                                        source: modelData.icon ?? ""
                                        visible: source.toString().length > 0
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: (modelData.icon ?? "").toString().length === 0
                                                 && modelData.buttonType !== 0
                                        text: modelData.checkState === Qt.Checked ? "✓" : ""
                                        color: root.theme.pink
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                    }
                                }

                                Text {
                                    width: parent.width - 44
                                    text: modelData.text ?? ""
                                    color: root.theme.foreground
                                    elide: Text.ElideRight
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: 10
                                    text: modelData.hasChildren ? "›" : ""
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.enabled

                                onClicked: {
                                    if (modelData.hasChildren) {
                                        root.currentMenu = modelData
                                    } else {
                                        modelData.triggered()
                                        root.closeMenu()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.closeMenu()
    }
}
