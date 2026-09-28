import QtQuick
import Quickshell
import QtQuick.Dialogs
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property var phoneData: ({})
    property bool busy: false
    property string busyTarget: ""
    property string errorText: ""
    property string errorTarget: ""
    property string shareTargetId: ""
    property string shareDraft: ""

    signal refreshRequested()
    signal pingRequested(string deviceId)
    signal ringRequested(string deviceId)
    signal pairRequested(string deviceId)
    signal unpairRequested(string deviceId)
    signal shareTextRequested(string deviceId, string message)
    signal shareFileRequested(string deviceId, string path)
    signal settingsRequested()

    readonly property var devices: phoneData?.devices ?? []
    readonly property var reachable: devices.filter(function(d) { return Boolean(d.reachable) })
    readonly property var offline: devices.filter(function(d) { return !Boolean(d.reachable) })
    readonly property bool daemon: phoneData?.daemon !== false
    readonly property string shareTargetName: {
        for (let i = 0; i < devices.length; i++) {
            if (String(devices[i].id) === root.shareTargetId)
                return String(devices[i].name || devices[i].id)
        }
        return ""
    }

    function batteryIcon(p) {
        const v = Number(p)
        if (v < 0) return ""
        if (v >= 90) return "󰁹"
        if (v >= 70) return "󰂁"
        if (v >= 50) return "󰁿"
        if (v >= 30) return "󰁽"
        if (v >= 15) return "󰁻"
        return "󰁺"
    }

    function statusLine(d) {
        const key = "device:" + String(d.id)
        if (root.busyTarget === key)
            return "Aplicando…"
        if (root.errorTarget === key && root.errorText.length > 0)
            return root.errorText
        if (d.reachable && d.paired)
            return "Conectado"
        if (d.reachable && !d.paired)
            return "Aguardando pareamento"
        if (!d.reachable && d.paired)
            return "Pareado • offline"
        return "Encontrado"
    }

    function statusColor(d) {
        const key = "device:" + String(d.id)
        if (root.errorTarget === key && root.errorText.length > 0)
            return root.theme.red
        if (root.busyTarget === key)
            return root.theme.blue
        if (d.reachable && d.paired)
            return root.theme.green
        return root.theme.grey
    }

    function fileUrlToPath(url) {
        let s = String(url)
        if (s.startsWith("file://"))
            s = s.replace(/^file:\/\//, "")
        try {
            s = decodeURIComponent(s)
        } catch (e) {}
        return s
    }

    onDevicesChanged: {
        // Keep the share target valid; default to the first reachable device.
        let ok = false
        for (let i = 0; i < reachable.length; i++) {
            if (String(reachable[i].id) === root.shareTargetId) {
                ok = true
                break
            }
        }
        if (!ok)
            root.shareTargetId = reachable.length > 0 ? String(reachable[0].id) : ""
    }

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 380
    implicitHeight: Math.min(540, 87 + 12 + Math.min(330, scrollContent.implicitHeight) + (reachable.length > 0 ? 86 : 0))

    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
            refreshRequested()
        }
    }

    FileDialog {
        id: filePicker
        title: "Compartilhar arquivo com " + (root.shareTargetName.length > 0 ? root.shareTargetName : "o telefone")
        fileMode: FileDialog.OpenFile
        property string deviceId: ""
        onAccepted: {
            if (deviceId.length > 0 && selectedFile.toString().length > 0)
                root.shareFileRequested(deviceId, root.fileUrlToPath(selectedFile))
        }
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        cardClip: true

        Keys.onEscapePressed: root.visible = false

        Item {
            id: headerSection
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            height: 38

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
                    text: "󰏲"
                    color: root.reachable.length > 0 ? root.theme.green : root.theme.grey
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 18
                }
            }

            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: 10
                anchors.right: heroActions.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: "Telefone"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: !root.daemon ? "KDE Connect indisponível" : (root.devices.length === 0 ? "Nenhum aparelho" : (root.reachable.length > 0 ? root.reachable.length + " alcançável" : "Nenhum alcançável"))
                    color: root.reachable.length > 0 ? root.theme.green : root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            Row {
                id: heroActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: refreshHover.hovered ? Qt.rgba(137/255, 180/255, 250/255, 0.25) : Qt.rgba(49/255, 50/255, 68/255, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler { id: refreshHover }
                    TapHandler { onTapped: root.refreshRequested() }
                }

                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: settingsHover.hovered ? Qt.rgba(137/255, 180/255, 250/255, 0.25) : Qt.rgba(49/255, 50/255, 68/255, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: settingsHover.hovered ? root.theme.blue : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 13
                    }

                    HoverHandler { id: settingsHover }
                    TapHandler { onTapped: root.settingsRequested() }
                }
            }
        }

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

        Flickable {
            id: scrollArea
            anchors.top: divider.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: shareSection.top
            anchors.bottomMargin: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: scrollContent.implicitHeight

            WheelKinetic { target: scrollArea }

            Column {
                id: scrollContent
                width: parent.width
                spacing: 10

                Item {
                    visible: root.devices.length === 0
                    width: parent.width
                    height: 48

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.daemon ? "Pareie no app KDE Connect (mesma rede) e atualize." : "Instale o pacote kdeconnect e inicie o daemon."
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Column {
                    visible: root.reachable.length > 0
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Alcançáveis"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.reachable

                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 64
                                radius: 8
                                color: rowHover.hovered ? Qt.rgba(69/255, 71/255, 90/255, 0.45) : Qt.rgba(49/255, 50/255, 68/255, 0.32)
                                border.width: 1
                                border.color: Qt.rgba(69/255, 71/255, 90/255, 0.20)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.top: parent.top
                                    anchors.topMargin: 7
                                    spacing: 9

                                    Text {
                                        text: "󰏲"
                                        color: root.theme.green
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        width: parent.width - 32
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: String(modelData.name || modelData.id)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Row {
                                            spacing: 5

                                            Text {
                                                text: root.statusLine(modelData)
                                                color: root.statusColor(modelData)
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 8
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                visible: Number(modelData.battery) >= 0
                                                text: "• " + root.batteryIcon(modelData.battery) + " " + modelData.battery + "%"
                                                color: root.theme.offWhite
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 8
                                            }
                                        }
                                    }
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 6
                                    spacing: 5

                                    Rectangle {
                                        width: 56
                                        height: 22
                                        radius: 6
                                        color: pingHover.hovered ? Qt.rgba(137/255, 180/255, 250/255, 0.25) : Qt.rgba(137/255, 180/255, 250/255, 0.12)
                                        border.width: 1
                                        border.color: Qt.rgba(137/255, 180/255, 250/255, 0.30)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Ping"
                                            color: root.theme.blue
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        HoverHandler { id: pingHover }
                                        TapHandler { onTapped: root.pingRequested(String(modelData.id)) }
                                    }

                                    Rectangle {
                                        width: 62
                                        height: 22
                                        radius: 6
                                        color: ringHover.hovered ? Qt.rgba(166/255, 227/255, 161/255, 0.25) : Qt.rgba(166/255, 227/255, 161/255, 0.12)
                                        border.width: 1
                                        border.color: Qt.rgba(166/255, 227/255, 161/255, 0.30)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Tocar"
                                            color: root.theme.green
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        HoverHandler { id: ringHover }
                                        TapHandler { onTapped: root.ringRequested(String(modelData.id)) }
                                    }

                                    Rectangle {
                                        width: 62
                                        height: 22
                                        radius: 6
                                        color: fileHover.hovered ? Qt.rgba(69/255, 71/255, 90/255, 0.55) : Qt.rgba(69/255, 71/255, 90/255, 0.30)
                                        border.width: 1
                                        border.color: Qt.rgba(69/255, 71/255, 90/255, 0.30)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Arquivo"
                                            color: root.theme.offWhite
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        HoverHandler { id: fileHover }
                                        TapHandler {
                                            onTapped: {
                                                root.shareTargetId = String(modelData.id)
                                                filePicker.deviceId = String(modelData.id)
                                                filePicker.open()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: !Boolean(modelData.paired)
                                        width: 56
                                        height: 22
                                        radius: 6
                                        color: pairHover.hovered ? Qt.rgba(166/255, 227/255, 161/255, 0.25) : "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(166/255, 227/255, 161/255, 0.30)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Parear"
                                            color: root.theme.green
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        HoverHandler { id: pairHover }
                                        TapHandler { onTapped: root.pairRequested(String(modelData.id)) }
                                    }
                                }

                                HoverHandler { id: rowHover }
                            }
                        }
                    }
                }

                Column {
                    visible: root.offline.length > 0
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Offline"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.offline

                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 42
                                radius: 8
                                color: offHover.hovered ? Qt.rgba(69/255, 71/255, 90/255, 0.45) : Qt.rgba(49/255, 50/255, 68/255, 0.22)
                                border.width: 1
                                border.color: Qt.rgba(69/255, 71/255, 90/255, 0.15)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: offUnpair.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 9

                                    Text {
                                        text: "󰏲"
                                        color: root.theme.grey
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
                                            text: String(modelData.name || modelData.id)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: root.statusLine(modelData)
                                            color: root.statusColor(modelData)
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Rectangle {
                                    id: offUnpair
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 70
                                    height: 24
                                    radius: 6
                                    visible: Boolean(modelData.paired)
                                    color: offForgetHover.hovered ? Qt.rgba(243/255, 139/255, 168/255, 0.25) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Esquecer"
                                        color: root.theme.red
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }

                                    HoverHandler { id: offForgetHover }
                                    TapHandler { onTapped: root.unpairRequested(String(modelData.id)) }
                                }

                                HoverHandler { id: offHover }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: shareSection
            visible: root.reachable.length > 0
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            height: shareSection.visible ? 74 : 0

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Qt.rgba(88/255, 91/255, 112/255, 0.35)
            }

            Text {
                id: shareLabel
                anchors.top: parent.top
                anchors.topMargin: 8
                width: parent.width
                text: "Texto para " + (root.shareTargetName.length > 0 ? root.shareTargetName : "…")
                color: root.theme.grey
                font.family: root.theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Row {
                anchors.top: shareLabel.bottom
                anchors.topMargin: 6
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: 6

                Rectangle {
                    width: parent.width - 66
                    height: 30
                    radius: 6
                    color: Qt.rgba(49/255, 50/255, 68/255, 0.45)
                    border.width: 1
                    border.color: shareInput.activeFocus ? root.theme.blue : Qt.rgba(69/255, 71/255, 90/255, 0.35)

                    TextInput {
                        id: shareInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                        maximumLength: 4000
                        onTextChanged: root.shareDraft = text
                        Keys.onReturnPressed: {
                            if (text.trim().length > 0 && root.shareTargetId.length > 0) {
                                root.shareTextRequested(root.shareTargetId, text.trim())
                                text = ""
                            }
                        }
                    }

                    Text {
                        visible: shareInput.text.length === 0
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Digite e Enter…"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: 60
                    height: 30
                    radius: 6
                    color: sendHover.hovered ? Qt.rgba(137/255, 180/255, 250/255, 0.30) : Qt.rgba(137/255, 180/255, 250/255, 0.15)
                    border.width: 1
                    border.color: Qt.rgba(137/255, 180/255, 250/255, 0.35)

                    Text {
                        anchors.centerIn: parent
                        text: "Enviar"
                        color: root.theme.blue
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    HoverHandler { id: sendHover }
                    TapHandler {
                        onTapped: {
                            if (shareInput.text.trim().length > 0 && root.shareTargetId.length > 0) {
                                root.shareTextRequested(root.shareTargetId, shareInput.text.trim())
                                shareInput.text = ""
                            }
                        }
                    }
                }
            }
        }

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
