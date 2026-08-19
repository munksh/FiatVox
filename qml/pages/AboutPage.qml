import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

// Who made this, what it does with your data, and where it came from.
//
// Four questions in that order, and nothing else. No changelog, no donation
// button, two links. Same form as Fiat Mos on purpose -- the family should
// answer the same questions in the same order.
//
// The lead is three examples rather than a summary. "A chromatic tuner that
// listens continuously" is accurate and says nothing; a drifting pipe, a new
// string and a held vowel say the same thing and can be heard.
//
// The accuracy sentence sits in the lead rather than in a section of its own.
// It is the second claim the app makes about itself, after privacy, and both
// are written flat: a number you can check beats an adjective.

Page {
    id: page

    // Fiat colours paint their own paper. Under an ambience there is no
    // background at all -- the wallpaper is the background.
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
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHead {
                title: qsTr("about")
                subtitle: "fiat vox"
            }

            // -- What it is -----------------------------------------------

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatVoxTheme.serif
                color: FiatVoxTheme.primaryText
                text: qsTr("A pipe that has drifted since the last cold snap. A string you put on this morning. A vowel held until it stops wavering.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatVoxTheme.secondaryText
                text: qsTr("One letter, seven dots and the frequency. The dots span a quarter-tone either side of true, so each one is worth about eight cents: green in the middle, amber beside it, red beyond. There is nothing to press and nothing to start — it listens the whole time it is open. Tap the face and it will sound the note back to you.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatVoxTheme.secondaryText
                text: qsTr("It hears from the low C of a pedal division up past the top of a piccolo, and against a clean tone it lands within a cent — a fifth of one dot. Where it cannot be certain it shows nothing rather than a guess.")
            }

            // -- The name --------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The name")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatVoxTheme.secondaryText
                textFormat: Text.StyledText
                linkColor: FiatVoxTheme.accent
                text: qsTr("<b>fiat</b> — Latin, <i>let there be</i>. From <i>fiat lux</i> in the Vulgate: let there be light, and there was light. The first app took the phrase. The rest of the family kept the verb.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatVoxTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("<b>vox</b> — Latin, <i>voice</i>. The word behind <i>vox populi</i>, and behind the <i>Vox Humana</i>, the organ stop built to imitate a singer. Everything this app measures is something making a voice.")
            }

            // -- The motto -------------------------------------------------
            //
            // It stands on its own. It does NOT explain the icon -- the icon is
            // a tuning fork, and there is no arithmetic in it. Two good things
            // next to each other is enough; a connection asserted where none
            // exists is worse than none claimed.

            Item { width: 1; height: Theme.paddingMedium }

            Rectangle {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                height: mottoColumn.height + Theme.paddingLarge * 2
                radius: FiatVoxTheme.cardRadius
                color: FiatVoxTheme.card
                border.color: FiatVoxTheme.cardBorder
                border.width: FiatVoxTheme.cardBorderWidth

                Column {
                    id: mottoColumn
                    anchors.centerIn: parent
                    width: parent.width - Theme.paddingLarge * 2
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: FiatVoxTheme.serif
                        font.italic: true
                        color: FiatVoxTheme.primaryText
                        text: "Musica est exercitium arithmeticae\noccultum nescientis se numerare animi"
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatVoxTheme.secondaryText
                        text: qsTr("Music is a hidden arithmetic exercise of a soul that does not know it is counting.")
                    }

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeTiny
                        color: FiatVoxTheme.secondaryText
                        text: "Leibniz, 1712"
                    }
                }
            }

            // -- Privacy ---------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Your data")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatVoxTheme.secondaryText
                text: qsTr("Fiat Vox asks for one permission — the microphone — and it is the whole app. Sound goes from the microphone into the pitch detector and nowhere else. Nothing is recorded, nothing is written to disk, and there is no network access to send it over.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatVoxTheme.secondaryText
                text: qsTr("The only thing it remembers between sessions is the reference pitch and whether you prefer Fiat colours. Two numbers. Close the app and everything it heard is gone.")
            }

            // -- Who ---------------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Made by")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatVoxTheme.serif
                color: FiatVoxTheme.primaryText
                text: "Munkstolen"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatVoxTheme.secondaryText
                text: "Caesar Prometheus Ivarsson"
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatVoxTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://munkstolen.se")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatVoxTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "munkstolen.se"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatVoxTheme.secondaryText
                        text: qsTr("Everything else I make")
                    }
                }
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatVoxTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://github.com/munksh/FiatVox")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatVoxTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "github.com/munksh/FiatVox"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatVoxTheme.secondaryText
                        text: qsTr("Source and issues · MIT licence")
                    }
                }
            }

            // -- The family ---------------------------------------------------
            //
            // Every name translates itself, and the translation explains the
            // app. That is worth more than a tagline.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The Fiat family")
            }

            Repeater {
                model: [
                    { name: "fiat lux", what: qsTr("let there be light — a light meter for film") },
                    { name: "fiat vox", what: qsTr("let there be voice — this one") },
                    { name: "fiat cor", what: qsTr("let there be heart — a metronome, after the first one anybody owns") },
                    { name: "fiat mos", what: qsTr("let there be habit — a habit tracker") }
                ]

                Column {
                    x: Theme.horizontalPageMargin
                    width: content.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: FiatVoxTheme.serif
                        color: FiatVoxTheme.primaryText
                        text: modelData.name
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatVoxTheme.secondaryText
                        text: modelData.what
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeTiny
                color: FiatVoxTheme.secondaryText
                text: qsTr("Four instruments that measure something you would otherwise guess at. They share a look, a palette and a stubbornness about staying on your own phone.")
            }

            // -- Version ---------------------------------------------------
            //
            // Last, because it is support and not identity. The number comes
            // from the rpm spec by way of qmake, so it is the one the package
            // was actually built with rather than one written down twice.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Version")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeSmall
                color: FiatVoxTheme.primaryText
                text: typeof appVersion !== "undefined" ? appVersion : qsTr("unknown")
            }

            // -- Colophon --------------------------------------------------
            //
            // A printer's mark at the end of a book: a short rule, the mark,
            // the wordmark. Nothing here is tappable -- the links are up under
            // "made by". This is the signature, not a button.

            Item { width: 1; height: Theme.itemSizeExtraSmall }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatVoxTheme.innerBorder
            }

            Item { width: 1; height: Theme.paddingLarge }

            MunkstolenMark {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeMedium
                frame: "ring"
                color: FiatVoxTheme.makerMark
            }

            Item { width: 1; height: Theme.paddingSmall }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "munkstolen"
                font.pixelSize: Theme.fontSizeSmall
                font.family: FiatVoxTheme.serif
                font.italic: true
                color: FiatVoxTheme.makerMark
            }
        }

        VerticalScrollDecorator { }
    }
}
