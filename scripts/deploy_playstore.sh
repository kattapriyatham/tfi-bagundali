#!/usr/bin/env bash
#
# Upload a signed AAB to a Google Play Console track via `fastlane supply`.
#
# Usage:
#   ./scripts/deploy_playstore.sh                      # internal track
#   ./scripts/deploy_playstore.sh internal
#   ./scripts/deploy_playstore.sh production --rollout 0.2
#
# One-time setup (can't be scripted — needs your own Play Console access):
#   1. Google Cloud Console -> IAM & Admin -> Service Accounts -> create one
#      -> Keys -> Add key -> JSON. Download it.
#   2. Play Console -> Setup -> API access -> link that service account,
#      grant it "Release Manager" permission on this app (Admin also works).
#      New accounts can take a few minutes to a few hours to propagate.
#   3. Save the downloaded key as android/play-console-key.json — it's
#      gitignored, never commit it.
#   4. Install fastlane: `gem install fastlane` or `brew install fastlane`.
#
# Build the AAB first with: ./scripts/build_release.sh --bundle
#
# Every upload needs a version code (`pubspec.yaml`'s `+N` suffix) higher
# than anything already uploaded to ANY track for this app, including ones
# you've abandoned — bump it before rebuilding if a previous attempt failed
# partway through.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

TRACK="${1:-internal}"
[[ $# -gt 0 ]] && shift
KEY_FILE="android/play-console-key.json"
AAB="build/app/outputs/bundle/release/app-release.aab"
PACKAGE_NAME="io.tfibagundali.app"

if ! command -v fastlane &>/dev/null; then
  echo "error: fastlane not found. Install with: gem install fastlane" >&2
  exit 1
fi

if [[ ! -f "$KEY_FILE" ]]; then
  echo "error: $KEY_FILE not found — see setup steps in this script's header" >&2
  exit 1
fi

if [[ ! -f "$AAB" ]]; then
  echo "error: $AAB not found — run ./scripts/build_release.sh --bundle first" >&2
  exit 1
fi

echo "Uploading $AAB to Play Console track '$TRACK' ($PACKAGE_NAME)..."
fastlane run upload_to_play_store \
  track:"$TRACK" \
  package_name:"$PACKAGE_NAME" \
  aab:"$AAB" \
  json_key:"$KEY_FILE" \
  "$@"

echo
echo "Done. Check the release in Play Console under Testing/Production > $TRACK."
