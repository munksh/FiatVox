import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * Instrumentet. En infattad urtavla med prickarna i ett försänkt spår,
 * bokstaven i antikva, och frekvensen i sin egen lilla brunn.
 *
 * Ingenting på tavlan är en kontroll. Ett tryck var som helst på ramen ljuder
 * stämtonen; allt annat bor i pull-down-menyn.
 */
Page {
    id: page
    allowedOrientations: Orientation.Portrait

    // ---- konfiguration ---------------------------------------------------
    // Sju prickar över +/- 25 cent: varje prick är värd ~8,3 cent.
    readonly property int dotCount: 7
    readonly property real centsRange: 25.0
    readonly property int centreDot: (dotCount - 1) / 2
    readonly property real centsPerDot: centsRange / centreDot

    // Om U+266F inte renderas på enhetens typsnitt, ändra till "#".
    readonly property string sharpGlyph: "♯"

    readonly property var noteLetters: ["C", "C", "D", "D", "E", "F", "F", "G", "G", "A", "A", "B"]
    readonly property var noteSharp:   [false, true, false, true, false, false, true, false, true, false, true, false]

    readonly property real bezelPad: Theme.paddingMedium

    // ---- levande tillstånd -----------------------------------------------
    readonly property int litDot: {
        if (!tuner.hasPitch)
            return -1
        var i = Math.round(tuner.cents / centsPerDot) + centreDot
        return Math.max(0, Math.min(dotCount - 1, i))
    }

    function dotColour(index) {
        if (index !== litDot)
            return FiatVoxTheme.dotIdle
        var distance = Math.abs(index - centreDot)
        if (distance === 0) return FiatVoxTheme.inTune
        if (distance === 1) return FiatVoxTheme.nearly
        return FiatVoxTheme.wrong
    }

    // ---- stämtonen -------------------------------------------------------
    // Vad tonen på skärmen *ska* vara, inte vad som uppmättes: en stämton är
    // målet, inte misstaget. Utan detekterad ton ljuder ett rent A på aktuell
    // referens — en stämgaffel i fickan.
    function toneFrequency() {
        if (!tuner.hasPitch)
            return tuner.referenceA

        var midi = (tuner.octave + 1) * 12 + tuner.noteIndex
        var hz = tuner.referenceA * Math.pow(2, (midi - 69) / 12)

        // En telefonhögtalare klarar inte en pedalton på 33 Hz. Vik in tonen i
        // det område den faktiskt kan ljuda; tonklassen är densamma.
        while (hz < 110.0) hz *= 2.0
        while (hz >= 1760.0) hz /= 2.0
        return hz
    }

    // ---- bakgrund --------------------------------------------------------
    // Målas bara i Fiat colours. Under en ambience finns inget här, och
    // bakgrundsbilden lyser igenom.
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
        contentHeight: parent.height

        PullDownMenu {
                    backgroundColor: FiatVoxTheme.surface
                    highlightColor: FiatVoxTheme.accent

                    MenuItem {
                        text: FiatVoxTheme.ambient ? "Fiat colours" : "Follow ambience"
                        color: FiatVoxTheme.primaryText
                        onClicked: FiatVoxTheme.setAmbient(!FiatVoxTheme.ambient)
                    }

                    MenuItem {
                        text: "Reference pitch — A" + "₄" + " " + Math.round(tuner.referenceA) + " Hz"
                        color: FiatVoxTheme.primaryText
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("ReferencePage.qml"))
                    }

                    MenuItem {
                        text: qsTr("About")
                        color: FiatVoxTheme.primaryText
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
                    }
                }

        // ---- ordmärket ---------------------------------------------------
        Item {
            id: wordmark
            width: parent.width
            height: Theme.itemSizeLarge
            anchors.top: parent.top

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: "fiat vox"
                color: FiatVoxTheme.primaryText
                font.pixelSize: Theme.fontSizeLarge
                font.family: FiatVoxTheme.serif
                font.italic: true
            }
        }

        // ---- ramen -------------------------------------------------------
        Rectangle {
            id: bezel
            x: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin * 2
            height: inner.height + page.bezelPad * 2
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Theme.paddingLarge
            radius: FiatVoxTheme.cardRadius
            color: FiatVoxTheme.card
            border.color: FiatVoxTheme.cardBorder
            border.width: FiatVoxTheme.cardBorderWidth

            // Den inre hårlinjen. Det är den som gör ett kort till en urtavla.
            Rectangle {
                id: inner
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: page.bezelPad
                }
                height: face.height + Theme.paddingLarge * 3
                color: "transparent"
                radius: bezel.radius - page.bezelPad
                border.color: FiatVoxTheme.innerBorder
                border.width: 1

                Column {
                    id: face
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: Theme.paddingLarge

                    // ---- det försänkta prickspåret -------------------------
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: dotRow.width + Theme.paddingLarge * 2
                        height: dotRow.height + Theme.paddingSmall * 2
                        radius: height / 2
                        color: FiatVoxTheme.recessFill
                        border.color: FiatVoxTheme.recessBorder
                        border.width: 1

                        Row {
                            id: dotRow
                            anchors.centerIn: parent
                            spacing: Theme.paddingMedium
                            readonly property real dotSize: Theme.itemSizeExtraSmall / 4

                            Repeater {
                                model: page.dotCount

                                Item {
                                    width: dotRow.dotSize
                                    height: dotRow.dotSize
                                    anchors.verticalCenter: parent.verticalCenter

                                    // mjuk gloria bakom den tända pricken
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * 2.4
                                        height: width
                                        radius: width / 2
                                        color: page.dotColour(index)
                                        opacity: index === page.litDot ? 0.18 : 0
                                        Behavior on opacity { NumberAnimation { duration: 180 } }
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * (index === page.litDot ? 1.0 : 0.62)
                                        height: width
                                        radius: width / 2
                                        color: page.dotColour(index)
                                        // Mittpricken syns även i tystnad, så
                                        // instrumentet aldrig ser avstängt ut.
                                        opacity: index === page.litDot
                                                 ? 1.0
                                                 : (index === page.centreDot ? 1.0 : 0.7)

                                        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                        Behavior on color { ColorAnimation { duration: 160 } }
                                        Behavior on opacity { NumberAnimation { duration: 160 } }
                                    }
                                }
                            }
                        }
                    }

                    // ---- bokstaven -----------------------------------------
                    // Centrerad på sidan för egen del; korset hänger utanför
                    // dess högerkant, så C:et i C♯ står där ett rent C står.
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: letter.width
                        height: letter.height * 0.80
                        opacity: tuner.hasPitch ? 1.0 : 0.3
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        // Vilomärket: ritat, inte ett tecken, så det är runt
                        // på varje typsnitt.
                        Rectangle {
                            anchors.centerIn: parent
                            visible: !tuner.hasPitch
                            width: letter.font.pixelSize * 0.13
                            height: width
                            radius: width / 2
                            color: FiatVoxTheme.primaryText
                        }

                        Text {
                            id: letter
                            text: tuner.hasPitch ? page.noteLetters[tuner.noteIndex] : " "
                            color: tone.playing ? FiatVoxTheme.accent : FiatVoxTheme.primaryText
                            font.pixelSize: Math.round(page.height * 0.22)
                            font.family: FiatVoxTheme.serif
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Text {
                            text: page.sharpGlyph
                            color: Theme.rgba(FiatVoxTheme.primaryText, 0.7)
                            visible: tuner.hasPitch && page.noteSharp[tuner.noteIndex]
                            font.pixelSize: Math.round(letter.font.pixelSize * 0.34)
                            font.family: FiatVoxTheme.serif
                            anchors.left: letter.right
                            anchors.leftMargin: -letter.font.pixelSize * 0.03
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -letter.font.pixelSize * 0.24
                        }
                    }

                    // ---- brunnen -------------------------------------------
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: readout.width + Theme.paddingLarge * 3
                        height: readout.height + Theme.paddingSmall * 2
                        radius: Theme.paddingMedium
                        color: FiatVoxTheme.recessFill
                        border.color: FiatVoxTheme.recessBorder
                        border.width: 1

                        Column {
                            id: readout
                            anchors.centerIn: parent
                            spacing: Theme.paddingSmall / 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tuner.hasPitch ? tuner.frequency.toFixed(1) + " Hz" : "—"
                                color: FiatVoxTheme.secondaryText
                                font.pixelSize: Theme.fontSizeLarge
                                font.family: "monospace"
                                opacity: tuner.hasPitch ? 1.0 : 0.5
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    if (!tuner.hasPitch)
                                        return " "
                                    var c = Math.round(tuner.cents)
                                    return (c > 0 ? "+" : "") + c + " ¢"
                                }
                                color: page.litDot === page.centreDot
                                       ? FiatVoxTheme.inTune
                                       : FiatVoxTheme.secondaryText
                                font.pixelSize: Theme.fontSizeExtraSmall
                                font.family: "monospace"
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }

                    // ---- ingraverad referens, och ärlig diagnostik ---------
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        // En död mikrofon och ett tyst rum ser likadana ut på
                        // tavlan. När ingen byte någonsin kommit, säg det.
                        text: {
                            if (tuner.errorString !== "")
                                return tuner.errorString.toUpperCase()
                            if (tone.playing)
                                return "SOUNDING " + tone.frequency.toFixed(1) + " Hz"
                            if (tuner.running && !tuner.receivingAudio)
                                return "WAITING FOR MIC"
                            return "A" + "₄" + "  " + Math.round(tuner.referenceA)
                        }
                        color: {
                            if (tuner.errorString !== "") return FiatVoxTheme.wrong
                            if (tone.playing) return FiatVoxTheme.accent
                            if (tuner.running && !tuner.receivingAudio) return FiatVoxTheme.nearly
                            return Theme.rgba(FiatVoxTheme.primaryText, 0.45)
                        }
                        font.pixelSize: Theme.fontSizeTiny
                        font.weight: Font.Bold
                        font.letterSpacing: Theme.pixelRatio * 3
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            // ---- ingångsnivå, en hårlinje inne i ramen -------------------
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(2, parent.width * 0.45 * tuner.level)
                height: 2
                radius: 1
                color: Theme.rgba(FiatVoxTheme.accent, 0.6)
                Behavior on width { NumberAnimation { duration: 90 } }
            }

            // ---- tryck på instrumentet för att ljuda tonen ---------------
            // Osynlig med flit. Inget ritas som ser ut som en knapp.
            MouseArea {
                anchors.fill: parent
                onClicked: tone.toggle(page.toneFrequency())
            }
        }
    }
}
