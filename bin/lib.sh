# shellcheck shell=sh
# Shared helpers for cpuhvfs-ctl and the Magisk service scripts.
# All persistent paths are scoped to MOD_ID.  The kernel interface
# (/proc/eem, the cpuhvfs module name) is global and cannot be namespaced.

MOD_ID=${MOD_ID:-dimensity-8000-9000-cpuhvfs}
MODDIR=${MODDIR:-/data/adb/modules/$MOD_ID}
STATE_DIR=${STATE_DIR:-/data/adb/$MOD_ID}
STATE_FILE="$STATE_DIR/state"
TRIP_FILE="$STATE_DIR/trip"
LOG_FILE="$STATE_DIR/module.log"
CONFIG_FILE="$STATE_DIR/config"
KO="$MODDIR/lib/cpuhvfs.ko"
LIMITS="$MODDIR/etc/limits.conf"
EEM_DIR=/proc/eem

die() { printf 'error: %s\n' "$*" >&2; exit "${EXIT_CODE:-1}"; }

log_msg() {
  mkdir -p "$STATE_DIR" 2>/dev/null
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

get_limit() { # key default
  _v=""
  [ -f "$LIMITS" ] && _v=$(grep -E "^$1=" "$LIMITS" 2>/dev/null | head -1 | cut -d= -f2)
  [ -n "${_v:-}" ] && printf '%s' "$_v" || printf '%s' "$2"
}

get_cluster_limit() { # cluster global_default
  _v=$(get_limit "max_$1" "" 2>/dev/null)
  [ -n "$_v" ] && { printf '%s' "$_v"; return; }
  printf '%s' "$2"
}

kernel_rel() { uname -r; }

ko_vermagic() {
  [ -f "$KO" ] || return 1
  tr -d '\000' < "$KO" 2>/dev/null | grep -a -o 'vermagic=[^ ]*' | head -1 | cut -d= -f2
}

ko_match() {
  [ -n "$(ko_vermagic 2>/dev/null)" ] && [ "$(ko_vermagic)" = "$(kernel_rel)" ]
}

ko_loaded() { [ -d /sys/module/cpuhvfs ]; }
eem_present() { [ -e "$EEM_DIR/eem_offset" ]; }

current_boot_id() {
  cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf 'unknown\n'
}

# Accept only an optional minus sign followed by decimal digits.
is_int() {
  case "$1" in
    ''|-) return 1 ;;
    -[0-9]*) _n=${1#-} ;;
    [0-9]*) _n=$1 ;;
    *) return 1 ;;
  esac
  case "$_n" in
    ''|*[!0-9]*) return 1 ;;
  esac
  return 0
}

int_abs() {
  if [ "$1" -lt 0 ]; then printf '%s' "$((0 - $1))"; else printf '%s' "$1"; fi
}

state_get() {
  [ -f "$STATE_FILE" ] && grep -E "^$1=" "$STATE_FILE" 2>/dev/null | head -1 | cut -d= -f2-
}

state_get_or() { # key default
  _v=$(state_get "$1")
  [ -n "$_v" ] && printf '%s' "$_v" || printf '%s' "$2"
}

state_set() { # key value
  mkdir -p "$STATE_DIR" 2>/dev/null || return 1
  _tmp="$STATE_FILE.tmp.$$"
  if [ -f "$STATE_FILE" ]; then
    grep -v -E "^$1=" "$STATE_FILE" > "$_tmp" 2>/dev/null || : > "$_tmp"
  else
    : > "$_tmp"
  fi
  printf '%s=%s\n' "$1" "$2" >> "$_tmp"
  mv -f "$_tmp" "$STATE_FILE"
}

state_del() {
  [ -f "$STATE_FILE" ] || return 0
  _tmp="$STATE_FILE.tmp.$$"
  grep -v -E "^$1=" "$STATE_FILE" > "$_tmp" 2>/dev/null || : > "$_tmp"
  mv -f "$_tmp" "$STATE_FILE"
}

write_offset() { # cluster value
  if [ -w "$EEM_DIR/eem_offset" ]; then
    printf '%s %s\n' "$1" "$2" > "$EEM_DIR/eem_offset"
    return $?
  fi
  if command -v su >/dev/null 2>&1; then
    su -c "printf '%s %s\\n' '$1' '$2' > $EEM_DIR/eem_offset" 2>/dev/null
    return $?
  fi
  return 1
}

arm_state() {
  state_set boot_id "$(current_boot_id)"
  state_set armed 1
}

clear_arm() {
  state_set armed 0
}

ramp_sleep() {
  _s=$(get_limit ramp_delay_sec 1)
  case "$_s" in ''|*[!0-9]*) _s=1;; esac
  [ "$_s" -gt 0 ] && sleep "$_s"
}

old_module_active() {
  [ -d /data/adb/modules/dimensity_8100_9000_cpuhvfs ] &&
    [ ! -f /data/adb/modules/dimensity_8100_9000_cpuhvfs/disable ]
}
