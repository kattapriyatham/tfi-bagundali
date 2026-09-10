import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../core/haptics.dart";
import "../core/router.dart";
import "../core/theme.dart";
import "../game/local/two_player_controller.dart";
import "../game/solo/solo_controller.dart" show deckProvider;
import "../storage/settings_store.dart";
import "widgets/card_view.dart";
import "widgets/countdown_view.dart";

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
      backgroundColor: AppColors.charcoal,
      body: deck.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            "Failed to load deck: $e",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (_) {
          if (_counting) {
            return CountdownView(
              onDone: () {
                setState(() => _counting = false);
                ref.read(twoPlayerControllerProvider.notifier).start();
              },
            );
          }

          ref.listen(twoPlayerControllerProvider, (prev, next) {
            if (prev == null) return;
            final haptics = ref.read(settingsProvider).haptics;
            final wrongChanged =
                next.wrongP1 != prev.wrongP1 || next.wrongP2 != prev.wrongP2;
            final prevScore = prev.state.countP1 + prev.state.countP2;
            final nextScore = next.state.countP1 + next.state.countP2;
            final scored = nextScore > prevScore;
            final hasWrong = next.wrongP1 != null || next.wrongP2 != null;
            if (wrongChanged && hasWrong) {
              hapticWrong(enabled: haptics);
            } else if (scored) {
              hapticMatch(enabled: haptics);
            }
          });

          final view = ref.watch(twoPlayerControllerProvider);

          return Stack(
            children: [
              const Column(
                children: [
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 2,
                      child: _PlayerHalf(
                        player: 1,
                        accent: AppColors.cinemaRed,
                      ),
                    ),
                  ),
                  Divider(height: 2, thickness: 2, color: Colors.white24),
                  Expanded(
                    child: _PlayerHalf(player: 2, accent: AppColors.teal),
                  ),
                ],
              ),
              if (view.state.isComplete)
                _ResultOverlay(
                  winner: view.state.winner,
                  p1: view.state.countP1,
                  p2: view.state.countP2,
                  onRematch: () =>
                      ref.read(twoPlayerControllerProvider.notifier).start(),
                  onHome: () => context.go(Routes.home),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerHalf extends ConsumerWidget {
  const _PlayerHalf({required this.player, required this.accent});

  final int player;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(twoPlayerControllerProvider);
    final deck = ref.watch(deckProvider).requireValue;
    final st = view.state;
    final w = MediaQuery.sizeOf(context).width;

    if (st.isComplete) {
      return const SizedBox.shrink();
    }

    final center = deck.card(st.centerCardId);
    final held = deck.card(st.heldFor(player));
    final wrong = view.wrongFor(player);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Player $player   ${player == 1 ? st.countP1 : st.countP2}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  "Same card. Find it first!",
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: CardView(
                card: center,
                diameter: (w * 0.40).clamp(140.0, 260.0),
                interactive: false,
                onSymbolTap: (_) {},
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: CardView(
                card: held,
                diameter: (w * 0.56).clamp(200.0, 360.0),
                wrongSymbolId: wrong >= 0 ? wrong : null,
                onSymbolTap: (id) => ref
                    .read(twoPlayerControllerProvider.notifier)
                    .tap(player, id),
              ),
            ),
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
