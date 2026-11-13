#!/usr/bin/env bash
# Bootstrap-only no-op display stub.
#
# The 4K xnu-10063 patch makes bsd_init reference native_legacy_display_probe()
# unconditionally.  The real build-legacy-stub.py needs kern_exec.o.json and is
# run by the final archive list, but the bootstrap pass links before that list
# and therefore needs a stub that can be built without a compile record.
#
# This archive is only for the bootstrap/prelink candidate.  nuwa4k_defconfig
# still points at build/legacy-stub/libLegacyStub.a built by
# scripts/build-legacy-stub.py for the final kernel.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT="$ROOT/build/bootstrap-legacy-stub"
mkdir -p "$OUT"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
SRC="$ROOT/package/LegacyDisplayStub.c"
OBJ="$OUT/LegacyDisplayStub.o"
ARCHIVE="$OUT/libBootstrapLegacyStub.a"

test -f "$SRC" || { echo "missing $SRC" >&2; exit 1; }
"$CC" -target arm64-apple-ios17.0 -isysroot "$SDK" -mkernel -O2 \
      -ffreestanding -fno-stack-protector -fno-builtin \
      -c "$SRC" -o "$OBJ"
rm -f "$ARCHIVE"
xcrun --sdk iphoneos ar rcs "$ARCHIVE" "$OBJ"
xcrun --sdk iphoneos nm -gU "$ARCHIVE" | grep -E 'native_legacy_display_(probe|late_probe)|boot_progress_poll' >&2 || true
echo "bootstrap legacy stub: $ARCHIVE"
