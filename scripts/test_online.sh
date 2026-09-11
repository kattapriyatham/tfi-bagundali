#!/usr/bin/env bash
#
# Runs `flutter test` against a live Firebase Local Emulator Suite instance.
# Starts the emulators, waits for them, runs tests, always tears down.
#
# Usage:
#   ./scripts/test_online.sh                    # all tests
#   ./scripts/test_online.sh test/rooms/         # a subset

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

firebase emulators:exec \
  --project spndex-37b0d \
  "flutter test --dart-define=USE_FIREBASE_EMULATOR=true ${*:-test}"
