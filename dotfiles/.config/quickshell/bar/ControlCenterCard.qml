pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs
import qs.components
import qs.controlcenter
import qs.services

Rectangle {
    id: root

    required property var theme
    property bool active: false
    property int totalUpdates: 0

    signal openUpdatesRequested()
    signal closeRequested()
    signal networkActionRequested(var args)
    signal bluetoothActionRequested(var args)

    property var networkData: ({})
    property var bluetoothData: ({})

    readonly property bool hasSharedNetwork: Boolean(networkData && (networkData.status || networkData.ok !== undefined))
    readonly property bool hasSharedBluetooth: Boolean(bluetoothData && (bluetoothData.controller !== undefined || bluetoothData.ok !== undefined))

    readonly property var netInfo: hasSharedNetwork ? networkData : networkState.data
    readonly property var btInfo: hasSharedBluetooth ? bluetoothData : bluetoothState.data

    readonly property var sink: Pipewire.defaultAudioSink

    property int brightness: 0
    property int brightnessMax: 1
    property bool brightnessAvailable: false
    property bool brightnessChanging: false
    readonly property bool dnd: NotificationState.dnd
    readonly property var runningGames: gameState.data?.games ?? []
    readonly property bool gameActive: Boolean(gameState.data?.active)

    property real memUsedMb: 0
    property real memTotalMb: 0
    property int memPercent: 0
    property string uptimeStr: ""

    implicitWidth: 334
    implicitHeight: Math.max(406, contentColumn.childrenRect.height + 20)
    radius: root.theme.radiusXl

    color: root.theme.cardBackground
    border.width: 1
    border.color: root.theme.borderRegular

    // ==========================================
    // PROCESSOS & MONITORES
    // ==========================================

    Process {
        id: brightnessMaxProc
        command: ["brightnessctl", "m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = parseInt(this.text.trim())
                if (!isNaN(m) && m > 0) {
                    root.brightnessMax = m
                    root.brightnessAvailable = true
                    if (!brightnessGetProc.running)
                        brightnessGetProc.running = true
                }
            }
        }
    }

    Process {
        id: brightnessGetProc
        command: ["brightnessctl", "g"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cur = parseInt(this.text.trim())
                if (!isNaN(cur) && root.brightnessMax > 0 && !root.brightnessChanging) {
                    root.brightness = Math.round((cur / root.brightnessMax) * 100)
                    root.brightnessAvailable = true
                }
            }
        }
    }

    Process {
        id: brightnessSetProc
    }

    function setBrightness(percent) {
        root.brightness = percent
        root.brightnessChanging = true
        brightnessSetProc.command = ["brightnessctl", "s", percent + "%"]
        brightnessSetProc.running = true
        brightnessDebounce.restart()
    }

    Timer {
        id: brightnessDebounce
        interval: 300
        repeat: false
        onTriggered: root.brightnessChanging = false
    }

    CommandJson {
        id: networkState
        command: ["python3", Quickshell.shellDir + "/scripts/network-status.py"]
        interval: (root.active && !root.hasSharedNetwork) ? 4000 : 0
    }

    Process {
        id: networkActionProc
        onRunningChanged: {
            if (!running)
                networkRefreshDelay.restart()
        }
    }

    Timer {
        id: networkRefreshDelay
        interval: 600
        repeat: false
        onTriggered: networkState.refresh()
    }

    function networkAction(args) {
        networkActionProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/network-action.py"
        ].concat(args)
        networkActionProc.running = true
    }

    CommandJson {
        id: bluetoothState
        command: ["python3", Quickshell.shellDir + "/scripts/bluetooth-state.py"]
        interval: (root.active && !root.hasSharedBluetooth) ? 4000 : 0
    }

    CommandJson {
        id: gameState
        command: ["python3", Quickshell.shellDir + "/scripts/game-status.py"]
        autoStart: root.active
        interval: 5000
    }

    Process {
        id: bluetoothActionProc
        onRunningChanged: {
            if (!running)
                bluetoothRefreshDelay.restart()
        }
    }

    Timer {
        id: bluetoothRefreshDelay
        interval: 600
        repeat: false
        onTriggered: bluetoothState.refresh()
    }

    function bluetoothAction(args) {
        bluetoothActionProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/bluetooth-action.py"
        ].concat(args)
        bluetoothActionProc.running = true
    }


    Process {
        id: sysStatsProc
        command: ["bash", "-c", "free -m | awk 'NR==2{print $3\"|\"$2\"|\"int($3*100/$2)}'; uptime -p"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length >= 1) {
                    const parts = lines[0].split("|")
                    if (parts.length >= 3) {
                        root.memUsedMb = parseInt(parts[0]) || 0
                        root.memTotalMb = parseInt(parts[1]) || 0
                        root.memPercent = parseInt(parts[2]) || 0
                    }
                }
                if (lines.length >= 2) {
                    root.uptimeStr = lines[1].replace("up ", "")
                        .replace(/,\s*/g, " ")
                        .replace(/\s*days?/g, "d")
                        .replace(/\s*hours?/g, "h")
                        .replace(/\s*minutes?/g, "m")
                }
            }
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            if (!sysStatsProc.running)
                sysStatsProc.running = true
        }
    }

    onActiveChanged: {
        if (active) {
            gameState.refresh()
            if (!brightnessMaxProc.running)
                brightnessMaxProc.running = true
            if (!sysStatsProc.running)
                sysStatsProc.running = true
            if (!root.hasSharedNetwork)
                networkState.refresh()
            if (!root.hasSharedBluetooth)
                bluetoothState.refresh()
        }
    }

    // ==========================================
    // CONTEÚDO VISUAL
    // ==========================================
    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        // Cabeçalho: Título + Ações Rápidas
        Item {
            width: parent.width
            height: 22

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                Text {
                    text: "󰓃"
                    color: root.theme.cyan
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 15
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: mixerHover.hovered ? "Mixer (pwvucontrol)"
                          : termHover.hovered ? "Terminal (Kitty)"
                          : "Controles & Sistema"
                    color: mixerHover.hovered ? root.theme.cyan
                           : termHover.hovered ? root.theme.green
                           : root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: 24
                    height: 24
                    radius: root.theme.pillRadius
                    color: mixerHover.hovered
                           ? root.theme.cardBackgroundHover
                           : root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: mixerHover.hovered
                           ? root.theme.pillBorderHover
                           : root.theme.glassBorderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "󰕾"
                        color: root.theme.cyan
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler {
                        id: mixerHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            root.closeRequested()
                            Quickshell.execDetached(["pwvucontrol"])
                        }
                    }
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: root.theme.pillRadius
                    color: termHover.hovered
                           ? root.theme.cardBackgroundHover
                           : root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: termHover.hovered
                           ? root.theme.pillBorderHover
                           : root.theme.glassBorderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "󰆍"
                        color: root.theme.green
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler {
                        id: termHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            root.closeRequested()
                            Quickshell.execDetached(["kitty"])
                        }
                    }
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: root.theme.pillRadius
                    color: settingsHover.hovered
                           ? root.theme.cardBackgroundHover
                           : root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: settingsHover.hovered
                           ? root.theme.pillBorderHover
                           : root.theme.glassBorderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: root.theme.accent
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler {
                        id: settingsHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            root.closeRequested()
                            Quickshell.execDetached(["quickshell", "ipc", "call", "spotlight", "theme"])
                        }
                    }
                }
            }
        }

        // Sliders de Volume e Brilho
        Rectangle {
            width: parent.width
            height: 88
            radius: root.theme.radiusLg
            color: root.theme.cardBackgroundSubtle
            border.width: 1
            border.color: root.theme.glassBorderSubtle

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                SliderRow {
                    width: parent.width
                    theme: root.theme
                    icon: root.sink?.audio?.muted ? "󰖁" : "󰕾"
                    value: root.sink?.audio ? root.sink.audio.volume : 0
                    maximum: 1.5
                    valueText: root.sink?.audio
                               ? Math.round(root.sink.audio.volume * 100) + "%"
                               : "--%"
                    accent: root.theme.blue
                    available: Boolean(root.sink?.audio)
                    onValueRequested: function(val) {
                        if (root.sink?.audio)
                            root.sink.audio.volume = val
                    }
                }

                SliderRow {
                    width: parent.width
                    theme: root.theme
                    icon: "󰃠"
                    value: root.brightness
                    maximum: 100
                    valueText: root.brightnessAvailable
                               ? root.brightness + "%"
                               : "--%"
                    accent: root.theme.yellow
                    available: root.brightnessAvailable
                    onValueRequested: function(val) {
                        root.setBrightness(val)
                    }
                }
            }
        }

        // Six equal-sized controls in two columns.
        Grid {
            width: parent.width
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            QuickTile {
                width: (parent.width - 8) / 2
                height: 48
                theme: root.theme
                icon: root.netInfo?.active_ssid ? "" : "󰤯"
                title: "Wi‑Fi"
                subtitle: String(root.netInfo?.active_ssid ?? "")
                          || (Boolean(root.netInfo?.wifi_enabled)
                              ? "Disponível"
                              : "Desligado")
                active: Boolean(root.netInfo?.wifi_enabled)
                accent: root.theme.cyan
                onClicked: {
                    const action = Boolean(root.netInfo?.wifi_enabled) ? "wifi-off" : "wifi-on"
                    if (root.hasSharedNetwork) {
                        root.networkActionRequested([action])
                    } else {
                        root.networkAction([action])
                    }
                }
            }

            QuickTile {
                width: (parent.width - 8) / 2
                height: 48
                theme: root.theme
                icon: ""
                title: "Bluetooth"
                subtitle: Boolean(root.btInfo?.powered)
                          ? (Number(root.btInfo?.connected_count ?? 0) > 0
                             ? Number(root.btInfo?.connected_count ?? 0) + " disp."
                             : "Ligado")
                          : "Desligado"
                active: Boolean(root.btInfo?.powered)
                available: Boolean(root.btInfo?.available ?? true)
                accent: root.theme.blue
                onClicked: {
                    const action = Boolean(root.btInfo?.powered) ? "power-off" : "power-on"
                    if (root.hasSharedBluetooth) {
                        root.bluetoothActionRequested([action])
                    } else {
                        root.bluetoothAction([action])
                    }
                }
            }

            QuickTile {
                width: (parent.width - 8) / 2
                height: 48
                theme: root.theme
                icon: root.dnd ? "󰪓" : "󰂜"
                title: "Não Perturbe"
                subtitle: root.dnd ? "Silenciado" : "Normal"
                active: root.dnd
                accent: root.theme.red
                onClicked: NotificationState.toggleDnd()
            }

            QuickTile {
                width: (parent.width - 8) / 2
                height: 48
                theme: root.theme
                icon: IdleState.inhibited ? "󰅶" : "󰾪"
                title: "Inibir Bloqueio"
                subtitle: IdleState.inhibited ? "Ativo" : "Padrão"
                active: IdleState.inhibited
                accent: root.theme.orange
                onClicked: IdleState.inhibited = !IdleState.inhibited
            }

            QuickTile {
                width: (parent.width - 8) / 2
                height: 48
                theme: root.theme
                icon: NightLightState.enabled ? "󰛨" : "󰛩"
                title: "Luz Noturna"
                subtitle: NightLightState.enabled
                          ? (NightLightState.isNight ? "4000K" : "Dia")
                          : (NightLightState.sunset.length > 0 && NightLightState.sunset !== "--:--"
                             ? NightLightState.sunset : "Off")
                active: NightLightState.enabled
                accent: root.theme.yellow
                onClicked: NightLightState.toggle()
            }

            QuickTile {
                width: (parent.width - 8) / 2
                height: 48
                theme: root.theme
                icon: "󰊴"
                title: "Jogos"
                subtitle: root.gameActive
                          ? (root.runningGames.length > 1
                             ? root.runningGames.length + " jogos em execução"
                             : String(root.runningGames[0]?.name ?? "Em execução"))
                          : "Nenhum jogo ativo"
                active: root.gameActive
                accent: root.theme.green
                onClicked: Quickshell.execDetached(["steam"])
            }
        }

        // Hardware status: informational, with no tiny action buttons.
        Item {
            width: parent.width
            height: 42

            Column {
                anchors.fill: parent
                spacing: 4

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍛  Memória RAM"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.memUsedMb > 0
                              ? (root.memUsedMb / 1024).toFixed(1) + " / " + (root.memTotalMb / 1024).toFixed(1) + " GB (" + root.memPercent + "%)"
                              : "--"
                        color: root.theme.offWhite
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(69/255, 71/255, 90/255, 0.45)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.memPercent / 100))
                        height: parent.height
                        radius: parent.radius
                        color: root.memPercent > 85 ? root.theme.red : (root.memPercent > 65 ? root.theme.yellow : root.theme.blue)
                    }
                }

                Text {
                    text: "󰅐  Uptime  " + (root.uptimeStr.length > 0 ? root.uptimeStr : "Ativo")
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        // Session actions live with system controls instead of under the calendar.
        Row {
            width: parent.width
            height: 36
            spacing: 8

            Rectangle {
                width: (parent.width - parent.spacing) / 2
                height: parent.height
                radius: root.theme.radiusMd
                color: updateHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle
                border.width: 1
                border.color: updateHover.hovered ? root.theme.pillBorderHover : root.theme.glassBorderSubtle

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: "󰚰"
                            color: root.theme.pink
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Atualizações"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 19
                        width: Math.max(24, updateBadgeText.implicitWidth + 12)
                        radius: 10
                        color: root.totalUpdates > 0 ? Qt.rgba(245/255, 194/255, 231/255, 0.20) : Qt.rgba(166/255, 227/255, 161/255, 0.15)
                        border.width: 1
                        border.color: root.totalUpdates > 0 ? root.theme.pink : root.theme.green

                        Text {
                            id: updateBadgeText
                            anchors.centerIn: parent
                            text: root.totalUpdates > 0 ? ("" + root.totalUpdates) : "Em dia"
                            color: root.totalUpdates > 0 ? root.theme.pink : root.theme.green
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }
                }

                HoverHandler { id: updateHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.openUpdatesRequested() }
            }

            Rectangle {
                id: sessionButton
                width: (parent.width - parent.spacing) / 2
                height: parent.height
                radius: root.theme.radiusMd
                color: sessionHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle
                border.width: 1
                border.color: sessionHover.hovered ? root.theme.pillBorderHover : root.theme.glassBorderSubtle

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "󰐥"
                        color: root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Sessão"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: sessionHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: sessionActionsPopup.open() }
            }
        }
    }

    SessionActionsPopup {
        id: sessionActionsPopup
        theme: root.theme
        target: sessionButton
        ownerActive: root.active

        onActionRequested: function(action) {
            root.closeRequested()
            Quickshell.execDetached([Quickshell.shellDir + "/scripts/session-action.sh", action])
        }
    }
}
