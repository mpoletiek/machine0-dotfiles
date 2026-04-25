#!/usr/bin/env bash
# Cycle the default audio OUTPUT (sink) using wpctl.
# Filters non-hardware and retries if WirePlumber refuses a sink.

set -euo pipefail

current_id=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
    | awk 'NR==1 {gsub(",","",$2); print $2}')

mapfile -t entries < <(
    wpctl status | awk '
        /^Audio$/  {in_audio=1; next}
        /^Video$/  {in_audio=0}
        in_audio && /Sinks:/       {in_snk=1; next}
        in_audio && /^[[:space:]]*[├└]─/ {in_snk=0}
        in_audio && in_snk {
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

sinks=()
names=()
for entry in "${entries[@]}"; do
    IFS=$'\t' read -r id display <<<"$entry"
    node_name=$(wpctl inspect "$id" 2>/dev/null \
        | awk -F'"' '/^[[:space:]]*\*?[[:space:]]*node\.name[[:space:]]*=/ {print $2; exit}')
    case "$node_name" in
        *snd_dummy*|*snd_aloop*|*pcspkr*|*loopback*|*Loopback*) continue ;;
    esac
    sinks+=("$id")
    names+=("$display")
done

if (( ${#sinks[@]} < 2 )); then
    notify-send -u low "Audio" "Only one real output device — nothing to cycle."
    exit 0
fi

start_idx=0
for i in "${!sinks[@]}"; do
    if [[ "${sinks[$i]}" == "$current_id" ]]; then
        start_idx=$(( (i + 1) % ${#sinks[@]} ))
        break
    fi
done

idx=$start_idx
attempts=0
applied=0
while (( attempts < ${#sinks[@]} )); do
    candidate_id="${sinks[$idx]}"
    candidate_name="${names[$idx]}"
    wpctl set-default "$candidate_id" 2>/dev/null || true
    sleep 0.15
    actual=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
                | awk 'NR==1 {gsub(",","",$2); print $2}')
    if [[ "$actual" == "$candidate_id" ]]; then
        applied=1
        notify-send -u low "Audio output" "$candidate_name"
        break
    fi
    idx=$(( (idx + 1) % ${#sinks[@]} ))
    attempts=$((attempts+1))
done

(( applied == 0 )) && notify-send -u normal "Audio output" "Failed to switch output device."
