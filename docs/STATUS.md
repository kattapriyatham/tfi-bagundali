# Build status — autonomous session 2026-09-10

Continued after Plan 1 while you were away. All work is on `main`, committed,
`flutter test` (60+) green, `flutter analyze` clean. Verified on the Android
emulator (`./scripts/run_dev.sh`).

## Done this session

| Area | State |
|---|---|
| Home screen | Redesigned to `docs/home-screen-design.png` — hero art, `title-logo` wordmark, card menu |
| Real sticker art | 56 of 57 symbols now use your Tollywood art; wired via `lib/deck/symbol_assets.dart` |
| Local 2-player | New split-screen "tabletop" mode (mirrored halves), reachable from home |
| Settings | New screen (haptics toggle, sound placeholder, about); wired from home |
| Haptics | Match = selection click, wrong = heavy impact, gated by the setting |
| Sound | System-sound cues (match / wrong / countdown tick), gated by the Sound setting (now live). No custom audio assets yet. |
| AdMob | `google_mobile_ads` 9.1.0 with **Google test ids**; banner on home + solo result, interstitial on cold-open and game-end. Disabled in debug builds. |
| App icon + name | Gold star + "TFI" on cinema red; label "TFI Bagundaali" on both platforms |
| Quit buttons | Solo and 2-player game screens have a close button — no dead ends |
| Animations | Solo cards scale/fade in on change; sticker knockout cleaned up (fewer halos) |
| `.env` + `scripts/run_dev.sh` | Runs the app on an Android emulator with `--dart-define`s from `.env` |

## Decisions I made (review these)

1. **Sticker packs.** `pack-8-*.png` are on a dark blended background with an
   irregular, slightly overlapping layout — automatic segmentation produced
   mangled cut-outs. I switched to **hand-tuned bounding boxes + an oval
   vignette fade** (`tool/extract_stickers.py`, `BOXES` dict). Result: each
   pack sticker reads as a framed portrait; a few still have a faint dark or
   colour halo. `pack-4-1.png` was already transparent and split cleanly.
   **To improve:** adjust the boxes in `tool/extract_stickers.py` or drop in
   hand-cropped PNGs at `assets/stickers/extracted/`, then
   `python3 tool/build_symbols.py`.

2. **The 57th symbol.** 28 + 4 + 8 + 8 + 8 = 56 real stickers. Duplicating one
   would make two "different" symbols look identical and break match-spotting,
   so **symbol id 56 uses the painted placeholder shape** (one coloured shape
   among 56 photos). Add a 57th sticker and it takes that slot automatically.

3. **2-player centre card.** The spec described a single shared centre card in
   the seam "readable from both sides". I show the centre card **once per
   half**, oriented for that player — simpler and unambiguous. Player 1's half
   is rotated 180°.

4. **AdMob = test ids only.** Real ids need your AdMob account. Every spot is
   marked `TODO(owner)` — `lib/ads/ad_ids.dart`,
   `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`.

5. **`analysis_options.yaml`** relaxed a handful of package-oriented lints
   (doc-comment requirement, single-quote preference, import ordering,
   freezed-vs-constructor-order). App code, not a published package.

## Not done (need you)

- **Online / realtime multiplayer (Plan 2)** — untouched, as you asked. Needs
  the Firebase project + credentials.
- **Sound effects** — no audio assets in the repo; the setting toggle is a
  placeholder.
- Real AdMob ids, privacy policy, Google UMP consent, Telugu localization,
  analytics — all pre-release items from the spec, still open.
- Sticker halo clean-up (see decision 1).

## How to run

```
cp .env.example .env
./scripts/run_dev.sh
```
