import QtQuick
import Quickshell
import qs.components

PopupWindow {

    id: root

    required property var theme
    required property Item target

    // Calendar & System properties
    property real cpuTemperature: 0
    property string cpuSensor: ""

    // Weather properties
    property var weatherData: ({})
    property var citiesData: ({})

    // Network & Bluetooth properties
    property var networkData: ({})
    property var bluetoothData: ({})

    // Weather signals
    signal refreshWeatherRequested()
    signal citySelected(string id)
    signal cityRemoved(string id)
    signal cityAdded(string id, string name, string region, string country,
                     real latitude, real longitude)

    // Network & Bluetooth signals
    signal networkActionRequested(var args)
    signal bluetoothActionRequested(var args)

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    readonly property real screenWidth: target?.window?.width ?? 1600
    readonly property real screenHeight: target?.window?.height ?? 900
    readonly property real maxAllowedWidth: Math.max(360, screenWidth - 32)
    readonly property real maxAllowedHeight: Math.min(screenHeight - 16, Math.max(300, screenHeight - 60))

    readonly property real availableContentWidth: Math.max(0, card.width - 20)
    readonly property real targetColumnsWidth: Math.max(0, availableContentWidth - 20)
    readonly property bool needsScroll: availableContentWidth < 840

    // Proportional column scaling when availableContentWidth >= 840:
    // Original proportions: 334 : 324 : 334 (total 992)
    readonly property real col1Width: needsScroll ? 320 : Math.round(targetColumnsWidth * (334 / 992))
    readonly property real col3Width: needsScroll ? 320 : Math.round(targetColumnsWidth * (334 / 992))
    readonly property real col2Width: needsScroll ? 310 : Math.max(260, targetColumnsWidth - col1Width - col3Width)

    readonly property int activePageIndex: {
        if (!needsScroll || flickable.contentWidth <= flickable.width) return 1
        const maxScroll = Math.max(1, flickable.contentWidth - flickable.width)
        const progress = flickable.contentX / maxScroll
        return progress < 0.33 ? 0 : (progress > 0.66 ? 2 : 1)
    }

    implicitWidth: Math.min(1032, maxAllowedWidth)
    implicitHeight: Math.min(needsScroll ? 438 : 426, maxAllowedHeight)

    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    function toggle() {

        root.visible = !root.visible
    }

    function moveToPage(x) {
        if (root.theme.qmlAnimationsEnabled) {
            scrollAnim.to = x
            scrollAnim.restart()
        } else {
            flickable.contentX = x
        }
    }

    function runUpdate(backend) {
        Quickshell.execDetached([
            "bash",
            Quickshell.shellDir + "/scripts/run-update-terminal.sh",
            backend
        ])
    }

    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
            openRefresh.restart()
        } else {
            openRefresh.stop()
            weatherCard.addMode = false
            weatherCard.cityMenuOpen = false
            weatherCard.searchResults = []
        }
    }

    // Defer rebuild + backend refreshes off the show frame so the
    // enter animation runs without a hitch.
    Timer {
        id: openRefresh
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.visible) return
            calendarCard.resetDate()
            calendarCard.refreshUpdates()
            root.refreshWeatherRequested()
        }
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        Keys.onEscapePressed: root.visible = false

        Keys.onLeftPressed: function(event) {
            if (root.needsScroll && root.activePageIndex > 0) {
                const targetIdx = root.activePageIndex - 1
                const pages = [
                    0,
                    Math.max(0, (weatherCard.width + 10) - (flickable.width - calendarCard.width) / 2),
                    Math.max(0, flickable.contentWidth - flickable.width)
                ]
                root.moveToPage(pages[targetIdx])
                event.accepted = true
            }
        }

        Keys.onRightPressed: function(event) {
            if (root.needsScroll && root.activePageIndex < 2) {
                const targetIdx = root.activePageIndex + 1
                const pages = [
                    0,
                    Math.max(0, (weatherCard.width + 10) - (flickable.width - calendarCard.width) / 2),
                    Math.max(0, flickable.contentWidth - flickable.width)
                ]
                root.moveToPage(pages[targetIdx])
                event.accepted = true
            }
        }

        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.margins: 10
            anchors.bottomMargin: root.needsScroll ? 22 : 10
            contentWidth: rowLayout.width
            contentHeight: rowLayout.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: root.needsScroll

            WheelKinetic {
                target: flickable
                orientation: Qt.Horizontal
            }

            NumberAnimation {
                id: scrollAnim
                target: flickable
                property: "contentX"
                duration: 250
                easing.type: Easing.OutCubic
            }

            Row {
                id: rowLayout
                spacing: 10
                height: flickable.height

                // Coluna 1: Clima & Cidades
                WeatherCard {
                    id: weatherCard
                    width: root.col1Width
                    height: parent.height
                    theme: root.theme
                    weatherData: root.weatherData
                    citiesData: root.citiesData

                    onRefreshRequested: root.refreshWeatherRequested()
                    onCitySelected: function(id) { root.citySelected(id) }
                    onCityRemoved: function(id) { root.cityRemoved(id) }
                    onCityAdded: function(id, name, region, country, lat, lon) {
                        root.cityAdded(id, name, region, country, lat, lon)
                    }
                }

                // Coluna 2: Calendário & Hardware Base
                CalendarCard {
                    id: calendarCard
                    width: root.col2Width
                    height: parent.height
                    theme: root.theme
                    active: root.visible
                    cpuTemperature: root.cpuTemperature
                    cpuSensor: root.cpuSensor

                    onOpenUpdatesRequested: {
                        root.visible = false
                        systemUpdatePopup.visible = true
                    }
                    onCloseRequested: {
                        root.visible = false
                    }
                }

                // Coluna 3: Controles de Hardware & Ações Rápidas
                ControlCenterCard {
                    id: controlCenterCard
                    width: root.col3Width
                    height: parent.height
                    theme: root.theme
                    active: root.visible
                    totalUpdates: calendarCard.totalUpdates
                    networkData: root.networkData
                    bluetoothData: root.bluetoothData

                    onNetworkActionRequested: function(args) { root.networkActionRequested(args) }
                    onBluetoothActionRequested: function(args) { root.bluetoothActionRequested(args) }
                    onOpenUpdatesRequested: {
                        root.visible = false
                        systemUpdatePopup.visible = true
                    }
                    onCloseRequested: {
                        root.visible = false
                    }
                }
            }
        }

        // Indicator dots/pills for compact screen widths
        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            visible: root.needsScroll

            Repeater {
                model: [
                    { name: "Clima", targetX: 0 },
                    { name: "Calendário", targetX: Math.max(0, (weatherCard.width + 10) - (flickable.width - calendarCard.width) / 2) },
                    { name: "Controles", targetX: Math.max(0, flickable.contentWidth - flickable.width) }
                ]

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: root.activePageIndex === index ? 22 : 7
                    height: 7
                    radius: 3.5
                    color: root.activePageIndex === index ? root.theme.accent : root.theme.surfaceVariant
                    opacity: root.activePageIndex === index ? 1.0 : 0.5

                    Behavior on width { enabled: root.theme.qmlAnimationsEnabled; NumberAnimation { duration: 150 } }
                    Behavior on opacity { enabled: root.theme.qmlAnimationsEnabled; NumberAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.moveToPage(modelData.targetX)
                        }
                    }
                }
            }
        }
    }

    SystemUpdatePopup {
        id: systemUpdatePopup
        theme: root.theme
        target: root.target
        repoData: calendarCard.repoData
        aurData: calendarCard.aurData
        flatpakData: calendarCard.flatpakData
        brewData: calendarCard.brewData

        onRefreshRequested: calendarCard.refreshUpdates()

        onUpdateRequested: function(backend) {
            root.runUpdate(backend)
            systemUpdatePopup.visible = false
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.visible = false
    }

    Shortcut {
        sequence: "Left"
        enabled: root.visible && !root.needsScroll && !weatherCard.cityMenuOpen
        onActivated: calendarCard.prevMonth()
    }

    Shortcut {
        sequence: "Right"
        enabled: root.visible && !root.needsScroll && !weatherCard.cityMenuOpen
        onActivated: calendarCard.nextMonth()
    }

    Shortcut {
        sequence: "["
        enabled: root.visible && !weatherCard.cityMenuOpen
        onActivated: calendarCard.prevMonth()
    }

    Shortcut {
        sequence: "]"
        enabled: root.visible && !weatherCard.cityMenuOpen
        onActivated: calendarCard.nextMonth()
    }

    Shortcut {
        sequence: "T"
        enabled: root.visible && !weatherCard.cityMenuOpen
        onActivated: calendarCard.resetDate()
    }

    Shortcut {
        sequence: "W"
        enabled: root.visible && !weatherCard.cityMenuOpen
        onActivated: calendarCard.startOnMonday = !calendarCard.startOnMonday
    }

    Shortcut {
        sequence: "R"
        enabled: root.visible && !weatherCard.cityMenuOpen
        onActivated: {
            root.refreshWeatherRequested()
            calendarCard.refreshUpdates()
        }
    }
}
