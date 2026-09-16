import "package:flutter/material.dart";

import "../../core/theme.dart";

/// Drives a one-shot "someone just matched" flash: fades in, holds, fades
/// out, then sits idle until the next [show]. Not a widget itself — own it
/// in a [State] (`vsync: this`), feed it into [MatchFlashBanner] and/or
/// [MatchCheckBadge], and call [dispose] alongside the state's own.
class MatchFlash extends ChangeNotifier {
  MatchFlash({required TickerProvider vsync})
      : controller = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 1400),
        ) {
    controller.addListener(notifyListeners);
  }

  final AnimationController controller;
  String? text;
  bool isSelf = false;

  static final Animatable<double> _opacitySequence = TweenSequence([
    TweenSequenceItem(
      weight: 15,
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOut)),
    ),
    TweenSequenceItem(weight: 55, tween: ConstantTween<double>(1)),
    TweenSequenceItem(
      weight: 30,
      tween: Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeIn)),
    ),
  ]);

  double get opacity => _opacitySequence.transform(controller.value);

  /// Starts (or restarts, if one is already mid-flash) the fade sequence
  /// with new content.
  void show({required String text, bool isSelf = false}) {
    this.text = text;
    this.isSelf = isSelf;
    controller.forward(from: 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// A small fading pill of text — "You matched it!" / "Priya matched it!" —
/// anchored wherever the caller places it.
class MatchFlashBanner extends StatelessWidget {
  const MatchFlashBanner({required this.flash, super.key});

  final MatchFlash flash;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flash,
      builder: (context, _) {
        final opacity = flash.opacity;
        if (opacity <= 0.01 || flash.text == null) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, (1 - opacity) * -8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: flash.isSelf ? AppColors.teal : AppColors.charcoal,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  flash.text!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A small fading checkmark badge — the "this card just matched" sticker.
/// Pass [onlySelf] true to only light up when [MatchFlash.isSelf] is true
/// (e.g. one shared flash driving several players' cards); leave it false
/// when the [flash] instance already belongs to exactly one card.
class MatchCheckBadge extends StatelessWidget {
  const MatchCheckBadge({
    required this.flash,
    this.onlySelf = false,
    super.key,
  });

  final MatchFlash flash;
  final bool onlySelf;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flash,
      builder: (context, _) {
        final active = !onlySelf || flash.isSelf;
        final opacity = active ? flash.opacity : 0.0;
        if (opacity <= 0.01) return const SizedBox.shrink();
        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}
