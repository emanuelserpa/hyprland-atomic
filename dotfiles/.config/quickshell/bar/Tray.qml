import QtQuick
import Quickshell.Services.SystemTray

Rectangle {
    id: root
    required property var theme
    required property var panelWindow

    implicitHeight: root.theme ? root.theme.pillHeight : 25
    implicitWidth: trayRow.implicitWidth + 14
    radius: root.theme ? root.theme.pillRadius : 6
    clip: true

    color: trayHover.hovered
           ? (root.theme ? root.theme.pillBackgroundHover : Qt.rgba(69/255, 71/255, 90/255, 0.65))
           : (root.theme ? root.theme.pillBackground : Qt.rgba(49/255, 50/255, 68/255, 0.50))

    border.width: 1
    border.color: trayHover.hovered
           ? (root.theme ? root.theme.pillBorderHover : Qt.rgba(88/255, 91/255, 112/255, 0.55))
           : (root.theme ? root.theme.pillBorder : Qt.rgba(69/255, 71/255, 90/255, 0.35))

    HoverHandler {
        id: trayHover
    }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            // Secret-agent / IME items stay running but are neither shown
            // nor icon-loaded here: an empty Image source keeps KIconLoader
            // away from nm-applet's animated theme icons, which caused a
            // past SIGSEGV (see ~/.cache/quickshell/crashes).
            model: SystemTray.items

            delegate: Item {
                id: trayDelegate
                required property var modelData

                readonly property bool shown: modelData.id !== "fcitx5"
                         && modelData.id !== "nm-applet"
                         && modelData.id !== "network-manager-applet"
                visible: shown
                width: shown ? 18 : 0
                height: root.theme ? root.theme.pillHeight : 25

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: shown ? modelData.icon : ""
                    sourceSize.width: 14
                    sourceSize.height: 14
                }

                TrayMenu {
                    id: trayMenu
                    theme: root.theme
                    target: trayDelegate
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                            return
                        }

                        if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                            modelData.activate()
                            return
                        }

                        if (modelData.hasMenu) {
                            if (trayMenu.visible) trayMenu.closeMenu()
                            else trayMenu.open(modelData.menu)
                        }
                        else if (mouse.button === Qt.LeftButton)
                            modelData.activate()
                    }

                    onWheel: function(wheel) {
                        modelData.scroll(
                            wheel.angleDelta.y !== 0
                                ? wheel.angleDelta.y
                                : wheel.angleDelta.x,
                            wheel.angleDelta.x !== 0
                        )
                    }
                }
            }
        }
    }
}
