#!/system/bin/sh
# Late boot service.  Safe default: load the driver only; never write an
# undervolt offset here.  Smart Power (or the user) must call cpuhvfs-ctl.
MODDIR=$(cd "$(dirname "$0")" && pwd)
. "$MODDIR/bin/lib.sh"
mkdir -p "$STATE_DIR" 2>/dev/null

if old_module_active; then
  log_msg "old dimensity_8100_9000_cpuhvfs module is enabled; refusing to load"
  exit 0
fi

if [ -e "$TRIP_FILE" ]; then
  log_msg "trip active; refusing to load: $(cat "$TRIP_FILE" 2>/dev/null)"
  exit 0
fi

# Wait for the normal Android boot to finish, but do not block forever.
i=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$i" -lt 120 ]; do
  sleep 2
  i=$((i + 1))
done

if [ -e "$TRIP_FILE" ]; then
  log_msg "trip appeared while waiting; refusing to load"
  exit 0
fi

"$MODDIR/bin/cpuhvfs-ctl" load >>"$LOG_FILE" 2>&1
_rc=$?
if [ "$_rc" -ne 0 ]; then
  log_msg "driver load failed rc=$_rc (no voltage was changed)"
  exit 0
fi

# Standalone observation timer.  Smart Power has its own timer; this one
# only confirms a profile applied through cpuhvfs-ctl.
if [ "$(state_get_or armed 0)" = "1" ]; then
  _observe=$(get_limit observe_sec 600)
  case "$_observe" in ''|*[!0-9]*) _observe=600;; esac
  _boot=$(current_boot_id)
  (
    sleep "$_observe"
    if [ "$(current_boot_id)" = "$_boot" ] && [ "$(state_get_or armed 0)" = "1" ]; then
      state_set armed 0
      state_set state confirmed
      log_msg "standalone observation passed; profile confirmed for this boot"
    fi
  ) &
fi

log_msg "driver loaded; no offsets applied (default_action=none)"
exit 0
