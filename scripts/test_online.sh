#!/usr/bin/env bash
#
# Runs the online-multiplayer integration tests (real firebase_auth /
# firebase_database / cloud_firestore plugins) against a live Firebase
# Local Emulator Suite instance, on a connected Android device/emulator.
#
# integration_test needs a real platform — plain `flutter test` runs on
# the Dart VM with no native platform behind it, so firebase_auth etc.
# (federated plugins using platform channels) fail with a channel error
# regardless of whether the emulator is running.
#
# Usage:
#   ./scripts/test_online.sh                                    # all integration tests
#   ./scripts/test_online.sh integration_test/anon_auth_test.dart
#   DEVICE=emulator-5554 ./scripts/test_online.sh

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

DEVICE="${DEVICE:-emulator-5554}"

firebase emulators:exec \
  --project spndex-37b0d \
  "flutter test -d $DEVICE ${*:-integration_test}"
