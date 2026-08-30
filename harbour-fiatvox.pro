# Fiat Vox — chromatic tuner for Sailfish OS
#
# OBS: qmake, inte CMake. Efter ändringar här:
# Build > Clean All, sedan Run qmake, sedan Build.

TARGET = harbour-fiatvox

CONFIG += sailfishapp
QT += multimedia

VERSION = 1.0.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

SOURCES += \
    src/FiatVox.cpp \
    src/pitchdetector.cpp \
    src/toneplayer.cpp

HEADERS += \
    src/pitchdetector.h \
    src/toneplayer.h

DISTFILES += \
    qml/harbour-fiatvox.qml \
    qml/FiatVoxTheme.qml \
    qml/qmldir \
    qml/components/PageHead.qml \
    qml/components/SectionLabel.qml \
    qml/components/MunkstolenMark.qml \
    qml/cover/CoverPage.qml \
    qml/pages/TunerPage.qml \
    qml/pages/ReferencePage.qml \
    qml/pages/AboutPage.qml \
    rpm/harbour-fiatvox.spec \
    harbour-fiatvox.desktop \
    README.md

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
