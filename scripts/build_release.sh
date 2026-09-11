#!/usr/bin/env bash
#
# Build a release Android artifact with env vars from .env.
#
# Usage:
#   ./scripts/build_release.sh              # universal release APK
#   ./scripts/build_release.sh --fast       # arm64 only — quickest, any modern phone
#   ./scripts/build_release.sh --split      # per-ABI APKs (smaller downloads)
#   ./scripts/build_release.sh --bundle     # AAB for the Play Store
#   ./scripts/build_release.sh .env.prod    # use a different env file
#
# Each KEY=VALUE in the env file is passed to the build as
# --dart-define=KEY=VALUE (read in Dart via String.fromEnvironment), same
# as scripts/run_dev.sh.
#
# NOTE: android/app/build.gradle.kts still signs the `release` build type
# with the debug keystore (Flutter template default). The APK/AAB builds
# and installs fine for sideloading and internal testing; wire a real
# signingConfig (keystore + key.properties) before shipping to the Play
# Store.

set -euo pipefail

# Repo root, regardless of where the script is called from.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

target="apk"
extra=()
ENV_FILE=".env"
for arg in "$@"; do
  case "$arg" in
    --fast)   extra+=(--target-platform android-arm64) ;;
    --split)  extra+=(--split-per-abi) ;;
    --bundle) target="appbundle" ;;
    *)        ENV_FILE="$arg" ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: $ENV_FILE not found. Create it with: cp .env.example .env" >&2
  exit 1
fi

# --- Parse env file into --dart-define args (mirrors scripts/run_dev.sh) ---
DART_DEFINES=()
while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="${raw#"${raw%%[![:space:]]*}"}"          # ltrim
  [[ -z "$line" || "$line" == \#* ]] && continue  # skip blank / comment
  line="${line#export }"
  key="${line%%=*}"
  val="${line#*=}"
  key="${key%"${key##*[![:space:]]}"}"           # rtrim key
  val="${val%\"}"; val="${val#\"}"               # strip double quotes
  val="${val%\'}"; val="${val#\'}"               # strip single quotes
  [[ -z "$key" ]] && continue
  DART_DEFINES+=(--dart-define="${key}=${val}")
done < "$ENV_FILE"

echo "Env file:     $ENV_FILE"
echo "dart-defines: ${#DART_DEFINES[@]}"
echo "Target:       $target ${extra[*]-}"
echo

flutter build "$target" --release \
  "${DART_DEFINES[@]}" \
  ${extra[@]+"${extra[@]}"}

echo
if [[ "$target" == "appbundle" ]]; then
  ls -lh build/app/outputs/bundle/release/*.aab
else
  ls -lh build/app/outputs/flutter-apk/*.apk
fi
