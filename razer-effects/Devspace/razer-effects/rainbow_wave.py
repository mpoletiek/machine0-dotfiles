#!/usr/bin/env python3
"""Rolling rainbow wave across a Razer per-key RGB keyboard.

Run:    python rainbow_wave.py
Stop:   Ctrl-C  (restores spectrum cycling)

Tune the constants below to change the look.
"""
import colorsys
import signal
import sys
import time

from openrazer.client import DeviceManager

FPS         = 30      # frames per second
SPEED       = 0.25    # full hue cycles per second
DIAGONAL    = 0.5     # 0 = pure horizontal scroll, 1 = strong diagonal
SATURATION  = 1.0     # 0..1
VALUE       = 1.0     # 0..1  (brightness of the rainbow itself)


def find_keyboard():
    for d in DeviceManager().devices:
        if d.type == "keyboard" and d.has("lighting_led_matrix"):
            return d
    sys.exit("No keyboard with per-key RGB found. Is openrazer-daemon running?")


def render(kbd, t):
    rows = kbd.fx.advanced.rows
    cols = kbd.fx.advanced.cols
    for r in range(rows):
        for c in range(cols):
            hue = ((c / cols) + (r / rows) * DIAGONAL + t * SPEED) % 1.0
            rr, gg, bb = colorsys.hsv_to_rgb(hue, SATURATION, VALUE)
            kbd.fx.advanced.matrix[r, c] = (int(rr * 255), int(gg * 255), int(bb * 255))
    kbd.fx.advanced.draw()


def main():
    kbd = find_keyboard()
    print(f"Driving {kbd.name} ({kbd.fx.advanced.rows}x{kbd.fx.advanced.cols}). Ctrl-C to stop.")

    def on_exit(*_):
        kbd.fx.spectrum()
        sys.exit(0)

    signal.signal(signal.SIGINT, on_exit)
    signal.signal(signal.SIGTERM, on_exit)

    frame_budget = 1.0 / FPS
    start = time.time()
    while True:
        loop_start = time.time()
        render(kbd, loop_start - start)
        time.sleep(max(0.0, frame_budget - (time.time() - loop_start)))


if __name__ == "__main__":
    main()
