# Fiat Vox

*Let there be voice.*

A chromatic tuner for Sailfish OS. Sibling to [Fiat Lux](https://github.com/munksh/FiatLux) — same idea that the instrument should speak and the interface should keep quiet, and the same ambience-first colour model.

The app listens continuously. There are no controls on the tuner face.

```
        · · · ● · · ·        seven dots, ±25 cents
                             centre = in tune (green)
            A                one dot out = amber
                             two or three = red
         440.2 Hz
           +1 ¢
```

---

## Ambience first

Like Fiat Lux, the app has no palette of its own. There is no background rectangle — the ambience wallpaper *is* the background — and text, accents and borders all come from `Theme.*`, so the tuner takes on whatever the user is running. Pick a light ambience and the instrument goes light without a line of extra code.

The instrument itself sits on one solid card, the same idiom as the meter cards in Fiat Lux: `Qt.rgba(0.08, 0.08, 0.08, 1)` on a dark scheme, `0.96` on a light one, a `Theme.rgba(Theme.primaryColor, 0.45)` border two pixels wide, radius `Theme.paddingLarge * 1.5`. That is what keeps a huge letter readable over someone's photograph of a lake. Appen står på egna ben.

Three colours refuse to follow the ambience:

| Colour | Meaning | Dark scheme | Light scheme |
|---|---|---|---|
| Green | in tune (within ~4 cents) | `#7FA65C` | `#41682A` |
| Amber | close — 4 to 12 cents out | `#C87941` | `#8F4E1B` |
| Red | wrong | `#A0403A` | `#8A2B25` |

These say *true, close, wrong*. Borrowing them from the accent colour would mean the tuner said different things in different ambiences, which is the one thing an instrument may not do. They shift between two sets only to keep their contrast against a dark or light card, and nothing more.

Everything else is ambience: the letter is `Theme.primaryColor`, the hertz is `Theme.secondaryColor`, the level hairline and the *sounding* state are `Theme.highlightColor`, and the reference pill is the Fiat Lux pill — `Theme.rgba(Theme.primaryColor, 0.15)` fill, `0.55` border, switching to the `highlightColor` pair while the tone plays.

It all lives in `qml/Palette.qml`, one `QtObject`, instantiated as `Palette { id: pal }`.

---

## The face

**Seven dots**, centred above the letter. Each dot is worth about **8.3 cents**; the row spans a quarter-tone either side of true. Centre is green, one either side amber, beyond that red. Right of centre means sharp, left means flat.

**The letter** is the nearest semitone, sharps only (`A`, `A♯`, `B` …). The letter is centred on the page *by itself* — the sharp hangs off its right edge rather than sharing the centring, so the C in `C♯` sits exactly where a plain `C` sits and nothing slides sideways as you play up the scale.

**The hertz** sits under the letter, monospace, in the secondary colour. Below that, the deviation in cents.

When the room goes quiet the reading is held for 1.2 s, then the face fades to a single resting dot — drawn, not a glyph, so it is round on every device font. The centre dot of the row stays faintly lit too, so the instrument never looks switched off.

**Tap the card** to sound the note — the stämton. The letter takes the ambience highlight colour while it plays, listening pauses so the tuner does not sit there hearing itself, and a tap stops it. It sounds the *true* equal-tempered pitch of the letter on screen, not the frequency you played: a reference is the target, not the mistake. With nothing detected it sounds a plain A at the current reference — a tuning fork in the pocket. Notes below A2 sound an octave up, since a phone speaker cannot reproduce a 33 Hz pedal note. It stops itself after a minute.

The cover has a play action, so you can sound the note without opening the app.

**Pull down** to open the reference pitch page — 415 to 443 Hz as pills on a card; tap one and it takes effect and pops back. The choice is saved. That is the only setting, and it lives above the fold so the face stays clean.

The pull-down item deliberately reads *Reference pitch — A₄ 440 Hz*, like a door rather than a readout. An earlier version showed the value and cycled it on tap, which looked exactly like a label that did nothing.

The **cover** keeps tuning. Prop the phone on the music stand and it still works.

---

## How it hears

`src/pitchdetector.{h,cpp}` — a `QAudioInput` capture chain feeding **YIN** (de Cheveigné & Kawahara, 2002): difference function, cumulative mean normalisation, absolute threshold, parabolic interpolation.

| | |
|---|---|
| Sample rate | 44 100 Hz, mono, 16-bit |
| Frame | 4096 samples, hop 2048 (~21 readings/sec) |
| Integration window | 2048 samples |
| Range | 27.5 Hz (A0, low organ pedal) to ~2100 Hz |
| Smoothing | exponential in the log domain, α = 0.35; resets on a real note change |
| Silence gate | RMS < 0.006 |

**Why YIN and not FFT.** An FFT bin at 44.1 kHz / 4096 is 10.8 Hz wide — around 40 cents at A4. Useless for tuning without heavy interpolation. YIN works in the time domain on the period itself, and its absolute-threshold step is specifically what stops a detector from octave-jumping on harmonically rich sounds — organ, bowed strings, a sung vowel.

Measured against synthetic tones (`test/yin_test.cpp`, builds standalone with `g++ -O2`):

```
A0 27.5 Hz     -0.39 ¢      A4 440 Hz rich   +0.12 ¢
C1 32.7 Hz     -0.00 ¢      A4 440 Hz noisy  -0.03 ¢
E2 82.4 Hz     +0.01 ¢      C5 523 Hz        +0.12 ¢
E4 330 Hz      +0.02 ¢      A6 1760 Hz       +1.38 ¢
```

Worst case 1.4 cents at A6, well under a fifth of a dot, and sub-cent everywhere you would actually tune.

CPU cost is roughly 3.3 M multiply-adds per frame at ~21 frames/sec. It runs on the main thread; if it ever stutters on the device, move `analyse()` to a `QThread` — nothing else has to change.

### Three things about capture, learned the hard way

The first build on the phone opened the stream, reported no error, and heard absolutely nothing. All three of these were wrong:

**Do not gate reads on `bytesAvailable()`.** The device reports `0` there while `read()` would happily hand over a buffer. The old code did `if (bytesAvailable() <= 0) return;` and therefore never read a single sample — silently, with no error to show for it. Just call `read()` and use whatever comes back.

**Do not rely on `readyRead()` alone.** It is still connected, but a 20 ms `QTimer` drives the reading, because not every backend emits it. Both funnel into the same `pumpAudio()`.

**Do not assume the sample rate you asked for.** If the device negotiates 48 kHz and you keep dividing the period by 44100, every reading is transposed by about 147 cents — a tuner that is confidently wrong, which is worse than one that says nothing. The negotiated rate is stored and the tau range is recomputed from it.

There is also a watchdog: if two and a half seconds pass with zero bytes, the stream is torn down and reopened using the device's own `preferredFormat()`. If that is silent too, `errorString` says so and the pill on the face reads **MICROPHONE GIVES NO AUDIO** instead of resting quietly as though the room were empty.

### When the microphone seems dead

`tools/mic-check.sh` runs on the phone and answers whether PulseAudio hands out microphone audio at all:

```bash
sh mic-check.sh
```

It lists the sources, records three seconds, and checks whether the samples are actually non-zero rather than a stream of digital silence — a muted source looks exactly like a working one until you look at the bytes. If that script is silent too, the problem is below Fiat Vox.

The app logs the negotiated format and every audio state change:

```bash
journalctl -f | grep -i fiatvox
```

---

## Trying the face before the phone

`tools/fiatvox-preview.html` is the same face in a browser — same card, same seven dots, same YIN detector ported to JavaScript. Open it on a phone or laptop and tap **Listen** to tune something for real; tap **simulate** in the corner to drag the deviation and check every colour without making a sound.

The drawer also carries four stand-in **ambiences** — two dark, two light, each with its own accent and wallpaper. Switching between them is the fastest way to see whether the semantic colours still hold up before you deploy anything.

It needs a secure origin for the microphone, so `file://` will fall back to simulate mode. Serve it locally to get the mic:

```bash
cd ~/Projects/FiatVox/tools && python3 -m http.server 8000
# then http://localhost:8000/fiatvox-preview.html
```

This is a design rig, not a second product — the Sailfish app is the app.

---

## Project layout

```
FiatVox/
├── FiatVox.pro              # qmake, not CMake
├── FiatVox.desktop
├── src/
│   ├── FiatVox.cpp          # exposes `tuner` and `tone` as context properties
│   ├── pitchdetector.h
│   ├── pitchdetector.cpp
│   ├── toneplayer.h
│   └── toneplayer.cpp       # QIODevice synth: sine + octave + twelfth, ramped
├── qml/
│   ├── FiatVox.qml
│   ├── Palette.qml          # the Fiat Lux colours, one place
│   ├── cover/CoverPage.qml
│   └── pages/
│       ├── TunerPage.qml
│       └── ReferencePage.qml
├── icons/{86x86,108x108,128x128,172x172}/FiatVox.png
├── rpm/FiatVox.spec
├── test/yin_test.cpp
└── tools/
    ├── make_icon.py
    ├── mic-check.sh          # run on the phone when the mic seems dead
    └── fiatvox-preview.html
```

The detector is a single C++ object exposed to QML as `tuner`, so the page and the cover share one microphone stream. No QML type registration, no second instance.

---

## Building

Same workflow as Fiat Lux. VirtualBox build engine — **not Docker**, the network to the emulator does not work.

1. Qt Creator → sail icon bottom-left → Start SDK build engine
2. Kit selector → `SailfishOS-5.0.0.62-i486` for the emulator, `aarch64` for the phone
3. Because this adds new files and a new Qt module: **Build → Clean All → Run qmake → Build**

Or from the terminal:

```bash
~/SailfishOS/bin/sfdk -c target=SailfishOS-5.0.0.62-i486 build
~/SailfishOS/bin/sfdk deploy --sdk
```

### Two things that can bite

**`QT += multimedia` is new here.** Fiat Lux does not use it. If the build cannot find `QAudioInput`, the target is missing `qt5-qtmultimedia-devel`:

```bash
~/SailfishOS/bin/sfdk -c target=SailfishOS-5.0.0.62-i486 build-shell \
  sb2 -t SailfishOS-5.0.0.62-i486 -m sdk-install -R zypper in qt5-qtmultimedia-devel
```

**The emulator has no microphone.** Expect `hasPitch` to stay false and the face to sit at the dim dash. This is the same situation as the camera in Fiat Lux — do not try to fix it in the emulator. The layout, colours, dots and pull-down can all be checked there; only the listening needs the real phone.

### Sandboxing

`FiatVox.desktop` ships with the `[X-Sailjail]` block commented out. Sideloaded apps run unsandboxed and get the microphone without asking, which is what you want while developing. Before submitting anywhere, uncomment the block and change `Exec` to `sailjail -p FiatVox.desktop /usr/bin/FiatVox`.

---

## Notes on the QML

- **Palette lives in one file.** `qml/Palette.qml` is a plain `QtObject` holding the card idiom, the pill idiom and the three semantic colours. Everything else goes straight to `Theme.*`. Change something once and the cover follows.
- **No background rectangle anywhere.** If you find yourself adding one, you have just cancelled the ambience.
- **The sharp glyph** is U+266F `♯`. If it renders as a box on the device, set `sharpGlyph: "#"` at the top of `TunerPage.qml` and `CoverPage.qml`.
- **The big letter** uses `Theme.fontFamilyHeading` at 30% of screen height. The Fiat Lux identity calls for Georgia italic for headlines, but Georgia is not on Sailfish — the Silica heading face reads better huge anyway. To go serif, bundle a font and set `font.family` on `letter`.
- **No `TextSwitch`, no needle, no meter arc.** The dots are the meter.

---

## Roadmap

1. **Transposing display** — `B♭` for clarinet and trumpet players, `E♭` for alto sax. One offset applied before the letter lookup.
2. **Temperaments** — meantone, Werckmeister, Kirnberger. Relevant for the organ, and it is only a table of cent offsets per key.
3. **Strobe mode** — a slowly rotating band instead of dots, for the last cent.
4. **Instrument presets** — guitar, mandolin, violin; light the nearest open string rather than the nearest semitone.

---

*Fiat Lux measures light. Fiat Vox measures pitch. Both are one instrument doing one thing quietly, in whatever ambience you happen to be wearing.*
