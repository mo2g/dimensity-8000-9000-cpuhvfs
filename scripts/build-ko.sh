#!/usr/bin/env bash
# Build lib/cpuhvfs.ko against an already-built pearl kernel tree.
#
# Required:
#   KERNEL_SRC=/path/to/pearl-s-oss-5.10.136
#   KERNEL_OUT=/path/to/the/out/directory/used/to/build/Image
#
# The output kernel must have the same .config, Module.symvers, compiler and
# LOCALVERSION as the kernel on the device.  The vendor symbols file contains
# the CRCs exported by the device's mcupm.ko and mtk_tinysys_ipi.ko.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KERNEL_SRC=${KERNEL_SRC:-}
KERNEL_OUT=${KERNEL_OUT:-}
SYMVERS=${SYMVERS:-"$ROOT/configs/pearl-vendor-symbols.symvers"}
COPY=0
[ "${1:-}" = "--copy" ] && COPY=1

if [ -z "$KERNEL_SRC" ] || [ -z "$KERNEL_OUT" ]; then
  echo "usage: KERNEL_SRC=... KERNEL_OUT=... $0 [--copy]" >&2
  exit 1
fi
KERNEL_SRC=$(cd "$KERNEL_SRC" && pwd)
KERNEL_OUT=$(cd "$KERNEL_OUT" && pwd)
[ -f "$KERNEL_OUT/Module.symvers" ] || { echo "missing $KERNEL_OUT/Module.symvers" >&2; exit 1; }
[ -f "$KERNEL_OUT/include/config/kernel.release" ] || { echo "missing built kernel.release" >&2; exit 1; }
[ -f "$SYMVERS" ] || { echo "missing vendor symbol file: $SYMVERS" >&2; exit 1; }

WORK="$KERNEL_SRC/drivers/misc/mediatek/cpuhvfs-build"
if [ -e "$WORK" ]; then
  echo "refusing to overwrite existing build dir: $WORK" >&2
  echo "remove it manually if it is a previous temporary build" >&2
  exit 1
fi
mkdir -p "$WORK"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT INT TERM

cp "$ROOT"/src/*.c "$ROOT"/src/*.h "$ROOT/src/Makefile" "$ROOT/src/Kconfig" "$WORK"/

# A normal Android kernel build already has these tools in PATH.  Users who
# built with a standalone LLVM can pass CLANG_DIR.
if [ -n "${CLANG_DIR:-}" ]; then
  export PATH="$CLANG_DIR:$PATH"
fi
command -v clang >/dev/null 2>&1 || { echo "clang not found (set CLANG_DIR)" >&2; exit 1; }
command -v ld.lld >/dev/null 2>&1 || { echo "ld.lld not found (set CLANG_DIR)" >&2; exit 1; }

make -C "$KERNEL_SRC" O="$KERNEL_OUT" M=drivers/misc/mediatek/cpuhvfs-build \
  ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  CONFIG_MEDIATEK_CPUFREQ_DEBUG=m \
  CONFIG_MTK_TINYSYS_MCUPM_SUPPORT=m \
  CONFIG_MTK_IPI=m \
  KBUILD_EXTRA_SYMBOLS="$SYMVERS" \
  modules

KO="$KERNEL_OUT/drivers/misc/mediatek/cpuhvfs-build/cpuhvfs.ko"
[ -f "$KO" ] || { echo "build finished but $KO is missing" >&2; exit 1; }

EXPECTED=$(cat "$KERNEL_OUT/include/config/kernel.release")
if command -v modinfo >/dev/null 2>&1; then
  ACTUAL=$(modinfo -F vermagic "$KO" | awk '{print $1}')
  [ "$ACTUAL" = "$EXPECTED" ] || {
    echo "vermagic mismatch: $ACTUAL != $EXPECTED" >&2
    exit 1
  }
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$KO"
else
  shasum -a 256 "$KO"
fi

if [ "$COPY" = "1" ]; then
  cp "$KO" "$ROOT/lib/cpuhvfs.ko"
  echo "copied to $ROOT/lib/cpuhvfs.ko"
fi
echo "built: $KO"
