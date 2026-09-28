import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    property var launcherController: null
    anchors {
        top: true
        left: true
        right: true
    }

    IdleInhibitor {
        window: root
        enabled: IdleState.inhibited
    }

    implicitHeight: 37
    color: "transparent"
    exclusiveZone: 37

    Theme { id: palette }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: 3
        radius: 9
        color: palette.background
        border.width: 1
        border.color: palette.glassBorder

        Row {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            StartButton { theme: palette }

            // Breathing room so workspace 1 is not hit by mistake.
            Item { width: 5; height: 1 }

            Workspaces { theme: palette }

            Item {
                width: submapWidget.visible ? submapWidget.width : 0
                height: 29

                Submap {
                    id: submapWidget
                    theme: palette
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Row {
            id: centerCluster
            anchors.centerIn: parent
            spacing: 7

            Weather {
                id: weatherWidget
                theme: palette
                plain: true
                active: dashboardPopup.visible
                anchors.verticalCenter: parent.verticalCenter
                onToggleDashboardRequested: dashboardPopup.toggle()
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "·"
                color: palette.grey
                opacity: 0.75
                font.family: palette.fontFamily
                font.pixelSize: 12
            }

            Clock {
                id: clockWidget
                theme: palette
                active: dashboardPopup.visible
                anchors.verticalCenter: parent.verticalCenter
                onToggleDashboardRequested: dashboardPopup.toggle()
            }
        }

        CenterDashboardPopup {
            id: dashboardPopup
            theme: palette
            target: centerCluster
            cpuTemperature: temperatureWidget.temp
            cpuSensor: temperatureWidget.sensor
            weatherData: weatherWidget.weatherData
            citiesData: weatherWidget.citiesData
            networkData: networkWidget.networkData
            bluetoothData: bluetoothWidget.bluetoothData

            onRefreshWeatherRequested: weatherWidget.refreshAll()
            onCitySelected: function(id) { weatherWidget.selectCity(id) }
            onCityRemoved: function(id) { weatherWidget.removeCity(id) }
            onCityAdded: function(id, name, region, country, lat, lon) {
                weatherWidget.addCity(id, name, region, country, lat, lon)
            }
            onNetworkActionRequested: function(args) { networkWidget.runAction(args, true) }
            onBluetoothActionRequested: function(args) { bluetoothWidget.runAction(args, true) }
        }

        Temperature {
            id: temperatureWidget
            theme: palette
            visible: false
            active: dashboardPopup.visible
        }

        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Tray {
                theme: palette
                panelWindow: root
            }

            Media { id: mediaWidget; theme: palette }
            Network { id: networkWidget; theme: palette }
            Bluetooth { id: bluetoothWidget; theme: palette }
            Phone { id: phoneWidget; theme: palette }
            Audio { theme: palette }
            Battery { theme: palette }
            Printer { theme: palette }
            SystemUpdates { theme: palette }
            ScreenRecording { theme: palette }
            NotificationControl { theme: palette }

        }
    }
}
