import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../ads/ad_service.dart";
import "../../auth/anon_auth.dart";
import "../../core/router.dart";
import "../../core/theme.dart";
import "../../game/online/online_inferno_controller.dart";
import "../../game/solo/solo_controller.dart" show deckProvider;
import "../../rooms/room_models.dart" show RoomPlayer, RoomSnapshot;
import "../../storage/active_room_store.dart";
import "../widgets/card_view.dart";
import "../widgets/confetti_overlay.dart";
import "../widgets/match_flash.dart";
import "../widgets/quit_confirm.dart";

class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final MatchFlash _flash = MatchFlash(vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(roomCodeProvider.notifier).state = widget.code;
      ref.read(activeRoomProvider.notifier).save(widget.code);
      ref.read(roomRepositoryProvider).reconnect(widget.code);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flash.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(roomRepositoryProvider).reconnect(widget.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckProvider);
    final room = ref.watch(onlineInfernoControllerProvider);

    ref.listen<AsyncValue<RoomSnapshot>>(onlineInfernoControllerProvider,
        (prev, next) {
      final prevSnap = prev?.value;
      final nextSnap = next.value;
      if (prevSnap == null || nextSnap == null) return;
      for (final entry in nextSnap.players.entries) {
        final prevCount = prevSnap.players[entry.key]?.count ?? 0;
        if (entry.value.count > prevCount) {
          final myUid = ref.read(firebaseAuthProvider).currentUser?.uid;
          final isSelf = entry.key == myUid;
          _flash.show(
            text:
                isSelf ? "You matched it!" : "${entry.value.name} matched it!",
            isSelf: isSelf,
          );
          break;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Room ${widget.code}"),
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final quit = await confirmQuit(
              context,
              title: "Quit game?",
              message: "You'll leave this online game.",
            );
            if (quit) {
              await ref
                  .read(roomRepositoryProvider)
                  .setConnected(widget.code, connected: false);
              await ref.read(activeRoomProvider.notifier).clear();
              if (context.mounted) context.go(Routes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: deck.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Failed to load deck: $e")),
          data: (loadedDeck) => room.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Room error: $e")),
            data: (snap) {
              final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
              if (myUid == null) {
                return const Center(child: Text("Not signed in"));
              }
              final me = snap.players[myUid];
              if (me == null) {
                return const Center(child: Text("You're not in this room"));
              }

              if (snap.isComplete) {
                ref
                    .read(onlineInfernoControllerProvider.notifier)
                    .markResultIfComplete();
                final standings = snap.players.entries.toList()
                  ..sort((a, b) => b.value.count.compareTo(a.value.count));
                return _ResultView(
                  standings: standings,
                  myUid: myUid,
                  onHome: () {
                    ref.read(adServiceProvider).showInterstitial();
                    ref.read(activeRoomProvider.notifier).clear();
                    context.go(Routes.home);
                  },
                );
              }

              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: CardView(
                            card: loadedDeck.card(snap.centerCardId),
                            accent: Colors.amber,
                            interactive: false,
                            onSymbolTap: (_) {},
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CardView(
                                card: loadedDeck.card(me.currentCardId),
                                accent: Colors.teal,
                                onSymbolTap: (id) => ref
                                    .read(
                                      onlineInfernoControllerProvider.notifier,
                                    )
                                    .tap(id),
                              ),
                              MatchCheckBadge(flash: _flash, onlySelf: true),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final e in snap.players.entries)
                              Column(
                                children: [
                                  Text(e.value.name),
                                  Text("${e.value.count}"),
                                  Icon(
                                    e.value.connected
                                        ? Icons.circle
                                        : Icons.circle_outlined,
                                    size: 10,
                                    color: e.value.connected
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(child: MatchFlashBanner(flash: _flash)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Colours cycled across the scoreboard's avatar chips. Mustard is left out
/// — its bright yellow can't carry the white initial legibly.
const _kAvatarColors = [
  AppColors.cinemaRed,
  AppColors.teal,
  AppColors.charcoal,
];

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.standings,
    required this.myUid,
    required this.onHome,
  });

  final List<MapEntry<String, RoomPlayer>> standings;
  final String myUid;
  final VoidCallback onHome;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery isn't available yet in initState, so the entrance kicks
    // off here instead — guarded to run only once per widget lifetime.
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _stage(double begin, double end) =>
      Interval(begin, end, curve: Curves.easeOutCubic).transform(
        _controller.value,
      );

  @override
  Widget build(BuildContext context) {
    final winner = widget.standings.first;
    final maxCount = math.max(
      1,
      widget.standings.map((e) => e.value.count).reduce(math.max),
    );

    return ColoredBox(
      color: AppColors.ivory,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ConfettiOverlay(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _reveal(
                      _stage(0, 0.45),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mustard.withValues(alpha: 0.55),
                              blurRadius: 32,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 64,
                          color: AppColors.mustard,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _reveal(
                      _stage(0.15, 0.55),
                      Column(
                        children: [
                          Text(
                            winner.key == widget.myUid
                                ? "You win!"
                                : winner.value.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.cinemaRed,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: AppColors.mustard,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          if (winner.key != widget.myUid) ...[
                            const SizedBox(height: 4),
                            const Text(
                              "WINS",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _reveal(
                      _stage(0.3, 0.7),
                      Column(
                        children: [
                          for (var i = 0; i < widget.standings.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _ScoreRow(
                              player: widget.standings[i].value,
                              isWinner: i == 0,
                              avatarColor:
                                  _kAvatarColors[i % _kAvatarColors.length],
                              fraction: _stage(0.45, 0.9) *
                                  widget.standings[i].value.count /
                                  maxCount,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _reveal(
                      _stage(0.5, 0.85),
                      SizedBox(
                        width: 240,
                        child: FilledButton(
                          onPressed: widget.onHome,
                          child: const Text("Home"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reveal(double t, Widget child) {
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - t.clamp(0.0, 1.0)) * 16),
        child: child,
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.player,
    required this.isWinner,
    required this.avatarColor,
    required this.fraction,
  });

  final RoomPlayer player;
  final bool isWinner;
  final Color avatarColor;

  /// 0..1 fraction of the leader's score, already eased for the reveal
  /// animation — the bar's current width, not just its final target.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isWinner ? Border.all(color: AppColors.mustard, width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: avatarColor,
            child: Text(
              player.name.isEmpty ? "?" : player.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isWinner) ...[
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 14,
                        color: AppColors.mustard,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        player.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 5,
                    color: AppColors.sand,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: ColoredBox(color: avatarColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${player.count}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.charcoal,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
