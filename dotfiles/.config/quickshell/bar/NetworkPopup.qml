import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target
    property var networkData: ({})
    property string errorText: ""
    property string errorTarget: ""
    property bool busy: false
    property string busyTarget: ""

    property var qrData: null
    property bool showQr: false
    property bool showQrPassword: false

    // Speedtest state
    property bool showSpeedTest: false
    property bool speedTestRunning: speedTestProc.running
    property string speedTestPhase: "" // "ping" | "download" | "upload" | "done" | "error"
    property real speedTestDown: 0
    property real speedTestUp: 0
    property real speedTestPing: 0
    property real speedTestProgress: 0
    property string speedTestError: ""

    property real prevRx: 0
    property real prevTx: 0
    property real prevTime: 0
    property real downSpeed: 0
    property real upSpeed: 0

    signal refreshRequested()
    signal wifiToggleRequested(bool enabled)
    signal disconnectRequested(string device)
    signal connectRequested(string ssid, string uuid, bool saved, bool secure)
    signal passwordPromptRequested(string ssid)
    signal vpnToggleRequested(string uuid, bool active)
    signal settingsRequested()
    signal qrRequested()
    signal copyRequested(string text)
    signal openPortalRequested()

    readonly property var networks: networkData?.networks ?? []
    readonly property var vpns: networkData?.vpns ?? []
    readonly property bool wifiEnabled: Boolean(networkData?.wifi_enabled)
    readonly property string activeSsid: String(networkData?.active_ssid ?? "")
    readonly property string activeDevice: String(networkData?.active_device ?? "")

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 380
    implicitHeight: Math.min(660, 160 + (showQr ? 112 : 0) + (showSpeedTest ? 112 : 0) + (Boolean(networkData?.portal) ? 36 : 0) + (telemetryStrip.visible ? 34 : 0) + wifiAreaHeight + vpnAreaHeight)
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    function toggle() {

        root.visible = !root.visible
    }

    onVisibleChanged: {
        if (!visible) {
            showQr = false
            showSpeedTest = false
            stopSpeedTest()
        } else {
            pingState.refresh()
            card.forceActiveFocus()
        }
    }

    onShowQrChanged: showQrPassword = false

    function startSpeedTest() {
        speedTestError = ""
        speedTestDown = 0
        speedTestUp = 0
        speedTestPing = 0
        speedTestProgress = 0
        speedTestPhase = "ping"
        speedTestProc.running = false
        speedTestProc.running = true
    }

    function stopSpeedTest() {
        speedTestProc.running = false
        if (speedTestPhase !== "done") {
            speedTestPhase = ""
        }
    }

    Process {
        id: speedTestProc
        command: ["python3", Quickshell.shellDir + "/scripts/network-speedtest.py"]
        running: false

        stdout: SplitParser {
            onRead: function(line) {
                try {
                    const msg = JSON.parse(line.trim())
                    if (msg.error) {
                        root.speedTestError = msg.error
                        root.speedTestPhase = "error"
                        return
                    }
                    root.speedTestPhase = msg.phase || ""
                    if (msg.download_mbps > 0) root.speedTestDown = msg.download_mbps
                    if (msg.upload_mbps > 0) root.speedTestUp = msg.upload_mbps
                    if (msg.ping_ms > 0) root.speedTestPing = msg.ping_ms
                    if (msg.progress !== undefined) root.speedTestProgress = msg.progress
                } catch (e) {}
            }
        }

        onRunningChanged: {
            if (!running && root.speedTestPhase !== "done" && root.speedTestPhase !== "error") {
                root.speedTestPhase = ""
            }
        }
    }

    CommandJson {
        id: pingState
        command: ["bash", Quickshell.shellDir + "/scripts/network-ping.sh"]
        interval: (root.visible && !root.speedTestRunning) ? 3500 : 0
        autoStart: false
    }

    readonly property int pingMs: Number(pingState.data?.ping ?? -1)

    function formatSpeed(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0) return "0 B/s"
        if (bytesPerSec >= 1048576) return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        if (bytesPerSec >= 1024) return (bytesPerSec / 1024).toFixed(0) + " KB/s"
        return Math.round(bytesPerSec) + " B/s"
    }

    onNetworkDataChanged: {
        const rx = Number(networkData?.rx_bytes ?? 0)
        const tx = Number(networkData?.tx_bytes ?? 0)
        const now = Date.now()

        if (prevTime > 0 && rx >= prevRx && tx >= prevTx) {
            const dt = (now - prevTime) / 1000
            if (dt >= 0.5) {
                downSpeed = (rx - prevRx) / dt
                upSpeed = (tx - prevTx) / dt
            }
        }
        prevRx = rx
        prevTx = tx
        prevTime = now
    }

    readonly property real wifiAreaHeight: wifiEnabled
        ? Math.max(48, Math.min(260, wifiList.implicitHeight))
        : 48
    readonly property real vpnAreaHeight: Math.max(46, Math.min(140, vpnList.implicitHeight))

    function wifiIcon(signal) {
        const s = Number(signal)
        if (s >= 80) return "󰤨"
        if (s >= 60) return "󰤥"
        if (s >= 40) return "󰤢"
        if (s >= 20) return "󰤟"
        return "󰤯"
    }

    readonly property string heroIcon: {
        if (networkData?.active_type === "ethernet") return "󰈀"
        if (networkData?.active_type === "wifi") return wifiIcon(networkData?.active_signal ?? 0)
        if (!wifiEnabled) return "󰤭"
        return "󰤮"
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        frameColor: root.theme.glassBorder

        Keys.onEscapePressed: root.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 9

            // Hero Header: Icon + Titles + Action Buttons
            Item {
                id: headerSection
                width: parent.width
                height: 38

                // Left: Hero Icon Box
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
                        text: root.heroIcon
                        color: networkData?.active_type === "ethernet" || root.activeSsid.length > 0
                               ? root.theme.cyan
                               : (!root.wifiEnabled ? root.theme.red : root.theme.grey)
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 18
                    }
                }

                // Right: Actions (Speedtest, QR Code, Settings, Wi-Fi Switch)
                Row {
                    id: heroActions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    // Speedtest Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 6
                        visible: root.activeSsid.length > 0 || networkData?.active_type === "ethernet"
                        anchors.verticalCenter: parent.verticalCenter
                        color: speedTestHover.hovered || root.showSpeedTest
                               ? Qt.rgba(137/255, 180/255, 250/255, 0.25)
                               : Qt.rgba(49/255, 50/255, 68/255, 0.40)

                        Text {
                            anchors.centerIn: parent
                            text: "󰓅"
                            color: root.showSpeedTest ? root.theme.blue : root.theme.offWhite
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 13
                        }

                        HoverHandler { id: speedTestHover }
                        TapHandler {
                            onTapped: {
                                root.showSpeedTest = !root.showSpeedTest
                                if (root.showSpeedTest) {
                                    root.showQr = false
                                    if (!root.speedTestRunning && root.speedTestPhase !== "done") {
                                        root.startSpeedTest()
                                    }
                                }
                            }
                        }
                    }

                    // QR Code Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 6
                        visible: root.activeSsid.length > 0 && networkData?.active_type === "wifi"
                        anchors.verticalCenter: parent.verticalCenter
                        color: qrHover.hovered || root.showQr
                               ? Qt.rgba(137/255, 180/255, 250/255, 0.25)
                               : Qt.rgba(49/255, 50/255, 68/255, 0.40)

                        Text {
                            anchors.centerIn: parent
                            text: "󰄡"
                            color: root.showQr ? root.theme.blue : root.theme.offWhite
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 13
                        }

                        HoverHandler { id: qrHover }
                        TapHandler {
                            onTapped: {
                                if (root.showQr) {
                                    root.showQr = false
                                } else {
                                    root.showSpeedTest = false
                                    root.qrRequested()
                                }
                            }
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

                    // Wi-Fi Switch
                    Rectangle {
                        width: 42
                        height: 22
                        radius: 11
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.wifiEnabled
                               ? Qt.rgba(166/255, 227/255, 161/255, 0.22)
                               : Qt.rgba(88/255, 91/255, 112/255, 0.55)
                        border.width: 1
                        border.color: root.wifiEnabled ? root.theme.green : root.theme.grey

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: root.wifiEnabled ? parent.width - width - 3 : 3
                            color: root.wifiEnabled ? root.theme.green : root.theme.grey

                            Behavior on x {
                                enabled: root.theme.qmlAnimationsEnabled
                                NumberAnimation { duration: 120 }
                            }
                        }

                        TapHandler {
                            onTapped: root.wifiToggleRequested(!root.wifiEnabled)
                        }
                    }
                }

                // Middle: Network Title & Subtitle (fills available space!)
                Column {
                    anchors.left: iconBox.right
                    anchors.leftMargin: 10
                    anchors.right: heroActions.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.activeSsid.length > 0
                              ? root.activeSsid
                              : (networkData?.active_type === "ethernet" ? "Ethernet" : "Sem conexão")
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.busyTarget === "__wifi__"
                              ? "Aplicando alteração…"
                              : (root.errorTarget === "__wifi__" && root.errorText.length > 0
                                 ? root.errorText
                                 : (!root.wifiEnabled
                                    ? "Wi‑Fi desligado"
                                    : (root.activeSsid.length > 0 || networkData?.active_type === "ethernet"
                                       ? ((networkData?.active_freq ? networkData.active_freq + "  •  " : "") +
                                          (networkData?.active_ip ? networkData.active_ip : "Conectado"))
                                       : "Nenhuma rede conectada")))
                        color: root.errorTarget === "__wifi__" && root.errorText.length > 0
                               ? root.theme.red
                               : (root.busyTarget === "__wifi__"
                                  ? root.theme.blue
                                  : (root.activeSsid.length > 0 || networkData?.active_type === "ethernet"
                                     ? root.theme.grey
                                     : root.theme.grey))
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }
            }

            // Captive Portal Alert Banner
            Rectangle {
                id: portalBanner
                width: parent.width
                height: 30
                radius: 6
                visible: Boolean(networkData?.portal)
                color: Qt.rgba(249/255, 226/255, 175/255, 0.15)
                border.width: 1
                border.color: root.theme.yellow

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "󰌾"
                        color: root.theme.yellow
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width - 80
                        text: "Rede requer login no navegador"
                        color: root.theme.yellow
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 50
                        height: 20
                        radius: 4
                        color: root.theme.yellow
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "Entrar"
                            color: root.theme.background
                            font.family: root.theme.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                        }

                        TapHandler {
                            onTapped: root.openPortalRequested()
                        }
                    }
                }
            }

            // Real-time Telemetry Card (Ping + Download + Upload)
            Rectangle {
                id: telemetryStrip
                width: parent.width
                height: 28
                radius: 7
                visible: root.activeSsid.length > 0 || networkData?.active_type === "ethernet"
                color: Qt.rgba(49/255, 50/255, 68/255, 0.32)
                border.width: 1
                border.color: Qt.rgba(69/255, 71/255, 90/255, 0.30)

                Row {
                    anchors.fill: parent

                    // Ping
                    Item {
                        width: (parent.width - 2) / 3
                        height: parent.height

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "󰓅"
                                color: root.pingMs < 0 ? root.theme.red : (root.pingMs < 60 ? root.theme.green : root.theme.yellow)
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.pingMs >= 0 ? (root.pingMs + " ms") : "Offline"
                                color: root.pingMs < 0 ? root.theme.red : (root.pingMs < 60 ? root.theme.green : root.theme.yellow)
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: 1
                        height: 14
                        color: Qt.rgba(88/255, 91/255, 112/255, 0.35)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Download
                    Item {
                        width: (parent.width - 2) / 3
                        height: parent.height

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "󰇚"
                                color: root.theme.blue
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.formatSpeed(root.downSpeed)
                                color: root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: 1
                        height: 14
                        color: Qt.rgba(88/255, 91/255, 112/255, 0.35)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Upload
                    Item {
                        width: (parent.width - 2) / 3
                        height: parent.height

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "󰕒"
                                color: root.theme.cyan
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.formatSpeed(root.upSpeed)
                                color: root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // Speedtest Card
            Rectangle {
                id: speedTestCard
                visible: root.showSpeedTest
                width: parent.width
                height: visible ? 104 : 0
                radius: 8
                color: Qt.rgba(30/255, 30/255, 46/255, 0.70)
                border.width: 1
                border.color: Qt.rgba(137/255, 180/255, 250/255, 0.35)
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 6

                    // Header row of speedtest
                    Item {
                        width: parent.width
                        height: 18

                        Row {
                            spacing: 6
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "󰓅"
                                color: root.theme.blue
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Speedtest"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: {
                                    if (root.speedTestPhase === "ping") return "• Medindo latência…"
                                    if (root.speedTestPhase === "download") return "• Testando download…"
                                    if (root.speedTestPhase === "upload") return "• Testando upload…"
                                    if (root.speedTestPhase === "done") return "• Concluído!"
                                    if (root.speedTestPhase === "error") return "• " + (root.speedTestError.length > 0 ? root.speedTestError : "Erro no teste")
                                    return ""
                                }
                                color: root.speedTestPhase === "done"
                                       ? root.theme.green
                                       : (root.speedTestPhase === "error" ? root.theme.red : root.theme.cyan)
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Retest / Start Button
                            Rectangle {
                                height: 18
                                width: 20
                                radius: 4
                                color: retestHover.hovered ? Qt.rgba(137/255, 180/255, 250/255, 0.30) : "transparent"
                                visible: !root.speedTestRunning

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑐"
                                    color: root.theme.blue
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 11
                                }

                                HoverHandler { id: retestHover }
                                TapHandler {
                                    onTapped: root.startSpeedTest()
                                }
                            }

                            // Stop Button
                            Rectangle {
                                height: 18
                                width: 20
                                radius: 4
                                color: stopHover.hovered ? Qt.rgba(243/255, 139/255, 168/255, 0.30) : "transparent"
                                visible: root.speedTestRunning

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰓛"
                                    color: root.theme.red
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 11
                                }

                                HoverHandler { id: stopHover }
                                TapHandler {
                                    onTapped: root.stopSpeedTest()
                                }
                            }

                            // Close Button
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 5
                                color: speedCloseHover.hovered
                                       ? Qt.rgba(69/255, 71/255, 90/255, 0.72)
                                       : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: speedCloseHover.hovered ? root.theme.offWhite : root.theme.grey
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 13
                                }

                                HoverHandler { id: speedCloseHover }
                                TapHandler {
                                    onTapped: {
                                        root.stopSpeedTest()
                                        root.showSpeedTest = false
                                    }
                                }
                            }
                        }
                    }

                    // 3 Metric Boxes: Ping, Download, Upload
                    Row {
                        width: parent.width
                        height: 48
                        spacing: 8

                        // Ping Box
                        Rectangle {
                            width: (parent.width - 16) / 3
                            height: parent.height
                            radius: 6
                            color: Qt.rgba(49/255, 50/255, 68/255, 0.45)

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Row {
                                    spacing: 4
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        text: "󰓅"
                                        color: root.speedTestPing > 0 && root.speedTestPing < 60 ? root.theme.green : root.theme.yellow
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Ping"
                                        color: root.theme.grey
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.speedTestPing > 0 ? (root.speedTestPing + " ms") : "--"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Download Box
                        Rectangle {
                            width: (parent.width - 16) / 3
                            height: parent.height
                            radius: 6
                            color: Qt.rgba(49/255, 50/255, 68/255, 0.45)

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Row {
                                    spacing: 4
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        text: "󰇚"
                                        color: root.theme.blue
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Download"
                                        color: root.theme.grey
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.speedTestDown > 0 ? (root.speedTestDown + " Mbps") : (root.speedTestPhase === "download" ? "…" : "--")
                                    color: root.theme.blue
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Upload Box
                        Rectangle {
                            width: (parent.width - 16) / 3
                            height: parent.height
                            radius: 6
                            color: Qt.rgba(49/255, 50/255, 68/255, 0.45)

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Row {
                                    spacing: 4
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        text: "󰕒"
                                        color: root.theme.cyan
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Upload"
                                        color: root.theme.grey
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.speedTestUp > 0 ? (root.speedTestUp + " Mbps") : (root.speedTestPhase === "upload" ? "…" : "--")
                                    color: root.theme.cyan
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }

                    // Progress bar
                    Rectangle {
                        width: parent.width
                        height: 3
                        radius: 2
                        color: Qt.rgba(49/255, 50/255, 68/255, 0.60)
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.speedTestProgress))
                            height: parent.height
                            radius: parent.radius
                            color: root.speedTestPhase === "done" ? root.theme.green : root.theme.blue

                            Behavior on width {
                                enabled: root.theme.qmlAnimationsEnabled
                                NumberAnimation { duration: 180 }
                            }
                        }
                    }
                }
            }

            // QR Code Inline Card
            Rectangle {
                id: qrCard
                visible: root.showQr && root.qrData !== null
                width: parent.width
                height: visible ? 104 : 0
                radius: 8
                color: Qt.rgba(30/255, 30/255, 46/255, 0.60)
                border.width: 1
                border.color: Qt.rgba(137/255, 180/255, 250/255, 0.35)
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 12

                    Rectangle {
                        width: 86
                        height: 86
                        radius: 6
                        color: "white"

                        Image {
                            anchors.centerIn: parent
                            width: 82
                            height: 82
                            source: root.qrData ? ("file://" + root.qrData.path) : ""
                            fillMode: Image.PreserveAspectFit
                            cache: false
                        }
                    }

                    Column {
                        width: parent.width - 108
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Row {
                            width: parent.width
                            spacing: 6

                            Text {
                                width: parent.width - 26
                                text: root.qrData?.ssid ?? ""
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 5
                                color: qrCloseHover.hovered
                                       ? Qt.rgba(69/255, 71/255, 90/255, 0.72)
                                       : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: qrCloseHover.hovered ? root.theme.offWhite : root.theme.grey
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 13
                                }

                                HoverHandler { id: qrCloseHover }
                                TapHandler { onTapped: root.showQr = false }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 5

                            Text {
                                width: parent.width - (passwordEye.visible ? passwordEye.width + parent.spacing : 0)
                                text: root.qrData?.password
                                      ? ("Senha: " + (root.showQrPassword ? root.qrData.password : "••••••••"))
                                      : "Rede sem senha"
                                color: root.theme.cyan
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                id: passwordEye
                                visible: Boolean(root.qrData?.password)
                                width: visible ? 18 : 0
                                text: root.showQrPassword ? "󰈈" : "󰈉"
                                color: passwordEyeHover.hovered ? root.theme.blue : root.theme.grey
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter

                                HoverHandler { id: passwordEyeHover }
                                TapHandler {
                                    onTapped: root.showQrPassword = !root.showQrPassword
                                }
                            }
                        }

                        Text {
                            text: "Aponte a câmera para conectar"
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 8
                        }

                        Row {
                            spacing: 6
                            visible: Boolean(root.qrData?.password)

                            Rectangle {
                                height: 20
                                width: copyTxt.implicitWidth + 14
                                radius: 4
                                color: copyHover.hovered ? root.theme.blue : Qt.rgba(137/255, 180/255, 250/255, 0.25)

                                Text {
                                    id: copyTxt
                                    anchors.centerIn: parent
                                    text: "Copiar senha"
                                    color: copyHover.hovered ? root.theme.background : root.theme.blue
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                }

                                HoverHandler { id: copyHover }
                                TapHandler {
                                    onTapped: {
                                        if (root.qrData?.password) {
                                            root.copyRequested(root.qrData.password)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.glassBorderSubtle
            }

            // Wi-Fi Header with Scan and Disconnect
            Item {
                id: wifiHeader
                width: parent.width
                height: 20

                Text {
                    text: "Redes Wi‑Fi"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    // Scan button
                    Row {
                        spacing: 4
                        visible: root.wifiEnabled
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "󰑐"
                            color: refreshHover.hovered ? root.theme.blue : root.theme.grey
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Escanear"
                            color: refreshHover.hovered ? root.theme.blue : root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        HoverHandler { id: refreshHover }
                        TapHandler { onTapped: root.refreshRequested() }
                    }

                    // Disconnect button
                    Text {
                        visible: root.activeSsid.length > 0
                        text: "Desconectar"
                        color: disconnectHover.hovered ? root.theme.red : root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter

                        HoverHandler { id: disconnectHover }
                        TapHandler {
                            onTapped: {
                                if (root.activeDevice.length > 0)
                                    root.disconnectRequested(root.activeDevice)
                            }
                        }
                    }
                }
            }

            // Wi-Fi Network List
            Item {
                width: parent.width
                height: root.wifiAreaHeight

                Text {
                    anchors.centerIn: parent
                    visible: !root.wifiEnabled
                    text: "Ative o Wi‑Fi para procurar redes."
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.wifiEnabled && root.networks.length === 0
                    text: "Nenhuma rede encontrada."
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                }

                Flickable {
                    id: wifiScroll
                    anchors.fill: parent
                    visible: root.wifiEnabled && root.networks.length > 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: wifiList.implicitHeight

                    WheelKinetic {
                        target: wifiScroll
                    }

                    Column {
                        id: wifiList
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: root.networks

                            delegate: Rectangle {
                                id: wifiRow
                                required property var modelData

                                readonly property string rowKey: "wifi:" + String(modelData.ssid)
                                readonly property bool isRowBusy: root.busyTarget === rowKey
                                readonly property bool isRowError: root.errorTarget === rowKey && root.errorText.length > 0

                                width: wifiList.width
                                height: 42
                                radius: 8
                                color: wifiHover.hovered
                                       ? Qt.rgba(69/255, 71/255, 90/255, 0.58)
                                       : (modelData.active
                                          ? Qt.rgba(148/255, 226/255, 213/255, 0.10)
                                          : Qt.rgba(49/255, 50/255, 68/255, 0.25))
                                border.width: 1
                                border.color: modelData.active
                                              ? Qt.rgba(148/255, 226/255, 213/255, 0.35)
                                              : Qt.rgba(69/255, 71/255, 90/255, 0.20)
                                clip: true

                                Column {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    anchors.topMargin: 5
                                    anchors.bottomMargin: 5
                                    spacing: 5

                                    Row {
                                        width: parent.width
                                        height: 32
                                        spacing: 9

                                        Text {
                                            width: 22
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.wifiIcon(modelData.signal)
                                            color: modelData.active ? root.theme.cyan : root.theme.offWhite
                                            font.family: root.theme.nerdFontFamily
                                            font.pixelSize: 15
                                        }

                                        Column {
                                            width: parent.width - 100
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1

                                            Text {
                                                width: parent.width
                                                text: String(modelData.ssid)
                                                color: root.theme.foreground
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 10
                                                font.weight: modelData.active ? Font.Bold : Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                text: isRowBusy
                                                      ? (modelData.active ? "Desconectando…" : "Conectando…")
                                                      : (isRowError
                                                         ? root.errorText
                                                         : (modelData.active
                                                            ? "Conectado"
                                                            : (modelData.saved
                                                               ? "Rede salva"
                                                               : (modelData.secure ? "Senha necessária" : "Rede aberta"))))
                                                color: isRowError
                                                       ? root.theme.red
                                                       : (isRowBusy
                                                          ? root.theme.blue
                                                          : (modelData.active ? root.theme.green : root.theme.grey))
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 8
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            width: 45
                                            anchors.verticalCenter: parent.verticalCenter
                                            horizontalAlignment: Text.AlignRight
                                            text: Number(modelData.signal) + "%"
                                            color: root.theme.grey
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 9
                                        }

                                        Text {
                                            width: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: Boolean(modelData.secure)
                                            text: ""
                                            color: root.theme.grey
                                            font.family: root.theme.nerdFontFamily
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                HoverHandler { id: wifiHover }

                                TapHandler {
                                    enabled: !Boolean(modelData.active) && !wifiRow.isRowBusy
                                    onTapped: {
                                        if (Boolean(modelData.saved) || !Boolean(modelData.secure)) {
                                            root.connectRequested(
                                                String(modelData.ssid),
                                                String(modelData.uuid ?? ""),
                                                Boolean(modelData.saved),
                                                Boolean(modelData.secure)
                                            )
                                        } else {
                                            root.passwordPromptRequested(String(modelData.ssid))
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 6
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.glassBorderSubtle
            }

            // VPN Header
            Item {
                id: vpnHeader
                width: parent.width
                height: 20

                Text {
                    text: "VPN"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // VPN List
            Item {
                width: parent.width
                height: root.vpnAreaHeight

                Text {
                    anchors.centerIn: parent
                    visible: root.vpns.length === 0
                    text: "Nenhuma VPN salva."
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                }

                Flickable {
                    id: vpnScroll
                    anchors.fill: parent
                    visible: root.vpns.length > 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: vpnList.implicitHeight

                    WheelKinetic {
                        target: vpnScroll
                    }

                    Column {
                        id: vpnList
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: root.vpns

                            delegate: Rectangle {
                                required property var modelData

                                width: vpnList.width
                                height: (root.errorTarget === ("vpn:" + String(modelData.uuid))
                                         && root.errorText.length > 0) ? 54 : 40
                                radius: 8
                                color: vpnHover.hovered
                                       ? Qt.rgba(69/255, 71/255, 90/255, 0.58)
                                       : Qt.rgba(49/255, 50/255, 68/255, 0.25)
                                border.width: 1
                                border.color: modelData.active
                                              ? Qt.rgba(166/255, 227/255, 161/255, 0.30)
                                              : Qt.rgba(69/255, 71/255, 90/255, 0.20)

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    spacing: 9

                                    Text {
                                        width: 22
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.type === "wireguard" ? "󰖂" : "󰌾"
                                        color: modelData.active ? root.theme.green : root.theme.grey
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 14
                                    }

                                    Column {
                                        width: parent.width - 70
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: String(modelData.name)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: modelData.active ? Font.Bold : Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width

                                            readonly property string rowKey:
                                                "vpn:" + String(modelData.uuid)

                                            text: root.busyTarget === rowKey
                                                  ? (modelData.active
                                                     ? "Desconectando…"
                                                     : "Conectando…")
                                                  : (root.errorTarget === rowKey
                                                     && root.errorText.length > 0
                                                     ? root.errorText
                                                     : (modelData.active
                                                        ? "Ativa"
                                                        : (modelData.type === "wireguard"
                                                           ? "WireGuard"
                                                           : "VPN")))

                                            color: root.errorTarget === rowKey
                                                   && root.errorText.length > 0
                                                   ? root.theme.red
                                                   : (root.busyTarget === rowKey
                                                      ? root.theme.blue
                                                      : (modelData.active
                                                         ? root.theme.green
                                                         : root.theme.grey))

                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 32
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: modelData.active
                                               ? Qt.rgba(166/255, 227/255, 161/255, 0.22)
                                               : Qt.rgba(88/255, 91/255, 112/255, 0.45)
                                        border.width: 1
                                        border.color: modelData.active
                                                      ? root.theme.green
                                                      : root.theme.grey

                                        Rectangle {
                                            width: 12
                                            height: 12
                                            radius: 6
                                            y: 2
                                            x: modelData.active ? parent.width - width - 2 : 2
                                            color: modelData.active ? root.theme.green : root.theme.grey

                                            Behavior on x {
                                                enabled: root.theme.qmlAnimationsEnabled
                                                NumberAnimation { duration: 120 }
                                            }
                                        }
                                    }
                                }

                                HoverHandler { id: vpnHover }

                                TapHandler {
                                    onTapped: root.vpnToggleRequested(
                                        String(modelData.uuid),
                                        Boolean(modelData.active)
                                    )
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 6
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
