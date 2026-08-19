import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * Den enda inställningen. Pills på ett kort — tryck på en så tillämpas den
 * och sidan poppar tillbaka. Ingen OK-knapp, inget att bekräfta.
 */
Page {
    id: page
    allowedOrientations: Orientation.Portrait

    readonly property var references: [415, 430, 432, 435, 438, 440, 441, 442, 443]

    // Varför just dessa nio, för den som undrar sen.
    readonly property var notes: ({
        415: "Barock",
        430: "Wienklassicism",
        432: "Verdi",
        435: "Gammal fransk",
        438: "1800-tal",
        440: "Modern standard",
        441: "Orkester",
        442: "Orkester",
        443: "Orkester"
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
                    text: "referenston"
                    color: FiatVoxTheme.primaryText
                    font.pixelSize: Theme.fontSizeLarge
                    font.family: FiatVoxTheme.serif
                    font.italic: true
                }
            }

            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                height: flow.height + Theme.paddingLarge * 2
                radius: FiatVoxTheme.cardRadius
                color: FiatVoxTheme.card
                border.color: FiatVoxTheme.cardBorder
                border.width: FiatVoxTheme.cardBorderWidth

                Flow {
                    id: flow
                    anchors.centerIn: parent
                    width: parent.width - Theme.paddingLarge * 2
                    spacing: Theme.paddingSmall

                    Repeater {
                        model: page.references

                        Rectangle {
                            id: pill
                            readonly property bool selected:
                                Math.round(tuner.referenceA) === modelData

                            radius: height / 2
                            color: selected ? FiatVoxTheme.pillFillActive : FiatVoxTheme.pillFill
                            border.color: selected ? FiatVoxTheme.pillBorderActive : FiatVoxTheme.pillBorder
                            border.width: 1
                            width: pillLabel.width + Theme.paddingLarge * 2
                            height: pillLabel.height + Theme.paddingMedium

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: pillLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: pill.selected ? FiatVoxTheme.accent : FiatVoxTheme.primaryText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    tuner.referenceA = modelData
                                    pageStack.pop()
                                }
                            }
                        }
                    }
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
