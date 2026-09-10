import "dart:async";

import "package:flutter/material.dart";

import "../../core/theme.dart";

class CountdownView extends StatefulWidget {
  const CountdownView({
    required this.onDone,
    this.onTick,
    this.step = const Duration(seconds: 1),
    super.key,
  });

  final VoidCallback onDone;

  /// Called once per frame change (3, 2, 1, GO!).
  final VoidCallback? onTick;
  final Duration step;

  @override
  State<CountdownView> createState() => _CountdownViewState();
}

class _CountdownViewState extends State<CountdownView> {
  static const _frames = ["3", "2", "1", "GO!"];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.onTick?.call();
    _timer = Timer.periodic(widget.step, (_) {
      if (_i >= _frames.length - 1) {
        _timer?.cancel();
        widget.onDone();
      } else {
        setState(() => _i++);
        widget.onTick?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.charcoal,
      child: Center(
        child: Text(
          _frames[_i],
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w900,
            color: AppColors.mustard,
          ),
        ),
      ),
    );
  }
}
