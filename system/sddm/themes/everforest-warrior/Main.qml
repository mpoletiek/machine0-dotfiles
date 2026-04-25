import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root
    // Match the actual screen, not a hardcoded 1920x1080 box. With
    // PreserveAspectFit on the wallpaper, anything outside the root
    // shows SDDM's default container color (white-ish on Wayland).
    width: Screen.width
    height: Screen.height
    color: "#000000"

    property string fontFamily: config.fontFamily
    property color bgColor: config.bgColor
    property color panelColor: config.panelColor
    property color borderColor: config.borderColor
    property color fgColor: config.fgColor
    property color fgDim: config.fgDim
    property color accent: config.accentColor
    property color accent2: config.accent2Color
    property color warnColor: config.warnColor
    property color failColor: config.failColor

    // ----- Background -----
    // Pure-black letterbox underneath — matches Noctalia fillColor "#000000".
    // Background image is pre-rendered at native screen res with letterbox
    // baked in by build-assets.sh (Lanczos, no blur), so PreserveAspectFit
    // is effectively a 1:1 blit when source size matches the screen.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }
    Image {
        id: bg
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: false
    }

    // Dim overlay: hardcoded black so it's never affected by config parse
    // weirdness (a malformed bgColor would default to white in Qt and show
    // through as a bright tint).
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: parseFloat(config.dimOpacity) || 0.25
    }

    // ----- Clock -----
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.14
        spacing: 2

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: root.fgColor
            font.family: root.fontFamily
            font.pixelSize: 96
            font.bold: true
            style: Text.Raised
            styleColor: "#00000077"
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            color: root.fgDim
            font.family: root.fontFamily
            font.pixelSize: 20
        }

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                const now = new Date()
                timeLabel.text = Qt.formatDateTime(now, "hh:mm")
                dateLabel.text = Qt.formatDateTime(now, "dddd, MMMM d")
            }
        }
    }

    // ----- Login panel -----
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 440
        height: 340
        radius: 12
        color: Qt.rgba(root.panelColor.r, root.panelColor.g, root.panelColor.b, 0.85)
        border.color: root.borderColor
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            // User row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: ""
                    color: root.accent
                    font.family: root.fontFamily
                    font.pixelSize: 20
                }

                ComboBox {
                    id: userCombo
                    Layout.fillWidth: true
                    model: userModel
                    textRole: "name"
                    currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    background: Rectangle {
                        radius: 6
                        color: root.bgColor
                        border.color: root.borderColor
                        border.width: 1
                    }
                    contentItem: Text {
                        text: userCombo.displayText
                        color: root.fgColor
                        font: userCombo.font
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                }
            }

            // Password field
            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                placeholderText: ""
                placeholderTextColor: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.45)
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 18
                horizontalAlignment: TextInput.AlignHCenter
                background: Rectangle {
                    radius: 6
                    color: root.bgColor
                    border.color: passwordField.activeFocus ? root.accent : root.borderColor
                    border.width: 2
                }
                Keys.onReturnPressed: submitLogin()
                Keys.onEnterPressed: submitLogin()
                focus: true
            }

            // Session + login row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ComboBox {
                    id: sessionCombo
                    Layout.fillWidth: true
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    background: Rectangle {
                        radius: 6
                        color: root.bgColor
                        border.color: root.borderColor
                        border.width: 1
                    }
                    contentItem: Text {
                        text: sessionCombo.displayText
                        color: root.fgDim
                        font: sessionCombo.font
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                }

                Button {
                    id: loginBtn
                    implicitWidth: 60
                    implicitHeight: 48
                    background: Rectangle {
                        radius: 6
                        color: loginBtn.down ? root.accent2 : root.accent
                    }
                    contentItem: Text {
                        text: "→"
                        color: root.bgColor
                        font.family: root.fontFamily
                        font.pixelSize: 22
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: submitLogin()
                }
            }

            // Status line
            Text {
                id: statusLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: root.failColor
                font.family: root.fontFamily
                font.pixelSize: 13
                font.italic: true
                text: ""
            }
        }
    }

    // ----- Power buttons (bottom right) -----
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 14

        Repeater {
            model: ListModel {
                ListElement { glyph: ""; action: "suspend" }
                ListElement { glyph: ""; action: "reboot" }
                ListElement { glyph: ""; action: "poweroff" }
            }

            delegate: Rectangle {
                width: 44; height: 44; radius: 22
                color: ma.containsMouse
                       ? root.accent
                       : Qt.rgba(root.panelColor.r, root.panelColor.g, root.panelColor.b, 0.65)
                border.color: root.borderColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: glyph
                    color: ma.containsMouse ? root.bgColor : root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 18
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (action === "suspend")       sddm.suspend()
                        else if (action === "reboot")   sddm.reboot()
                        else if (action === "poweroff") sddm.powerOff()
                    }
                }
            }
        }
    }

    // ----- Helpers -----
    function submitLogin() {
        statusLabel.color = root.fgDim
        statusLabel.text = "authenticating…"
        sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            statusLabel.color = root.accent
            statusLabel.text = "welcome"
        }
        function onLoginFailed() {
            statusLabel.color = root.failColor
            statusLabel.text = "authentication failed"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
