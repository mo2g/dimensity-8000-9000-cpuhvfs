#!/usr/bin/env bash
# Create a Magisk-installable zip from the module directory.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${OUT:-"$ROOT/dist"}
NAME="dimensity-8000-9000-cpuhvfs-$(sed -n 's/^version=//p' "$ROOT/module.prop" | head -1).zip"
mkdir -p "$OUT"
rm -f "$OUT/$NAME" "$OUT/$NAME.sha256"
command -v zip >/dev/null 2>&1 || { echo "zip is required" >&2; exit 1; }
(
  cd "$ROOT"
  zip -r -9 "$OUT/$NAME" \
    module.prop customize.sh post-fs-data.sh service.sh uninstall.sh \
    bin etc lib src configs scripts docs patches README.md README.zh-CN.md README.en.md \
    LICENSE SECURITY.md THIRD_PARTY_NOTICES.md CHANGELOG.md \
    -x '.git/*' 'dist/*' '*.DS_Store' '*/__pycache__/*'
)
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$OUT/$NAME" | tee "$OUT/$NAME.sha256"
else
  shasum -a 256 "$OUT/$NAME" | tee "$OUT/$NAME.sha256"
fi
echo "$OUT/$NAME"
