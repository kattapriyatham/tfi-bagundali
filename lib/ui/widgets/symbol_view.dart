import "dart:math";

import "package:flutter/material.dart";

import "../../deck/symbol_assets.dart";
import "../../deck/symbol_catalog.dart";

/// Renders one game symbol: the real Tollywood sticker art when a bundled
/// asset exists for [symbolId], otherwise a painted placeholder shape.
class SymbolView extends StatelessWidget {
  const SymbolView({required this.symbolId, this.size = 48, super.key});

  final int symbolId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset =
        (symbolId >= 0 && symbolId < kSymbolAssets.length)
            ? kSymbolAssets[symbolId]
            : null;

    return SizedBox(
      width: size,
      height: size,
      child: asset != null
          ? Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    final art = symbolArt(symbolId);
    return CustomPaint(
      painter: _SymbolPainter(art),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              art.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  _SymbolPainter(this.art);

  final SymbolArt art;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(art.colorValue);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    switch (art.shape) {
      case SymbolShape.circle:
        canvas.drawCircle(c, r, paint);
      case SymbolShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: c, radius: r * 0.92),
            const Radius.circular(6),
          ),
          paint,
        );
      case SymbolShape.triangle:
        _polygon(canvas, c, r, 3, paint, rotation: -pi / 2);
      case SymbolShape.diamond:
        _polygon(canvas, c, r, 4, paint);
      case SymbolShape.pentagon:
        _polygon(canvas, c, r, 5, paint, rotation: -pi / 2);
      case SymbolShape.hexagon:
        _polygon(canvas, c, r, 6, paint);
      case SymbolShape.star:
        _star(canvas, c, r, paint);
      case SymbolShape.cross:
        final t = r * 0.5;
        canvas
          ..drawRect(
            Rect.fromCenter(center: c, width: 2 * r, height: t),
            paint,
          )
          ..drawRect(
            Rect.fromCenter(center: c, width: t, height: 2 * r),
            paint,
          );
    }
  }

  void _polygon(
    Canvas canvas,
    Offset c,
    double r,
    int sides,
    Paint paint, {
    double rotation = 0,
  }) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = rotation + i * 2 * pi / sides;
      final p = c + Offset(cos(a), sin(a)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final p = c + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(_SymbolPainter old) => old.art != art;
}
