import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root
    required property var theme
    property bool plain: false
    property bool active: false

    readonly property var weatherData: weather.data
    readonly property var citiesData: cities.data

    implicitWidth: pill.visible ? pill.implicitWidth : 0
    implicitHeight: root.theme ? root.theme.pillHeight : 25

    signal cityChanged()
    signal toggleDashboardRequested()

    CommandJson {
        id: weather
        command: ["python3", Quickshell.shellDir + "/scripts/waybar-wttr.py"]
        interval: 300000
    }

    CommandJson {
        id: cities
        command: ["python3", Quickshell.shellDir + "/scripts/weather-cities.py", "list"]
        interval: 0
    }

    function refreshAll() {
        cities.refresh()
        weather.refresh()
    }

    function selectCity(id) {
        citySelectProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/weather-cities.py",
            "select",
            id
        ]
        if (!citySelectProc.running)
            citySelectProc.running = true
    }

    function removeCity(id) {
        cityRemoveProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/weather-cities.py",
            "remove",
            id
        ]
        if (!cityRemoveProc.running)
            cityRemoveProc.running = true
    }

    function addCity(id, name, region, country, latitude, longitude) {
        cityAddProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/weather-cities.py",
            "add",
            "--id", id,
            "--name", name,
            "--region", region,
            "--country", country,
            "--latitude", String(latitude),
            "--longitude", String(longitude)
        ]
        if (!cityAddProc.running)
            cityAddProc.running = true
    }

    function cycleCity(direction) {
        cycleProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/weather-cities.py",
            "cycle",
            direction
        ]
        if (!cycleProc.running)
            cycleProc.running = true
    }

    Process {
        id: cycleProc
        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: cycleProc.output = this.text
        }

        onExited: {
            cities.refresh()
            weather.refresh()
            root.cityChanged()
        }
    }

    Process {
        id: citySelectProc
        stdout: StdioCollector {}
        onExited: {
            cities.refresh()
            weather.refresh()
            root.cityChanged()
        }
    }

    Process {
        id: cityRemoveProc
        stdout: StdioCollector {}
        onExited: {
            cities.refresh()
            weather.refresh()
            root.cityChanged()
        }
    }

    Process {
        id: cityAddProc
        stdout: StdioCollector {}
        onExited: {
            cities.refresh()
            weather.refresh()
            root.cityChanged()
        }
    }

    Pill {
        id: pill
        anchors.fill: parent
        visible: weather.text.length > 0
        theme: root.theme
        plain: root.plain
        highlighted: root.active
        text: weather.text
        tooltipText: {
            if (!weather.data?.city) return "Previsão do tempo"
            let tip = weather.data.city
            if (weather.data.temperature && weather.data.temperature !== "--")
                tip += " • " + weather.data.temperature + "°C"
            if (weather.data.description && weather.data.description !== "Previsão indisponível")
                tip += " • " + weather.data.description
            tip += " • Botão direito: atualizar"
            return tip
        }
        textColor: theme.offWhite

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.toggleDashboardRequested()
            } else if (mouse.button === Qt.RightButton) {
                root.refreshAll()
            }
        }

        mouseArea.onWheel: function(wheel) {
            root.cycleCity(wheel.angleDelta.y < 0 ? "next" : "prev")
            wheel.accepted = true
        }
    }
}
