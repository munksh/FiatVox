#!/usr/bin/env python3
"""Render the Fiat Vox app icon: a tuning fork, cream on darkroom brown,
with one amber dot beneath it — the lit centre dot from the tuner face."""

import os
from PIL import Image, ImageDraw

BG = (0x1E, 0x1A, 0x12, 255)
CREAM = (0xF4, 0xEE, 0xD8, 255)
AMBER = (0xC8, 0x79, 0x41, 255)

S = 1024  # supersampled canvas


def render():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    k = S / 512.0

    def r(*v):
        return [x * k for x in v]

    # background, Sailfish squircle-ish rounded square
    d.rounded_rectangle(r(0, 0, 511, 511), radius=110 * k, fill=BG)

    # fork: outer U
    fork = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fork)
    fd.rounded_rectangle(r(176, 84, 336, 344), radius=80 * k, fill=CREAM)
    # inner slot between the tines (cut out)
    fd.rounded_rectangle(r(214, 60, 298, 288), radius=42 * k, fill=(0, 0, 0, 0))
    # stem
    fd.rounded_rectangle(r(238, 330, 274, 446), radius=18 * k, fill=CREAM)

    img = Image.alpha_composite(img, fork)
    d = ImageDraw.Draw(img)

    # the lit dot, sounding between the tines
    d.ellipse(r(233, 113, 279, 159), fill=AMBER)

    return img


def main():
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    master = render()
    master.resize((512, 512), Image.LANCZOS).save(
        os.path.join(base, "icons", "fiatvox-icon-512.png"))
    for size in (86, 108, 128, 172):
        d = os.path.join(base, "icons", "%dx%d" % (size, size))
        os.makedirs(d, exist_ok=True)
        master.resize((size, size), Image.LANCZOS).save(
            os.path.join(d, "FiatVox.png"))
        print("wrote", os.path.join(d, "FiatVox.png"))


if __name__ == "__main__":
    main()
