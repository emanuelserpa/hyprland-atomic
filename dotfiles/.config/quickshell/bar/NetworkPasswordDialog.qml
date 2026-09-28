import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var theme
    required property Item target
    property string ssid: ""
    property string errorText: ""
    property bool busy: false
    property bool showPassword: false

    signal connectRequested(string ssid, string password)

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 340
    implicitHeight: 184
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true


    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.visible = false
    }

    function openFor(networkName) {
        ssid = networkName
        showPassword = false
        passwordField.text = ""
        visible = true
        passwordField.forceActiveFocus()
    }

    function submit() {
        if (busy || passwordField.text.length === 0) return
        const value = passwordField.text
        passwordField.text = ""
        showPassword = false
        connectRequested(ssid, value)
    }

    onVisibleChanged: {
        if (visible) passwordField.forceActiveFocus()
        else {
            passwordField.text = ""
            showPassword = false
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: root.theme.radiusPopup
        color: root.theme.background
        border.width: 1
        border.color: root.theme.borderPopup
        focus: true

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text {
                width: parent.width
                text: "Conectar ao Wi‑Fi"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Text {
                width: parent.width
                text: root.ssid
                color: root.theme.cyan
                font.family: root.theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: root.theme.radiusSm
                color: root.theme.surface
                border.width: 1
                border.color: passwordField.activeFocus ? root.theme.blue : root.theme.borderRegular

                TextInput {
                    id: passwordField
                    anchors.left: parent.left
                    anchors.right: eyeButton.left
                    anchors.leftMargin: 10
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 12
                    enabled: !root.busy
                    onAccepted: root.submit()
                }

                Text {
                    anchors.left: passwordField.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: passwordField.text.length === 0 && !passwordField.activeFocus
                    text: "Senha da rede"
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                }

                Item {
                    id: eyeButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 32

                    Text {
                        anchors.centerIn: parent
                        text: root.showPassword ? "󰈈" : "󰈉"
                        color: eyeHover.hovered ? root.theme.blue : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 14
                    }

                    HoverHandler { id: eyeHover }
                    TapHandler { onTapped: root.showPassword = !root.showPassword }
                }
            }

            Text {
                width: parent.width
                height: 18
                text: root.busy ? "Conectando…" : root.errorText
                color: root.busy ? root.theme.blue : root.theme.red
                font.family: root.theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 76
                    height: 28
                    radius: root.theme.radiusSm
                    color: cancelHover.hovered ? root.theme.surfaceHover : root.theme.surface
                    Text {
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: root.theme.offWhite
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                    HoverHandler { id: cancelHover }
                    TapHandler { onTapped: root.visible = false }
                }

                Rectangle {
                    width: 78
                    height: 28
                    radius: root.theme.radiusSm
                    opacity: root.busy ? 0.5 : 1
                    color: connectHover.hovered ? root.theme.cyan : root.theme.blue
                    Text {
                        anchors.centerIn: parent
                        text: "Conectar"
                        color: root.theme.backgroundOpaque
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    HoverHandler { id: connectHover }
                    TapHandler { enabled: !root.busy; onTapped: root.submit() }
                }
            }
        }
    }
}
