// Standalone check of the YIN core used in src/pitchdetector.cpp.
// Same constants, same steps, no Qt. Build:  g++ -O2 -o yin_test yin_test.cpp
#include <cstdio>
#include <cmath>
#include <vector>
#include <algorithm>

static const int kSampleRate = 44100;
static const int kFrame  = 4096;
static const int kWindow = 2048;
static const int kTauMin = 21;
static const int kTauMax = 1604;
static const float kYinThreshold = 0.15f;
static const float kYinReject = 0.55f;

double detectPitch(const float *x, int n, double *clarityOut)
{
    const int tauMax = std::min(kTauMax, n - kWindow);
    if (tauMax <= kTauMin) return 0.0;

    std::vector<float> diff(tauMax + 2, 0.0f), cmnd(tauMax + 2, 1.0f);

    for (int tau = 1; tau <= tauMax; ++tau) {
        float acc = 0.0f;
        for (int j = 0; j < kWindow; ++j) {
            const float d = x[j] - x[j + tau];
            acc += d * d;
        }
        diff[tau] = acc;
    }

    double running = 0.0;
    for (int tau = 1; tau <= tauMax; ++tau) {
        running += diff[tau];
        cmnd[tau] = running > 0.0 ? float(diff[tau] * tau / running) : 1.0f;
    }

    int tau = -1;
    for (int t = kTauMin; t <= tauMax; ++t) {
        if (cmnd[t] < kYinThreshold) {
            while (t + 1 <= tauMax && cmnd[t + 1] < cmnd[t]) ++t;
            tau = t;
            break;
        }
    }
    if (tau < 0) {
        float best = kYinReject;
        for (int t = kTauMin; t <= tauMax; ++t)
            if (cmnd[t] < best) { best = cmnd[t]; tau = t; }
        if (tau < 0) return 0.0;
    }

    double betterTau = tau;
    if (tau > 0 && tau < tauMax) {
        const float s0 = cmnd[tau - 1], s1 = cmnd[tau], s2 = cmnd[tau + 1];
        const float denom = 2.0f * (2.0f * s1 - s2 - s0);
        if (std::fabs(denom) > 1e-9f) betterTau = tau + (s2 - s0) / denom;
    }
    if (betterTau <= 0.0) return 0.0;
    if (clarityOut) *clarityOut = 1.0 - cmnd[tau];
    return double(kSampleRate) / betterTau;
}

static unsigned int seed = 12345;
static float frand() { seed = seed * 1103515245u + 12345u; return ((seed >> 8) & 0xFFFF) / 32768.0f - 1.0f; }

// harmonics: 1 = pure sine, >1 = sawtooth-ish (organ / guitar / voice)
static void makeTone(std::vector<float> &buf, double f, int harmonics, double noise)
{
    for (int i = 0; i < (int)buf.size(); ++i) {
        double t = double(i) / kSampleRate, v = 0.0;
        for (int h = 1; h <= harmonics; ++h)
            v += std::sin(2.0 * M_PI * f * h * t + h * 0.7) / h;
        buf[i] = float(0.3 * v + noise * frand());
    }
}

int main()
{
    struct Case { const char *name; double f; int harmonics; double noise; };
    const Case cases[] = {
        {"A0  pure     ", 27.50,  1,  0.000},
        {"C1  organ ped", 32.70,  8,  0.001},
        {"E2  guitar 6 ", 82.41,  10, 0.002},
        {"A2  guitar 5 ", 110.00, 10, 0.002},
        {"D3  guitar 4 ", 146.83, 10, 0.002},
        {"G3  guitar 3 ", 196.00, 10, 0.002},
        {"B3  guitar 2 ", 246.94, 10, 0.002},
        {"E4  guitar 1 ", 329.63, 10, 0.002},
        {"A4  reference", 440.00, 1,  0.000},
        {"A4  rich     ", 440.00, 12, 0.005},
        {"A4  noisy    ", 440.00, 8,  0.030},
        {"A4 +7 cents  ", 441.78, 8,  0.002},
        {"A4 -7 cents  ", 438.22, 8,  0.002},
        {"A4 +25 cents ", 446.40, 8,  0.002},
        {"C5           ", 523.25, 6,  0.002},
        {"A5           ", 880.00, 4,  0.002},
        {"C6           ", 1046.50, 3, 0.002},
        {"A6           ", 1760.00, 2, 0.002},
    };

    std::vector<float> buf(kFrame);
    double worst = 0.0;
    printf("%-14s %10s %10s %8s %8s\n", "case", "expected", "detected", "cents", "clarity");
    printf("---------------------------------------------------------\n");
    for (const Case &c : cases) {
        makeTone(buf, c.f, c.harmonics, c.noise);
        double clarity = 0.0;
        double f = detectPitch(buf.data(), kFrame, &clarity);
        double cents = f > 0 ? 1200.0 * std::log2(f / c.f) : 9999.0;
        printf("%-14s %10.2f %10.2f %+8.2f %8.3f%s\n",
               c.name, c.f, f, cents, clarity,
               std::fabs(cents) > 3.0 ? "   <-- OFF" : "");
        worst = std::max(worst, std::fabs(cents));
    }
    printf("---------------------------------------------------------\n");
    printf("worst deviation: %.2f cents\n", worst);

    // silence should report nothing
    std::fill(buf.begin(), buf.end(), 0.0f);
    printf("silence -> %.2f Hz (want 0)\n", detectPitch(buf.data(), kFrame, 0));
    return worst < 3.0 ? 0 : 1;
}
