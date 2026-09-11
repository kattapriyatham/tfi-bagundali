import "dart:math" as math;

import "package:flutter/material.dart";

import "../../deck/card_layout.dart";
import "../../deck/models.dart";
import "symbol_view.dart";

class CardView extends StatelessWidget {
  const CardView({
    required this.card,
    required this.onSymbolTap,
    this.diameter = 320,
    this.flashSymbolId,
    this.wrongSymbolId,
    this.interactive = true,
    this.accent,
    this.label,
    super.key,
  });

  final GameCard card;
  final void Function(int symbolId) onSymbolTap;
  final double diameter;
  final int? flashSymbolId;
  final int? wrongSymbolId;
  final bool interactive;

  /// Ring colour distinguishing this card's role (e.g. "the centre pile"
  /// vs "your card") when two same-sized cards are shown side by side.
  final Color? accent;

  /// Small pill caption shown above the card, e.g. "CENTER" / "YOUR CARD".
  /// Requires [accent] (used as the pill's background).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final placements = layoutForCard(card);
    final radius = diameter / 2;

    final circle = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7ED),
        shape: BoxShape.circle,
        border: accent == null ? null : Border.all(color: accent!, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          children: [
            for (final p in placements)
              Positioned(
                left: radius + p.x * radius - kSymbolRadius * p.scale * radius,
                top: radius + p.y * radius - kSymbolRadius * p.scale * radius,
                width: 2 * kSymbolRadius * p.scale * radius,
                height: 2 * kSymbolRadius * p.scale * radius,
                child: Transform.rotate(
                  angle: p.rotationTurns * 2 * math.pi,
                  child: GestureDetector(
                    key: ValueKey("symbol-${p.symbolId}"),
                    behavior: HitTestBehavior.opaque,
                    onTap: interactive ? () => onSymbolTap(p.symbolId) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: p.symbolId == flashSymbolId
                              ? const Color(0xFFF4C542)
                              : p.symbolId == wrongSymbolId
                                  ? const Color(0xFFC63B2B)
                                  : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: SymbolView(
                          symbolId: p.symbolId,
                          size: 2 * kSymbolRadius * p.scale * radius * 1.18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (label == null) return circle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        circle,
      ],
    );
  }
}
