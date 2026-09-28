import QtQuick
import Quickshell
import qs.components

PopupWindow {

    id: root

    required property var theme
    required property Item target

    property var bluetoothData: ({})
    property bool busy: false
    property string busyTarget: ""
    property string errorText: ""
    property string errorTarget: ""
    property bool isScanning: false

    signal openedChanged(bool opened)
    signal refreshRequested()
    signal powerToggleRequested(bool enabled)
    signal deviceConnectRequested(string mac)
    signal deviceDisconnectRequested(string mac)
    signal devicePairRequested(string mac)
    signal deviceRemoveRequested(string mac)
    signal settingsRequested()

    readonly property bool powered: Boolean(bluetoothData?.powered)
    readonly property bool available: bluetoothData?.available !== false
    readonly property var connectedDevices: bluetoothData?.connected ?? []
    readonly property var pairedDevices: bluetoothData?.paired_devices ?? []
    readonly property var discoveredDevices: bluetoothData?.discovered ?? []

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    readonly property real fixedHeaderHeight: 14 + 38 + 10 + 1 + 10 + 14 // 87px
    implicitWidth: 380
    implicitHeight: Math.min(540, fixedHeaderHeight + Math.min(420, scrollContent.implicitHeight))

    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    onVisibleChanged: {

        root.openedChanged(visible)
        if (visible) {
            card.forceActiveFocus()
        }
    }

    function iconFor(iconName, deviceName) {
        const icon = String(iconName ?? "").toLowerCase()
        const name = String(deviceName ?? "").toLowerCase()
        const full = icon + " " + name

        if (full.includes("headset") || full.includes("headphone") || full.includes("audio")
            || full.includes("earphone") || full.includes("earbuds") || full.includes("moondrop")
            || full.includes("airpods") || full.includes("buds") || full.includes("sound") || full.includes("speaker"))
            return "󰋋"
        if (full.includes("gamepad") || full.includes("gaming") || full.includes("controller")
            || full.includes("joystick") || full.includes("xbox") || full.includes("ps4")
            || full.includes("ps5") || full.includes("dualshock") || full.includes("dualsense"))
            return "󰊴"
        if (full.includes("keyboard") || full.includes("teclado") || full.includes("keychron"))
            return "󰌌"
        if (full.includes("mouse") || full.includes("trackpad") || full.includes("pointer"))
            return "󰍽"
        if (full.includes("phone") || full.includes("iphone") || full.includes("android")
            || full.includes("galaxy") || full.includes("pixel") || full.includes("smartphone"))
            return "󰏲"
        if (full.includes("computer") || full.includes("pc") || full.includes("laptop")
            || full.includes("desktop") || full.includes("macbook"))
            return "󰌢"
        if (full.includes("watch") || full.includes("relogio") || full.includes("band"))
            return "󰂥"

        return ""
    }

    function batteryIcon(percentage) {
        const p = Number(percentage)
        if (p >= 90) return "󰁹"
        if (p >= 70) return "󰂁"
        if (p >= 50) return "󰁿"
        if (p >= 30) return "󰁽"
        if (p >= 15) return "󰁻"
        return "󰁺"
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        cardClip: true

        Keys.onEscapePressed: root.visible = false

        // 1. Header Section: Icon Box + Titles + Action Buttons
        Item {
            id: headerSection
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            height: 38

            // Hero Icon Box
            Rectangle {
                id: iconBox
                width: 36
                height: 36
                radius: 8
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(49/255, 50/255, 68/255, 0.55)

                Text {
                    anchors.centerIn: parent
                    text: !root.powered ? "󰂲" : (root.connectedDevices.length > 0 ? "󰂱" : "󰂯")
                    color: !root.powered
                           ? root.theme.grey
                           : (root.connectedDevices.length > 0 ? root.theme.green : root.theme.cyan)
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 18
                }
            }

            // Middle Titles
            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: 10
                anchors.right: heroActions.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: "Bluetooth"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.busyTarget === "__power__"
                          ? "Aplicando alteração…"
                          : (root.errorTarget === "__power__" && root.errorText.length > 0
                             ? root.errorText
                             : (!root.available
                                ? "Bluetooth indisponível"
                                : (!root.powered
                                   ? "Desligado"
                                   : (root.connectedDevices.length > 0
                                      ? (String(root.connectedDevices[0].alias || root.connectedDevices[0].name) +
                                         (root.connectedDevices[0].battery >= 0 ? " • " + root.connectedDevices[0].battery + "%" : "") +
                                         (root.connectedDevices.length > 1 ? " (+" + (root.connectedDevices.length - 1) + ")" : ""))
                                      : (root.isScanning ? "Procurando dispositivos…" : "Pronto para conectar")))))
                    color: root.errorTarget === "__power__" && root.errorText.length > 0
                           ? root.theme.red
                           : (root.busyTarget === "__power__"
                              ? root.theme.blue
                              : (root.connectedDevices.length > 0
                                 ? root.theme.green
                                 : root.theme.grey))
                    font.family: root.theme.fontFamily
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            // Right Actions
            Row {
                id: heroActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Scan / Refresh Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    visible: root.powered
                    anchors.verticalCenter: parent.verticalCenter
                    color: scanHover.hovered || root.isScanning
                           ? Qt.rgba(137/255, 180/255, 250/255, 0.25)
                           : Qt.rgba(49/255, 50/255, 68/255, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: root.isScanning ? root.theme.blue : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: root.theme.qmlAnimationsEnabled && root.visible && root.powered && root.isScanning
                        }
                    }

                    HoverHandler { id: scanHover }
                    TapHandler {
                        enabled: !root.busy
                        onTapped: root.refreshRequested()
                    }
                }

                // Settings Gear Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: settingsHover.hovered
                           ? Qt.rgba(137/255, 180/255, 250/255, 0.25)
                           : Qt.rgba(49/255, 50/255, 68/255, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: settingsHover.hovered ? root.theme.blue : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 13
                    }

                    HoverHandler { id: settingsHover }
                    TapHandler {
                        onTapped: root.settingsRequested()
                    }
                }

                // Bluetooth Power Switch
                Rectangle {
                    width: 42
                    height: 22
                    radius: 11
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.powered
                           ? Qt.rgba(166/255, 227/255, 161/255, 0.22)
                           : Qt.rgba(88/255, 91/255, 112/255, 0.55)
                    border.width: 1
                    border.color: root.powered ? root.theme.green : root.theme.grey

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        y: 2
                        x: root.powered ? parent.width - width - 3 : 3
                        color: root.powered ? root.theme.green : root.theme.grey

                        Behavior on x {
                            enabled: root.theme.qmlAnimationsEnabled
                            NumberAnimation { duration: 120 }
                        }
                    }

                    TapHandler {
                        enabled: root.available && !root.busy
                        onTapped: root.powerToggleRequested(!root.powered)
                    }
                }
            }
        }

        // 2. Divider Line
        Rectangle {
            id: divider
            anchors.top: headerSection.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            height: 1
            color: Qt.rgba(88/255, 91/255, 112/255, 0.35)
        }

        // 3. Unified Scroll Area
        Flickable {
            id: scrollArea
            anchors.top: divider.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: scrollContent.implicitHeight

            WheelKinetic {
                target: scrollArea
            }

            Column {
                id: scrollContent
                width: parent.width
                spacing: 10

                // Estado Desligado
                Item {
                    visible: !root.powered
                    width: parent.width
                    height: 48

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰂲"
                            color: root.theme.grey
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Ligue o Bluetooth para conectar dispositivos"
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // 1. CONECTADOS SECTION
                Column {
                    visible: root.powered && root.connectedDevices.length > 0
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Conectados"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.connectedDevices

                            delegate: Rectangle {
                                id: connCard
                                required property var modelData

                                width: parent.width
                                height: 44
                                radius: 8
                                color: connHover.hovered
                                       ? Qt.rgba(166/255, 227/255, 161/255, 0.16)
                                       : Qt.rgba(166/255, 227/255, 161/255, 0.09)
                                border.width: 1
                                border.color: Qt.rgba(166/255, 227/255, 161/255, 0.28)

                                // Left Side: Icon + Name + Battery
                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: connAction.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 9

                                    Text {
                                        text: root.iconFor(modelData.icon, modelData.name)
                                        color: root.theme.green
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        width: parent.width - 25
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: String(modelData.alias || modelData.name)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Row {
                                            spacing: 5

                                            Text {
                                                readonly property string rowKey: "device:" + String(modelData.mac)
                                                text: root.busyTarget === rowKey
                                                      ? "Desconectando…"
                                                      : (root.errorTarget === rowKey && root.errorText.length > 0
                                                         ? root.errorText
                                                         : "Conectado")
                                                color: root.errorTarget === ("device:" + String(modelData.mac)) && root.errorText.length > 0
                                                       ? root.theme.red
                                                       : (root.busyTarget === ("device:" + String(modelData.mac)) ? root.theme.blue : root.theme.green)
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 8
                                            }

                                            Row {
                                                visible: Number(modelData.battery) >= 0
                                                spacing: 3
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    text: "•"
                                                    color: root.theme.grey
                                                    font.pixelSize: 8
                                                }

                                                Text {
                                                    text: root.batteryIcon(modelData.battery)
                                                    color: Number(modelData.battery) > 20 ? root.theme.green : root.theme.red
                                                    font.family: root.theme.nerdFontFamily
                                                    font.pixelSize: 9
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Text {
                                                    text: modelData.battery + "%"
                                                    color: root.theme.offWhite
                                                    font.family: root.theme.fontFamily
                                                    font.pixelSize: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }
                                }

                                // Right Side: Disconnect Button
                                Rectangle {
                                    id: connAction
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 72
                                    height: 24
                                    radius: 6
                                    color: discHover.hovered
                                           ? Qt.rgba(243/255, 139/255, 168/255, 0.25)
                                           : Qt.rgba(243/255, 139/255, 168/255, 0.12)
                                    border.width: 1
                                    border.color: Qt.rgba(243/255, 139/255, 168/255, 0.30)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Desconectar"
                                        color: root.theme.red
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }

                                    HoverHandler { id: discHover }
                                    TapHandler {
                                        onTapped: root.deviceDisconnectRequested(String(modelData.mac))
                                    }
                                }

                                HoverHandler { id: connHover }
                            }
                        }
                    }
                }

                // 2. MEUS DISPOSITIVOS (SALVOS) SECTION
                Column {
                    visible: root.powered && root.pairedDevices.length > 0
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Meus dispositivos"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.pairedDevices

                            delegate: Rectangle {
                                id: pairedCard
                                required property var modelData

                                width: parent.width
                                height: 42
                                radius: 8
                                color: pairedHover.hovered
                                       ? Qt.rgba(69/255, 71/255, 90/255, 0.45)
                                       : Qt.rgba(49/255, 50/255, 68/255, 0.32)
                                border.width: 1
                                border.color: pairedHover.hovered
                                              ? Qt.rgba(69/255, 71/255, 90/255, 0.35)
                                              : Qt.rgba(69/255, 71/255, 90/255, 0.15)

                                // Left Side: Icon + Name + Status
                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: pairedActions.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 9

                                    Text {
                                        text: root.iconFor(modelData.icon, modelData.name)
                                        color: root.theme.offWhite
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 15
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        width: parent.width - 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: String(modelData.alias || modelData.name)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            readonly property string rowKey: "device:" + String(modelData.mac)
                                            width: parent.width
                                            text: root.busyTarget === rowKey
                                                  ? "Conectando…"
                                                  : (root.errorTarget === rowKey && root.errorText.length > 0
                                                     ? root.errorText
                                                     : "Pareado")
                                            color: root.errorTarget === ("device:" + String(modelData.mac)) && root.errorText.length > 0
                                                   ? root.theme.red
                                                   : (root.busyTarget === ("device:" + String(modelData.mac)) ? root.theme.blue : root.theme.grey)
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Right Side: Connect + Remove (Trash)
                                Row {
                                    id: pairedActions
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 5

                                    Rectangle {
                                        width: 58
                                        height: 24
                                        radius: 6
                                        color: connBtnHover.hovered
                                               ? Qt.rgba(166/255, 227/255, 161/255, 0.25)
                                               : Qt.rgba(166/255, 227/255, 161/255, 0.12)
                                        border.width: 1
                                        border.color: Qt.rgba(166/255, 227/255, 161/255, 0.30)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Conectar"
                                            color: root.theme.green
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        HoverHandler { id: connBtnHover }
                                        TapHandler {
                                            onTapped: root.deviceConnectRequested(String(modelData.mac))
                                        }
                                    }

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 6
                                        color: forgetHover.hovered
                                               ? Qt.rgba(243/255, 139/255, 168/255, 0.25)
                                               : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            color: forgetHover.hovered ? root.theme.red : root.theme.grey
                                            font.family: root.theme.nerdFontFamily
                                            font.pixelSize: 11
                                        }

                                        HoverHandler { id: forgetHover }
                                        TapHandler {
                                            onTapped: root.deviceRemoveRequested(String(modelData.mac))
                                        }
                                    }
                                }

                                HoverHandler { id: pairedHover }
                            }
                        }
                    }
                }

                // 3. DISPOSITIVOS PRÓXIMOS SECTION
                Column {
                    visible: root.powered
                    width: parent.width
                    spacing: 5

                    Row {
                        width: parent.width
                        height: 18
                        spacing: 6

                        Text {
                            text: "Dispositivos próximos"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: root.isScanning
                            text: "• Buscando…"
                            color: root.theme.cyan
                            font.family: root.theme.fontFamily
                            font.pixelSize: 8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Mensagem de lista vazia
                    Item {
                        visible: root.discoveredDevices.length === 0
                        width: parent.width
                        height: 28

                        Text {
                            anchors.centerIn: parent
                            text: root.isScanning
                                  ? "Procurando dispositivos próximos…"
                                  : "Nenhum dispositivo novo encontrado."
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                        }
                    }

                    Column {
                        visible: root.discoveredDevices.length > 0
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.discoveredDevices

                            delegate: Rectangle {
                                id: discovCard
                                required property var modelData

                                width: parent.width
                                height: 40
                                radius: 8
                                color: discovHover.hovered
                                       ? Qt.rgba(69/255, 71/255, 90/255, 0.45)
                                       : Qt.rgba(49/255, 50/255, 68/255, 0.22)
                                border.width: 1
                                border.color: discovHover.hovered
                                              ? Qt.rgba(69/255, 71/255, 90/255, 0.30)
                                              : Qt.rgba(69/255, 71/255, 90/255, 0.12)

                                // Left Side: Icon + Name + Status
                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: discovAction.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 9

                                    Text {
                                        text: root.iconFor(modelData.icon, modelData.name)
                                        color: root.theme.cyan
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 15
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        width: parent.width - 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: String(modelData.alias || modelData.name)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            readonly property string rowKey: "device:" + String(modelData.mac)
                                            width: parent.width
                                            text: root.busyTarget === rowKey
                                                  ? "Pareando…"
                                                  : (root.errorTarget === rowKey && root.errorText.length > 0
                                                     ? root.errorText
                                                     : "Dispositivo próximo")
                                            color: root.errorTarget === ("device:" + String(modelData.mac)) && root.errorText.length > 0
                                                   ? root.theme.red
                                                   : (root.busyTarget === ("device:" + String(modelData.mac)) ? root.theme.blue : root.theme.grey)
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Right Side: Pair Button
                                Rectangle {
                                    id: discovAction
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 56
                                    height: 24
                                    radius: 6
                                    color: pairBtnHover.hovered
                                           ? Qt.rgba(166/255, 227/255, 161/255, 0.25)
                                           : Qt.rgba(166/255, 227/255, 161/255, 0.12)
                                    border.width: 1
                                    border.color: Qt.rgba(166/255, 227/255, 161/255, 0.30)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Text {
                                            text: "󰐕"
                                            color: root.theme.green
                                            font.family: root.theme.nerdFontFamily
                                            font.pixelSize: 9
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "Parear"
                                            color: root.theme.green
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    HoverHandler { id: pairBtnHover }
                                    TapHandler {
                                        onTapped: root.devicePairRequested(String(modelData.mac))
                                    }
                                }

                                HoverHandler { id: discovHover }
                            }
                        }
                    }
                }
            }
        }

        // 4. Sleek Vertical Scroll Indicator
        Rectangle {
            id: scrollIndicator
            anchors.right: parent.right
            anchors.rightMargin: 3
            y: scrollArea.y + (scrollArea.contentY / Math.max(1, scrollArea.contentHeight)) * scrollArea.height
            width: 3
            height: Math.max(20, (scrollArea.height / Math.max(1, scrollArea.contentHeight)) * scrollArea.height)
            radius: 1.5
            color: Qt.rgba(205/255, 214/255, 244/255, 0.35)
            visible: scrollArea.contentHeight > scrollArea.height
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
