# TFI Bagundaali

A Tollywood-themed Spot It / Dobble card game (Flutter, iOS + Android).

## Status

Plan 1 of 3: offline solo time-attack. Online multiplayer and local 2-player
land in later plans.

## Develop

    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    flutter run

## Test

    flutter test
    flutter analyze

## Regenerate the deck

    dart run tool/generate_deck_json.dart

`assets/deck.json` is committed and guarded by `test/deck/deck_json_test.dart`.

## Architecture

- `lib/deck` (except `deck_loader.dart`), `lib/game/engine`, `lib/core/rng.dart`
  — pure Dart, no Flutter (guarded by `test/core/purity_test.dart`).
- `lib/deck/deck_loader.dart` — the asset-I/O boundary (`loadDeck`).
- `lib/game/solo` — Riverpod controller.
- `lib/ui` — screens and widgets.
- Symbol art is placeholder (`CustomPainter` in `SymbolView`); the real
  sticker assets in `assets/stickers/` replace `symbolArt()` later, and the
  deck needs 57 symbols (currently 28 stickers).

## Spec & plans

`docs/superpowers/specs/` and `docs/superpowers/plans/`.
