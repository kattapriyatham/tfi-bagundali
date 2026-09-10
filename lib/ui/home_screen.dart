import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../core/router.dart";
import "../core/theme.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text(
              "TFI Bagundaali",
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal,
                  ),
            ),
            const SizedBox(height: 8),
            const Text("Spot the one. For the love of TFI."),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => context.go(Routes.solo),
                    child: const Text("Play Solo"),
                  ),
                  const SizedBox(height: 12),
                  const FilledButton(
                    onPressed: null,
                    child: Text("Play Online"),
                  ),
                  const SizedBox(height: 12),
                  const FilledButton(
                    onPressed: null,
                    child: Text("2-Player"),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Online & 2-Player coming soon",
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              key: const Key("ad-slot"),
              height: 56,
              alignment: Alignment.center,
              color: AppColors.sand,
            ),
          ],
        ),
      ),
    );
  }
}
