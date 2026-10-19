#!/system/bin/sh
# Magisk uninstall hook.  Restore zero offsets before removing the driver.
MODDIR=$(cd "$(dirname "$0")" && pwd)
. "$MODDIR/bin/lib.sh"

"$MODDIR/bin/cpuhvfs-ctl" restore >/dev/null 2>&1 || true
"$MODDIR/bin/cpuhvfs-ctl" unload >/dev/null 2>&1 || true
rm -rf "$STATE_DIR" 2>/dev/null || true
exit 0
