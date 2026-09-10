import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../core/haptics.dart";
import "../core/router.dart";
import "../game/engine/round_state.dart";
import "../game/solo/solo_controller.dart";
import "../storage/settings_store.dart";
import "widgets/card_view.dart";
import "widgets/countdown_view.dart";

class SoloGameScreen extends ConsumerStatefulWidget {
  const SoloGameScreen({super.key});

  @override
  ConsumerState<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends ConsumerState<SoloGameScreen> {
  bool _counting = true;
  bool _leaving = false;

  Future<void> _onComplete() async {
    if (_leaving) return;
    _leaving = true;
    await ref.read(soloControllerProvider.notifier).committed;
    if (mounted) context.go(Routes.soloResult);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(soloControllerProvider, (prev, next) {
      final haptics = ref.read(settingsProvider).haptics;
      if (prev != null &&
          next.lastWrongSymbolId != null &&
          next.lastWrongSymbolId != prev.lastWrongSymbolId) {
        hapticWrong(enabled: haptics);
      } else if (prev != null &&
          next.round.collected > prev.round.collected) {
        hapticMatch(enabled: haptics);
      }
      if (next.complete) _onComplete();
    });

    final deck = ref.watch(deckProvider);

    return Scaffold(
      body: SafeArea(
        child: deck.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Failed to load deck: $e")),
          data: (loadedDeck) {
            if (_counting) {
              return CountdownView(
                onDone: () {
                  setState(() => _counting = false);
                  ref.read(soloControllerProvider.notifier).start();
                },
              );
            }

            final view = ref.watch(soloControllerProvider);
            if (view.complete) {
              return const Center(child: CircularProgressIndicator());
            }

            final center = loadedDeck.card(centerCardId(view.round));
            final held = loadedDeck.card(view.round.heldCardId);
            final w = MediaQuery.sizeOf(context).width;
            final centerD = (w * 0.52).clamp(180.0, 320.0);
            final heldD = (w * 0.92).clamp(280.0, 460.0);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: "Quit to menu",
                        onPressed: () => context.go(Routes.home),
                      ),
                      Text(
                        _fmt(view.elapsed),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text("Cards Left ${view.cardsLeft}/56"),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: CardView(
                      card: center,
                      diameter: centerD,
                      interactive: false,
                      onSymbolTap: (_) {},
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: CardView(
                      card: held,
                      diameter: heldD,
                      wrongSymbolId: view.lastWrongSymbolId,
                      onSymbolTap: (id) =>
                          ref.read(soloControllerProvider.notifier).tap(id),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text("Find the matching symbol!"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    final tenths = d.inMilliseconds.remainder(1000) ~/ 100;
    return "${(s ~/ 60).toString().padLeft(2, '0')}:"
        "${(s % 60).toString().padLeft(2, '0')}.$tenths";
  }
}
