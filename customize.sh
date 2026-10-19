#!/system/bin/sh
# Magisk installer.  This module is deliberately kernel-locked: a .ko built
# for another kernel must not be loaded just because it is present.
SKIPUNZIP=0

ui() { command -v ui_print >/dev/null 2>&1 && ui_print "$*" || echo "$*"; }
fail() { ui "!! $*"; abort "$*"; }

MOD_ID=dimensity-8000-9000-cpuhvfs
KO="$MODPATH/lib/cpuhvfs.ko"
STATE_DIR=/data/adb/$MOD_ID

ui "Installing $MOD_ID"
ui "Target kernel: $(uname -r)"

[ -f "$KO" ] || fail "missing lib/cpuhvfs.ko"
[ "$(getprop ro.product.cpu.abi 2>/dev/null)" = "arm64-v8a" ] || fail "this package is arm64-only"

KO_VERMAGIC=$(tr -d '\000' < "$KO" 2>/dev/null | grep -a -o 'vermagic=[^ ]*' | head -1 | cut -d= -f2)
[ -n "$KO_VERMAGIC" ] || fail "cannot read vermagic from lib/cpuhvfs.ko"
[ "$KO_VERMAGIC" = "$(uname -r)" ] || fail "kernel mismatch: module=$KO_VERMAGIC device=$(uname -r)"

if [ -d /data/adb/modules/dimensity_8100_9000_cpuhvfs ] && \
   [ ! -f /data/adb/modules/dimensity_8100_9000_cpuhvfs/disable ]; then
  fail "旧模块 dimensity_8100_9000_cpuhvfs 仍启用；请先禁用它并重启，再安装本模块"
fi

if [ -e /proc/eem/eem_offset ]; then
  fail "/proc/eem 已被占用；请禁旧模块、重启确认 /proc/eem 不存在后再安装"
fi

mkdir -p "$STATE_DIR" 2>/dev/null || fail "cannot create $STATE_DIR"
chmod 700 "$STATE_DIR" 2>/dev/null || true

# Normalize executable bits after Magisk extracts the archive.
chmod 0755 "$MODPATH/bin/cpuhvfs-ctl" "$MODPATH/post-fs-data.sh" \
  "$MODPATH/service.sh" "$MODPATH/uninstall.sh" 2>/dev/null || true
chmod 0755 "$MODPATH/bin/lib.sh" 2>/dev/null || true

ui "Kernel check passed."
ui "Default: driver-only; no undervolt is applied automatically."
ui "Use: su -c '$MODPATH/bin/cpuhvfs-ctl' status"
