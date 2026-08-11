#!/usr/bin/env bash
# Brightness control over DDC/CI for external monitors.
#
# brightnessctl only drives /sys/class/backlight, which is populated solely by
# an internal laptop panel (eDP). On a desktop that directory is empty, so
# brightnessctl silently falls back to the first /sys/class/leds device and
# toggles a keyboard LED instead. External monitors are driven over DDC/CI on
# the connector's I2C bus, which is what ddcutil speaks.
#
# Usage: brightness.sh up|down|set <0-100>|get
set -euo pipefail

STEP="${BRIGHTNESS_STEP:-5}"
VCP_BRIGHTNESS=10

runtime="${XDG_RUNTIME_DIR:-/tmp}"
bus_cache="$runtime/ddc-brightness-bus"
lock_file="$runtime/ddc-brightness.lock"

usage() {
    printf 'usage: %s up|down|set <0-100>|get\n' "${0##*/}" >&2
}

# A full `ddcutil detect` costs about a second. A held-down key must not pay
# that on every repeat, so the resolved bus is cached for the session.
detect_bus() {
    ddcutil detect 2>/dev/null \
        | awk '/I2C bus:/ { sub(/^.*\/dev\/i2c-/, "", $0); print $0; exit }'
}

resolve_bus() {
    if [ -s "$bus_cache" ]; then
        cat "$bus_cache"
        return 0
    fi
    local bus
    bus="$(detect_bus)"
    if [ -z "$bus" ]; then
        printf 'brightness: no DDC/CI-capable display found\n' >&2
        return 1
    fi
    printf '%s' "$bus" >"$bus_cache"
    printf '%s' "$bus"
}

# --noverify skips the read-back after a write, roughly halving round trips.
run_ddc() {
    local bus="$1"; shift
    ddcutil --bus "$bus" --noverify "$@" 2>/dev/null
}

main() {
    local action="${1:-}"
    local -a op

    case "$action" in
        up)   op=(setvcp "$VCP_BRIGHTNESS" + "$STEP") ;;
        down) op=(setvcp "$VCP_BRIGHTNESS" - "$STEP") ;;
        set)
            local value="${2:-}"
            case "$value" in
                ''|*[!0-9]*) usage; return 2 ;;
            esac
            [ "$value" -le 100 ] || { usage; return 2; }
            op=(setvcp "$VCP_BRIGHTNESS" "$value")
            ;;
        get)  op=(getvcp "$VCP_BRIGHTNESS") ;;
        *)    usage; return 2 ;;
    esac

    # Drop this invocation if another is already talking to the monitor.
    # Key repeat outruns DDC, and queued writes would keep dimming long after
    # the key is released.
    exec 9>"$lock_file"
    flock -n 9 || return 0

    local bus
    bus="$(resolve_bus)" || return 1

    if run_ddc "$bus" "${op[@]}"; then
        return 0
    fi

    # A cached bus goes stale when the monitor moves ports or is replugged.
    # Re-detect once before giving up.
    rm -f "$bus_cache"
    bus="$(resolve_bus)" || return 1
    run_ddc "$bus" "${op[@]}"
}

main "$@"
