import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../core/router.dart";
import "../core/theme.dart";
import "../game/solo/solo_controller.dart";
import "../storage/best_time_store.dart";

class SoloResultScreen extends ConsumerWidget {
  const SoloResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(soloControllerProvider);
    final isBest = ref.read(soloControllerProvider.notifier).isNewBest;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "YOU DID IT!",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Text(
                _fmt(view.elapsed),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (isBest)
                const Chip(
                  backgroundColor: AppColors.mustard,
                  label: Text("New best!"),
                )
              else
                FutureBuilder<Duration?>(
                  future: BestTimeStore().read(),
                  builder: (_, snap) => Text(
                    snap.data == null ? "" : "Best: ${_fmt(snap.data!)}",
                  ),
                ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: () => context.go(Routes.solo),
                      child: const Text("Play Again"),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go(Routes.home),
                      child: const Text("Home"),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
