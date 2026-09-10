import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../ads/ad_service.dart";
import "../ads/banner_ad_slot.dart";
import "../core/router.dart";
import "../core/theme.dart";
import "../game/solo/solo_controller.dart";
import "../storage/best_time_store.dart";

class SoloResultScreen extends ConsumerStatefulWidget {
  const SoloResultScreen({super.key});

  @override
  ConsumerState<SoloResultScreen> createState() => _SoloResultScreenState();
}

class _SoloResultScreenState extends ConsumerState<SoloResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adServiceProvider).showInterstitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(soloControllerProvider);
    final isBest = ref.read(soloControllerProvider.notifier).isNewBest;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "YOU DID IT!",
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
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
                          snap.data == null
                              ? ""
                              : "Best: ${_fmt(snap.data!)}",
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
            const BannerAdSlot(),
          ],
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
