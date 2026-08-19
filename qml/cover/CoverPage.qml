import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * Covern fortsätter stämma. Ställ telefonen på notstället så funkar den ändå.
 */
CoverBackground {
    id: cover

    readonly property int dotCount: 7
    readonly property real centsRange: 25.0
    readonly property int centreDot: (dotCount - 1) / 2
    readonly property real centsPerDot: centsRange / centreDot
    readonly property string sharpGlyph: "♯"
    readonly property var noteLetters: ["C", "C", "D", "D", "E", "F", "F", "G", "G", "A", "A", "B"]
    readonly property var noteSharp:   [false, true, false, true, false, false, true, false, true, false, true, false]

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

    // Målas bara i Fiat colours; annars äger ambiencen covern.
    Rectangle {
        anchors.fill: parent
        visible: !FiatVoxTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatVoxTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatVoxTheme.backgroundLow }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.paddingMedium

        // det försänkta spåret, i miniatyr
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: coverDots.width + Theme.paddingMedium * 2
            height: coverDots.height + Theme.paddingSmall
            radius: height / 2
            color: FiatVoxTheme.recessFill
            border.color: FiatVoxTheme.recessBorder
            border.width: 1

            Row {
                id: coverDots
                anchors.centerIn: parent
                spacing: Theme.paddingSmall
                readonly property real dotSize: Theme.paddingMedium * 0.7

                Repeater {
                    model: cover.dotCount
                    Rectangle {
                        width: coverDots.dotSize
                        height: width
                        radius: width / 2
                        color: cover.dotColour(index)
                        opacity: index === cover.litDot || index === cover.centreDot ? 1.0 : 0.7
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                    }
                }
            }
        }

        // Bokstaven centrerad på sig själv; korset hänger utanför högerkanten.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: coverLetter.width
            height: coverLetter.height
            opacity: tuner.hasPitch ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Rectangle {
                anchors.centerIn: parent
                visible: !tuner.hasPitch
                width: coverLetter.font.pixelSize * 0.13
                height: width
                radius: width / 2
                color: FiatVoxTheme.primaryText
            }

            Text {
                id: coverLetter
                text: tuner.hasPitch ? cover.noteLetters[tuner.noteIndex] : " "
                color: tone.playing ? FiatVoxTheme.accent : FiatVoxTheme.primaryText
                font.pixelSize: Theme.fontSizeHuge * 1.8
                font.family: FiatVoxTheme.serif
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Text {
                text: cover.sharpGlyph
                color: Theme.rgba(FiatVoxTheme.primaryText, 0.7)
                visible: tuner.hasPitch && cover.noteSharp[tuner.noteIndex]
                font.pixelSize: coverLetter.font.pixelSize * 0.34
                font.family: FiatVoxTheme.serif
                anchors.left: coverLetter.right
                anchors.leftMargin: -coverLetter.font.pixelSize * 0.03
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -coverLetter.font.pixelSize * 0.24
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tone.playing
                  ? tone.frequency.toFixed(1)
                  : (tuner.hasPitch ? tuner.frequency.toFixed(1) : "fiat vox")
            color: tone.playing ? FiatVoxTheme.accent : FiatVoxTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
            font.family: tone.playing || tuner.hasPitch ? "monospace" : FiatVoxTheme.serif
            font.italic: !tone.playing && !tuner.hasPitch
        }
    }

    // Ljud tonen utan att öppna appen — för när telefonen redan står på
    // notstället.
    CoverActionList {
        id: soundAction

        CoverAction {
            iconSource: tone.playing
                        ? "image://theme/icon-cover-pause"
                        : "image://theme/icon-cover-play"
            onTriggered: {
                if (tone.playing) {
                    tone.stop()
                    return
                }
                var hz = tuner.referenceA
                if (tuner.hasPitch) {
                    var midi = (tuner.octave + 1) * 12 + tuner.noteIndex
                    hz = tuner.referenceA * Math.pow(2, (midi - 69) / 12)
                    while (hz < 110.0) hz *= 2.0
                    while (hz >= 1760.0) hz /= 2.0
                }
                tone.play(hz)
            }
        }
    }
}
