#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QScopedPointer>
#include <sailfishapp.h>

#include "pitchdetector.h"
#include "toneplayer.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName(QStringLiteral("se.munkstolen"));
    app->setApplicationName(QStringLiteral("FiatVox"));

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // One detector for the whole app, shared by the page and the cover.
    PitchDetector detector;
    view->rootContext()->setContextProperty(QStringLiteral("tuner"), &detector);

    // The reference tone. Sounding and listening at the same time would only
    // measure the app, so FiatVox.qml pauses the detector while it plays.
    TonePlayer tone;
    view->rootContext()->setContextProperty(QStringLiteral("tone"), &tone);

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    detector.start();

    return app->exec();
}
