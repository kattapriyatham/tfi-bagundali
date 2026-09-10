import "package:flutter/material.dart";

import "../../deck/symbol_assets.dart";
import "../../deck/symbol_catalog.dart";

/// Renders one game symbol: the real Tollywood sticker art when a bundled
/// asset exists for [symbolId], otherwise a clean cinema glyph (only symbol
/// id 56 has no art).
class SymbolView extends StatelessWidget {
  const SymbolView({required this.symbolId, this.size = 48, super.key});

  final int symbolId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = (symbolId >= 0 && symbolId < kSymbolAssets.length)
        ? kSymbolAssets[symbolId]
        : null;

    return SizedBox(
      width: size,
      height: size,
      child: asset != null
          ? Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    final c = symbolArt(symbolId).colorValue;
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.local_movies_rounded,
          color: c == 0 ? const Color(0xFFC63B2B) : Color(c),
          size: 64,
        ),
      ),
    );
  }
}
