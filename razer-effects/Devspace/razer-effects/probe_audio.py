#!/usr/bin/env python3
"""Run the same FFT pipeline as ripple.py's audio_reader and print per-band
magnitudes once per second for 10 seconds. Use to calibrate AUDIO_NORM.

Play audio loudly while this runs.
"""
import subprocess
import sys
import time

import numpy as np  # pyright: ignore[reportMissingImports]

RATE       = 22050
CHUNK      = 1024
BAND_EDGES = [80, 250, 1000, 4000, RATE // 2]

proc = subprocess.Popen(
    [
        "parec", "--device=@DEFAULT_MONITOR@",
        "--format=s16le", f"--rate={RATE}", "--channels=1", "--raw",
        "--latency-msec=20",
    ],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)
assert proc.stdout is not None

window = np.hanning(CHUNK).astype(np.float32)
freqs = np.fft.rfftfreq(CHUNK, 1.0 / RATE)
masks = [(freqs >= lo) & (freqs < hi) for lo, hi in zip(BAND_EDGES[:-1], BAND_EDGES[1:])]

end = time.time() + 10
last_print = 0.0
peak_per_band = [0.0, 0.0, 0.0, 0.0]

while time.time() < end:
    data = proc.stdout.read(CHUNK * 2)
    if not data or len(data) < CHUNK * 2:
        print(f"parec stream ended after {len(data)} bytes", file=sys.stderr)
        break
    samples = np.frombuffer(data, dtype=np.int16).astype(np.float32) / 32768.0
    samples *= window
    spectrum = np.abs(np.fft.rfft(samples))
    for i, m in enumerate(masks):
        mag = float(spectrum[m].mean()) if m.any() else 0.0
        peak_per_band[i] = max(peak_per_band[i], mag)
    if time.time() - last_print > 1.0:
        last_print = time.time()
        rms = float(np.sqrt(np.mean(samples**2)))
        cur = [float(spectrum[m].mean()) if m.any() else 0.0 for m in masks]
        print(f"sample_rms={rms:.4f}  bands={[f'{x:.3f}' for x in cur]}  peaks_so_far={[f'{x:.3f}' for x in peak_per_band]}")

proc.terminate()
err = proc.stderr.read().decode(errors="replace") if proc.stderr else ""
if err:
    print("--- parec stderr ---", file=sys.stderr)
    print(err, file=sys.stderr)

print()
print(f"PEAK band magnitudes across 10s: {[f'{x:.3f}' for x in peak_per_band]}")
print(f"Recommend AUDIO_NORM ≈ peak * 0.5 to make full music = full bar")
