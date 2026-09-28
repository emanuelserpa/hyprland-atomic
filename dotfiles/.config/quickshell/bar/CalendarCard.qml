import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

Rectangle {
    id: root

    required property var theme
    property real cpuTemperature: 0
    property string cpuSensor: ""
    property int fanRpm: 0
    property string fanSensor: ""
    property bool updateDetails: false
    property bool active: false
    property date shownDate: new Date()

    signal openUpdatesRequested()
    signal closeRequested()

    implicitWidth: 324
    implicitHeight: 406
    radius: root.theme.radiusXl

    color: root.theme.cardBackground
    border.width: 1
    border.color: root.theme.borderRegular

    readonly property int currentYear: (new Date()).getFullYear()
    readonly property bool isLeapYear: (currentYear % 4 === 0 && currentYear % 100 !== 0) || (currentYear % 400 === 0)
    readonly property int daysInCurrentYear: isLeapYear ? 366 : 365
    readonly property int dayOfYear: {
        const now = new Date()
        const start = new Date(now.getFullYear(), 0, 0)
        const diff = (now - start) + ((start.getTimezoneOffset() - now.getTimezoneOffset()) * 60 * 1000)
        const oneDay = 1000 * 60 * 60 * 24
        return Math.floor(diff / oneDay)
    }
    readonly property real yearProgress: Math.max(0, Math.min(1, dayOfYear / daysInCurrentYear))

    readonly property color tempColor:
        cpuTemperature >= 80 ? theme.red
        : cpuTemperature >= 70 ? theme.orange
        : cpuTemperature >= 55 ? theme.yellow
        : theme.cyan

    Process {
        id: fanProc
        command: [
            "bash",
            Quickshell.shellDir + "/scripts/fan-speed.sh"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                const parts = line.split("|")
                const rpm = parseInt(parts[0])

                root.fanRpm = isNaN(rpm) ? 0 : rpm
                root.fanSensor = parts.length > 1
                                 ? parts.slice(1).join("|")
                                 : ""
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.active
        onTriggered: {
            if (!fanProc.running)
                fanProc.running = true
        }
    }

    onActiveChanged: {
        if (active && !fanProc.running)
            fanProc.running = true
    }

    readonly property int archCount: UpdateState.archCount
    readonly property int aurCount: UpdateState.aurCount
    readonly property int flatpakCount: UpdateState.flatpakCount
    readonly property int brewCount: UpdateState.brewCount
    readonly property int totalUpdates: UpdateState.totalUpdates

    readonly property var repoData: UpdateState.repoData
    readonly property var aurData: UpdateState.aurData
    readonly property var flatpakData: UpdateState.flatpakData
    readonly property var brewData: UpdateState.brewData

    function monthName(m) {
        const names = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        return names[m]
    }

    property bool startOnMonday: true
    readonly property var weekdayNames: startOnMonday
        ? ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
        : ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    readonly property bool isCurrentMonth: shownDate.getMonth() === (new Date()).getMonth()
                                           && shownDate.getFullYear() === (new Date()).getFullYear()

    function firstWeekday() {
        const d = new Date(shownDate.getFullYear(), shownDate.getMonth(), 1)
        return startOnMonday ? (d.getDay() + 6) % 7 : d.getDay()
    }

    function daysInMonth() {
        return new Date(
            shownDate.getFullYear(),
            shownDate.getMonth() + 1,
            0
        ).getDate()
    }

    function prevMonth() {
        shownDate = new Date(
            shownDate.getFullYear(),
            shownDate.getMonth() - 1,
            1
        )
    }

    function nextMonth() {
        shownDate = new Date(
            shownDate.getFullYear(),
            shownDate.getMonth() + 1,
            1
        )
    }

    function resetDate() {
        shownDate = new Date()
    }

    function refreshUpdates() {
        UpdateState.refreshUpdates()
        if (!fanProc.running)
            fanProc.running = true
    }

    function formattedHeaderDate() {
        const d = root.shownDate
        const weekdays = [
            "Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira",
            "Quinta-feira", "Sexta-feira", "Sábado"
        ]
        const months = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        return (weekdays[d.getDay()] + ", " + d.getDate() + " de " + months[d.getMonth()]).toUpperCase()
    }

    function getISOWeek(d) {
        const date = new Date(d.getTime())
        date.setHours(0, 0, 0, 0)
        date.setDate(date.getDate() + 3 - (date.getDay() + 6) % 7)
        const week1 = new Date(date.getFullYear(), 0, 4)
        return 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7)
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        // Header: Date by name
        Item {
            width: parent.width
            height: 18

            Item {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: headerDateRow.implicitWidth
                height: 18

                Row {
                    id: headerDateRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: ""
                        color: root.theme.blue
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.formattedHeaderDate()
                        color: headerDateMouse.containsMouse && !root.isCurrentMonth
                               ? root.theme.blue
                               : root.theme.offWhite
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        opacity: 0.85
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: headerDateMouse
                    anchors.fill: parent
                    enabled: !root.isCurrentMonth
                    hoverEnabled: enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetDate()
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 16
                width: todayBtnRow.implicitWidth + 8
                radius: 4
                visible: !root.isCurrentMonth
                color: todayBtnMouse.containsMouse
                       ? Qt.rgba(137/255, 180/255, 250/255, 0.28)
                       : Qt.rgba(69/255, 71/255, 90/255, 0.40)

                Row {
                    id: todayBtnRow
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        text: "󰁞"
                        color: root.theme.blue
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Hoje"
                        color: root.theme.offWhite
                        font.family: root.theme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: todayBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetDate()
                }
            }
        }

        // Month Navigation
        Row {
            width: parent.width
            height: 22

            Text {
                width: 26
                height: parent.height
                text: "‹"
                color: prevMonthHover.hovered
                       ? root.theme.foreground
                       : root.theme.grey
                font.family: root.theme.fontFamily
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                HoverHandler { id: prevMonthHover }
                TapHandler { onTapped: root.prevMonth() }
            }

            Text {
                width: parent.width - 52
                height: parent.height
                text: (root.monthName(root.shownDate.getMonth()) + " " + root.shownDate.getFullYear()).toUpperCase()
                color: monthClickHover.hovered && !root.isCurrentMonth
                       ? root.theme.blue
                       : root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                HoverHandler { id: monthClickHover }
                TapHandler {
                    onTapped: {
                        if (!root.isCurrentMonth) root.resetDate()
                    }
                }
            }

            Text {
                width: 26
                height: parent.height
                text: "›"
                color: nextMonthHover.hovered
                       ? root.theme.foreground
                       : root.theme.grey
                font.family: root.theme.fontFamily
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                HoverHandler { id: nextMonthHover }
                TapHandler { onTapped: root.nextMonth() }
            }
        }

        // Weekday names
        Row {
            width: parent.width
            height: 15
            spacing: 0

            Rectangle {
                width: 24
                height: parent.height
                radius: 3
                color: semHover.containsMouse
                       ? Qt.rgba(69/255, 71/255, 90/255, 0.40)
                       : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "Sem"
                    color: semHover.containsMouse ? root.theme.blue : root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: semHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startOnMonday = !root.startOnMonday
                }
            }

            Rectangle {
                width: 1
                height: 11
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(88/255, 91/255, 112/255, 0.35)
            }

            Item { width: 5; height: 1 }

            Row {
                width: parent.width - 30
                height: parent.height

                Repeater {
                    model: root.weekdayNames

                    delegate: Text {
                        required property string modelData
                        width: parent.width / 7
                        height: parent.height
                        text: modelData
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Calendar Grid by Weeks
        Column {
            id: calendarGrid
            width: parent.width
            spacing: 1

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    if (event.angleDelta.y < 0) {
                        root.nextMonth()
                    } else if (event.angleDelta.y > 0) {
                        root.prevMonth()
                    }
                }
            }

            Repeater {
                model: 6

                delegate: Row {
                    id: weekRow
                    required property int index

                    readonly property int rowIndex: index

                    // Check if this row has any days in the shown month
                    readonly property int rowStartDay: 1 - root.firstWeekday() + (rowIndex * 7)
                    readonly property int rowEndDay: rowStartDay + 6
                    readonly property bool rowHasDays: rowStartDay <= root.daysInMonth() && rowEndDay >= 1

                    // Date of the Monday of this week
                    readonly property date rowDate: new Date(root.shownDate.getFullYear(), root.shownDate.getMonth(), rowStartDay)
                    readonly property int weekNumber: root.getISOWeek(rowDate)

                    width: parent ? parent.width : 0
                    height: 25
                    spacing: 0

                    // Week number
                    Text {
                        width: 24
                        height: parent.height
                        text: weekRow.rowHasDays ? weekRow.weekNumber : ""
                        color: root.theme.grey
                        opacity: 0.65
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(88/255, 91/255, 112/255, 0.22)
                    }

                    Item { width: 5; height: 1 }

                    // 7 days of the week
                    Row {
                        width: parent.width - 30
                        height: parent.height
                        spacing: 2

                        Repeater {
                            model: 7

                            delegate: Rectangle {
                                id: dayCell
                                required property int index

                                readonly property int day: weekRow.rowStartDay + index
                                readonly property bool valid: day >= 1 && day <= root.daysInMonth()

                                readonly property date today: new Date()
                                readonly property bool isToday:
                                    valid
                                    && day === today.getDate()
                                    && root.shownDate.getMonth() === today.getMonth()
                                    && root.shownDate.getFullYear() === today.getFullYear()

                                width: (parent.width - 12) / 7
                                height: 25
                                radius: 6

                                color: isToday
                                       ? Qt.rgba(137/255, 180/255, 250/255, 0.72)
                                       : (dayHover.hovered && valid ? Qt.rgba(69/255, 71/255, 90/255, 0.35) : "transparent")

                                Text {
                                    anchors.centerIn: parent
                                    text: dayCell.valid ? dayCell.day : ""
                                    color: dayCell.isToday
                                           ? root.theme.background
                                           : root.theme.offWhite
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: dayCell.isToday ? Font.Bold : Font.Normal
                                }

                                HoverHandler { id: dayHover; enabled: dayCell.valid }
                            }
                        }
                    }
                }
            }
        }

        // Year Progress Strip (Strictly bounded)
        Column {
            width: parent.width
            spacing: 3

            Item {
                width: parent.width
                height: 12

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Ano " + root.currentYear
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.yearProgress * 100) + "%  •  dia " + root.dayOfYear + " de " + root.daysInCurrentYear
                    color: root.theme.offWhite
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(49/255, 50/255, 68/255, 0.65)
                clip: true

                Rectangle {
                    width: Math.min(parent.width, Math.max(0, parent.width * root.yearProgress))
                    height: parent.height
                    radius: 2
                    color: root.theme.blue
                }
            }
        }

        // Box de Telemetria de Hardware (CPU & Cooler)
        Item {
            width: parent.width
            height: 88

            Column {
                anchors.fill: parent
                spacing: 6

                // Cabeçalho da Telemetria
                Item {
                    width: parent.width
                    height: 14

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            text: "󰍛"
                            color: root.theme.blue
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Telemetria Térmica"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.cpuSensor.length > 0 ? root.cpuSensor : "ThinkPad T14"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                    }
                }

                // Grid 2 Colunas: CPU Térmico | Cooler RPM
                Row {
                    width: parent.width
                    spacing: 8

                    // Card CPU
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 62
                        radius: root.theme.radiusMd
                        color: root.theme.cardBackgroundSubtle
                        border.width: 1
                        border.color: root.theme.glassBorderSubtle

                        Column {
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 3

                            Item {
                                width: parent.width
                                height: 13

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        text: "󰔏"
                                        color: root.tempColor
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "CPU"
                                        color: root.theme.grey
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.cpuTemperature < 55 ? "Normal" : (root.cpuTemperature < 75 ? "Média" : "Alta")
                                    color: root.tempColor
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }
                            }

                            Row {
                                spacing: 2

                                Text {
                                    text: Math.round(root.cpuTemperature)
                                    color: root.tempColor
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 17
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: "°C"
                                    color: root.theme.offWhite
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 3
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Qt.rgba(69/255, 71/255, 90/255, 0.45)

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, root.cpuTemperature / 100))
                                    height: parent.height
                                    radius: 2
                                    color: root.tempColor
                                }
                            }
                        }
                    }

                    // Card Cooler / Ventilação
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 62
                        radius: root.theme.radiusMd
                        color: root.theme.cardBackgroundSubtle
                        border.width: 1
                        border.color: root.theme.glassBorderSubtle

                        Column {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 2

                            Item {
                                width: parent.width
                                height: 13

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        id: fanIconSpin
                                        text: "󰈐"
                                        color: root.fanRpm > 0 ? root.theme.cyan : root.theme.grey
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        transformOrigin: Item.Center

                                        NumberAnimation on rotation {
                                            running: root.theme.qmlAnimationsEnabled && root.fanRpm > 0 && root.visible
                                            from: 0
                                            to: 360
                                            loops: Animation.Infinite
                                            duration: Math.max(300, Math.min(2500, Math.round(180000 / Math.max(500, root.fanRpm))))
                                        }
                                    }

                                    Text {
                                        text: "Cooler"
                                        color: root.theme.grey
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.fanSensor === "unavailable"
                                          ? "N/D"
                                          : (root.fanRpm === 0 ? "Passivo" : (root.fanRpm > 3500 ? "Turbo" : "Ativo"))
                                    color: root.fanRpm > 0 ? root.theme.cyan : root.theme.green
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }
                            }

                            Row {
                                spacing: 2

                                Text {
                                    text: root.fanRpm > 0 ? ("" + root.fanRpm) : "0"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 17
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: " RPM"
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 3
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Qt.rgba(69/255, 71/255, 90/255, 0.45)

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, root.fanRpm / 5000))
                                    height: parent.height
                                    radius: 2
                                    color: root.fanRpm > 3500 ? root.theme.orange : root.theme.cyan
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
