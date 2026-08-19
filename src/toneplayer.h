#ifndef TONEPLAYER_H
#define TONEPLAYER_H

#include <QObject>
#include <QIODevice>
#include <QAudioOutput>
#include <QTimer>

/*
 * ToneGenerator
 * -------------
 * Synthesises the reference tone on demand. A pure sine disappears on a
 * phone speaker, so this is a sine with a little second and third harmonic
 * on top — closer to an organ flute than to a laboratory oscillator, and
 * audible across a room.
 *
 * Gain is ramped over ~15 ms on both ends. Without that you get a click,
 * and a click is the least analogue sound there is.
 */
class ToneGenerator : public QIODevice
{
    Q_OBJECT

public:
    explicit ToneGenerator(int sampleRate, QObject *parent = 0);

    void setFrequency(qreal hz);
    void noteOn();
    void noteOff();
    bool silent() const { return m_gain <= 0.0 && m_target <= 0.0; }

    qint64 readData(char *data, qint64 maxlen);
    qint64 writeData(const char *data, qint64 len);
    qint64 bytesAvailable() const;
    bool isSequential() const { return true; }

private:
    int m_sampleRate;
    double m_phase;
    double m_phaseStep;
    double m_gain;
    double m_target;
    double m_ramp;
};

/*
 * TonePlayer
 * ----------
 * The QML-facing object. Exposed as `tone`.
 */
class TonePlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(qreal frequency READ frequency NOTIFY frequencyChanged)

public:
    explicit TonePlayer(QObject *parent = 0);
    ~TonePlayer();

    bool playing() const    { return m_playing; }
    qreal frequency() const { return m_frequency; }

public slots:
    void play(qreal hz);
    void stop();
    void toggle(qreal hz);

signals:
    void playingChanged();
    void frequencyChanged();

private slots:
    void releaseDevice();

private:
    void ensureOutput();

    QAudioOutput *m_output;
    ToneGenerator *m_generator;
    QTimer m_release;    // tears the audio device down once the ramp is done
    QTimer m_autoStop;   // never leave a tone singing in a pocket
    bool m_playing;
    qreal m_frequency;
    int m_sampleRate;
};

#endif // TONEPLAYER_H
