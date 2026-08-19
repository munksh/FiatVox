#ifndef PITCHDETECTOR_H
#define PITCHDETECTOR_H

#include <QObject>
#include <QVector>
#include <QAudioFormat>
#include <QAudioInput>
#include <QIODevice>
#include <QPointer>
#include <QElapsedTimer>
#include <QTimer>

/*
 * PitchDetector
 * -------------
 * Continuous microphone capture + YIN pitch detection, exposed to QML.
 *
 * Usage from QML: the object is a context property called `tuner`.
 * Everything is read-only except referenceA and paused.
 *
 * Capture notes, learned on the device:
 *
 *  - Do NOT gate reads on QIODevice::bytesAvailable(). Several backends,
 *    including the one Sailfish uses, report 0 there while read() would
 *    happily return a buffer. Gating on it means the tuner sits in silence
 *    forever with no error to show for it.
 *  - Do NOT rely on readyRead() alone either. It is connected, but a timer
 *    polls as well, because not every backend emits it.
 *  - Do NOT assume the sample rate you asked for. Whatever the device
 *    negotiates is what the period has to be divided by, or every reading is
 *    transposed.
 */
class PitchDetector : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool running        READ running        NOTIFY runningChanged)
    Q_PROPERTY(bool hasPitch       READ hasPitch       NOTIFY readingChanged)
    Q_PROPERTY(qreal frequency     READ frequency      NOTIFY readingChanged)
    Q_PROPERTY(int noteIndex       READ noteIndex      NOTIFY readingChanged)  // 0..11, 0 = C
    Q_PROPERTY(int octave          READ octave         NOTIFY readingChanged)  // scientific pitch
    Q_PROPERTY(qreal cents         READ cents          NOTIFY readingChanged)  // -50..+50
    Q_PROPERTY(qreal clarity       READ clarity        NOTIFY readingChanged)  // 0..1
    Q_PROPERTY(qreal level         READ level          NOTIFY levelChanged)    // 0..1 input RMS
    Q_PROPERTY(qreal referenceA    READ referenceA     WRITE setReferenceA NOTIFY referenceAChanged)

    // Set while the reference tone is sounding, so the tuner does not sit
    // there listening to itself and reporting a perfect result.
    Q_PROPERTY(bool paused         READ paused         WRITE setPaused     NOTIFY pausedChanged)

    // Diagnostics. `receivingAudio` is false when the stream opened without
    // complaint but not one byte has ever arrived — the difference between a
    // quiet room and a dead microphone, which the UI otherwise cannot tell.
    Q_PROPERTY(bool receivingAudio READ receivingAudio NOTIFY receivingAudioChanged)
    Q_PROPERTY(QString deviceInfo  READ deviceInfo     NOTIFY deviceInfoChanged)
    Q_PROPERTY(QString errorString READ errorString    NOTIFY errorStringChanged)

public:
    explicit PitchDetector(QObject *parent = 0);
    ~PitchDetector();

    bool running() const        { return m_running; }
    bool hasPitch() const       { return m_hasPitch; }
    qreal frequency() const     { return m_frequency; }
    int noteIndex() const       { return m_noteIndex; }
    int octave() const          { return m_octave; }
    qreal cents() const         { return m_cents; }
    qreal clarity() const       { return m_clarity; }
    qreal level() const         { return m_level; }
    qreal referenceA() const    { return m_referenceA; }
    bool paused() const         { return m_paused; }
    bool receivingAudio() const { return m_receivingAudio; }
    QString deviceInfo() const  { return m_deviceInfo; }
    QString errorString() const { return m_errorString; }

    void setReferenceA(qreal hz);
    void setPaused(bool paused);

public slots:
    void start();
    void stop();
    void restart();

signals:
    void runningChanged();
    void readingChanged();
    void levelChanged();
    void referenceAChanged();
    void pausedChanged();
    void receivingAudioChanged();
    void deviceInfoChanged();
    void errorStringChanged();

private slots:
    void pumpAudio();
    void handleStateChange(QAudio::State state);
    void checkForSilenceOfTheDevice();

private:
    bool openStream(bool useDevicePreferredFormat);
    void closeStream();
    void configureForRate(int sampleRate);
    void analyse();
    qreal detectPitch(const float *x, int n, qreal *clarityOut);
    void updateNote();
    void setError(const QString &err);

    // --- capture ---
    QAudioInput *m_audio;
    QPointer<QIODevice> m_source;
    QTimer m_pump;        // polls the device; readyRead is not enough
    QTimer m_watchdog;    // notices a stream that opened but never speaks
    QVector<float> m_ring;
    QVector<qint16> m_scratch;
    qint64 m_bytesSeen;
    bool m_triedPreferredFormat;

    // --- YIN work buffers (allocated once, reused every frame) ---
    QVector<float> m_diff;
    QVector<float> m_cmnd;
    int m_sampleRate;
    int m_tauMin;
    int m_tauMax;

    // --- state ---
    bool m_running;
    bool m_receivingAudio;
    bool m_hasPitch;
    qreal m_frequency;
    qreal m_smoothFrequency;
    int m_noteIndex;
    int m_octave;
    qreal m_cents;
    qreal m_clarity;
    qreal m_level;
    qreal m_referenceA;
    bool m_paused;
    QString m_deviceInfo;
    QString m_errorString;
    QElapsedTimer m_sinceLastPitch;

    // --- fixed constants ---
    enum Constants {
        kFrame   = 4096,   // samples per analysis frame
        kWindow  = 2048,   // YIN integration window
        kHop     = 2048,   // ~21 updates per second at 44.1 kHz
        kMaxRing = kFrame * 4,
        kPumpMs  = 20,     // how often we ask the device for samples
        kWatchMs = 2500    // how long a mute stream gets before we retry
    };
    static const qreal kMinFreq;   // 27.5 Hz, A0 — low organ pedal
    static const qreal kMaxFreq;   // 2100 Hz
};

#endif // PITCHDETECTOR_H
