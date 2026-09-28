import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.components

Rectangle {
    id: root

    required property var theme
    property var weatherData: ({})
    property var citiesData: ({})
    property bool cityMenuOpen: false
    property bool addMode: false
    property var searchResults: []

    signal refreshRequested()
    signal citySelected(string id)
    signal cityRemoved(string id)
    signal cityAdded(string id, string name, string region, string country,
                     real latitude, real longitude)

    implicitWidth: 334
    implicitHeight: 406
    radius: root.theme.radiusXl

    color: root.theme.cardBackground
    border.width: 1
    border.color: root.theme.borderRegular

    function value(name, fallback) {
        const v = weatherData ? weatherData[name] : undefined
        return (v === undefined || v === null || String(v).length === 0)
               ? fallback : String(v)
    }

    function doSearch() {
        const q = citySearch.text.trim()
        if (q.length < 2) {
            root.searchResults = []
            return
        }

        searchProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/weather-cities.py",
            "search",
            q
        ]

        if (!searchProc.running)
            searchProc.running = true
    }

    Process {
        id: searchProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.searchResults = obj.results ?? []
                } catch (e) {
                    root.searchResults = []
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Top city selector + quick add button
        Row {
            width: parent.width
            height: 34
            spacing: 6

            Rectangle {
                width: parent.width - 40
                height: 34
                radius: 8
                color: cityHeaderHover.hovered || root.cityMenuOpen
                       ? Qt.rgba(69/255,71/255,90/255,0.56)
                       : Qt.rgba(49/255,50/255,68/255,0.48)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍎"
                        color: root.theme.blue
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    Text {
                        width: parent.width - 44
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.value("city", "Localização automática")
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.cityMenuOpen ? "󰅀" : "󰅂"
                        color: root.theme.grey
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 9
                    }
                }

                HoverHandler { id: cityHeaderHover }

                TapHandler {
                    onTapped: {
                        root.cityMenuOpen = !root.cityMenuOpen
                        root.addMode = false
                        root.searchResults = []
                    }
                }
            }

            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: addTopHover.hovered
                       ? Qt.rgba(69/255,71/255,90/255,0.66)
                       : Qt.rgba(49/255,50/255,68/255,0.50)

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: root.theme.blue
                    font.family: root.theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Normal
                }

                HoverHandler { id: addTopHover }

                TapHandler {
                    onTapped: {
                        root.cityMenuOpen = true
                        root.addMode = true
                        root.searchResults = []
                        citySearch.forceActiveFocus()
                    }
                }
            }
        }

        // City management mode
        Item {
            visible: root.cityMenuOpen
            width: parent.width
            height: visible ? 336 : 0

            Column {
                anchors.fill: parent
                spacing: 7

                Text {
                    text: root.addMode ? "Adicionar cidade" : "Cidades salvas"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Rectangle {
                    visible: root.addMode
                    width: parent.width
                    height: visible ? 32 : 0
                    radius: 7
                    color: Qt.rgba(49/255,50/255,68/255,0.46)
                    border.width: citySearch.activeFocus ? 1 : 0
                    border.color: root.theme.blue

                    TextInput {
                        id: citySearch
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 32
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.theme.foreground
                        selectionColor: root.theme.blue
                        selectedTextColor: root.theme.background
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        clip: true

                        onAccepted: root.doSearch()
                    }

                    Text {
                        visible: citySearch.text.length === 0
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        text: "Buscar cidade..."
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: searchHover.hovered
                               ? root.theme.foreground
                               : root.theme.blue
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 10

                        HoverHandler { id: searchHover }
                        TapHandler { onTapped: root.doSearch() }
                    }
                }

                ListView {
                    id: citySearchList
                    visible: root.addMode
                    width: parent.width
                    height: visible ? 260 : 0
                    clip: true
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.searchResults

                    WheelKinetic { target: citySearchList }

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 42
                        radius: 7
                        color: searchResultHover.hovered
                               ? Qt.rgba(69/255,71/255,90/255,0.52)
                               : "transparent"

                        Column {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 4
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.name ?? ""
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: [modelData.region, modelData.country]
                                      .filter(Boolean).join(", ")
                                color: root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        HoverHandler { id: searchResultHover }

                        TapHandler {
                            onTapped: {
                                root.cityAdded(
                                    String(modelData.id ?? ""),
                                    String(modelData.name ?? ""),
                                    String(modelData.region ?? ""),
                                    String(modelData.country ?? ""),
                                    Number(modelData.latitude ?? 0),
                                    Number(modelData.longitude ?? 0)
                                )
                                root.addMode = false
                                root.cityMenuOpen = false
                            }
                        }
                    }
                }

                ListView {
                    id: savedCities
                    visible: !root.addMode
                    width: parent.width
                    height: visible ? 264 : 0
                    clip: true
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.citiesData?.cities ?? []

                    WheelKinetic { target: savedCities }

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 42
                        radius: 7
                        color: cityRowHover.hovered
                               ? Qt.rgba(69/255,71/255,90/255,0.52)
                               : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 7

                            Text {
                                width: 16
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.selected ? "" : ""
                                color: root.theme.green
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 10
                            }

                            Column {
                                width: parent.width - 52
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData.name ?? ""
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: modelData.selected
                                                 ? Font.Bold
                                                 : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: String(modelData.subtitle ?? "").length > 0
                                    width: parent.width
                                    text: modelData.subtitle ?? ""
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                visible: !modelData.automatic
                                width: 18
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰆴"
                                color: removeHover.hovered
                                       ? root.theme.red
                                       : root.theme.grey
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 9

                                HoverHandler { id: removeHover }
                                TapHandler {
                                    onTapped: root.cityRemoved(modelData.id)
                                }
                            }
                        }

                        HoverHandler { id: cityRowHover }

                        TapHandler {
                            onTapped: {
                                root.citySelected(modelData.id)
                                root.cityMenuOpen = false
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 6
                    color: manageBackHover.hovered
                           ? Qt.rgba(69/255,71/255,90/255,0.50)
                           : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰁍"
                            color: root.theme.grey
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 9
                        }

                        Text {
                            text: root.addMode ? "Voltar para cidades" : "Voltar para previsão"
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                        }
                    }

                    HoverHandler { id: manageBackHover }

                    TapHandler {
                        onTapped: {
                            if (root.addMode) {
                                root.addMode = false
                                root.searchResults = []
                            } else {
                                root.cityMenuOpen = false
                            }
                        }
                    }
                }
            }
        }

        // Main weather view
        Item {
            visible: !root.cityMenuOpen
            width: parent.width
            height: visible ? 336 : 0

            Column {
                anchors.fill: parent
                spacing: 7

                // Current Condition
                Row {
                    width: parent.width
                    height: 72
                    spacing: 7

                    Text {
                        width: 54
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: root.value("icon", "󰖐")
                        color: root.theme.yellow
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 38
                    }

                    Column {
                        width: parent.width - 120
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: root.value("temperature", "--") + "°C"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 30
                            font.weight: Font.Bold
                        }

                        Text {
                            width: parent.width
                            text: root.value("description", "Previsão indisponível")
                            color: root.theme.offWhite
                            font.family: root.theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Column {
                        width: 52
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Row {
                            spacing: 4
                            Text {
                                text: "↑"
                                color: root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                            }
                            Text {
                                text: ((root.weatherData?.days ?? []).length > 0
                                       ? root.weatherData.days[0].maxtemp : "--") + "°"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Row {
                            spacing: 4
                            Text {
                                text: "↓"
                                color: root.theme.blue
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                            }
                            Text {
                                text: ((root.weatherData?.days ?? []).length > 0
                                       ? root.weatherData.days[0].mintemp : "--") + "°"
                                color: root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // Next six hours
                Row {
                    width: parent.width
                    height: 56
                    spacing: 2

                    Repeater {
                        model: root.weatherData?.hours ?? []

                        delegate: Column {
                            required property var modelData

                            width: (parent.width - 10) / 6
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.label ?? ""
                                color: root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: parent.width
                                text: modelData.icon ?? "󰖐"
                                color: root.theme.yellow
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: parent.width
                                text: (modelData.temp ?? "--") + "°"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                // Weather Metrics Row
                Row {
                    width: parent.width
                    height: 26
                    spacing: 6

                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: 26
                        radius: 6
                        color: Qt.rgba(49/255,50/255,68/255,0.45)

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰈈"
                                color: root.theme.orange
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: (root.weatherData?.feels_like ?? "--") + "°C"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: 26
                        radius: 6
                        color: Qt.rgba(49/255,50/255,68/255,0.45)

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰖎"
                                color: root.theme.cyan
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: (root.weatherData?.humidity ?? "--") + "%"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: 26
                        radius: 6
                        color: Qt.rgba(49/255,50/255,68/255,0.45)

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰖝"
                                color: root.theme.blue
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: (root.weatherData?.wind ?? "--") + " km/h"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(88/255,91/255,112/255,0.35)
                }

                // Five day list
                Column {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: root.weatherData?.days ?? []

                        delegate: Row {
                            required property var modelData

                            width: parent.width
                            height: 29

                            Text {
                                width: 110
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label ?? ""
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Text {
                                width: 36
                                anchors.verticalCenter: parent.verticalCenter
                                text: (modelData.periods?.length ?? 0) > 1
                                      ? (modelData.periods[1].icon ?? "󰖐")
                                      : "󰖐"
                                color: root.theme.yellow
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item { width: Math.max(0, parent.width - 236); height: 1 }

                            Text {
                                width: 42
                                anchors.verticalCenter: parent.verticalCenter
                                text: "↑ " + (modelData.maxtemp ?? "--") + "°"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                width: 42
                                anchors.verticalCenter: parent.verticalCenter
                                text: "↓ " + (modelData.mintemp ?? "--") + "°"
                                color: root.theme.blue
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 14
                    spacing: 4

                    Text {
                        text: "󰔛"
                        color: root.theme.grey
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.weatherData?.updated_at
                              ? "Atualizado às " + Qt.formatDateTime(new Date(root.weatherData.updated_at), "HH:mm")
                              : "Previsão Open-Meteo"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: Math.max(0, parent.width - 200); height: 1 }

                    Text {
                        visible: Boolean(root.weatherData?.stale)
                        text: "Última válida"
                        color: root.theme.yellow
                        font.family: root.theme.fontFamily
                        font.pixelSize: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
