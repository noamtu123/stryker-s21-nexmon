#!/bin/bash
# Assemble the Stryker S21 Nexmon Backend KernelSU-Next / Magisk module zip.
#
# Provide the built artifacts via env vars (or edit the defaults):
#   AIRCRACK_DIR  dir with native airodump-ng / aireplay-ng (aircrack-ng build)
#   WTOOLS_DIR    dir with native iwpriv / iwconfig / iwlist (wireless_tools)
#   NEXUTIL       path to the Nexmon nexutil binary
#   APK           path to the fork debug APK (bundled so the module installs it)
#   OUT           output zip path
#
# Native tool build notes are in ../README.md (NDK r27c, OpenSSL, zlib,
# aircrack-ng 1.7 built --disable-libnl with the AIRCRACK_NEXMON osdep patch).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

AIRCRACK_DIR="${AIRCRACK_DIR:?set AIRCRACK_DIR}"
WTOOLS_DIR="${WTOOLS_DIR:?set WTOOLS_DIR}"
NEXUTIL="${NEXUTIL:?set NEXUTIL}"
APK="${APK:?set APK}"
OUT="${OUT:-$HERE/stryker-s21-backend.zip}"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/system/bin" "$STAGE/META-INF/com/google/android"

# scripts (force LF)
for f in module.prop customize.sh service.sh action.sh; do
  sed 's/\r$//' "$HERE/$f" > "$STAGE/$f"
done
sed 's/\r$//' "$HERE/META-INF/com/google/android/update-binary"  > "$STAGE/META-INF/com/google/android/update-binary"
sed 's/\r$//' "$HERE/META-INF/com/google/android/updater-script" > "$STAGE/META-INF/com/google/android/updater-script"
chmod 0755 "$STAGE"/*.sh "$STAGE/META-INF/com/google/android/update-binary"

# native tools
cp "$AIRCRACK_DIR/airodump-ng" "$STAGE/system/bin/airodump-ng"
cp "$AIRCRACK_DIR/aireplay-ng" "$STAGE/system/bin/aireplay-ng"
cp "$WTOOLS_DIR/iwpriv"        "$STAGE/system/bin/iwpriv"
cp "$WTOOLS_DIR/iwconfig"      "$STAGE/system/bin/iwconfig"
cp "$WTOOLS_DIR/iwlist"        "$STAGE/system/bin/iwlist"
cp "$NEXUTIL"                  "$STAGE/system/bin/nexutil"
chmod 0755 "$STAGE/system/bin/"*

# fork app
cp "$APK" "$STAGE/stryker.apk"

rm -f "$OUT"
( cd "$STAGE" && zip -r -X -9 "$OUT" . >/dev/null )
echo "built: $OUT"
