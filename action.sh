#!/system/bin/sh
MODDIR=$(cd "$(dirname "$0")" && pwd)
exec "$MODDIR/bin/cpuhvfs-ctl" status
