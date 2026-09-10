#!/usr/bin/env bash
#
# Run the Flutter app on an Android emulator with env vars from .env.
#
# Usage:
#   ./scripts/run_dev.sh                 # uses .env
#   ./scripts/run_dev.sh .env.staging    # uses a different env file
#   ANDROID_EMULATOR=Pixel_7_API_34 ./scripts/run_dev.sh
#
# Each KEY=VALUE in the env file is passed to the app as
# --dart-define=KEY=VALUE (read in Dart via String.fromEnvironment).

set -euo pipefail

# Repo root, regardless of where the script is called from.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

ENV_FILE="${1:-.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: $ENV_FILE not found. Create it with: cp .env.example .env" >&2
  exit 1
fi

# --- Parse env file into --dart-define args ---
DART_DEFINES=()
ENV_ANDROID_EMULATOR=""
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
  [[ "$key" == "ANDROID_EMULATOR" ]] && ENV_ANDROID_EMULATOR="$val"
done < "$ENV_FILE"

# Precedence: shell env > env file > built-in default.
EMULATOR_ID="${ANDROID_EMULATOR:-${ENV_ANDROID_EMULATOR:-Medium_Phone_API_35}}"

# --- Ensure an Android device is attached ---
android_device() {
  adb devices | awk 'NR>1 && $2=="device" {print $1; exit}'
}

DEVICE_ID="$(android_device || true)"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No Android device attached. Launching emulator: $EMULATOR_ID"
  flutter emulators --launch "$EMULATOR_ID"
  echo "Waiting for emulator to boot..."
  adb wait-for-device
  until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
    sleep 2
  done
  DEVICE_ID="$(android_device)"
fi

echo "Device:       $DEVICE_ID"
echo "Env file:     $ENV_FILE"
echo "dart-defines: ${#DART_DEFINES[@]}"

exec flutter run -d "$DEVICE_ID" "${DART_DEFINES[@]}"
