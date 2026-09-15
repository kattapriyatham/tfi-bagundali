import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../ads/ad_service.dart";
import "../ads/banner_ad_slot.dart";
import "../auth/anon_auth.dart";
import "../core/online_availability.dart";
import "../core/router.dart";
import "../core/theme.dart";
import "../game/online/online_inferno_controller.dart"
    show roomRepositoryProvider;
import "../storage/active_room_store.dart";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _rejoinCode;
  bool _rejoinIsLobby = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adServiceProvider).showColdOpenInterstitial();
    });
    _checkForActiveRoom();
  }

  Future<void> _checkForActiveRoom() async {
    final code = await ref.read(activeRoomProvider.notifier).readStored();
    if (code == null || !mounted) return;

    try {
      await ensureSignedIn(ref.read(firebaseAuthProvider));
      final myUid = ref.read(firebaseAuthProvider).currentUser?.uid;
      final room = await ref.read(roomRepositoryProvider).getRoom(code);
      final stillIn = room.exists &&
          room.meta.status != "finished" &&
          room.players.containsKey(myUid);
      if (!stillIn) {
        await ref.read(activeRoomProvider.notifier).clear();
        return;
      }
      if (mounted) {
        setState(() {
          _rejoinCode = code;
          _rejoinIsLobby = room.meta.status == "lobby";
        });
      }
    } catch (_) {
      // Offline or lookup failed — leave the stored code alone and just
      // don't show the banner this time; a later launch can retry.
    }
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
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => context.go(Routes.settings),
                    tooltip: "Settings",
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                if (_rejoinCode != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _RejoinBanner(
                      code: _rejoinCode!,
                      isLobby: _rejoinIsLobby,
                      onTap: () {
                        final code = _rejoinCode!;
                        context.go(
                          _rejoinIsLobby
                              ? Routes.onlineLobby(code)
                              : Routes.onlineGame(code),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
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
                SizedBox(
                  height: 192,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.bolt_rounded,
                            label: "Play Solo",
                            subtitle: "Time Attack",
                            primary: true,
                            onTap: () => context.go(Routes.solo),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final available =
                                  ref.watch(onlineAvailableProvider);
                              return _MenuCard(
                                icon: Icons.public_rounded,
                                label: "Play Online",
                                subtitle: "With fans worldwide",
                                comingSoon: !available,
                                onTap: available
                                    ? () => context.go(Routes.online)
                                    : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.people_alt_rounded,
                            label: "2-Player",
                            subtitle: "Same device",
                            onTap: () => context.go(Routes.twoPlayer),
                          ),
                        ),
                      ],
                    ),
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

/// Lets a player who was disconnected (backgrounded, killed, or otherwise
/// dropped out) get back to the online room they were last in — there's
/// otherwise no path back to it once its route is gone.
class _RejoinBanner extends StatelessWidget {
  const _RejoinBanner({
    required this.code,
    required this.isLobby,
    required this.onTap,
  });

  final String code;
  final bool isLobby;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cinemaRed,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.replay_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLobby
                      ? "Rejoin room $code"
                      : "Rejoin your game in room $code",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
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

/// One card in the 3-up menu row. Fixed height, fills whatever width its
/// parent `Expanded` gives it, so the row always occupies a constant height.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.primary = false,
    this.comingSoon = false,
  });

  final IconData icon;
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: primary
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: fg, size: 24),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.75),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                  Icon(Icons.chevron_right, color: fg, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
