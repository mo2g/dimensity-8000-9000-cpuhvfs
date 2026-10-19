#!/system/bin/sh
# Runs very early, before Magisk's late service stage.
# If the previous boot ended while an offset profile was armed, do not
# silently re-use it.  The driver is normally not loaded yet, but restore
# zeros if another loader made /proc/eem available early.
MODDIR=$(cd "$(dirname "$0")" && pwd)
. "$MODDIR/bin/lib.sh"
mkdir -p "$STATE_DIR" 2>/dev/null

_prev_boot=$(state_get_or boot_id unknown)
_now_boot=$(current_boot_id)
_armed=$(state_get_or armed 0)
_state=$(state_get_or state idle)

if [ "$_armed" = "1" ] && [ "$_prev_boot" != "$_now_boot" ]; then
  printf 'reboot_during_observation\n' > "$TRIP_FILE"
  state_set applied '0 0 0 0'
  state_set armed 0
  state_set state tripped
  # Best-effort restore in case a vendor/old loader exposed eem already.
  "$MODDIR/bin/cpuhvfs-ctl" restore >/dev/null 2>&1 || true
  log_msg "circuit breaker: reboot during armed observation; offsets cleared/null, driver will not auto-load"
fi

if [ -f "$TRIP_FILE" ]; then
  log_msg "trip present: $(cat "$TRIP_FILE" 2>/dev/null); service will not load cpuhvfs"
fi
exit 0
