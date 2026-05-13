#!/usr/bin/env python3
"""Diagnostic: list Razer keyboard event devices and report keypresses on each.

Run for ~10s while typing, then check which device(s) show events.
"""
import os
import select
import sys
import time

import evdev  # pyright: ignore[reportMissingImports]

CANDIDATES = [
    "/dev/input/by-id/usb-Razer_Razer_BlackWidow_V3_Pro-event-kbd",
    "/dev/input/by-id/usb-Razer_Razer_BlackWidow_V3_Pro-if01-event-kbd",
]

devs = []
for path in CANDIDATES:
    real = os.path.realpath(path)
    try:
        dev = evdev.InputDevice(path)
        print(f"OPEN  {path} -> {real}")
        print(f"        name: {dev.name!r}")
        print(f"        caps (EV_KEY count): {len(dev.capabilities().get(evdev.ecodes.EV_KEY, []))}")
        devs.append(dev)
    except Exception as e:
        print(f"FAIL  {path}: {e}")

if not devs:
    sys.exit("No devices opened.")

print("\nType for 10 seconds — events will print below:")
fd_map = {d.fd: d for d in devs}
end = time.time() + 10
while time.time() < end:
    r, _, _ = select.select(fd_map.keys(), [], [], 0.5)
    for fd in r:
        dev = fd_map[fd]
        for ev in dev.read():
            if ev.type == evdev.ecodes.EV_KEY and ev.value == 1:
                name = evdev.ecodes.KEY.get(ev.code, "?")
                if isinstance(name, list):
                    name = name[0]
                print(f"  [{dev.path}] keydown code={ev.code} name={name}")

print("Done.")
