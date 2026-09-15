import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../auth/anon_auth.dart";
import "../../core/router.dart";
import "../../game/online/online_inferno_controller.dart";
import "../../game/solo/solo_controller.dart" show deckProvider;
import "../../rooms/room_models.dart" show RoomPlayer;
import "../../storage/active_room_store.dart";
import "../widgets/card_view.dart";
import "../widgets/quit_confirm.dart";

class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen>
    with WidgetsBindingObserver {
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

    return Scaffold(
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
                    ref.read(activeRoomProvider.notifier).clear();
                    context.go(Routes.home);
                  },
                );
              }

              return Column(
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
                      child: CardView(
                        card: loadedDeck.card(me.currentCardId),
                        accent: Colors.teal,
                        onSymbolTap: (id) => ref
                            .read(onlineInfernoControllerProvider.notifier)
                            .tap(id),
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
                  IconButton(
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.standings,
    required this.myUid,
    required this.onHome,
  });

  final List<MapEntry<String, RoomPlayer>> standings;
  final String myUid;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            standings.first.key == myUid
                ? "You win!"
                : "${standings.first.value.name} wins!",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          for (final e in standings) Text("${e.value.name}: ${e.value.count}"),
          const SizedBox(height: 24),
          FilledButton(onPressed: onHome, child: const Text("Home")),
        ],
      ),
    );
  }
}
