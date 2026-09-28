import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Pill {
    id: root

    property int brightness: 0
    property bool available: false
    property string deviceName: ""
    property bool changing: false

    function iconFor(value) {
        if (value <= 25) return "󰃞"
        if (value <= 65) return "󰃟"
        return "󰃠"
    }

    function refresh() {
        if (!root.changing && !queryProc.running)
            queryProc.running = true
    }

    function setBrightness(value) {
        if (!root.available || root.changing)
            return

        const v = Math.max(1, Math.min(100, Math.round(value)))
        root.brightness = v
        root.changing = true
        setProc.command = ["brightnessctl", "set", v + "%"]
        setProc.running = true
    }

    function changeBrightness(delta) {
        setBrightness(root.brightness + delta)
    }

    text: root.available
          ? root.iconFor(root.brightness) + " " + root.brightness + "%"
          : "󰃠 --%"

    textColor: root.available ? theme.yellow : theme.grey
    highlighted: false

    tooltipText: root.available
                 ? "Brilho: " + root.brightness + "% • Scroll: ajustar"
                 : "Brilho indisponível"

    Process {
        id: queryProc
        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                // brightnessctl -m output ordering differs between versions.
                // Find the field that actually contains "%" instead of assuming
                // the percentage is always in a fixed position.
                const line = this.text.trim().split("\n")[0] ?? ""
                const fields = line.split(",")

                if (fields.length >= 4) {
                    const pctField = fields.find(function(field) {
                        return String(field).includes("%")
                    })

                    const pct = pctField !== undefined
                              ? parseInt(String(pctField).replace("%", "").trim())
                              : NaN

                    root.available = !isNaN(pct)
                    root.brightness = root.available
                                      ? Math.max(0, Math.min(100, pct))
                                      : 0
                    root.deviceName = String(fields[0] ?? "").trim()
                } else {
                    root.available = false
                    root.deviceName = ""
                }
            }
        }
    }

    Process {
        id: setProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.changing = false
                refreshDelay.restart()
            }
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshDelay
        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    BrightnessPopup {
        id: popup
        theme: root.theme
        target: root
        brightness: root.brightness
        available: root.available
        deviceName: root.deviceName
        onBrightnessRequested: function(value) {
            root.setBrightness(value)
        }
    }

    mouseArea.onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton)
            popup.visible = !popup.visible
    }

    mouseArea.onWheel: function(wheel) {
        if (!root.available) return
        root.changeBrightness(wheel.angleDelta.y > 0 ? 5 : -5)
    }
}
