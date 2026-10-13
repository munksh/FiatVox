import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import ".."

Page {
    id: page
    allowedOrientations: Orientation.Portrait

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
                    text: "note names"
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
                    choices: Notation.systems
                    current: Notation.system
                    onChosen: Notation.setSystem(value)
                }
            }

            Text {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                color: FiatVoxTheme.secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                text: Notation.scale()
            }
        }
    }
}
