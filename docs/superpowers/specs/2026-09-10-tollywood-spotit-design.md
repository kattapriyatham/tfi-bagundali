# TFI Bagundali — Design Spec

- **App title:** TFI Bagundali (Telugu Film Industry — "bagundali" / "may it
  do well", a common fan sentiment). Earlier drafts: "Tollywood Spot It",
  "Match Cut", "TFI Banisa".
- **Date:** 2026-09-10
- **Status:** Draft for review
- **Author:** priyathamkatta@randomwalk.ai (with Claude)
- **Amendment (2026-09-12):** dropped the two Cloud Functions (`createRoom`,
  `finishGame`) for v1. Room-code allocation and end-of-game stat writes now
  happen client-side, guarded by RTDB/Firestore security rules instead of
  server-trusted code. Rationale: avoids requiring the Blaze billing plan;
  the game already has no server-authoritative anti-cheat (§1 non-goals), so
  this doesn't lower the security bar in a way that matters for a
  play-with-friends party game. Every place below that said "Cloud Function"
  is updated to the client+rules equivalent. App id also changed post-draft:
  `io.tfibagundali.app` (was `ai.randomwalk.*`).

## 1. Overview

A Flutter mobile game: a Tollywood-themed clone of *Spot It! / Dobble*. Two
cards always share exactly one matching symbol; players race to spot it. Ships
to the Apple App Store and Google Play as a free, ad-supported product.

Title/branding is not final; run a trademark and store-name-collision check
before release. Store listing may need a qualifier (e.g. "TFI Banisa — Telugu
cinema card game").

The symbol set is 57 **original sticker designs already created/commissioned by
the project owner** (no real-actor likenesses, no studio artwork), so there is
no third-party IP exposure.

### Goals

- Ship a polished, real store product (both platforms) with a single game mode.
- Local play (solo + 2-player on one device) and online play (2–8 players via
  room codes).
- Zero ongoing content obligation: one deck, one mode, done.
- Revenue purely from ads.

### Non-goals (explicitly out of scope for v1)

- Additional card decks or downloadable content.
- Additional mini-game modes (The Well, Hot Potato, etc.).
- In-app purchases of any kind, "remove ads", or premium tiers.
- Matchmaking with strangers, friends lists, chat, social graph.
- Accounts as a requirement. Web/desktop builds.
- Leaderboards / cross-player ranking (local stats only in v1).
- Server-authoritative anti-cheat.

## 2. Platform & tech stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (stable), Dart 3 | iOS + Android only |
| State management | Riverpod (`flutter_riverpod`) | Stream providers map cleanly to RTDB listeners |
| Navigation | `go_router` | |
| Models / immutability | `freezed` + `json_serializable` | |
| Backend | Firebase (single project) | See approach below |
| Live game state | **Firebase Realtime Database (RTDB)** | Low latency, native `onDisconnect` presence |
| Durable data | **Cloud Firestore** | User profile + lifetime stats |
| Auth | Firebase Auth — anonymous, with optional Google / Apple linking | Linking deferred; anonymous is the launch path |
| Ads | Google AdMob (`google_mobile_ads`) | |
| Cloud Functions | None for v1 (see amendment) — room-code allocation and end-game stats done client-side, security-rules-gated | Avoids requiring the Blaze plan |
| Lints | `very_good_analysis` | |
| Rendering | Plain Flutter widgets + `AnimationController` | No game engine (Flame) — the game is tap hit-testing over a layout of images |

### Backend approach (decided: "Approach C")

- **RTDB** holds the active game: room, players, deck order, center-pile
  pointer. High-frequency small writes; `onDisconnect` auto-cleans a player
  who drops.
- **Firestore** holds the user profile and lifetime stats (games played, games
  won, best solo time). Better queries, offline support.
- **Room creation and end-of-game stats are client-side** (no Cloud
  Functions in v1 — see amendment): the client runs an RTDB transaction to
  atomically claim a short code, and each participant writes its own
  Firestore stats when a game ends. Security rules constrain both writes
  (see §9) so this isn't wide open.
- Race resolution for "who tapped first" is client-reported using an RTDB
  transaction directly on `deck.centerIndex` (see §6, §8.2). Acceptable for
  a play-with-friends party game; no server round-trip on the tap path (cold
  starts would spike latency in a reaction game).

## 3. Monetization

100% free. No IAP, no `in_app_purchase` dependency, no entitlement logic.

**AdMob placements (only these):**

| Placement | Format | Rule |
|---|---|---|
| Cold app open | Interstitial (pre-cached) | Once per launch; dismissible after AdMob's close delay |
| Full game finished → returning to menu | Interstitial | After a *complete game*, never between rounds |
| Home / lobby / results screens | Banner (adaptive) | Static screens only |

**Never** show an ad during a round or between rounds. The "one more round"
loop (a round is ~2–4 minutes) is the retention engine and must stay
uninterrupted. A rematch from the results screen goes straight into the next
round with no ad.

Ad unit IDs come from a build-time config; test IDs in debug builds. A simple
`AdService` wraps load/show, swallows failures silently (no ad = no-op, game
never blocks on an ad).

## 4. Deck & card model

Pure Dart. No Flutter, no Firebase. Fully unit-tested.

### 4.1 Symbol set

The 57 sticker images ship as bundled assets, indexed `0..56`.

```
Symbol { int id; String assetPath }
```

### 4.2 Deck generation (order-7 projective plane)

Generates 57 cards, each with 8 symbol indices, such that **any two cards share
exactly one symbol**.

Construction: the standard finite-projective-plane method for prime `n = 7`
(the well-known "Dobble algorithm"):

- 1 card of the `n+1` "first-group" symbols.
- `n` cards each pairing the first first-group symbol with one full block of
  the remaining `n²` symbols.
- `n²` cards each pairing one of the other `n` first-group symbols with one
  symbol from every block, selected by `(i*k + j) mod n`.

Total: `1 + 7 + 49 = 57` cards, `57` symbols, `8` symbols per card. The exact
index arithmetic is pinned by the invariant test below rather than by this
prose — if the test passes, the construction is correct.

The deck is **precomputed once and shipped as `assets/deck.json`** (a
`List<List<int>>`), with the generator kept in the repo and run by a test that
regenerates and diffs against the committed JSON.

**Invariant test:** for all `57 * 56 / 2 = 1596` card pairs, exactly one shared
symbol. Also assert: every symbol appears on exactly 8 cards; every card has 8
distinct symbols.

### 4.3 Card visual layout

What makes Dobble hard: symbols are scattered, individually rotated, and
different sizes. Layout is **deterministic from the card ID** via a seeded RNG,
so every device renders the same card identically with nothing synced over the
network.

- Seed = `cardId`.
- 8 symbols placed into 8 loose zones (roughly: center + ring of 7) inside a
  circle, with per-symbol jitter.
- Each symbol: random `scale` in `[0.7, 1.15]`, random `rotationTurns` in
  `[0, 1)`.
- Non-overlap by rejection sampling (bounded retries, then accept best
  candidate). Target: no two symbol bounding circles overlap by more than a
  small tolerance.
- A golden test locks a sample of rendered cards.

```
GameCard        { int id; List<int> symbolIds; List<SymbolPlacement> layout }
SymbolPlacement { int symbolId; double x, y;   // unit circle coords, -1..1
                  double scale; double rotationTurns }
```

## 5. App architecture

Layered so the game logic is testable without Flutter or Firebase.

```
lib/
  main.dart                bootstrap (Firebase.initializeApp, ProviderScope)
  app.dart                 MaterialApp.router, theme

  core/                    theme, router, constants, Result/failure types, seeded RNG
  deck/                    deck generator, card layout, Symbol/GameCard/SymbolPlacement
  game/
    engine/                PURE game logic, no Flutter/Firebase:
                             InfernoEngine  — round state machine
                             MatchRules     — "is symbol X the match between card A and center C"
                             Scoring        — counts, final winner (argmax, tie -> earliest to reach)
    local/                 solo time-attack + split-screen 2P controllers (Riverpod)
    online/                RTDB data layer + sync controllers
                             RoomRepository, GameRepository (streams), OnlineInfernoController
    widgets/               CardView, SymbolView, RoundHud, CountdownView
  rooms/                   create/join UI, room-code entry
  auth/                    anonymous sign-in bootstrap, (optional) account linking
  profile/                 Firestore ProfileRepository, stats models
  ads/                     AdService, placement policy
  ui/                      Home, Lobby, GamePlay, Results, Settings screens; shared widgets
```

**Dependency rule:** `game/engine` depends on `deck` and nothing else. Local
and online controllers wrap the same engine so round logic is identical across
modes.

## 6. Data model

### 6.1 RTDB — live game state

Path root: `/rooms/{roomCode}`

```
/rooms/{roomCode}
  meta
    status        : "lobby" | "countdown" | "playing" | "finished"
    hostUid       : string
    createdAt     : <server ts>
    maxPlayers    : 8
  deck
    order         : [int x57]        # shuffled card IDs, written by host at game start
    centerIndex   : int              # index into order; RTDB-transaction-guarded (see §8.2)
  players/{uid}
    name          : string
    joinedAt      : <server ts>      # also the host-migration order
    connected     : bool             # maintained via onDisconnect
    currentCardId : int
    count         : int              # cards collected
  result
    winnerUid     : string | null
    standings     : { uid: count }   # written once at finish
```

- Center card ID = `deck.order[deck.centerIndex]`.
- Game ends when `centerIndex == 57`.
- Presence: on join, client sets `connected = true` and registers
  `onDisconnect().update({ connected: false })`.

### 6.2 Firestore — durable

```
/users/{uid}
  displayName    : string
  createdAt      : timestamp
  linkedProvider : "google" | "apple" | null
  stats
    gamesPlayed  : int
    gamesWon     : int
    onlinePlayed : int
    bestSoloMs   : int | null        # fastest solo time-attack clear
    lastPlayedAt : timestamp
```

Written from the client for both solo and online results (no Cloud Function
in v1 — see amendment). Security rules only allow a user to write their own
`/users/{uid}` doc and only allow `stats` counters to increase, so a
rage-quitter or a tampered client can inflate their own numbers at worst —
not another player's.

## 7. Game flow — local

### 7.1 Solo time-attack

Single player vs the clock. Center pile = full 57-card deck shuffled; player
holds one card. Find the match, tap it, next center card flips. Timer runs from
first tap to last card. Best time saved to Firestore (`bestSoloMs`). No
network, no ads mid-run (banner on the pre/post screens only).

### 7.2 Split-screen 2-player ("tabletop")

Device laid flat between two players. Screen split into two mirrored halves;
each half shows that player's current card, the shared center card in the
middle. Both tap on their own half. Same engine, same race resolution as
online but resolved locally (no RTDB). First correct tap wins the center card.
Most cards when the pile empties wins.

## 8. Game flow — online

### 8.1 Room lifecycle

1. **Create:** host generates a random 5-letter code client-side (uppercase,
   `O/0/I/1` excluded) and runs an RTDB transaction on
   `/rooms/{code}/meta`: commit only if the node is currently null, writing
   `status = "lobby"`, `hostUid = me`. On abort (rare collision), regenerate
   and retry, bounded at a handful of attempts.
2. **Join:** player enters code, picks a display name, client writes
   `/rooms/{code}/players/{uid}` and registers `onDisconnect`. Reject if
   `status != "lobby"` or `players` count `>= maxPlayers`.
3. **Lobby:** all clients stream `/rooms/{code}`. Host sees a Start button
   (enabled at ≥2 connected players).
4. **Start:** host shuffles a deck order, writes `deck.order`, deals card
   `order[i]` to the i-th player by `joinedAt`, sets `centerIndex = playerCount`,
   `status = "countdown"`, then `"playing"` after a 3-2-1.
5. **Finish:** when `centerIndex` reaches 57, the client that wrote the final
   advance sets `status = "finished"` and writes `/rooms/{code}/result`
   (standings computed from `players/*/count`, already visible to it via the
   stream). Each connected client independently writes its own
   `/users/{uid}/stats` in Firestore once it observes `status == "finished"`
   — no single client is trusted to write on others' behalf.
6. **Rematch:** host resets `deck` and per-player `count`/`currentCardId`,
   `status = "countdown"`. Same room, same code. No ad (mid-session).

### 8.2 Round / match resolution

Current center card `C = order[centerIndex]`.

1. Player taps a symbol on their own card. **Client-side check first**
   (`MatchRules`): is the tapped symbol the single shared symbol between the
   player's `currentCardId` and `C`?
   - Wrong → local "wrong" feedback (shake + brief 500 ms input lockout). No
     network write. Prevents tap-spam races.
2. Correct → run an **RTDB transaction directly on
   `/rooms/{code}/deck/centerIndex`**: if the current value equals the
   client's `expectedCenterIndex`, set it to `expectedCenterIndex + 1` and
   commit; otherwise abort. RTDB serializes concurrent transactions on the
   same path, so this alone guarantees exactly one winner per card — no
   separate lock node needed (an earlier draft used a `round.lockUid` node
   for this; dropped as redundant once the transaction target moved to
   `centerIndex` itself).
3. The transaction **winner** (the client whose transaction committed)
   follows up with a plain multi-location update: `players/{me}/count += 1`,
   `players/{me}/currentCardId = C`.
4. A losing client's transaction simply fails to commit — it shows a local
   "too slow" (no network write, nothing to sync) and re-renders once its
   `/rooms/{code}` stream delivers the new `centerIndex`.

This gives a single authoritative winner per card without a server on the
tap path. Worst case under perfectly simultaneous taps: RTDB serializes the
transactions; exactly one commits.

### 8.3 Disconnect & error handling

| Situation | Handling |
|---|---|
| Player loses connection mid-game | `onDisconnect` sets `connected = false`. Their card stays out of play. Game continues for the rest. |
| Player reconnects | Client re-attaches listener, sets `connected = true`, resumes from current `centerIndex` and their `currentCardId`. |
| Only one connected player remains | That client sets `status = "finished"` and writes `/rooms/{code}/result` itself. Remaining player wins by default. |
| **Host** disconnects | Deterministic migration: the connected player with the earliest `joinedAt` becomes host (client-side election; the elected client writes `meta.hostUid = me`). |
| Host disconnects in lobby with no one else | Room is abandoned; a scheduled Function (or TTL) reaps `lobby` rooms older than 30 min and `finished` rooms older than 1 h. |
| Transaction contention / RTDB write fails | The `centerIndex` transaction naturally retries itself internally (RTDB behavior); if the whole operation still errors, show a non-blocking toast and keep listening (state will still converge from the stream). |
| Two clients both try to advance the same card (shouldn't happen) | Impossible by construction — the `centerIndex` transaction only commits once per value; a second attempt targeting the same `expectedCenterIndex` always aborts. |
| Firestore stat write fails | Non-fatal; retried client-side with backoff. Worst case the player's lifetime stats miss one game — no gameplay impact. |
| AdMob fails to load / show | Silent no-op. Game never waits on an ad. |
| Deck asset missing / corrupt | App fails fast at startup with a clear error (should be caught by the regeneration test in CI). |

## 9. Security rules (sketch — finalized during implementation)

**RTDB:**

- `/rooms/{code}/players/{uid}` writable only by `auth.uid == uid`.
- `/rooms/{code}/meta`: creatable by any authenticated user **only when the
  node doesn't already exist** (`!data.exists()`), which is what makes
  client-side room creation safe from overwrite races; updates after
  creation only by `auth.uid == meta.hostUid` (host migration writes guarded
  by "previous host not connected").
- `/rooms/{code}/deck/centerIndex`: writable by any authenticated player in
  `players`, validated to only increase by 1 per write. `players/{uid}/count`
  likewise validated to only increase by 1. Full anti-cheat is out of scope,
  but the rules block gross tampering.
- `/rooms/{code}/result`: writable once (`!data.exists()`) by any player in
  `players`, only when `meta.status == "finished"`.
- Reads: any authenticated user who knows the code.

**Firestore:**

- `/users/{uid}` readable/writable only by `auth.uid == uid`; `stats` fields
  may only be updated to a value `>=` the current one (monotonic counters),
  enforced in rules since there's no server-trusted writer in v1.

## 10. Testing strategy

| Layer | Tests |
|---|---|
| Deck generator | Invariant over all 1596 pairs; symbol frequency; regenerate-and-diff `deck.json` |
| Card layout | Non-overlap within tolerance; determinism (same seed → same layout); golden render of sample cards |
| `MatchRules` | Correct/incorrect symbol identification across random card pairs |
| `InfernoEngine` | Round advance, count updates, end condition, tie-break |
| `Scoring` | argmax winner, ties |
| Online repos | Against the **Firebase Emulator Suite** (RTDB + Firestore): client-side room-create transaction under contention → exactly one winner, join/max-players reject, start deal, two simulated clients racing the `centerIndex` transaction → exactly one winner, disconnect flips `connected`, host migration, result-write-once |
| Security rules | Emulator rules tests: room create rejected if code exists; `stats` write rejected if it decreases; `result` write rejected before `status == "finished"` or if already written |
| Widgets | `CardView` tap hit-testing maps to the right symbol; lobby renders player list; results screen |
| Manual / device | Two physical devices: full online game, backgrounding, airplane-mode mid-round, host kill |

CI: `flutter analyze`, `flutter test` (incl. emulator-backed security-rules
tests), deck regeneration check.

## 11. Milestones

1. **Deck engine + rendering** — generator, `deck.json`, `CardView`, layout,
   all offline. Tests green.
2. **Solo time-attack** — fully playable single-player loop, timer, local best.
3. **Firebase bootstrap** — project, anonymous auth, Firestore profile doc,
   emulator wiring for tests.
4. **Rooms + lobby** — client-side room-create transaction, join by code,
   lobby stream, presence.
5. **Online Inferno** — deck deal, round sync, transaction-based match
   resolution, client-written results + stats.
6. **Resilience** — disconnect handling, reconnect, host migration, room reaping.
7. **Split-screen local 2P**.
8. **AdMob** — interstitials (cold open, game end), banners (static screens),
   `AdService`, test vs prod unit IDs.
9. **Polish** — sound, haptics, countdown, animations, settings, display-name
   editing, optional Google/Apple linking.
10. **Store prep** — app icons, adaptive icon, splash, screenshots, store
    listings (English + Telugu), privacy policy, data-safety form, AdMob +
    GDPR/UMP consent, age rating, release builds, closed test track.

## 12. Open questions

1. **Split-screen local 2P vs. solo-only for v1.** Split-screen doubles the
   layout work. Option: ship solo time-attack + online at launch, add
   split-screen in a fast follow. (Leaning: keep split-screen if cheap after
   the engine is shared; otherwise defer.)
2. **Room code length** — 5 letters ≈ 11.8M combos, plenty; confirm format
   (letters only vs. letters+digits, excluding `O/0/I/1`).
3. **Min players to start** — 2 confirmed; any max-time or AFK handling for
   online rounds where nobody finds the match? (Proposed: a "no match found"
   is impossible in Dobble, so no timeout needed; a hint after 15 s could be a
   later accessibility option.)
4. **Telugu localization at launch** vs. English-only v1 with Telugu fast
   follow.
5. **Consent / UMP** — AdMob EU consent flow: include the Google UMP SDK at
   launch even though the audience is India-first? (Recommended yes, low cost.)
6. **Analytics** — Firebase Analytics for funnel (installs → first game →
   retention)? Not in scope above; cheap to add, recommend yes.

## 13. Future (post-v1, not committed)

- Additional modes (The Well, Hot Potato).
- Additional decks as free updates or the first paid IAP if the game gains
  traction.
- Friends list + rematch invites.
- Global leaderboard for solo time-attack.
- Spectator mode.
