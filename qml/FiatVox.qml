import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    id: app

    initialPage: Component { TunerPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait

    // `tuner` and `tone` are C++ context properties set up in main().
    // The detector keeps running while the app is alive so the cover stays
    // live — except while the reference tone is sounding, when it would
    // otherwise just listen to the app itself.
    Connections {
        target: tone
        onPlayingChanged: tuner.paused = tone.playing
    }

    Component.onDestruction: {
        tone.stop()
        tuner.stop()
    }
}
