#include "pitchdetector.h"

#include <QAudioDeviceInfo>
#include <QSettings>
#include <QDebug>
#include <qmath.h>
#include <cmath>

const qreal PitchDetector::kMinFreq = 27.5;
const qreal PitchDetector::kMaxFreq = 2100.0;

namespace {

// Below this RMS we treat the room as silent and stop reporting a note.
const qreal kSilenceRms   = 0.006;
// YIN's absolute threshold. Lower = stricter about what counts as a pitch.
const float kYinThreshold = 0.15f;
// A candidate worse than this is discarded even if it is the global minimum.
const float kYinReject    = 0.55f;
// How long a note keeps being reported after the sound stops (ms).
const int   kHoldMs       = 1200;
// Samples per read attempt.
const int   kChunk        = 4096;

}

PitchDetector::PitchDetector(QObject *parent)
    : QObject(parent)
    , m_audio(0)
    , m_bytesSeen(0)
    , m_triedPreferredFormat(false)
    , m_sampleRate(44100)
    , m_tauMin(21)
    , m_tauMax(1604)
    , m_running(false)
    , m_receivingAudio(false)
    , m_hasPitch(false)
    , m_frequency(0)
    , m_smoothFrequency(0)
    , m_noteIndex(9)   // A
    , m_octave(4)
    , m_cents(0)
    , m_clarity(0)
    , m_level(0)
    , m_referenceA(440.0)
    , m_paused(false)
{
    m_ring.reserve(int(kMaxRing));
    m_scratch.resize(kChunk);
    m_diff.resize(int(kFrame) - int(kWindow) + 2);
    m_cmnd.resize(int(kFrame) - int(kWindow) + 2);
    configureForRate(m_sampleRate);

    QSettings settings(QStringLiteral("se.munkstolen"), QStringLiteral("FiatVox"));
    const qreal saved = settings.value(QStringLiteral("referenceA"), 440.0).toReal();
    if (saved >= 300.0 && saved <= 550.0)
        m_referenceA = saved;

    m_pump.setInterval(int(kPumpMs));
    connect(&m_pump, SIGNAL(timeout()), this, SLOT(pumpAudio()));

    m_watchdog.setSingleShot(true);
    m_watchdog.setInterval(int(kWatchMs));
    connect(&m_watchdog, SIGNAL(timeout()), this, SLOT(checkForSilenceOfTheDevice()));
}

PitchDetector::~PitchDetector()
{
    stop();
}

void PitchDetector::configureForRate(int sampleRate)
{
    m_sampleRate = sampleRate;
    m_tauMin = qMax(2, int(sampleRate / kMaxFreq));
    m_tauMax = qMin(int(sampleRate / kMinFreq), int(kFrame) - int(kWindow));
}

void PitchDetector::setReferenceA(qreal hz)
{
    if (hz < 300.0 || hz > 550.0)
        return;
    if (qFuzzyCompare(m_referenceA, hz))
        return;
    m_referenceA = hz;

    QSettings settings(QStringLiteral("se.munkstolen"), QStringLiteral("FiatVox"));
    settings.setValue(QStringLiteral("referenceA"), hz);

    emit referenceAChanged();
    if (m_hasPitch) {
        updateNote();
        emit readingChanged();
    }
}

void PitchDetector::setPaused(bool paused)
{
    if (m_paused == paused)
        return;
    m_paused = paused;

    if (!m_paused) {
        // Throw away whatever accumulated while the tone was sounding and
        // start listening from silence rather than from an echo.
        m_ring.clear();
        m_smoothFrequency = 0;
        m_sinceLastPitch.restart();
    }

    emit pausedChanged();
}

void PitchDetector::setError(const QString &err)
{
    if (m_errorString == err)
        return;
    m_errorString = err;
    emit errorStringChanged();
}

// ---------------------------------------------------------------- the stream

bool PitchDetector::openStream(bool useDevicePreferredFormat)
{
    const QAudioDeviceInfo device = QAudioDeviceInfo::defaultInputDevice();
    if (device.isNull()) {
        setError(QStringLiteral("No microphone device"));
        m_deviceInfo = QStringLiteral("no input device");
        emit deviceInfoChanged();
        return false;
    }

    QAudioFormat format;
    if (useDevicePreferredFormat) {
        // Second attempt: stop arguing with the device and take what it likes.
        format = device.preferredFormat();
        qWarning() << "FiatVox: retrying with the device's preferred format";
    } else {
        format.setSampleRate(44100);
        format.setChannelCount(1);
        format.setSampleSize(16);
        format.setCodec(QStringLiteral("audio/pcm"));
        format.setByteOrder(QAudioFormat::LittleEndian);
        format.setSampleType(QAudioFormat::SignedInt);

        if (!device.isFormatSupported(format))
            format = device.nearestFormat(format);
    }

    // We only know how to read mono 16-bit signed. Anything else and we would
    // be interpreting the bytes wrong, which is worse than saying so.
    if (format.sampleSize() != 16
            || format.sampleType() != QAudioFormat::SignedInt
            || format.channelCount() != 1) {
        setError(QStringLiteral("Unsupported mic format"));
        m_deviceInfo = QStringLiteral("%1 · %2 Hz %3ch %4bit")
                .arg(device.deviceName())
                .arg(format.sampleRate())
                .arg(format.channelCount())
                .arg(format.sampleSize());
        emit deviceInfoChanged();
        return false;
    }

    // Whatever rate we ended up with is the rate the period is divided by.
    configureForRate(format.sampleRate());

    m_audio = new QAudioInput(device, format, this);
    connect(m_audio, SIGNAL(stateChanged(QAudio::State)),
            this, SLOT(handleStateChange(QAudio::State)));

    m_source = m_audio->start();
    if (!m_source) {
        setError(QStringLiteral("Could not open microphone"));
        m_audio->deleteLater();
        m_audio = 0;
        return false;
    }

    // Connected as a hint, not as the mechanism — the timer does the work.
    connect(m_source.data(), SIGNAL(readyRead()), this, SLOT(pumpAudio()));

    m_deviceInfo = QStringLiteral("%1 · %2 Hz")
            .arg(device.deviceName())
            .arg(format.sampleRate());
    emit deviceInfoChanged();

    qWarning() << "FiatVox: capturing from" << device.deviceName()
               << format.sampleRate() << "Hz"
               << format.channelCount() << "ch"
               << format.sampleSize() << "bit"
               << "| state" << m_audio->state()
               << "| error" << m_audio->error();

    return true;
}

void PitchDetector::closeStream()
{
    m_pump.stop();
    m_watchdog.stop();
    if (m_audio) {
        m_audio->stop();
        m_audio->deleteLater();
        m_audio = 0;
    }
    m_source = 0;
    m_ring.clear();
}

void PitchDetector::start()
{
    if (m_running)
        return;

    m_bytesSeen = 0;
    m_triedPreferredFormat = false;

    if (!openStream(false))
        return;

    setError(QString());
    m_sinceLastPitch.start();
    m_pump.start();
    m_watchdog.start();
    m_running = true;
    emit runningChanged();
}

void PitchDetector::stop()
{
    if (!m_running && !m_audio)
        return;

    closeStream();

    m_running = false;
    m_hasPitch = false;
    m_receivingAudio = false;
    m_level = 0;
    emit receivingAudioChanged();
    emit levelChanged();
    emit readingChanged();
    emit runningChanged();
}

void PitchDetector::restart()
{
    stop();
    start();
}

void PitchDetector::handleStateChange(QAudio::State state)
{
    if (!m_audio)
        return;

    qWarning() << "FiatVox: audio input state" << state
               << "error" << m_audio->error();

    if (state == QAudio::StoppedState && m_audio->error() != QAudio::NoError)
        setError(QStringLiteral("Microphone stopped"));
}

/*
 * The stream opened, nobody complained, and nothing has arrived. Try once more
 * with the device's own preferred format before admitting defeat, then say so
 * in plain words rather than showing a face that looks like a quiet room.
 */
void PitchDetector::checkForSilenceOfTheDevice()
{
    if (m_bytesSeen > 0)
        return;

    if (!m_triedPreferredFormat) {
        m_triedPreferredFormat = true;
        qWarning() << "FiatVox: no audio after" << int(kWatchMs) << "ms, retrying";
        closeStream();
        if (openStream(true)) {
            m_pump.start();
            m_watchdog.start();
        }
        return;
    }

    setError(QStringLiteral("Microphone gives no audio"));
    qWarning() << "FiatVox: still no audio from the microphone."
               << "Check `pactl list sources short` on the device.";
}

// ------------------------------------------------------------------- reading

void PitchDetector::pumpAudio()
{
    if (!m_source)
        return;

    // Note what is NOT here: a bytesAvailable() check. Asking politely first
    // is exactly what made this read nothing at all on the device.
    forever {
        const qint64 read = m_source->read(reinterpret_cast<char *>(m_scratch.data()),
                                           qint64(kChunk) * qint64(sizeof(qint16)));
        if (read <= 0)
            break;

        m_bytesSeen += read;
        if (!m_receivingAudio) {
            m_receivingAudio = true;
            emit receivingAudioChanged();
            setError(QString());
        }

        if (!m_paused) {
            const int got = int(read / qint64(sizeof(qint16)));
            for (int i = 0; i < got; ++i)
                m_ring.append(m_scratch.at(i) / 32768.0f);

            if (m_ring.size() > int(kMaxRing))
                m_ring.remove(0, m_ring.size() - int(kMaxRing));
        }

        if (read < qint64(kChunk) * qint64(sizeof(qint16)))
            break;
    }

    if (m_paused) {
        // Draining the device so it does not overflow, but the samples go
        // nowhere: the display holds whatever it last heard.
        m_ring.clear();
        return;
    }

    while (m_ring.size() >= int(kFrame)) {
        analyse();
        m_ring.remove(0, int(kHop));
    }
}

void PitchDetector::analyse()
{
    float *x = m_ring.data();

    // Remove DC offset and measure level in one pass.
    double sum = 0.0;
    for (int i = 0; i < int(kFrame); ++i)
        sum += x[i];
    const float mean = static_cast<float>(sum / double(int(kFrame)));

    double energy = 0.0;
    for (int i = 0; i < int(kFrame); ++i) {
        x[i] -= mean;
        energy += static_cast<double>(x[i]) * x[i];
    }
    const qreal rms = std::sqrt(energy / double(int(kFrame)));

    const qreal newLevel = qMin(1.0, rms * 6.0);
    if (qAbs(newLevel - m_level) > 0.01) {
        m_level = newLevel;
        emit levelChanged();
    }

    if (rms < kSilenceRms) {
        // Hold the last reading briefly so the display does not flicker
        // between plucks or breaths.
        if (m_hasPitch && m_sinceLastPitch.elapsed() > kHoldMs) {
            m_hasPitch = false;
            m_smoothFrequency = 0;
            emit readingChanged();
        }
        return;
    }

    qreal clarity = 0;
    const qreal freq = detectPitch(x, int(kFrame), &clarity);

    if (freq <= 0.0) {
        if (m_hasPitch && m_sinceLastPitch.elapsed() > kHoldMs) {
            m_hasPitch = false;
            m_smoothFrequency = 0;
            emit readingChanged();
        }
        return;
    }

    m_sinceLastPitch.restart();

    // Smooth in the log domain: a musically even response, and it keeps the
    // dots from jittering. A big jump (new note) resets instead of gliding.
    if (m_smoothFrequency > 0.0 && qAbs(std::log(freq / m_smoothFrequency)) < 0.06) {
        const qreal alpha = 0.35;
        m_smoothFrequency = std::exp(alpha * std::log(freq)
                                     + (1.0 - alpha) * std::log(m_smoothFrequency));
    } else {
        m_smoothFrequency = freq;
    }

    m_frequency = m_smoothFrequency;
    m_clarity = clarity;
    m_hasPitch = true;
    updateNote();
    emit readingChanged();
}

/*
 * YIN (de Cheveigné & Kawahara, 2002), steps 1-5.
 * Returns 0 when no confident pitch is found.
 */
qreal PitchDetector::detectPitch(const float *x, int n, qreal *clarityOut)
{
    const int tauMax = qMin(m_tauMax, n - int(kWindow));
    if (tauMax <= m_tauMin)
        return 0.0;

    // Step 2: difference function.
    for (int tau = 1; tau <= tauMax; ++tau) {
        float acc = 0.0f;
        const float *a = x;
        const float *b = x + tau;
        for (int j = 0; j < int(kWindow); ++j) {
            const float d = a[j] - b[j];
            acc += d * d;
        }
        m_diff[tau] = acc;
    }

    // Step 3: cumulative mean normalised difference.
    m_cmnd[0] = 1.0f;
    double running = 0.0;
    for (int tau = 1; tau <= tauMax; ++tau) {
        running += m_diff[tau];
        m_cmnd[tau] = (running > 0.0)
                ? static_cast<float>(m_diff[tau] * tau / running)
                : 1.0f;
    }

    // Step 4: absolute threshold — first dip below it wins, which is what
    // stops the detector from octave-jumping on rich sounds like an organ.
    int tau = -1;
    for (int t = m_tauMin; t <= tauMax; ++t) {
        if (m_cmnd[t] < kYinThreshold) {
            while (t + 1 <= tauMax && m_cmnd[t + 1] < m_cmnd[t])
                ++t;
            tau = t;
            break;
        }
    }
    if (tau < 0) {
        // Nothing crossed the threshold: fall back to the global minimum,
        // but only accept it if it is at least vaguely periodic.
        float best = kYinReject;
        for (int t = m_tauMin; t <= tauMax; ++t) {
            if (m_cmnd[t] < best) {
                best = m_cmnd[t];
                tau = t;
            }
        }
        if (tau < 0)
            return 0.0;
    }

    // Step 5: parabolic interpolation for sub-sample period accuracy.
    qreal betterTau = tau;
    if (tau > 0 && tau < tauMax) {
        const float s0 = m_cmnd[tau - 1];
        const float s1 = m_cmnd[tau];
        const float s2 = m_cmnd[tau + 1];
        const float denom = 2.0f * (2.0f * s1 - s2 - s0);
        if (qAbs(denom) > 1e-9f)
            betterTau = tau + (s2 - s0) / denom;
    }

    if (betterTau <= 0.0)
        return 0.0;

    if (clarityOut)
        *clarityOut = qBound(0.0, 1.0 - static_cast<qreal>(m_cmnd[tau]), 1.0);

    return static_cast<qreal>(m_sampleRate) / betterTau;
}

void PitchDetector::updateNote()
{
    if (m_frequency <= 0.0)
        return;

    // MIDI note number in the continuous domain, then split into the nearest
    // semitone and the deviation from it.
    const qreal midi = 69.0 + 12.0 * std::log(m_frequency / m_referenceA) / std::log(2.0);
    const int nearest = static_cast<int>(std::floor(midi + 0.5));

    m_cents = (midi - nearest) * 100.0;
    m_noteIndex = ((nearest % 12) + 12) % 12;   // 0 = C
    m_octave = nearest / 12 - 1;                // MIDI 60 = C4
}
