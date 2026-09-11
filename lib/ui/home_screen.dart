import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../ads/ad_service.dart";
import "../ads/banner_ad_slot.dart";
import "../core/router.dart";
import "../core/theme.dart";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adServiceProvider).showColdOpenInterstitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hero art at full opacity throughout — the raised hand + tickets
          // need their own dark surroundings to read (they're lit to glow
          // against black in the source art; erasing that to flat ivory
          // washed them out).
          Image.asset("assets/fan-ticket.png", fit: BoxFit.cover),
          // Ivory wash at the very top (hides the plain black void behind
          // the wordmark, easing off by the time the ticket appears) plus
          // the usual dark scrim toward the bottom for the menu cards.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.05, 0.13, 0.22, 0.5, 0.68, 1.0],
                colors: [
                  Color(0xEEFAF7ED),
                  Color(0xC0FAF7ED),
                  Color(0x55FAF7ED),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xC015100E),
                  Color(0xF80D0A08),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Image.asset(
                            "assets/title-logo.png",
                            fit: BoxFit.contain,
                            height: 128,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _Tagline(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Column(
                    children: [
                      _MenuButton(
                        label: "Play Solo",
                        subtitle: "Time Attack Mode",
                        primary: true,
                        onTap: () => context.go(Routes.solo),
                      ),
                      const SizedBox(height: 12),
                      const _MenuButton(
                        label: "Play Online",
                        subtitle: "Play with fans worldwide",
                        comingSoon: true,
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        label: "2-Player",
                        subtitle: "Same device, tabletop",
                        onTap: () => context.go(Routes.twoPlayer),
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        label: "Settings",
                        subtitle: "Sound, haptics, about",
                        onTap: () => context.go(Routes.settings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "A TELUGU CINEMA PARTY GAME",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const BannerAdSlot(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    // A soft ivory halo keeps the dark text legible even where the wash
    // has eased off and the art underneath is showing through.
    const style = TextStyle(
      color: AppColors.charcoal,
      fontSize: 15,
      letterSpacing: 2.5,
      fontWeight: FontWeight.w700,
      height: 1.5,
      shadows: [
        Shadow(color: AppColors.ivory, blurRadius: 10),
        Shadow(color: AppColors.ivory, blurRadius: 10),
      ],
    );
    return const Column(
      children: [
        Text("SPOT THE ONE.", style: style),
        Text(
          "FOR THE LOVE OF TFI.",
          style: style,
          semanticsLabel: "Spot the one. For the love of TFI.",
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.subtitle,
    this.onTap,
    this.primary = false,
    this.comingSoon = false,
  });

  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !comingSoon;
    final bg = primary
        ? AppColors.cinemaRed
        : Colors.white.withValues(alpha: 0.10);
    final fg = primary || enabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.55);

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: primary
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (comingSoon)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mustard.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "SOON",
                      style: TextStyle(
                        color: AppColors.charcoal,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
