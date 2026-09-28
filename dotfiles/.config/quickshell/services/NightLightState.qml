pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property bool enabled: false
    property bool active: false
    property bool isNight: false
    property string sunrise: "--:--"
    property string sunset: "--:--"
    property string city: ""
    property string backend: ""
    property int nightTemp: 4000
    property int currentTemp: 6500

    function refresh() {
        statusState.refresh()
    }

    function applyStatus(res) {
        if (!res || !res.ok)
            return
        root.enabled = Boolean(res.enabled)
        root.active = Boolean(res.active)
        root.isNight = Boolean(res.is_night)
        root.sunrise = String(res.sunrise ?? "--:--")
        root.sunset = String(res.sunset ?? "--:--")
        root.city = String(res.city ?? "")
        root.backend = String(res.backend ?? "")
        root.nightTemp = Number(res.night_temp ?? 4000)
        root.currentTemp = Number(res.current_temp ?? 6500)
    }

    function toggle() {
        Quickshell.execDetached(["python3", "-B", Quickshell.shellDir + "/scripts/nightlight-manager.py", "toggle"])
        refreshTimer.restart()
    }

    function setEnabled(val) {
        const action = val ? "on" : "off"
        Quickshell.execDetached(["python3", "-B", Quickshell.shellDir + "/scripts/nightlight-manager.py", action])
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    CommandJson {
        id: statusState
        command: ["python3", "-B", Quickshell.shellDir + "/scripts/nightlight-manager.py", "status"]
        interval: 0
        onDataChanged: root.applyStatus(data)
    }
}
