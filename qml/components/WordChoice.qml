import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// One choice out of a few, written as words: "415  430  432  440".
// The chosen word is in the accent with a bar under it, the rest are grey.

Flow {
    id: root

    // [{ label: "box", value: ... }, ...]
    property var choices: []
    property var current
    signal chosen(var value)

    spacing: Theme.paddingLarge

    Repeater {
        model: root.choices
        delegate: MouseArea {
            id: word
            readonly property bool on: modelData.value === root.current
            width: wordLabel.implicitWidth + Theme.paddingSmall * 2
            height: Theme.itemSizeExtraSmall
            onClicked: root.chosen(modelData.value)

            Rectangle {
                anchors.fill: parent
                radius: Theme.paddingSmall
                color: FiatVoxTheme.highlightWash
                visible: word.pressed && word.containsMouse
            }

            Label {
                id: wordLabel
                anchors.centerIn: parent
                text: modelData.label
                color: word.on ? FiatVoxTheme.accent : FiatVoxTheme.secondaryText
                font.pixelSize: Theme.fontSizeSmall
                font.bold: word.on
            }

            Rectangle {
                visible: word.on
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: wordLabel.bottom
                anchors.topMargin: Theme.paddingSmall / 2
                width: wordLabel.width
                height: Math.max(2, Theme.paddingSmall / 2)
                color: FiatVoxTheme.accent
            }
        }
    }
}
