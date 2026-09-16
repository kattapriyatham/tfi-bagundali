import "dart:math" as math;

import "package:flutter/material.dart";

/// A continuous, looping confetti fall meant to sit behind foreground
/// content (e.g. in a [Stack]). Purely decorative — `IgnorePointer` so it
/// never intercepts taps — and pauses on `MediaQuery.disableAnimations`
/// (the OS "reduce motion" setting) instead of forcing movement.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    this.colors = const [
      Color(0xFFC63B2B),
      Color(0xFFF4C542),
      Color(0xFF2E6F73),
      Color(0xFFFAF7ED),
    ],
    this.pieceCount = 60,
    super.key,
  });

  final List<Color> colors;
  final int pieceCount;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _pieces = List.generate(
      widget.pieceCount,
      (_) => _ConfettiPiece.random(random, widget.colors),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.of(context).disableAnimations;
    if (reduced != _reducedMotion) {
      _reducedMotion = reduced;
      if (reduced) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_pieces, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.yOffset,
    required this.width,
    required this.height,
    required this.color,
    required this.swayAmount,
    required this.swayFrequency,
    required this.rotationOffset,
    required this.rotationSpeed,
  });

  factory _ConfettiPiece.random(math.Random r, List<Color> colors) {
    return _ConfettiPiece(
      x: r.nextDouble(),
      yOffset: r.nextDouble(),
      width: 4 + r.nextDouble() * 3,
      height: 7 + r.nextDouble() * 4,
      color: colors[r.nextInt(colors.length)],
      swayAmount: 6 + r.nextDouble() * 10,
      swayFrequency: 1.5 + r.nextDouble() * 2,
      rotationOffset: r.nextDouble() * math.pi * 2,
      rotationSpeed: (r.nextDouble() - 0.5) * 6,
    );
  }

  /// Fractional horizontal position (0..1 of the canvas width).
  final double x;

  /// Fractional phase offset in the fall cycle, so pieces don't all start
  /// at the same height.
  final double yOffset;
  final double width;
  final double height;
  final Color color;
  final double swayAmount;
  final double swayFrequency;
  final double rotationOffset;
  final double rotationSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_ConfettiPiece> pieces;

  /// 0..1 loop position of the shared fall cycle.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final piece in pieces) {
      final fall = (piece.yOffset + t) % 1.0;
      final y = fall * (size.height + 40) - 20;
      final swayPhase =
          (t * piece.swayFrequency + piece.rotationOffset) * 2 * math.pi;
      final sway = math.sin(swayPhase) * piece.swayAmount;
      final x = piece.x * size.width + sway;
      final angle = piece.rotationOffset + t * piece.rotationSpeed * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      paint.color = piece.color;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.width,
          height: piece.height,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
