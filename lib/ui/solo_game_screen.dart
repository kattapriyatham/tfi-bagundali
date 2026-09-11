import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../core/haptics.dart";
import "../core/router.dart";
import "../core/sound.dart";
import "../core/theme.dart";
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
      final s = ref.read(settingsProvider);
      if (prev != null &&
          next.lastWrongSymbolId != null &&
          next.lastWrongSymbolId != prev.lastWrongSymbolId) {
        hapticWrong(enabled: s.haptics);
        sfxWrong(enabled: s.sound);
      } else if (prev != null &&
          next.round.collected > prev.round.collected) {
        hapticMatch(enabled: s.haptics);
        sfxMatch(enabled: s.sound);
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
                onTick: () =>
                    sfxTick(enabled: ref.read(settingsProvider).sound),
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
            // Reference (centre pile) and your card are the same size —
            // only the ring colour + label tell them apart.
            final cardD = (w * 0.74).clamp(220.0, 360.0);

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
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: CardView(
                          key: ValueKey("center-${center.id}"),
                          card: center,
                          diameter: cardD,
                          interactive: false,
                          accent: AppColors.mustard,
                          label: "CENTER",
                          onSymbolTap: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (c, a) => ScaleTransition(
                          scale: Tween<double>(begin: 0.86, end: 1).animate(a),
                          child: FadeTransition(opacity: a, child: c),
                        ),
                        child: CardView(
                          key: ValueKey("held-${held.id}"),
                          card: held,
                          diameter: cardD,
                          accent: AppColors.cinemaRed,
                          label: "YOUR CARD",
                          wrongSymbolId: view.lastWrongSymbolId,
                          onSymbolTap: (id) => ref
                              .read(soloControllerProvider.notifier)
                              .tap(id),
                        ),
                      ),
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
