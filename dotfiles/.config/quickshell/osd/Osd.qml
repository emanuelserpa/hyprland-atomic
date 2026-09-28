import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs

PanelWindow {
    id: root

    anchors {
        bottom: true
    }

    margins.bottom: 72
    implicitWidth: 310
    implicitHeight: 68

    exclusionMode: ExclusionMode.Ignore
    focusable: false
    aboveWindows: true
    color: "transparent"
    visible: root.showing && root.onFocusedMonitor

    Theme { id: palette }

    property bool showing: false

    // Generic OSD payload. Any future observer can call showGeneric().
    property string osdKind: "volume"
    property string osdLabel: "Volume"
    property string osdIcon: "󰕾"
    property int osdValue: 0
    property int osdMaximum: 100
    property color osdAccent: palette.cyan
    property int osdDuration: 1250
    property bool osdMuted: false

    readonly property var hyprMonitor: Hyprland.monitorFor(root.screen)
    readonly property bool onFocusedMonitor:
        root.hyprMonitor === null || root.hyprMonitor === undefined
        ? true
        : Boolean(root.hyprMonitor.focused)

    function showGeneric(kind, label, icon, newValue, maximum, accent, duration, isMuted) {
        root.osdKind = String(kind)
        root.osdLabel = String(label)
        root.osdIcon = String(icon)
        root.osdMaximum = Math.max(1, Math.round(maximum))
        root.osdValue = Math.max(0, Math.min(root.osdMaximum, Math.round(newValue)))
        root.osdAccent = accent
        root.osdDuration = Math.max(250, Math.round(duration))
        root.osdMuted = Boolean(isMuted)

        hideTimer.interval = root.osdDuration
        root.showing = true
        hideTimer.restart()
    }

    function volumeIcon(v, isMuted) {
        if (isMuted || v <= 0) return "󰖁"
        if (v < 34) return "󰕿"
        if (v < 67) return "󰖀"
        return "󰕾"
    }

    function microphoneIcon(isMuted) {
        return isMuted ? "󰍭" : "󰍬"
    }

    function brightnessIcon(v) {
        if (v <= 25) return "󰃞"
        if (v <= 65) return "󰃟"
        return "󰃠"
    }

    function showVolume(v, isMuted) {
        root.showGeneric(
            "volume",
            isMuted ? "Volume mudo" : "Volume",
            root.volumeIcon(v, isMuted),
            v,
            150,
            isMuted ? palette.red : palette.cyan,
            1250,
            isMuted
        )
    }

    function showMicrophone(v, isMuted) {
        root.showGeneric(
            "microphone",
            isMuted ? "Microfone mudo" : "Microfone",
            root.microphoneIcon(isMuted),
            v,
            150,
            isMuted ? palette.red : palette.pink,
            1250,
            isMuted
        )
    }

    function showBrightness(v) {
        root.showGeneric(
            "brightness",
            "Brilho",
            root.brightnessIcon(v),
            v,
            100,
            palette.yellow,
            1250,
            false
        )
    }

    Timer {
        id: hideTimer
        interval: 1250
        repeat: false
        onTriggered: root.showing = false
    }

    // ----------------------------- Audio ---------------------------------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property int sinkVolume:
        root.sink?.audio ? Math.round(root.sink.audio.volume * 100) : 0

    readonly property bool sinkMuted:
        root.sink?.audio ? Boolean(root.sink.audio.muted) : false

    readonly property int sourceVolume:
        root.source?.audio ? Math.round(root.source.audio.volume * 100) : 0

    readonly property bool sourceMuted:
        root.source?.audio ? Boolean(root.source.audio.muted) : false

    property bool audioReady: false

    property int lastSinkVolume: -1
    property bool lastSinkMuted: false

    property int lastSourceVolume: -1
    property bool lastSourceMuted: false

    Timer {
        interval: 650
        running: true
        repeat: false
        onTriggered: {
            root.lastSinkVolume = root.sinkVolume
            root.lastSinkMuted = root.sinkMuted

            root.lastSourceVolume = root.sourceVolume
            root.lastSourceMuted = root.sourceMuted

            root.audioReady = true
        }
    }

    onSinkVolumeChanged: {
        if (!root.audioReady)
            return

        if (root.sinkVolume !== root.lastSinkVolume) {
            root.lastSinkVolume = root.sinkVolume
            root.showVolume(root.sinkVolume, root.sinkMuted)
        }
    }

    onSinkMutedChanged: {
        if (!root.audioReady)
            return

        if (root.sinkMuted !== root.lastSinkMuted) {
            root.lastSinkMuted = root.sinkMuted
            root.showVolume(root.sinkVolume, root.sinkMuted)
        }
    }

    onSourceVolumeChanged: {
        if (!root.audioReady)
            return

        if (root.sourceVolume !== root.lastSourceVolume) {
            root.lastSourceVolume = root.sourceVolume
            root.showMicrophone(root.sourceVolume, root.sourceMuted)
        }
    }

    onSourceMutedChanged: {
        if (!root.audioReady)
            return

        if (root.sourceMuted !== root.lastSourceMuted) {
            root.lastSourceMuted = root.sourceMuted
            root.showMicrophone(root.sourceVolume, root.sourceMuted)
        }
    }

    // --------------------------- Brightness -------------------------------
    property string backlightDevice: ""
    property int brightnessMax: 0
    property int brightnessValue: 0
    property bool brightnessReady: false

    Process {
        id: discoverBacklight
        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim().split("\n")[0] ?? ""
                const fields = line.split(",")

                if (fields.length < 4)
                    return

                root.backlightDevice = String(fields[0] ?? "").trim()

                const rawMax = parseInt(String(fields[fields.length - 1] ?? "0").trim())
                if (!isNaN(rawMax))
                    root.brightnessMax = rawMax
            }
        }
    }

    FileView {
        id: brightnessFile
        path: root.backlightDevice.length > 0
              ? "/sys/class/backlight/" + root.backlightDevice + "/brightness"
              : ""
        watchChanges: true
        printErrors: false

        onFileChanged: {
            this.reload()
            brightnessReload.restart()
        }

        onLoaded: brightnessReload.restart()
    }

    FileView {
        id: brightnessMaxFile
        path: root.backlightDevice.length > 0
              ? "/sys/class/backlight/" + root.backlightDevice + "/max_brightness"
              : ""
        watchChanges: false
        printErrors: false

        onLoaded: brightnessReload.restart()
    }

    Timer {
        id: brightnessReload
        interval: 35
        repeat: false

        onTriggered: {
            let raw = parseInt(brightnessFile.text().trim())
            let max = parseInt(brightnessMaxFile.text().trim())

            if (isNaN(max) || max <= 0)
                max = root.brightnessMax

            if (isNaN(raw) || isNaN(max) || max <= 0)
                return

            const pct = Math.max(0, Math.min(100, Math.round(raw * 100 / max)))

            if (!root.brightnessReady) {
                root.brightnessValue = pct
                root.brightnessReady = true
                return
            }

            if (pct !== root.brightnessValue) {
                root.brightnessValue = pct
                root.showBrightness(pct)
            }
        }
    }

    Component.onCompleted: discoverBacklight.running = true

    // ----------------------------- Visual --------------------------------
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: palette.background
        border.width: 1
        border.color: palette.surfaceHover

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                width: 42
                height: 42
                radius: 11
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(root.osdAccent.r, root.osdAccent.g, root.osdAccent.b, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: root.osdIcon
                    color: root.osdAccent
                    font.family: palette.nerdFontFamily
                    font.pixelSize: 19
                }
            }

            Column {
                width: parent.width - 54
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Row {
                    width: parent.width

                    Text {
                        id: osdLabel
                        text: root.osdLabel
                        color: palette.foreground
                        font.family: palette.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Item {
                        width: parent.width - osdLabel.implicitWidth - osdValue.implicitWidth
                        height: 1
                    }

                    Text {
                        id: osdValue
                        text: root.osdValue + "%"
                        color: root.osdAccent
                        font.family: palette.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 7
                    radius: 3.5
                    color: Qt.rgba(palette.surfaceHover.r, palette.surfaceHover.g, palette.surfaceHover.b, 0.50)

                    Rectangle {
                        width: parent.width * Math.max(
                            0,
                            Math.min(
                                1,
                                root.osdValue / root.osdMaximum
                            )
                        )
                        height: parent.height
                        radius: parent.radius
                        color: root.osdAccent
                    }
                }
            }
        }
    }
}
