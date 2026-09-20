import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects 1.0
import "."

import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width || 1920
    height: Screen.height || 1080

    // -------------------------------------------------------------------------
    // Responsive Scaling
    // -------------------------------------------------------------------------
    readonly property real scaleFactor: Math.max(0.5, Math.min(width / 1920, height / 1080))
    readonly property real baseUnit: 8 * scaleFactor
    
    // -------------------------------------------------------------------------
    // Theme Constants & Style Tokens
    // -------------------------------------------------------------------------
    readonly property color mPrimary: "#d6d6d6"
    readonly property color mOnPrimary: "#151515"
    readonly property color mSurface: "#151515"
    readonly property color mSurfaceVariant: "#212121"
    readonly property color mOnSurface: "#eeeeee"
    readonly property color mOnSurfaceVariant: "#a0a0a0"
    readonly property color mError: "#b8b8b8"
    readonly property color mOutline:"#3e3e3e"
    
    // Responsive sizes
    readonly property real radiusL: 20 * scaleFactor
    readonly property real fontSizeM: 11 * scaleFactor
    readonly property real fontSizeL: 13 * scaleFactor
    readonly property real fontSizeXL: 16 * scaleFactor
    readonly property real fontSizeXXL: 18 * scaleFactor
    readonly property real fontSizeClock: 42 * scaleFactor

    // Configurable Background
    readonly property string backgroundPath: "background.png"

    // Fonts
    property font fontMain: Qt.font({
        family: "Google Sans",
        pixelSize: 14 * scaleFactor
    })
    
    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    // -------------------------------------------------------------------------
    // Background
    // -------------------------------------------------------------------------
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.backgroundPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        clip: true
        visible: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.6) } // Darker top
            GradientStop { position: 0.4; color: Qt.rgba(0,0,0,0.2) }
            GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.7) } // Darker bottom
        }
    }
    
    // -------------------------------------------------------------------------
    // Top Card: User Info & Time
    // -------------------------------------------------------------------------
    Rectangle {
        id: headerCard
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.12
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: Math.max(400 * scaleFactor, Math.min(parent.width * 0.70, 550 * scaleFactor))
        height: 120 * scaleFactor
        radius: root.radiusL
        color: root.mSurface
        border.color: Qt.rgba(root.mOutline.r, root.mOutline.g, root.mOutline.b, 0.2)
        border.width: 1 * scaleFactor

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: 16 * scaleFactor
            spacing: 32 * scaleFactor

            // -----------------------------------------------------------------
            // Clickable User Info (Avatar + Name) — click to cycle users
            // -----------------------------------------------------------------
            RowLayout {
                id: userInfoRow
                spacing: 32 * scaleFactor
                Layout.alignment: Qt.AlignVCenter

                // Perspective wrapper so the flip looks 3D instead of squashed
                Item {
                    id: avatarFlipWrapper
                    Layout.preferredWidth: 70 * scaleFactor
                    Layout.preferredHeight: 70 * scaleFactor
                    Layout.alignment: Qt.AlignVCenter

                    transform: Rotation {
                        id: flipRotation
                        origin.x: avatarFlipWrapper.width / 2
                        origin.y: avatarFlipWrapper.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: 0
                    }

                    // Avatar - Perfect Circle
                    Item {
                        id: avatarRect
                        anchors.fill: parent

                        // List of all available usernames, gathered from userModel below
                        property var userList: []

                        // Manual override set by clicking; empty means "use default"
                        property string overrideUser: ""

                        property int tryIndex: 0

                        property string primaryUser: userModel.lastUser
                        property string currentIcon: ""
                        property string currentHome: ""
                        property string currentRealName: ""
                        property string firstUserName: ""

                        // Data Extractor
                        Repeater {
                            model: userModel
                            delegate: Item {
                                visible: false

                                Component.onCompleted: {
                                    if (avatarRect.userList.indexOf(model.name) === -1) {
                                        var arr = avatarRect.userList.slice()
                                        arr.push(model.name)
                                        avatarRect.userList = arr
                                    }
                                }

                                // Capture first user name as fallback
                                Binding {
                                    target: avatarRect
                                    property: "firstUserName"
                                    value: model.name
                                    when: index === 0
                                }

                                // Capture details if this matches the user currently displayed
                                Binding {
                                    target: avatarRect
                                    property: "currentIcon"
                                    value: model.icon
                                    when: model.name === avatarRect.displayUser
                                }
                                Binding {
                                    target: avatarRect
                                    property: "currentHome"
                                    value: model.homeDir
                                    when: model.name === avatarRect.displayUser
                                }
                                Binding {
                                    target: avatarRect
                                    property: "currentRealName"
                                    value: model.realName
                                    when: model.name === avatarRect.displayUser
                                }
                            }
                        }

                        // Computed property for whom we are showing.
                        // overrideUser (set by clicking) wins over the SDDM-reported last user.
                        property string displayUser: overrideUser !== "" ? overrideUser : (primaryUser !== "" ? primaryUser : firstUserName)
                        property string displayName: currentRealName !== "" ? currentRealName : (displayUser !== "" ? displayUser : "User")

                        // Reset image fallback index when user changes
                        onDisplayUserChanged: {
                            tryIndex = 0
                        }

                        // Cycle to the next user in userList
                        function cycleUser() {
                            if (userList.length < 2) return
                            var curIdx = userList.indexOf(displayUser)
                            var nextIdx = (curIdx + 1) % userList.length
                            overrideUser = userList[nextIdx]
                            sessionList.currentIndex = sessionModel.lastIndex
                            passwordBox.text = ""
                        }

                        // Get list of icon paths to try
                        property var iconPaths: {
                            var paths = []
                            var u = displayUser

                            if (u) {
                                // 1. Try path from userModel (if any)
                                if (currentIcon && currentIcon !== "") {
                                    var p = currentIcon
                                    if (p.indexOf("://") === -1 && p.charAt(0) === '/')
                                        p = "file://" + p
                                    paths.push(p)
                                }

                                // 2. Try home directory faces
                                if (currentHome) {
                                    paths.push("file://" + currentHome + "/.face.icon")
                                    paths.push("file://" + currentHome + "/.face")
                                }

                                // 3. System paths
                                paths.push("file:///usr/share/sddm/faces/" + u + ".face.icon")
                                paths.push("file:///var/lib/AccountsService/icons/" + u)
                            }

                            // 4. Default fallback
                            paths.push("file:///usr/share/sddm/faces/.face.icon")

                            return paths
                        }

                        // Circular mask for perfect circle
                        Rectangle {
                            id: avatarMask
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }

                        // User avatar image (circular)
                        Image {
                            id: userAvatar
                            anchors.fill: parent
                            source: {
                                if (parent.iconPaths.length === 0) return ""
                                var idx = Math.min(parent.tryIndex, parent.iconPaths.length - 1)
                                return parent.iconPaths[idx]
                            }
                            sourceSize: Qt.size(70 * scaleFactor, 70 * scaleFactor)
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: status === Image.Ready
                            asynchronous: true

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: avatarMask
                            }

                            // Try next path if current one fails
                            onStatusChanged: {
                                if (status === Image.Error && parent.tryIndex < parent.iconPaths.length - 1) {
                                    parent.tryIndex++
                                }
                            }
                        }

                        // Fallback logo if user avatar not available
                        Image {
                            id: fallbackLogo
                            anchors.fill: parent
                            anchors.margins: 8 * scaleFactor
                            source: "logo.svg"
                            sourceSize: Qt.size(70 * scaleFactor, 70 * scaleFactor)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: userAvatar.status !== Image.Ready && userAvatar.status !== Image.Loading

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: avatarMask
                            }
                        }

                        // Circular border — pulses slightly while hovered as a hint it's clickable
                        Rectangle {
                            id: avatarBorder
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.color: userInfoMouseArea.containsMouse ? root.mPrimary : root.mPrimary
                            border.width: (userInfoMouseArea.containsMouse ? 3 : 2) * scaleFactor
                            opacity: userInfoMouseArea.containsMouse ? 1.0 : 0.85

                            Behavior on border.width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }
                }

                // Text Info
                ColumnLayout {
                    id: userTextColumn
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2 * scaleFactor

                    // Small wrapper item lets us fade+slide the two text rows together
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: nameSlideColumn.implicitHeight

                        ColumnLayout {
                            id: nameSlideColumn
                            width: parent.width
                            spacing: 2 * scaleFactor

                            Text {
                                id: welcomeText
                                text: "Welcome back, " + avatarRect.displayName + "!"
                                font.pixelSize: root.fontSizeXXL
                                font.bold: true
                                color: root.mOnSurface
                            }

                            Text {
                                text: Qt.formatDate(new Date(), "dddd, MMMM d")
                                font.pixelSize: root.fontSizeXL
                                color: root.mOnSurfaceVariant
                            }
                        }
                    }

                    // Small hint label, only visible when there's more than one user
                    Text {
                        text: "Click your photo to switch user"
                        font.pixelSize: root.fontSizeM * 0.85
                        color: Qt.rgba(root.mOnSurfaceVariant.r, root.mOnSurfaceVariant.g, root.mOnSurfaceVariant.b, 0.6)
                        visible: avatarRect.userList.length > 1
                    }
                }

                // The actual click target, drawn on top so it captures input
                // for both the avatar and the text next to it.
                MouseArea {
                    id: userInfoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: avatarRect.userList.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: avatarRect.userList.length > 1

                    onClicked: userSwitchAnimation.start()
                }

                // -------------------------------------------------------------
                // The "jelly flip" animation:
                // 1. Avatar rotates out on the Y axis while text fades/slides up
                // 2. Midway through, the underlying user actually changes
                // 3. Avatar rotates back in from the mirrored angle, text fades/slides back
                // -------------------------------------------------------------
                ParallelAnimation {
                    id: userSwitchAnimation

                    SequentialAnimation {
                        NumberAnimation {
                            target: flipRotation
                            property: "angle"
                            from: 0
                            to: 90
                            duration: 220
                            easing.type: Easing.InCubic
                        }
                        ScriptAction { script: avatarRect.cycleUser() }
                        PropertyAction { target: flipRotation; property: "angle"; value: -90 }
                        NumberAnimation {
                            target: flipRotation
                            property: "angle"
                            from: -90
                            to: 0
                            duration: 260
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.6
                        }
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: nameSlideColumn
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 160
                            easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: nameSlideColumn
                            property: "y"
                            from: 0
                            to: -10 * scaleFactor
                            duration: 160
                            easing.type: Easing.InQuad
                        }
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: 220 }
                        PropertyAction { target: nameSlideColumn; property: "y"; value: 10 * scaleFactor }
                        ParallelAnimation {
                            NumberAnimation {
                                target: nameSlideColumn
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 220
                                easing.type: Easing.OutQuad
                            }
                            NumberAnimation {
                                target: nameSlideColumn
                                property: "y"
                                from: 10 * scaleFactor
                                to: 0
                                duration: 220
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    // A quick "pop" scale on the whole avatar for extra juiciness
                    SequentialAnimation {
                        NumberAnimation { target: avatarFlipWrapper; property: "scale"; from: 1.0; to: 0.85; duration: 220; easing.type: Easing.InQuad }
                        NumberAnimation { target: avatarFlipWrapper; property: "scale"; from: 0.85; to: 1.08; duration: 200; easing.type: Easing.OutQuad }
                        NumberAnimation { target: avatarFlipWrapper; property: "scale"; from: 1.08; to: 1.0; duration: 140; easing.type: Easing.OutQuad }
                    }
                }
            }
            
            Item { Layout.fillWidth: true } // Spacer
            
            // Clock
            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                font.pixelSize: root.fontSizeClock
                font.bold: true
                color: root.mOnSurface
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Bottom Card: Password & Controls
    // -------------------------------------------------------------------------
    Rectangle {
        id: bottomCard
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: Math.min(750 * scaleFactor, parent.width * 0.9)
        height: 140 * scaleFactor
        radius: root.radiusL
        color: root.mSurface
        border.color: Qt.rgba(root.mOutline.r, root.mOutline.g, root.mOutline.b, 0.2)
        border.width: 1 * scaleFactor
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20 * scaleFactor
            spacing: 15 * scaleFactor
            
            // Password Field Row
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 50 * scaleFactor
                spacing: 15 * scaleFactor
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.mSurfaceVariant
                    radius: 12 * scaleFactor
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: passwordBox.forceActiveFocus()
                    }

                    Row {
                        id: symbolsWrapper
                        spacing: 4 * scaleFactor
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 15 * scaleFactor

                        Repeater {
                            model: passwordBox.text.length

                            delegate: Rectangle {
                                width: 15 * scaleFactor
                                height: 15 * scaleFactor
                                radius: width / 2
                                color: root.mOnSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Rectangle {
                            width: 2 * scaleFactor
                            height: 14 * scaleFactor
                            color: root.mOnSurface
                            visible: passwordBox.activeFocus
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: passwordBox.activeFocus
                                loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 0; duration: 500 }
                                NumberAnimation { from: 0; to: 1; duration: 500 }
                            }
                        }
                    }
                    
                    TextInput {
                        id: passwordBox
                        anchors.fill: parent
                        anchors.margins: 15 * scaleFactor
                        verticalAlignment: Text.AlignVCenter
                        
                        text: ""
                        echoMode: TextInput.NoEcho
                        visible: false
                        font.pixelSize: 14 * scaleFactor
                        
                        focus: true
                        
                        onAccepted: sddm.login(avatarRect.displayUser, passwordBox.text, sessionList.currentIndex)
                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                sddm.login(avatarRect.displayUser, passwordBox.text, sessionList.currentIndex)
                                event.accepted = true
                            }
                        }
                    }
                    
                    Text {
                        anchors.fill: parent
                        anchors.margins: 15 * scaleFactor
                        verticalAlignment: Text.AlignVCenter
                        text: "Password..."
                        color: Qt.rgba(root.mOnSurfaceVariant.r, root.mOnSurfaceVariant.g, root.mOnSurfaceVariant.b, 0.5)
                        font.pixelSize: 14 * scaleFactor
                        visible: !passwordBox.text && !passwordBox.activeFocus
                    }
                }
                
                // Login Button
                Controls.Button {
                    Layout.preferredWidth: 100 * scaleFactor
                    Layout.fillHeight: true
                    
                    background: Rectangle {
                        color: parent.down ? Qt.darker(root.mPrimary, 1.2) : root.mPrimary
                        radius: 12 * scaleFactor
                    }
                    
                    contentItem: Text {
                        text: "Login"
                        font.pixelSize: 14 * scaleFactor
                        font.bold: true
                        color: root.mOnPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: sddm.login(avatarRect.displayUser, passwordBox.text, sessionList.currentIndex)
                }
            }
            
            // Controls Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * scaleFactor
                
                // Session List
                Controls.ComboBox {
                   id: sessionList
                   model: sessionModel
                   textRole: "name"
                   currentIndex: sessionModel.lastIndex
                   
                   Layout.preferredWidth: 200 * scaleFactor
                   Layout.preferredHeight: 36 * scaleFactor

                   onActivated: passwordBox.forceActiveFocus()
                   
                   delegate: Controls.ItemDelegate {
                       width: parent.width
                       text: model.name || ""
                       highlighted: sessionList.highlightedIndex === index
                       contentItem: Text {
                           text: parent.text
                           color: root.mOnSurface
                           font.pixelSize: root.fontSizeM
                           verticalAlignment: Text.AlignVCenter
                       }
                       background: Rectangle {
                           color: parent.highlighted ? root.mSurfaceVariant : "transparent"
                       }
                   }
                   
                   background: Rectangle {
                       color: root.mSurfaceVariant
                       radius: 8 * scaleFactor
                   }
                   
                   contentItem: Text {
                       leftPadding: 10 * scaleFactor
                       text: sessionList.displayText || ""
                       color: root.mOnSurface
                       font.pixelSize: root.fontSizeM
                       verticalAlignment: Text.AlignVCenter
                   }

                   popup: Controls.Popup {
                       y: sessionList.height - 1
                       width: sessionList.width
                       implicitHeight: contentItem.implicitHeight
                       padding: 1 * scaleFactor
                       onClosed: passwordBox.forceActiveFocus()
                       contentItem: ListView {
                           clip: true
                           implicitHeight: contentHeight
                           model: sessionList.popup.visible ? sessionList.delegateModel : null
                           currentIndex: sessionList.highlightedIndex
                           Controls.ScrollIndicator.vertical: Controls.ScrollIndicator { }
                       }

                       background: Rectangle {
                           border.color: root.mOutline
                           color: root.mSurface
                           radius: 4 * scaleFactor
                       }
                   }
               }
                
                Item { Layout.fillWidth: true } // Spacer
                
                // Power Buttons
                Repeater {
                    model: [
                        { text: "Suspend", type: "suspend" },
                        { text: "Reboot", type: "reboot" },
                        { text: "Shutdown", type: "shutdown" }
                    ]
                    
                    delegate: Controls.Button {
                        text: modelData.text
                        Layout.preferredHeight: 36 * scaleFactor
                        Layout.preferredWidth: 100 * scaleFactor
                        
                        background: Rectangle {
                            color: parent.down ? Qt.darker(root.mSurfaceVariant, 1.2) : root.mSurfaceVariant
                            radius: 8 * scaleFactor
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: root.fontSizeM
                            color: root.mOnSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            if (modelData.type === "suspend") {
                                sddm.suspend()
                            } else if (modelData.type === "reboot") {
                                sddm.reboot()
                            } else if (modelData.type === "shutdown") {
                                sddm.powerOff()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Error Message
    // -------------------------------------------------------------------------
     Rectangle {
        width: errorMessage.implicitWidth + 40 * scaleFactor
        height: 50 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomCard.top
        anchors.bottomMargin: 20 * scaleFactor
        radius: root.radiusL
        color: root.mError
        visible: errorMessage.text !== ""
        
        Text {
            id: errorMessage
            anchors.centerIn: parent
            text: "" // Set by signal
            color: "#1e1418" // mOnError
            font.pixelSize: root.fontSizeM
            font.bold: true
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordBox.text = ""
            errorMessage.text = "Authentication failed"
        }
    }
}
