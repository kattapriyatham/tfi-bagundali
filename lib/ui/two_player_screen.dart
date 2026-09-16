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
import "widgets/match_flash.dart";
import "widgets/quit_confirm.dart";

class TwoPlayerScreen extends ConsumerStatefulWidget {
  const TwoPlayerScreen({super.key});

  @override
  ConsumerState<TwoPlayerScreen> createState() => _TwoPlayerScreenState();
}

class _TwoPlayerScreenState extends ConsumerState<TwoPlayerScreen>
    with TickerProviderStateMixin {
  bool _counting = true;
  late final MatchFlash _flashP1 = MatchFlash(vsync: this);
  late final MatchFlash _flashP2 = MatchFlash(vsync: this);

  @override
  void dispose() {
    _flashP1.dispose();
    _flashP2.dispose();
    super.dispose();
  }

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
                  final p1Scored = next.state.countP1 > prev.state.countP1;
                  final p2Scored = next.state.countP2 > prev.state.countP2;
                  final scored = p1Scored || p2Scored;
                  final hasWrong = next.wrongP1 != null || next.wrongP2 != null;
                  if (wrongChanged && hasWrong) {
                    hapticWrong(enabled: st.haptics);
                    sfxWrong(enabled: st.sound);
                  } else if (scored) {
                    hapticMatch(enabled: st.haptics);
                    sfxMatch(enabled: st.sound);
                    if (p1Scored) _flashP1.show(text: "Matched!", isSelf: true);
                    if (p2Scored) _flashP2.show(text: "Matched!", isSelf: true);
                  }
                });

                final view = ref.watch(twoPlayerControllerProvider);

                return Stack(
                  children: [
                    if (!view.state.isComplete)
                      _MatchBoard(flashP1: _flashP1, flashP2: _flashP2),
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

/// Fixed vertical space each player's badge (label + score, plus the gap
/// to its card) takes — reserved up front so the diameter calc never lets
/// a circle grow tall enough to push its own badge off-screen.
const double _kBadgeBlockHeight = 52;

/// The three cards — player 1's, the shared centre pile, and player 2's —
/// with the leftover vertical space split evenly between and around them.
class _MatchBoard extends ConsumerWidget {
  const _MatchBoard({required this.flashP1, required this.flashP2});

  final MatchFlash flashP1;
  final MatchFlash flashP2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(twoPlayerControllerProvider);
    final deck = ref.watch(deckProvider).requireValue;
    final st = view.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave just enough room for spaceEvenly to produce visible gaps
        // between the three rows, instead of them touching edge-to-edge,
        // and for each player row's badge above/below its circle.
        final heightBound =
            constraints.maxHeight / 3 * 0.94 - _kBadgeBlockHeight;
        // The badge is a compact pill centred under the full screen width,
        // not tucked to the circle's own side — so, unlike the circle, it
        // never needs extra width reserved to avoid the screen edge.
        final widthBound = constraints.maxWidth - 24;
        final diameter = math.min(widthBound, heightBound).clamp(120.0, 500.0);

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PlayerBlock(
                diameter: diameter,
                accent: AppColors.cinemaRed,
                card: deck.card(st.heldFor(1)),
                wrongSymbolId: view.wrongFor(1) >= 0 ? view.wrongFor(1) : null,
                score: st.countP1,
                playerLabel: "Player 1",
                anchor: _BadgeAnchor.above,
                invertBadge: true,
                flash: flashP1,
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
              _PlayerBlock(
                diameter: diameter,
                accent: AppColors.teal,
                card: deck.card(st.heldFor(2)),
                wrongSymbolId: view.wrongFor(2) >= 0 ? view.wrongFor(2) : null,
                score: st.countP2,
                playerLabel: "Player 2",
                anchor: _BadgeAnchor.below,
                flash: flashP2,
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

/// Where a player's badge sits relative to their card — `above` for the
/// player at the top of the screen, `below` for the one at the bottom, so
/// each badge lands at the screen edge nearest that player.
enum _BadgeAnchor { above, below }

/// A player's card with a compact score badge stacked above or below it,
/// both centred on the same vertical line as the (badge-less) centre card.
class _PlayerBlock extends StatelessWidget {
  const _PlayerBlock({
    required this.diameter,
    required this.accent,
    required this.card,
    required this.score,
    required this.playerLabel,
    required this.onSymbolTap,
    required this.anchor,
    required this.flash,
    this.wrongSymbolId,
    this.invertBadge = false,
  });

  final double diameter;
  final Color accent;
  final GameCard card;
  final int? wrongSymbolId;
  final int score;
  final String playerLabel;
  final _BadgeAnchor anchor;
  final MatchFlash flash;

  /// Rotates the badge's content 180° — for the player whose card is read
  /// from the far end of the device.
  final bool invertBadge;
  final void Function(int symbolId) onSymbolTap;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$score",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
    final orientedBadge =
        invertBadge ? RotatedBox(quarterTurns: 2, child: badge) : badge;

    final circle = Stack(
      alignment: Alignment.topRight,
      children: [
        CardView(
          card: card,
          diameter: diameter,
          accent: accent,
          wrongSymbolId: wrongSymbolId,
          onSymbolTap: onSymbolTap,
        ),
        MatchCheckBadge(flash: flash),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: anchor == _BadgeAnchor.above
          ? [orientedBadge, const SizedBox(height: 8), circle]
          : [circle, const SizedBox(height: 8), orientedBadge],
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
