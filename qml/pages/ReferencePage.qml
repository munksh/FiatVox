import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import ".."

Page {
    id: page
    allowedOrientations: Orientation.Portrait

    readonly property var references: [415, 430, 432, 435, 438, 440, 441, 442, 443]

    readonly property var notes: ({
            415: "Baroque",
            430: "Classical",
            432: "Verdi",
            435: "Old French",
            438: "19th century",
            440: "Modern standard",
            441: "Orchestral",
            442: "Orchestral",
            443: "Orchestral"
        })

    Rectangle {
        anchors.fill: parent
        visible: !FiatVoxTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatVoxTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatVoxTheme.backgroundLow }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge * 2

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            Item {
                width: parent.width
                height: Theme.itemSizeLarge

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    text: "reference tone"
                    color: FiatVoxTheme.primaryText
                    font.pixelSize: Theme.fontSizeLarge
                    font.family: FiatVoxTheme.serif
                    font.italic: true
                }
            }

            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                height: choice.height + Theme.paddingLarge * 2
                radius: FiatVoxTheme.cardRadius
                color: FiatVoxTheme.card
                border.color: FiatVoxTheme.cardBorder
                border.width: FiatVoxTheme.cardBorderWidth

                WordChoice {
                    id: choice
                    anchors.centerIn: parent
                    width: parent.width - Theme.paddingLarge * 2
                    choices: page.references.map(function (hz) { return { label: String(hz), value: hz } })
                    current: Math.round(tuner.referenceA)
                    onChosen: tuner.referenceA = value
                }
            }

            Text {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                color: FiatVoxTheme.secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "A" + "₄" + " = " + Math.round(tuner.referenceA) + " Hz · "
                      + (page.notes[Math.round(tuner.referenceA)] || "")
            }
        }
    }
}
