#!/usr/bin/env python3
"""Green base + RAM-usage bar on F-row + white ripples on keypress.

Run:    .venv/bin/python ripple.py
Stop:   Ctrl-C   (restores spectrum cycling)

Layers (bottom → top):
  1. Solid green base (everywhere)
  2. Ambient: RAM usage bar on F-row (F1..F12), additive
  3. Ripples from keypresses, additive

Requires:
  - openrazer-daemon running
  - membership in 'plugdev' (to read /dev/input/event*)
  - python-evdev (installed in this project's .venv)
"""
import math
import re
import signal
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field

import evdev  # pyright: ignore[reportMissingImports]
from openrazer.client import DeviceManager

# ---------- tunables ----------
BASE_COLOR     = (0, 60, 0)        # solid green base
RIPPLE_COLOR   = (0, 255, 0)       # color added on top per ripple
SPEED          = 12.0              # ring radius growth (cells / second)
LIFETIME       = 1.0               # seconds before a ripple fades out
THICKNESS      = 1.5               # ring thickness in cells
FPS            = 30
KBD_EVDEV_PATH = "/dev/input/by-id/usb-Razer_Razer_BlackWidow_V3_Pro-if01-event-kbd"

# RAM bar overlay
RAM_BAR_ROW       = 0                    # matrix row hosting the bar (F-row)
RAM_BAR_COLS      = list(range(2, 14))   # F1..F12 → matrix cols 2..13
RAM_POLL_SECONDS  = 1.0                  # /proc/meminfo polling interval
RAM_BAR_COLOR     = (255, 0, 0)          # color added on top of green for lit F-keys

# CPU bar overlay
CPU_BAR_ROW       = 1                    # number row
CPU_BAR_COLS      = list(range(1, 11))   # keys 1..0 → matrix cols 1..10
CPU_POLL_SECONDS  = 1.0                  # /proc/stat sample interval
CPU_BAR_COLOR     = (255, 0, 0)          # color added on top of green for lit number keys

# Audio-reactive VU bars (numpad area)
AUDIO_DEVICE      = "@DEFAULT_MONITOR@"  # parec source (default sink's monitor)
AUDIO_RATE        = 22050                # Hz
AUDIO_CHUNK       = 1024                 # samples per FFT frame
AUDIO_BAR_COLS    = list(range(0, 14))   # 14 bands: LCtrl → RCtrl across main typing area
AUDIO_BAR_ROWS    = [5, 4, 3, 2]         # bottom → top: Ctrl/Win/Alt row up to QWERTY row
# 14 log-spaced edges 60–6000 Hz: bass → low-mid → mid → high-mid → presence
AUDIO_BAND_EDGES  = [60, 85, 115, 160, 225, 310, 430, 600, 835, 1160, 1610, 2240, 3100, 4320, 6000]
AUDIO_GAIN_DECAY  = 0.993                # per-band peak decay per FFT frame (~21 Hz)
AUDIO_DECAY       = 0.85                 # peak-hold decay per frame (slow falloff)
AUDIO_BAR_COLOR   = (255, 0, 255)        # magenta — distinct from red bars

# Disk I/O monitor (numpad 3×4 block, bottom-up)
DISK_BAR_COLS     = [17, 18, 19]         # KP{1,2,3} / KP{4,5,6} / KP{7,8,9} / NumLk row
DISK_BAR_ROWS     = [4, 3, 2, 1]         # bottom (KP1-3) → top (NumLk//*)
DISK_POLL_SECONDS = 0.5                  # responsive to bursts
DISK_GAIN_DECAY   = 0.985                # peak-tracking decay per poll
DISK_BAR_COLOR    = (0, 100, 255)        # blue
# Whole-disk devices only (skip partitions, loop, ram, dm)
DISK_DEV_RE       = re.compile(r"^(sd[a-z]|nvme\d+n\d+|vd[a-z]|hd[a-z]|mmcblk\d+)$")
# -------------------------------

# evdev-keyname -> (row, col) on the BlackWidow V3 Pro matrix (US ANSI).
# Derived from openrazer_daemon/keyboard.py:KEY_MAPPING with -1 col shift:
# canonical col 0 is the M1-M6 macro-key column (not physically present on the
# V3 Pro), so real keys start at canonical col 1 == hardware matrix col 0.
KEY_MAP = {
    # Row 0 (F-row + media cluster)
    "KEY_ESC": (0, 0),
    "KEY_F1": (0, 2),  "KEY_F2": (0, 3),  "KEY_F3": (0, 4),  "KEY_F4": (0, 5),
    "KEY_F5": (0, 6),  "KEY_F6": (0, 7),  "KEY_F7": (0, 8),  "KEY_F8": (0, 9),
    "KEY_F9": (0, 10), "KEY_F10": (0, 11), "KEY_F11": (0, 12), "KEY_F12": (0, 13),
    "KEY_SYSRQ": (0, 14), "KEY_SCROLLLOCK": (0, 15), "KEY_PAUSE": (0, 16),
    # Row 1 (number row + nav + numpad top)
    "KEY_GRAVE": (1, 0),
    "KEY_1": (1, 1), "KEY_2": (1, 2), "KEY_3": (1, 3), "KEY_4": (1, 4),
    "KEY_5": (1, 5), "KEY_6": (1, 6), "KEY_7": (1, 7), "KEY_8": (1, 8),
    "KEY_9": (1, 9), "KEY_0": (1, 10),
    "KEY_MINUS": (1, 11), "KEY_EQUAL": (1, 12), "KEY_BACKSPACE": (1, 13),
    "KEY_INSERT": (1, 14), "KEY_HOME": (1, 15), "KEY_PAGEUP": (1, 16),
    "KEY_NUMLOCK": (1, 17), "KEY_KPSLASH": (1, 18),
    "KEY_KPASTERISK": (1, 19), "KEY_KPMINUS": (1, 20),
    # Row 2 (QWERTY + nav + numpad)
    "KEY_TAB": (2, 0),
    "KEY_Q": (2, 1), "KEY_W": (2, 2), "KEY_E": (2, 3), "KEY_R": (2, 4),
    "KEY_T": (2, 5), "KEY_Y": (2, 6), "KEY_U": (2, 7), "KEY_I": (2, 8),
    "KEY_O": (2, 9), "KEY_P": (2, 10),
    "KEY_LEFTBRACE": (2, 11), "KEY_RIGHTBRACE": (2, 12),
    "KEY_DELETE": (2, 14), "KEY_END": (2, 15), "KEY_PAGEDOWN": (2, 16),
    "KEY_KP7": (2, 17), "KEY_KP8": (2, 18), "KEY_KP9": (2, 19),
    "KEY_KPPLUS": (2, 20),
    # Row 3 (home row + numpad)
    "KEY_CAPSLOCK": (3, 0),
    "KEY_A": (3, 1), "KEY_S": (3, 2), "KEY_D": (3, 3), "KEY_F": (3, 4),
    "KEY_G": (3, 5), "KEY_H": (3, 6), "KEY_J": (3, 7), "KEY_K": (3, 8),
    "KEY_L": (3, 9), "KEY_SEMICOLON": (3, 10), "KEY_APOSTROPHE": (3, 11),
    "KEY_BACKSLASH": (3, 12), "KEY_ENTER": (3, 13),
    "KEY_KP4": (3, 17), "KEY_KP5": (3, 18), "KEY_KP6": (3, 19),
    # Row 4 (ZXCV + arrow up + numpad)
    "KEY_LEFTSHIFT": (4, 0),
    "KEY_Z": (4, 2), "KEY_X": (4, 3), "KEY_C": (4, 4), "KEY_V": (4, 5),
    "KEY_B": (4, 6), "KEY_N": (4, 7), "KEY_M": (4, 8),
    "KEY_COMMA": (4, 9), "KEY_DOT": (4, 10), "KEY_SLASH": (4, 11),
    "KEY_RIGHTSHIFT": (4, 13), "KEY_UP": (4, 15),
    "KEY_KP1": (4, 17), "KEY_KP2": (4, 18), "KEY_KP3": (4, 19),
    "KEY_KPENTER": (4, 20),
    # Row 5 (modifiers + space + arrows + numpad)
    "KEY_LEFTCTRL": (5, 0), "KEY_LEFTMETA": (5, 1), "KEY_LEFTALT": (5, 2),
    "KEY_SPACE": (5, 6),
    "KEY_RIGHTALT": (5, 10), "KEY_FN": (5, 11),
    "KEY_MENU": (5, 12), "KEY_RIGHTCTRL": (5, 13),
    "KEY_LEFT": (5, 14), "KEY_DOWN": (5, 15), "KEY_RIGHT": (5, 16),
    "KEY_KP0": (5, 18), "KEY_KPDOT": (5, 19),
}


@dataclass
class Ripple:
    row: int
    col: int
    birth: float


@dataclass
class State:
    ripples: list[Ripple] = field(default_factory=list)
    ram_used_ratio: float = 0.0   # 0..1
    cpu_used_ratio: float = 0.0   # 0..1, aggregate across cores
    audio_bands: list[float] = field(default_factory=lambda: [0.0] * 14)
    disk_io_ratio: float = 0.0   # 0..1, auto-gained


def find_keyboard():
    for d in DeviceManager().devices:
        if d.type == "keyboard" and d.has("lighting_led_matrix"):
            return d
    sys.exit("No keyboard with per-key RGB found. Is openrazer-daemon running?")


def read_ram_used_ratio() -> float:
    """Return current memory pressure as (Total - Available) / Total in [0, 1]."""
    try:
        total = avail = None
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    total = int(line.split()[1])
                elif line.startswith("MemAvailable:"):
                    avail = int(line.split()[1])
                if total is not None and avail is not None:
                    break
        if not total or avail is None:
            return 0.0
        return max(0.0, min(1.0, (total - avail) / total))
    except Exception:
        return 0.0


def ram_reader(state, lock, stop_event):
    """Thread: refresh state.ram_used_ratio from /proc/meminfo on a slow tick."""
    while not stop_event.is_set():
        v = read_ram_used_ratio()
        with lock:
            state.ram_used_ratio = v
        # Use wait() so SIGTERM/SIGINT wake us promptly
        stop_event.wait(RAM_POLL_SECONDS)


def read_cpu_times() -> tuple[int, int]:
    """Return (total_jiffies, idle_jiffies) from the aggregate /proc/stat line."""
    with open("/proc/stat") as f:
        parts = f.readline().split()
    # parts[0] = "cpu"; rest = user nice system idle iowait irq softirq steal guest guest_nice
    nums = [int(x) for x in parts[1:]]
    idle = nums[3] + (nums[4] if len(nums) > 4 else 0)  # idle + iowait
    return sum(nums), idle


def cpu_reader(state, lock, stop_event):
    """Thread: compute aggregate CPU utilization from /proc/stat deltas."""
    prev_total, prev_idle = read_cpu_times()
    while not stop_event.is_set():
        if stop_event.wait(CPU_POLL_SECONDS):
            return
        total, idle = read_cpu_times()
        d_total = total - prev_total
        d_idle = idle - prev_idle
        usage = max(0.0, min(1.0, 1.0 - d_idle / d_total)) if d_total > 0 else 0.0
        with lock:
            state.cpu_used_ratio = usage
        prev_total, prev_idle = total, idle


def read_disk_total_sectors() -> int:
    """Sum read+write sectors across whole-disk devices in /proc/diskstats."""
    total = 0
    try:
        with open("/proc/diskstats") as f:
            for line in f:
                parts = line.split()
                if len(parts) < 14:
                    continue
                if not DISK_DEV_RE.match(parts[2]):
                    continue
                total += int(parts[5]) + int(parts[9])  # sectors_read + sectors_written
    except Exception:
        return 0
    return total


def disk_reader(state, lock, stop_event):
    """Thread: compute aggregate disk I/O rate, auto-gained to 0..1."""
    prev = read_disk_total_sectors()
    peak = 1024.0  # ~512 KB/s starting reference (sectors=512 bytes)
    while not stop_event.is_set():
        if stop_event.wait(DISK_POLL_SECONDS):
            return
        now = read_disk_total_sectors()
        delta = max(0, now - prev) / DISK_POLL_SECONDS  # sectors/sec
        prev = now
        peak = max(peak * DISK_GAIN_DECAY, delta)
        ratio = delta / max(peak, 1.0)
        with lock:
            state.disk_io_ratio = max(0.0, min(1.0, ratio))


def audio_reader(state, lock, stop_event):
    """Thread: read default-sink monitor via parec, compute spectrum band amplitudes."""
    import numpy as np  # local: a missing/broken numpy shouldn't kill the script
    cmd = [
        "parec",
        f"--device={AUDIO_DEVICE}",
        "--format=s16le",
        f"--rate={AUDIO_RATE}",
        "--channels=1",
        "--raw",
        "--latency-msec=20",
    ]
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        print("parec not found — install pipewire-pulse or pulseaudio-utils", file=sys.stderr)
        return

    chunk_bytes = AUDIO_CHUNK * 2  # int16 = 2 bytes
    window = np.hanning(AUDIO_CHUNK).astype(np.float32)
    freqs = np.fft.rfftfreq(AUDIO_CHUNK, 1.0 / AUDIO_RATE)
    band_masks = [
        (freqs >= lo) & (freqs < hi)
        for lo, hi in zip(AUDIO_BAND_EDGES[:-1], AUDIO_BAND_EDGES[1:])
    ]
    n_bands = len(band_masks)
    # Auto-gain: each band tracks its own slowly-decaying peak as the
    # normalization reference. Initialize tiny but non-zero to avoid div/0.
    peaks = [1e-6] * n_bands
    smoothed = [0.0] * n_bands

    try:
        while not stop_event.is_set():
            assert proc.stdout is not None
            data = proc.stdout.read(chunk_bytes)
            if not data or len(data) < chunk_bytes:
                break
            samples = np.frombuffer(data, dtype=np.int16).astype(np.float32) / 32768.0
            samples *= window
            spectrum = np.abs(np.fft.rfft(samples))
            new = []
            for i, mask in enumerate(band_masks):
                mag = float(spectrum[mask].mean()) if mask.any() else 0.0
                peaks[i] = max(peaks[i] * AUDIO_GAIN_DECAY, mag)
                new.append(min(1.0, mag / peaks[i]))
            # Fast attack, slow decay (classic VU peak-hold smoothing for display)
            smoothed = [max(n, s * AUDIO_DECAY) for s, n in zip(smoothed, new)]
            with lock:
                state.audio_bands = list(smoothed)
    finally:
        proc.terminate()


def keypress_reader(state, lock, stop_event):
    """Thread: append a Ripple at the matrix position of each keydown."""
    try:
        dev = evdev.InputDevice(KBD_EVDEV_PATH)
    except (FileNotFoundError, PermissionError) as e:
        print(f"Could not open {KBD_EVDEV_PATH}: {e}", file=sys.stderr)
        stop_event.set()
        return

    print(f"Listening for keys on {dev.name}")
    for ev in dev.read_loop():
        if stop_event.is_set():
            return
        if ev.type != evdev.ecodes.EV_KEY or ev.value != 1:  # 1 = key down
            continue
        name = evdev.ecodes.KEY.get(ev.code)
        if name is None:
            continue
        if isinstance(name, list):
            name = name[0]
        pos = KEY_MAP.get(name)
        if pos is None:
            continue
        with lock:
            state.ripples.append(Ripple(row=pos[0], col=pos[1], birth=time.time()))


def render(kbd, state, lock):
    rows = kbd.fx.advanced.rows
    cols = kbd.fx.advanced.cols
    now = time.time()

    with lock:
        state.ripples[:] = [rp for rp in state.ripples if (now - rp.birth) < LIFETIME]
        active = list(state.ripples)
        ram_ratio = state.ram_used_ratio
        cpu_ratio = state.cpu_used_ratio
        bands = list(state.audio_bands)
        disk_ratio = state.disk_io_ratio

    br, bg, bb = BASE_COLOR
    rr_c, rg_c, rb_c = RIPPLE_COLOR

    # Precompute 1D ambient bars: (row, set-of-lit-cols, rgb-color)
    overlays = []
    for ratio, bar_row, bar_cols, bar_color in (
        (ram_ratio, RAM_BAR_ROW, RAM_BAR_COLS, RAM_BAR_COLOR),
        (cpu_ratio, CPU_BAR_ROW, CPU_BAR_COLS, CPU_BAR_COLOR),
    ):
        filled = int(round(ratio * len(bar_cols)))
        overlays.append((bar_row, set(bar_cols[:filled]), bar_color))

    # Precompute 2D audio VU cells (row, col) for fast lookup
    audio_lit = set()
    for band_idx, col in enumerate(AUDIO_BAR_COLS):
        if band_idx >= len(bands):
            break
        rows_lit = int(round(bands[band_idx] * len(AUDIO_BAR_ROWS)))
        for i in range(rows_lit):
            audio_lit.add((AUDIO_BAR_ROWS[i], col))

    # Precompute 2D disk I/O fill cells (full row at each level)
    disk_lit = set()
    disk_filled = int(round(disk_ratio * len(DISK_BAR_ROWS)))
    for i in range(disk_filled):
        for col in DISK_BAR_COLS:
            disk_lit.add((DISK_BAR_ROWS[i], col))

    for r in range(rows):
        for c in range(cols):
            # 1. base
            out_r, out_g, out_b = br, bg, bb

            # 2. ambient bars (replace base on lit cells — keeps colors pure)
            painted = False
            for ov_row, ov_lit, ov_color in overlays:
                if r == ov_row and c in ov_lit:
                    out_r, out_g, out_b = ov_color
                    painted = True
                    break
            if not painted and (r, c) in audio_lit:
                out_r, out_g, out_b = AUDIO_BAR_COLOR
            elif not painted and (r, c) in disk_lit:
                out_r, out_g, out_b = DISK_BAR_COLOR

            # 3. ripples
            for rp in active:
                age = now - rp.birth
                ring = age * SPEED
                dist = math.hypot(r - rp.row, c - rp.col)
                diff = abs(dist - ring)
                if diff < THICKNESS:
                    fade = 1.0 - (age / LIFETIME)
                    edge = 1.0 - (diff / THICKNESS)
                    intensity = fade * edge
                    out_r += int(rr_c * intensity)
                    out_g += int(rg_c * intensity)
                    out_b += int(rb_c * intensity)

            kbd.fx.advanced.matrix[r, c] = (
                min(out_r, 255), min(out_g, 255), min(out_b, 255)
            )
    kbd.fx.advanced.draw()


def main():
    kbd = find_keyboard()
    print(f"Driving {kbd.name} ({kbd.fx.advanced.rows}x{kbd.fx.advanced.cols}).")

    state = State()
    lock = threading.Lock()
    stop_event = threading.Event()

    def on_exit(*_):
        stop_event.set()
        kbd.fx.spectrum()
        sys.exit(0)

    signal.signal(signal.SIGINT, on_exit)
    signal.signal(signal.SIGTERM, on_exit)

    threading.Thread(target=keypress_reader, args=(state, lock, stop_event), daemon=True).start()
    threading.Thread(target=ram_reader,      args=(state, lock, stop_event), daemon=True).start()
    threading.Thread(target=cpu_reader,      args=(state, lock, stop_event), daemon=True).start()
    threading.Thread(target=audio_reader,    args=(state, lock, stop_event), daemon=True).start()
    threading.Thread(target=disk_reader,     args=(state, lock, stop_event), daemon=True).start()

    frame_budget = 1.0 / FPS
    while not stop_event.is_set():
        start = time.time()
        render(kbd, state, lock)
        time.sleep(max(0.0, frame_budget - (time.time() - start)))


if __name__ == "__main__":
    main()
