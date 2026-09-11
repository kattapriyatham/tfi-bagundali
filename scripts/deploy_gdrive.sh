#!/usr/bin/env bash
#
# Build a release APK and upload it to Google Drive at apps/tfi-bagundaali/.
#
# Usage:
#   ./scripts/deploy_gdrive.sh              # build (--fast) + upload
#   ./scripts/deploy_gdrive.sh --no-build   # upload the existing APK as-is
#   ./scripts/deploy_gdrive.sh --split      # forwarded to build_release.sh
#
# Requires the `rclone` CLI with a configured remote named "gdrive"
# (`rclone listremotes` should show "gdrive:"). The chat's Google Drive tool
# can't take this file inline — a release APK is 30MB+, i.e. 40MB+ once
# base64-encoded, well past what fits in a single tool call — so this
# project uploads via rclone instead. See docs/STATUS.md.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

REMOTE="gdrive:apps/tfi-bagundaali/"
APK="build/app/outputs/flutter-apk/app-release.apk"

do_build=1
build_args=()
for arg in "$@"; do
  case "$arg" in
    --no-build) do_build=0 ;;
    *)          build_args+=("$arg") ;;
  esac
done

if ! rclone listremotes 2>/dev/null | grep -q "^gdrive:$"; then
  echo "error: no 'gdrive' rclone remote configured. Run: rclone config" >&2
  exit 1
fi

if [[ "$do_build" == "1" ]]; then
  ./scripts/build_release.sh --fast "${build_args[@]}"
fi

[[ -f "$APK" ]] || { echo "error: $APK not found — build it first" >&2; exit 1; }

echo
echo "Uploading $APK -> $REMOTE"
rclone copy "$APK" "$REMOTE" --progress

echo
echo "Done. Listing $REMOTE:"
rclone lsl "$REMOTE"
