import "root:/"
import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    required property var bar
    property bool borderless: Config.options.bar.borderless
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / Config.options.bar.workspaces.shown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int baseWorkspaceButtonWidth: 26
    property real workspaceIconSize: baseWorkspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: baseWorkspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (monitor.activeWorkspace?.id - 1) % Config.options.bar.workspaces.shown
    property int maxIconsPerWorkspace: 4 //

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: Config.options.bar.workspaces.shown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * Config.options.bar.workspaces.shown + i + 1);
        })
    }

    // Initialize workspaceOccupied when the component is created
    Component.onCompleted: updateWorkspaceOccupied()

    // Listen for changes in Hyprland.workspaces.values
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`workspace r-1`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            } 
        }
    }

    // Workspaces - background
    RowLayout {
        id: rowLayout
        z: 1

        spacing: 0
        anchors.fill: parent
        implicitHeight: Appearance.sizes.barHeight

        Repeater {
            model: Config.options.bar.workspaces.shown

            Rectangle {
                z: 1
                property var workspaceWindows: {
                    const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id === workspaceGroup * Config.options.bar.workspaces.shown + index + 1)
                    const uniqueApps = []
                    const seenClasses = new Set()
                    
                    for (const win of windowsInThisWorkspace) {
                        if (!seenClasses.has(win.class) && uniqueApps.length < maxIconsPerWorkspace) {
                            uniqueApps.push(win)
                            seenClasses.add(win.class)
                        }
                    }
                    return uniqueApps
                }
                property int dynamicWidth: baseWorkspaceButtonWidth + (workspaceWindows.length > 0 ? (workspaceWindows.length - 1) * (baseWorkspaceButtonWidth - 4) : 0)
                implicitWidth: dynamicWidth
                implicitHeight: baseWorkspaceButtonWidth
                
                Behavior on dynamicWidth {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                radius: Appearance.rounding.full
                property var leftOccupied: (workspaceOccupied[index-1] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index))
                property var rightOccupied: (workspaceOccupied[index+1] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index+2))
                property var radiusLeft: leftOccupied ? 0 : Appearance.rounding.full
                property var radiusRight: rightOccupied ? 0 : Appearance.rounding.full

                topLeftRadius: radiusLeft
                bottomLeftRadius: radiusLeft
                topRightRadius: radiusRight
                bottomRightRadius: radiusRight
                
                color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
                opacity: (workspaceOccupied[index] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index+1)) ? 1 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on radiusLeft {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Behavior on radiusRight {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

            }

        }

    }

    // Active workspace
    Rectangle {
        z: 2
        // Make active ws indicator, which has a brighter color, smaller to look like it is of the same size as ws occupied highlight
        property real activeWorkspaceMargin: 2
        implicitHeight: workspaceButtonWidth - activeWorkspaceMargin * 2
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary
        anchors.verticalCenter: parent.verticalCenter

        property real idx1: workspaceIndexInGroup
        property real idx2: workspaceIndexInGroup
        property real dynamicX: {
            let x = 0
            for (let i = 0; i < Math.min(idx1, idx2); i++) {
                const wsIndex = i
                const windowsInWs = HyprlandData.windowList.filter(w => w.workspace.id === workspaceGroup * Config.options.bar.workspaces.shown + wsIndex + 1)
                const uniqueApps = new Set(windowsInWs.map(w => w.class)).size
                const clampedApps = Math.min(uniqueApps, maxIconsPerWorkspace)
                x += baseWorkspaceButtonWidth + (clampedApps > 0 ? (clampedApps - 1) * (baseWorkspaceButtonWidth - 4) : 0)
            }
            return x
        }
        property real dynamicWidth: {
            const windowsInWs = HyprlandData.windowList.filter(w => w.workspace.id === monitor.activeWorkspace?.id)
            const uniqueApps = new Set(windowsInWs.map(w => w.class)).size
            const clampedApps = Math.min(uniqueApps, maxIconsPerWorkspace)
            return baseWorkspaceButtonWidth + (clampedApps > 0 ? (clampedApps - 1) * (baseWorkspaceButtonWidth - 4) : 0)
        }
        x: dynamicX + activeWorkspaceMargin
        implicitWidth: dynamicWidth - activeWorkspaceMargin * 2
        
        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on dynamicX {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on dynamicWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Behavior on activeWorkspaceMargin {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on idx1 { // Leading anim
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutSine
            }
        }
        Behavior on idx2 { // Following anim
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutSine
            }
        }
    }

    // Workspaces - numbers
    RowLayout {
        id: rowLayoutNumbers
        z: 3

        spacing: 0
        anchors.fill: parent
        implicitHeight: Appearance.sizes.barHeight

        Repeater {
            model: Config.options.bar.workspaces.shown

            Button {
                id: button
                property int workspaceValue: workspaceGroup * Config.options.bar.workspaces.shown + index + 1
                property var workspaceWindows: {
                    const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceValue)
                    const uniqueApps = []
                    const seenClasses = new Set()
                    
                    for (const win of windowsInThisWorkspace) {
                        if (!seenClasses.has(win.class) && uniqueApps.length < maxIconsPerWorkspace) {
                            uniqueApps.push(win)
                            seenClasses.add(win.class)
                        }
                    }
                    return uniqueApps
                }
                property int dynamicWidth: baseWorkspaceButtonWidth + (workspaceWindows.length > 0 ? (workspaceWindows.length - 1) * (baseWorkspaceButtonWidth - 4) : 0)
                Layout.fillHeight: true
                onPressed: Hyprland.dispatch(`workspace ${workspaceValue}`)
                width: dynamicWidth
                
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on dynamicWidth {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                
                background: Item {
                    id: workspaceButtonBackground
                    implicitWidth: button.dynamicWidth
                    implicitHeight: baseWorkspaceButtonWidth
                    
                    property var workspaceWindows: button.workspaceWindows
                    property var biggestWindow: workspaceWindows.length > 0 ? workspaceWindows[0] : null
                    
                    Behavior on implicitWidth {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    StyledText { // Workspace number text
                        opacity: GlobalStates.workspaceShowNumbers
                            || ((Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !workspaceButtonBackground.biggestWindow || GlobalStates.workspaceShowNumbers))
                            || (GlobalStates.workspaceShowNumbers && !Config.options?.bar.workspaces.showAppIcons)
                            )  ? 1 : 0
                        z: 3

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                        text: `${button.workspaceValue}`
                        elide: Text.ElideRight
                        color: (monitor.activeWorkspace?.id == button.workspaceValue) ? 
                            Appearance.m3colors.m3onPrimary : 
                            (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    
                    Rectangle { // Dot instead of ws number
                        id: wsDot
                        opacity: (Config.options?.bar.workspaces.alwaysShowNumbers
                            || GlobalStates.workspaceShowNumbers
                            || (Config.options?.bar.workspaces.showAppIcons && workspaceButtonBackground.biggestWindow)
                            ) ? 0 : 1
                        visible: opacity > 0
                        anchors.centerIn: parent
                        width: baseWorkspaceButtonWidth * 0.18
                        height: width
                        radius: width / 2
                        color: (monitor.activeWorkspace?.id == button.workspaceValue) ? 
                            Appearance.m3colors.m3onPrimary : 
                            (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    
                    // Multiple app icons laid out horizontally
                    Row {
                        id: iconRow
                        anchors.centerIn: parent
                        spacing: 2
                        opacity: !Config.options?.bar.workspaces.showAppIcons ? 0 :
                            (workspaceButtonBackground.workspaceWindows.length > 0 && !GlobalStates.workspaceShowNumbers && Config.options?.bar.workspaces.showAppIcons) ? 
                            1 : workspaceButtonBackground.workspaceWindows.length > 0 ? workspaceIconOpacityShrinked : 0
                        visible: opacity > 0
                        
                        Repeater {
                            model: workspaceButtonBackground.workspaceWindows
                            
                            Item {
                                width: (!GlobalStates.workspaceShowNumbers && Config.options?.bar.workspaces.showAppIcons) ? 
                                    workspaceIconSize : workspaceIconSizeShrinked
                                height: width
                                
                                // Smooth entry/exit animation for icons
                                scale: 1.0
                                opacity: 1.0
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutBack
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                
                                Component.onCompleted: {
                                    scale = 0.0
                                    opacity = 0.0
                                    scaleAnimation.start()
                                    opacityAnimation.start()
                                }
                                
                                NumberAnimation on scale {
                                    id: scaleAnimation
                                    to: 1.0
                                    duration: 200
                                    easing.type: Easing.OutBack
                                    running: false
                                }
                                
                                NumberAnimation on opacity {
                                    id: opacityAnimation
                                    to: 1.0
                                    duration: 200
                                    easing.type: Easing.OutQuad
                                    running: false
                                }
                                
                                IconImage {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: Quickshell.iconPath(AppSearch.guessIcon(modelData?.class), "image-missing")
                                    
                                    Behavior on opacity {
                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                    }
                                }
                                
                                Loader {
                                    active: Config.options.bar.workspaces.monochromeIcons
                                    anchors.fill: appIcon
                                    sourceComponent: Item {
                                        Desaturate {
                                            id: desaturatedIcon
                                            visible: false // There's already color overlay
                                            anchors.fill: parent
                                            source: appIcon
                                            desaturation: 0
                                        }
                                        ColorOverlay {
                                            anchors.fill: desaturatedIcon
                                            source: desaturatedIcon
                                            color: ColorUtils.transparentize(wsDot.color, 0.6)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}
