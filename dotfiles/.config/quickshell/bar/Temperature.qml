import QtQuick
import Quickshell
import qs.components

Pill {
    id: root

    property real temp: Number(tempState.data?.temp_c ?? 0)
    property string sensor: String(tempState.data?.sensor ?? "")
    property bool active: false
    readonly property bool shouldPoll: root.active || popup.visible

    text: "󰔏 " + Math.round(temp) + "°C"
    textColor: temp >= 80 ? theme.red : theme.yellow
    highlighted: temp >= 80

    tooltipText: "Temperatura CPU: " + Math.round(temp) + "°C"

    TemperaturePopup {
        id: popup
        theme: root.theme
        target: root
        temperature: root.temp
        sensor: root.sensor
    }

    mouseArea.onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton)
            popup.visible = !popup.visible
    }

    CommandJson {
        id: tempState
        command: ["python3", Quickshell.shellDir + "/scripts/temperature-status.py"]
        interval: root.shouldPoll ? 3000 : 0
    }

    onShouldPollChanged: {
        if (shouldPoll)
            tempState.refresh()
    }
}
