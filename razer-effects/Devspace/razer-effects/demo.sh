#!/usr/bin/env bash
# demo.sh — exercise RAM / CPU / Disk-I/O so ripple.py's bars visibly animate.
#
# Usage:
#   demo.sh                   # run all four phases in sequence (default)
#   demo.sh all               # same as no args
#   demo.sh ram               # RAM wave only
#   demo.sh cpu               # CPU wave only
#   demo.sh disk              # Disk I/O wave only
#   demo.sh finale            # all three simultaneously
#   demo.sh ram cpu           # run RAM then CPU (any combination)
#   demo.sh -h | --help       # this help
#
# Cleanup runs on EXIT (Ctrl-C safe) — kills helpers, removes temp file.

set -u

TMPFILE="$HOME/.cache/razer-demo.disk.tmp"
PIDS=()
CORES="$(nproc)"

usage() {
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

cleanup() {
    echo
    echo "==> cleanup"
    for pid in "${PIDS[@]:-}"; do
        [ -n "${pid:-}" ] && kill "$pid" 2>/dev/null || true
    done
    # belt-and-suspenders: kill anything we may have spawned
    pkill -P $$ 2>/dev/null || true
    rm -f "$TMPFILE"
    echo "    done"
}
trap cleanup EXIT INT TERM

banner() { printf '\n==> %s\n' "$*"; }

# ---------- helpers ----------------------------------------------------------

# hold N GiB of RAM resident for T seconds. Uses numpy.fill() to dirty
# every page fast — pure-Python touch is ~30x slower at 32+ GiB scale.
ram_hold() {
    local gib="$1" secs="$2"
    python3 -c "
import time, numpy as np  # pyright: ignore[reportMissingImports]
buf = np.empty(${gib} * 1024 * 1024 * 1024 // 8, dtype=np.int64)
buf.fill(1)  # dirty every page → counts toward RSS
time.sleep(${secs})
" &
    PIDS+=("$!")
}

# spin one CPU core flat-out for T seconds
cpu_burn() {
    local secs="$1"
    ( end=$((SECONDS + secs)); while [ "$SECONDS" -lt "$end" ]; do :; done ) &
    PIDS+=("$!")
}

# write N MiB to disk, fsync, then delete (one burst)
disk_burst() {
    local mib="$1"
    dd if=/dev/zero of="$TMPFILE" bs=1M count="$mib" conv=fdatasync status=none
    rm -f "$TMPFILE"
}

# ---------- phases -----------------------------------------------------------

phase_ram() {
    banner "RAM wave (watch the F-row; 62 GiB total, ~10 GiB baseline)"
    # Scale: 2→8→16→32→40 GiB on top of baseline.
    # At 40 GiB extra ≈ 80% used → ~10 of 12 F-row cells lit. Cap leaves headroom.
    for gib in 2 8 16 32 40 32 16 8 2; do
        echo "    allocate ${gib} GiB"
        ram_hold "$gib" 5
        sleep 5
        wait "${PIDS[-1]}" 2>/dev/null || true
    done
}

phase_cpu() {
    banner "CPU wave (watch the number row)"
    for n in 1 2 4 "$CORES" 4 2 1; do
        [ "$n" -gt "$CORES" ] && n="$CORES"
        echo "    burn ${n} core(s) for 3s"
        for _ in $(seq 1 "$n"); do cpu_burn 3; done
        sleep 3.2
    done
}

phase_disk() {
    banner "Disk I/O wave (watch the numpad block)"
    for mib in 64 128 256 512 1024 512 128; do
        echo "    write ${mib} MiB"
        disk_burst "$mib"
        sleep 1
    done
}

phase_finale() {
    banner "Finale — all three at once, 12s"
    ram_hold 24 12
    for _ in $(seq 1 "$CORES"); do cpu_burn 10; done
    (
        end=$((SECONDS + 10))
        while [ "$SECONDS" -lt "$end" ]; do
            dd if=/dev/zero of="$TMPFILE" bs=1M count=256 conv=fdatasync status=none
            rm -f "$TMPFILE"
        done
    ) &
    PIDS+=("$!")
    sleep 13
}

# ---------- dispatch ---------------------------------------------------------

# default: run everything
if [ "$#" -eq 0 ]; then
    set -- all
fi

# expand 'all' to the full sequence
args=()
for a in "$@"; do
    case "$a" in
        all)                 args+=(ram cpu disk finale) ;;
        ram|cpu|disk|finale) args+=("$a") ;;
        -h|--help)           usage 0 ;;
        *) echo "unknown phase: $a" >&2; usage 2 ;;
    esac
done

for a in "${args[@]}"; do
    case "$a" in
        ram)    phase_ram ;;
        cpu)    phase_cpu ;;
        disk)   phase_disk ;;
        finale) phase_finale ;;
    esac
done

echo
echo "==> demo complete"
