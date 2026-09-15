import "dart:async";
import "dart:ui";

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
import "widgets/quit_confirm.dart";

class SoloGameScreen extends ConsumerStatefulWidget {
  const SoloGameScreen({super.key});

  @override
  ConsumerState<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends ConsumerState<SoloGameScreen> {
  bool _counting = true;
  bool _leaving = false;
  Timer? _ticker;

  Future<void> _onComplete() async {
    _ticker?.cancel();
    if (_leaving) return;
    _leaving = true;
    await ref.read(soloControllerProvider.notifier).committed;
    if (mounted) context.go(Routes.soloResult);
  }

  /// Repaints every 100ms so the clock ticks in real time instead of only
  /// jumping forward on the next correct tap (SoloView.elapsed only updates
  /// then; this redraws using DateTime.now() in between).
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/game-bg.png", fit: BoxFit.cover),
          SafeArea(
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
                      _startTicker();
                    },
                  );
                }

                final view = ref.watch(soloControllerProvider);
                if (view.complete) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ctrl = ref.read(soloControllerProvider.notifier);
                final displayElapsed = ctrl.firstTapAt == null
                    ? Duration.zero
                    : DateTime.now().difference(ctrl.firstTapAt!);

                final center = loadedDeck.card(centerCardId(view.round));
                final held = loadedDeck.card(view.round.heldCardId);
                final w = MediaQuery.sizeOf(context).width;
                // Reference (centre pile) and your card are the same size —
                // only position (top vs bottom) tells them apart.
                final cardD = (w * 0.92).clamp(260.0, 460.0);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 16, 4),
                      child: Row(
                        children: [
                          _FrostedIconButton(
                            icon: Icons.close,
                            tooltip: "Quit to menu",
                            onPressed: () => _confirmQuit(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatusPill(
                              time: _fmt(displayElapsed),
                              cardsLeft: view.cardsLeft,
                            ),
                          ),
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
                              backgroundColor: const Color(0xFFF3E8D6),
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
                              scale:
                                  Tween<double>(begin: 0.86, end: 1).animate(a),
                              child: FadeTransition(opacity: a, child: c),
                            ),
                            child: CardView(
                              key: ValueKey("held-${held.id}"),
                              card: held,
                              diameter: cardD,
                              glow: true,
                              wrongSymbolId: view.lastWrongSymbolId,
                              onSymbolTap: (id) => ref
                                  .read(soloControllerProvider.notifier)
                                  .tap(id),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final quit = await confirmQuit(context);
    if (quit && context.mounted) context.go(Routes.home);
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    final tenths = d.inMilliseconds.remainder(1000) ~/ 100;
    return "${(s ~/ 60).toString().padLeft(2, '0')}:"
        "${(s % 60).toString().padLeft(2, '0')}.$tenths";
  }
}

/// Frosted-glass pill showing the elapsed time and remaining cards, split
/// by a thin divider — matches the game's translucent-badge look over the
/// full-bleed background art.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.time, required this.cardsLeft});

  final String time;
  final int cardsLeft;

  @override
  Widget build(BuildContext context) {
    return _Frosted(
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.cinemaRed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 26, color: Colors.black.withAlpha(31)),
          const SizedBox(width: 14),
          const Icon(
            Icons.style_rounded,
            color: AppColors.charcoal,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Cards Left",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal.withAlpha(153),
                ),
              ),
              Text(
                "$cardsLeft",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return _Frosted(
      borderRadius: BorderRadius.circular(999),
      padding: EdgeInsets.zero,
      child: IconButton(
        icon: Icon(icon, color: AppColors.charcoal),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

/// Shared frosted-glass surface: blurred, translucent white, soft shadow.
class _Frosted extends StatelessWidget {
  const _Frosted({
    required this.child,
    required this.borderRadius,
    required this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(179),
            borderRadius: borderRadius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
