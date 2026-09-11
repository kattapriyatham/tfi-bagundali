import "dart:math";

import "../core/rng.dart";
import "models.dart";

const double kSymbolRadius = 0.23;

/// Deterministic scatter layout for a card, keyed on [GameCard.id].
///
/// Places 8 symbols: one near the centre, seven around a jittered ring,
/// with bounded rejection sampling to avoid gross overlap and keep every
/// symbol inside the unit card.
///
/// Tuned constants (ring radius span, angular jitter, attempt budget) were
/// adjusted until all 57 generated cards pass the overlap + in-bounds tests.
List<SymbolPlacement> layoutForCard(GameCard card) {
  final rng = SeededRng(card.id * 2654435761 + 1);
  final placed = <SymbolPlacement>[];

  for (var i = 0; i < card.symbolIds.length; i++) {
    final isCentre = i == 0;
    SymbolPlacement? best;
    var bestGap = -double.infinity;

    for (var attempt = 0; attempt < 400; attempt++) {
      final scale = 0.82 + rng.nextDouble() * 0.43;
      final maxR = 1.0 - kSymbolRadius * scale;
      final radius = isCentre
          ? rng.nextDouble() * 0.12 * maxR
          : (0.46 + rng.nextDouble() * 0.52) * maxR;
      final angle = (isCentre ? 0.0 : (i - 1) / 7 * 2 * pi) +
          (rng.nextDouble() - 0.5) * 0.55;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;

      var minGap = double.infinity;
      for (final p in placed) {
        final centreDist = sqrt(pow(p.x - x, 2) + pow(p.y - y, 2));
        final gap =
            centreDist - (kSymbolRadius * p.scale + kSymbolRadius * scale);
        minGap = min(minGap, gap);
      }

      final candidate = SymbolPlacement(
        symbolId: card.symbolIds[i],
        x: x,
        y: y,
        scale: scale,
        rotationTurns: rng.nextDouble(),
      );

      if (placed.isEmpty || minGap > 0) {
        best = candidate;
        break;
      }
      if (minGap > bestGap) {
        bestGap = minGap;
        best = candidate;
      }
    }

    placed.add(best!);
  }

  return placed;
}
