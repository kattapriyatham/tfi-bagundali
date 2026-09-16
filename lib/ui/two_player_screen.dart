import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../ads/ad_service.dart";
import "../core/haptics.dart";
import "../core/router.dart";
import "../core/sound.dart";
import "../core/theme.dart";
import "../deck/models.dart";
import "../game/local/two_player_controller.dart";
import "../game/solo/solo_controller.dart" show deckProvider;
import "../storage/settings_store.dart";
import "widgets/card_view.dart";
import "widgets/countdown_view.dart";
import "widgets/quit_confirm.dart";

class TwoPlayerScreen extends ConsumerStatefulWidget {
  const TwoPlayerScreen({super.key});

  @override
  ConsumerState<TwoPlayerScreen> createState() => _TwoPlayerScreenState();
}

class _TwoPlayerScreenState extends ConsumerState<TwoPlayerScreen> {
  bool _counting = true;

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/game-bg.png", fit: BoxFit.cover),
          SafeArea(
            child: deck.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text("Failed to load deck: $e"),
              ),
              data: (_) {
                if (_counting) {
                  return CountdownView(
                    onTick: () =>
                        sfxTick(enabled: ref.read(settingsProvider).sound),
                    onDone: () {
                      setState(() => _counting = false);
                      ref.read(twoPlayerControllerProvider.notifier).start();
                    },
                  );
                }

                ref.listen(twoPlayerControllerProvider, (prev, next) {
                  if (prev == null) return;
                  final st = ref.read(settingsProvider);
                  final wrongChanged = next.wrongP1 != prev.wrongP1 ||
                      next.wrongP2 != prev.wrongP2;
                  final prevScore = prev.state.countP1 + prev.state.countP2;
                  final nextScore = next.state.countP1 + next.state.countP2;
                  final scored = nextScore > prevScore;
                  final hasWrong = next.wrongP1 != null || next.wrongP2 != null;
                  if (wrongChanged && hasWrong) {
                    hapticWrong(enabled: st.haptics);
                    sfxWrong(enabled: st.sound);
                  } else if (scored) {
                    hapticMatch(enabled: st.haptics);
                    sfxMatch(enabled: st.sound);
                  }
                });

                final view = ref.watch(twoPlayerControllerProvider);

                return Stack(
                  children: [
                    if (!view.state.isComplete) const _MatchBoard(),
                    if (!view.state.isComplete)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black38,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: "Quit to menu",
                            onPressed: () async {
                              final quit = await confirmQuit(
                                context,
                                title: "Quit match?",
                                message: "This match's progress will be lost.",
                              );
                              if (quit && context.mounted) {
                                context.go(Routes.home);
                              }
                            },
                          ),
                        ),
                      ),
                    if (view.state.isComplete)
                      _ResultOverlay(
                        winner: view.state.winner,
                        p1: view.state.countP1,
                        p2: view.state.countP2,
                        onRematch: () => ref
                            .read(twoPlayerControllerProvider.notifier)
                            .start(),
                        onHome: () {
                          ref.read(adServiceProvider).showInterstitial();
                          context.go(Routes.home);
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal space reserved outside each player circle for its score
/// badge, so the badge never gets clipped by the screen edge. Must cover
/// the badge's max width (104 + 22 padding) minus the smallest tuck-in.
const double _kBadgeReserve = 112;

/// The three cards — player 1's, the shared centre pile, and player 2's —
/// with the leftover vertical space split evenly between and around them.
class _MatchBoard extends ConsumerWidget {
  const _MatchBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(twoPlayerControllerProvider);
    final deck = ref.watch(deckProvider).requireValue;
    final st = view.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave just enough room for spaceEvenly to produce visible gaps
        // between the three circles, instead of them touching edge-to-edge.
        final heightBound = constraints.maxHeight / 3 * 0.94;
        // Each circle is centred at `diameter` width and its badge pokes out
        // past that box on one side only — but centring means the *other*
        // side gets the same leftover margin too, so both sides need to
        // clear the badge for the box to actually stay centred on screen.
        final widthBound = constraints.maxWidth - (_kBadgeReserve * 2);
        final diameter = math.min(widthBound, heightBound).clamp(120.0, 500.0);

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PlayerCircle(
                diameter: diameter,
                accent: AppColors.cinemaRed,
                card: deck.card(st.heldFor(1)),
                wrongSymbolId: view.wrongFor(1) >= 0 ? view.wrongFor(1) : null,
                score: st.countP1,
                playerLabel: "Player 1",
                badgeSide: _BadgeSide.left,
                invertBadge: true,
                onSymbolTap: (id) =>
                    ref.read(twoPlayerControllerProvider.notifier).tap(1, id),
              ),
              CardView(
                card: deck.card(st.centerCardId),
                diameter: diameter,
                interactive: false,
                accent: AppColors.mustard,
                onSymbolTap: (_) {},
              ),
              _PlayerCircle(
                diameter: diameter,
                accent: AppColors.teal,
                card: deck.card(st.heldFor(2)),
                wrongSymbolId: view.wrongFor(2) >= 0 ? view.wrongFor(2) : null,
                score: st.countP2,
                playerLabel: "Player 2",
                badgeSide: _BadgeSide.right,
                onSymbolTap: (id) =>
                    ref.read(twoPlayerControllerProvider.notifier).tap(2, id),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _BadgeSide { left, right }

/// A player's card with a compact score badge overlapping its edge,
/// vertically centred, instead of a full-width header row above the card.
class _PlayerCircle extends StatelessWidget {
  const _PlayerCircle({
    required this.diameter,
    required this.accent,
    required this.card,
    required this.score,
    required this.playerLabel,
    required this.onSymbolTap,
    required this.badgeSide,
    this.wrongSymbolId,
    this.invertBadge = false,
  });

  final double diameter;
  final Color accent;
  final GameCard card;
  final int? wrongSymbolId;
  final int score;
  final String playerLabel;
  final _BadgeSide badgeSide;

  /// Rotates the badge's content 180° — for the player whose card is read
  /// from the far end of the device.
  final bool invertBadge;
  final void Function(int symbolId) onSymbolTap;

  @override
  Widget build(BuildContext context) {
    final isLeft = badgeSide == _BadgeSide.left;

    final badge = Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: accent,
        // Rounded on the outer (visible) end, square on the end tucked
        // behind the card — that end is hidden, so its shape doesn't show.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? 14 : 0),
          bottomLeft: Radius.circular(isLeft ? 14 : 0),
          topRight: Radius.circular(isLeft ? 0 : 14),
          bottomRight: Radius.circular(isLeft ? 0 : 14),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          Text(
            "$score",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    // How far the badge's inner end reaches back under the card. Painted
    // behind the card, that portion is hidden by the opaque circle — only
    // the part sticking out past the circle's edge is visible — so the
    // badge reads as emerging from underneath it.
    final tuckIn = diameter * 0.14;

    // The box is exactly the circle's own width, same as the (badge-less)
    // centre card — so all three stay centred on the same vertical line.
    // The badge pokes out past this box's edge via Clip.none; the caller
    // reserves `_kBadgeReserve` of margin on *both* sides of the circle
    // (since a centred box splits its leftover space evenly) so that
    // overflow never reaches the screen edge.
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            right: isLeft ? diameter - tuckIn : null,
            left: isLeft ? null : diameter - tuckIn,
            child: Center(
              child: invertBadge
                  ? RotatedBox(quarterTurns: 2, child: badge)
                  : badge,
            ),
          ),
          CardView(
            card: card,
            diameter: diameter,
            accent: accent,
            wrongSymbolId: wrongSymbolId,
            onSymbolTap: onSymbolTap,
          ),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.winner,
    required this.p1,
    required this.p2,
    required this.onRematch,
    required this.onHome,
  });

  final int winner;
  final int p1;
  final int p2;
  final VoidCallback onRematch;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final title = winner == 0 ? "It's a tie!" : "Player $winner wins!";
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Player 1: $p1     Player 2: $p2",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: onRematch,
                    child: const Text("Rematch"),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onHome,
                    child: const Text("Home"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
