#!/usr/bin/env bash
# Cycle the default audio INPUT (source) using wpctl.
# Filters non-hardware (snd_dummy, snd_aloop, loopback, monitors) and retries
# if WirePlumber refuses a source (e.g. unplugged analog jack).

set -euo pipefail

current_id=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null \
    | awk 'NR==1 {gsub(",","",$2); print $2}')

# Collect all audio source "ID<TAB>DESCRIPTION" pairs
mapfile -t entries < <(
    wpctl status | awk '
        /^Audio$/  {in_audio=1; next}
        /^Video$/  {in_audio=0}
        in_audio && /Sources:/     {in_src=1; next}
        in_audio && /^[[:space:]]*[├└]─/ {in_src=0}
        in_audio && in_src {
            line=$0
            sub(/^[^0-9]*/, "", line)
            if (match(line, /^[0-9]+\./)) {
                id=substr(line, 1, RLENGTH-1)
                name=substr(line, RLENGTH+1)
                sub(/^[[:space:]]+/, "", name)
                sub(/[[:space:]]*\[vol:.*\]$/, "", name)
                sub(/[[:space:]]+$/, "", name)
                print id "\t" name
            }
        }
    '
)

# Filter by node.name (canonical) — drops dummy, loopback, monitor devices.
sources=()
names=()
for entry in "${entries[@]}"; do
    IFS=$'\t' read -r id display <<<"$entry"
    node_name=$(wpctl inspect "$id" 2>/dev/null \
        | awk -F'"' '/^[[:space:]]*\*?[[:space:]]*node\.name[[:space:]]*=/ {print $2; exit}')
    case "$node_name" in
        *snd_dummy*|*snd_aloop*|*pcspkr*|*loopback*|*Loopback*|*.monitor) continue ;;
    esac
    sources+=("$id")
    names+=("$display")
done

if (( ${#sources[@]} < 2 )); then
    notify-send -u low "Mic" "Only one real input device — nothing to cycle."
    exit 0
fi

# Find current, set next — with retry loop if WirePlumber refuses.
start_idx=0
for i in "${!sources[@]}"; do
    if [[ "${sources[$i]}" == "$current_id" ]]; then
        start_idx=$(( (i + 1) % ${#sources[@]} ))
        break
    fi
done

idx=$start_idx
attempts=0
applied=0
while (( attempts < ${#sources[@]} )); do
    candidate_id="${sources[$idx]}"
    candidate_name="${names[$idx]}"
    wpctl set-default "$candidate_id" 2>/dev/null || true
    sleep 0.15
    actual=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null \
                | awk 'NR==1 {gsub(",","",$2); print $2}')
    if [[ "$actual" == "$candidate_id" ]]; then
        applied=1
        notify-send -u low "Audio input" "$candidate_name"
        break
    fi
    idx=$(( (idx + 1) % ${#sources[@]} ))
    attempts=$((attempts+1))
done

(( applied == 0 )) && notify-send -u normal "Audio input" "Failed to switch input device."
