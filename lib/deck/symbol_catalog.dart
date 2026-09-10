import "package:freezed_annotation/freezed_annotation.dart";

part "symbol_catalog.freezed.dart";

const int kSymbolCount = 57;

enum SymbolShape {
  circle,
  square,
  triangle,
  diamond,
  hexagon,
  star,
  pentagon,
  cross,
}

@freezed
class SymbolArt with _$SymbolArt {
  const factory SymbolArt({
    required SymbolShape shape,
    required int colorValue,
    required String label,
  }) = _SymbolArt;
}

// 8 distinct hues (ARGB), tuned to read on an ivory card.
const List<int> _palette = [
  0xFFC63B2B, // cinema red
  0xFF2E6F73, // muted teal
  0xFFF4C542, // mustard
  0xFF1A1A1A, // charcoal
  0xFF3D5A80, // slate blue
  0xFF8E4585, // plum
  0xFF4C7A34, // leaf green
  0xFFD98324, // amber
];

/// Deterministic placeholder art for symbol [id] (0..56).
/// Real sticker assets replace this mapping later without touching callers.
SymbolArt symbolArt(int id) {
  assert(id >= 0 && id < kSymbolCount, "symbol id out of range: $id");
  final shape = SymbolShape.values[id % SymbolShape.values.length];
  final color = _palette[(id * 3) % _palette.length];
  return SymbolArt(shape: shape, colorValue: color, label: "${id + 1}");
}
