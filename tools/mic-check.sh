#!/bin/sh
# Run this ON THE PHONE, over SSH or in the terminal app, as the nemo/defaultuser.
#
#   sh mic-check.sh
#
# It answers one question: does PulseAudio hand out microphone audio at all?
# If this script is silent too, the problem is below Fiat Vox and no amount of
# fiddling with QAudioInput will help.

echo "== sources =="
pactl list sources short || echo "pactl missing or PulseAudio not reachable"

echo
echo "== default source =="
pactl info 2>/dev/null | grep -i "default source"

echo
echo "== recording 3 seconds =="
REC=""
for c in parecord parec pacat; do
    command -v "$c" >/dev/null 2>&1 && REC="$c" && break
done

if [ -z "$REC" ]; then
    echo "no parecord/parec/pacat on this device — install pulseaudio-utils"
    exit 1
fi

OUT=/tmp/fiatvox-mic-test.raw
rm -f "$OUT"

case "$REC" in
    parecord) timeout 3 parecord --channels=1 --rate=44100 --format=s16le "$OUT" ;;
    *)        timeout 3 "$REC" --record --channels=1 --rate=44100 --format=s16le > "$OUT" ;;
esac

SIZE=$(wc -c < "$OUT" 2>/dev/null || echo 0)
echo "captured $SIZE bytes (expect roughly 264000 for 3 s of 44.1 kHz mono 16-bit)"

if [ "$SIZE" -lt 1000 ]; then
    echo "RESULT: the microphone gave nothing. This is a system-level problem."
    exit 1
fi

# Are the samples actually non-zero, or is it a stream of silence?
NONZERO=$(od -An -tu1 -N 20000 "$OUT" | tr ' ' '\n' | grep -v '^$' | grep -vc '^0$')
echo "non-zero bytes in the first 20 kB: $NONZERO"

if [ "$NONZERO" -lt 100 ]; then
    echo "RESULT: the stream runs but it is digital silence — the source is"
    echo "        probably muted. Try: pactl set-source-mute @DEFAULT_SOURCE@ 0"
else
    echo "RESULT: the microphone works. If Fiat Vox still hears nothing, the"
    echo "        problem is in the app — send the output of:"
    echo "        journalctl -f | grep -i fiatvox"
fi
