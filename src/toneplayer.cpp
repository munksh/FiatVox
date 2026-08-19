#include "toneplayer.h"

#include <QAudioDeviceInfo>
#include <QAudioFormat>
#include <QDebug>
#include <qmath.h>
#include <cmath>

namespace {

// Harmonic recipe. Fundamental plus a touch of octave and twelfth.
const double kH1 = 1.00;
const double kH2 = 0.35;
const double kH3 = 0.15;
const double kNorm = 0.32 / (kH1 + kH2 + kH3);

const int kAutoStopMs = 60000;   // one minute is long enough to tune a rank
const int kReleaseMs  = 250;

}

// ---------------------------------------------------------------- generator

ToneGenerator::ToneGenerator(int sampleRate, QObject *parent)
    : QIODevice(parent)
    , m_sampleRate(sampleRate)
    , m_phase(0.0)
    , m_phaseStep(0.0)
    , m_gain(0.0)
    , m_target(0.0)
{
    // 15 ms attack and release.
    m_ramp = 1.0 / (0.015 * sampleRate);
}

void ToneGenerator::setFrequency(qreal hz)
{
    m_phaseStep = 2.0 * M_PI * double(hz) / double(m_sampleRate);
}

void ToneGenerator::noteOn()
{
    m_target = 1.0;
}

void ToneGenerator::noteOff()
{
    m_target = 0.0;
}

qint64 ToneGenerator::readData(char *data, qint64 maxlen)
{
    const int frames = int(maxlen / qint64(sizeof(qint16)));
    if (frames <= 0)
        return 0;

    qint16 *out = reinterpret_cast<qint16 *>(data);

    for (int i = 0; i < frames; ++i) {
        if (m_gain < m_target)
            m_gain = qMin(m_target, m_gain + m_ramp);
        else if (m_gain > m_target)
            m_gain = qMax(m_target, m_gain - m_ramp);

        double v = 0.0;
        if (m_gain > 0.0) {
            v = kH1 * std::sin(m_phase)
              + kH2 * std::sin(2.0 * m_phase)
              + kH3 * std::sin(3.0 * m_phase);
            v *= kNorm * m_gain;
        }

        m_phase += m_phaseStep;
        if (m_phase > 2.0 * M_PI)
            m_phase -= 2.0 * M_PI;

        out[i] = qint16(qBound(-1.0, v, 1.0) * 32767.0);
    }

    return qint64(frames) * qint64(sizeof(qint16));
}

qint64 ToneGenerator::writeData(const char *data, qint64 len)
{
    Q_UNUSED(data)
    Q_UNUSED(len)
    return 0;
}

qint64 ToneGenerator::bytesAvailable() const
{
    // Always more where that came from.
    return 8192 + QIODevice::bytesAvailable();
}

// ------------------------------------------------------------------- player

TonePlayer::TonePlayer(QObject *parent)
    : QObject(parent)
    , m_output(0)
    , m_generator(0)
    , m_playing(false)
    , m_frequency(440.0)
    , m_sampleRate(44100)
{
    m_release.setSingleShot(true);
    m_release.setInterval(kReleaseMs);
    connect(&m_release, SIGNAL(timeout()), this, SLOT(releaseDevice()));

    m_autoStop.setSingleShot(true);
    m_autoStop.setInterval(kAutoStopMs);
    connect(&m_autoStop, SIGNAL(timeout()), this, SLOT(stop()));
}

TonePlayer::~TonePlayer()
{
    if (m_output)
        m_output->stop();
}

void TonePlayer::ensureOutput()
{
    if (m_output)
        return;

    QAudioFormat format;
    format.setSampleRate(m_sampleRate);
    format.setChannelCount(1);
    format.setSampleSize(16);
    format.setCodec("audio/pcm");
    format.setByteOrder(QAudioFormat::LittleEndian);
    format.setSampleType(QAudioFormat::SignedInt);

    QAudioDeviceInfo device = QAudioDeviceInfo::defaultOutputDevice();
    if (!device.isFormatSupported(format)) {
        format = device.nearestFormat(format);
        m_sampleRate = format.sampleRate();
    }

    m_generator = new ToneGenerator(m_sampleRate, this);
    m_generator->setFrequency(m_frequency);
    m_generator->open(QIODevice::ReadOnly);

    m_output = new QAudioOutput(device, format, this);
    m_output->setVolume(1.0);
}

void TonePlayer::play(qreal hz)
{
    if (hz < 20.0 || hz > 5000.0)
        return;

    ensureOutput();
    if (!m_output || !m_generator)
        return;

    m_release.stop();

    if (!qFuzzyCompare(m_frequency, hz)) {
        m_frequency = hz;
        m_generator->setFrequency(hz);
        emit frequencyChanged();
    }

    if (m_output->state() != QAudio::ActiveState)
        m_output->start(m_generator);

    m_generator->noteOn();
    m_autoStop.start();

    if (!m_playing) {
        m_playing = true;
        emit playingChanged();
    }
}

void TonePlayer::stop()
{
    m_autoStop.stop();
    if (m_generator)
        m_generator->noteOff();

    if (m_playing) {
        m_playing = false;
        emit playingChanged();
    }

    // Let the release ramp finish before closing the device, or the last
    // few milliseconds turn into a click.
    m_release.start();
}

void TonePlayer::toggle(qreal hz)
{
    if (m_playing)
        stop();
    else
        play(hz);
}

void TonePlayer::releaseDevice()
{
    if (m_output && !m_playing)
        m_output->stop();
}
