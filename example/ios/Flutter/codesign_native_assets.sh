#!/bin/sh
set -euo pipefail

if [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  echo "Skipping native-asset codesign (PLATFORM_NAME=${PLATFORM_NAME:-})."
  exit 0
fi

if [ "${CODE_SIGNING_REQUIRED:-}" = "NO" ]; then
  echo "Skipping native-asset codesign (CODE_SIGNING_REQUIRED=NO)."
  exit 0
fi

if [ -z "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
  echo "Skipping native-asset codesign (no EXPANDED_CODE_SIGN_IDENTITY)."
  exit 0
fi

FRAMEWORKS_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
if [ ! -d "${FRAMEWORKS_DIR}" ]; then
  echo "No Frameworks dir at ${FRAMEWORKS_DIR}"
  exit 0
fi

# Sign only Flutter native-asset frameworks (bundle id: io.flutter.flutter.native-assets.*)
for fw in "${FRAMEWORKS_DIR}"/*.framework; do
  [ -d "${fw}" ] || continue
  plist="${fw}/Info.plist"
  [ -f "${plist}" ] || continue

  bundle_id="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "${plist}" 2>/dev/null || true)"
  case "${bundle_id}" in
    io.flutter.flutter.native-assets.*)
      echo "Codesigning native asset framework: $(basename "${fw}") (${bundle_id})"
      /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --timestamp=none "${fw}"
      ;;
  esac
done
