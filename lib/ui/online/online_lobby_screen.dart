import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../auth/anon_auth.dart";
import "../../core/router.dart";
import "../../game/engine/round_state.dart" show shuffledDeckOrder;
import "../../game/online/online_inferno_controller.dart"
    show roomRepositoryProvider;
import "../../rooms/room_models.dart";
import "../../storage/active_room_store.dart";
import "../widgets/quit_confirm.dart";

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
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
    final code = widget.code;
    final repo = ref.watch(roomRepositoryProvider);
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Room $code"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final quit = await confirmQuit(
              context,
              title: "Leave room?",
              message: "You'll leave this lobby.",
            );
            if (quit) {
              await repo.setConnected(code, connected: false);
              await ref.read(activeRoomProvider.notifier).clear();
              if (context.mounted) context.go(Routes.home);
            }
          },
        ),
      ),
      body: StreamBuilder<RoomSnapshot>(
        stream: repo.watchRoom(code),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final room = snap.data!;
          final isHost = room.meta.hostUid == myUid;
          final connectedCount =
              room.players.values.where((p) => p.connected).length;

          if (room.meta.status != "lobby") {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(Routes.onlineGame(code));
            });
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                "Code: $code",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              for (final entry in room.players.entries)
                ListTile(
                  title: Text(entry.value.name),
                  trailing: Icon(
                    entry.value.connected
                        ? Icons.circle
                        : Icons.circle_outlined,
                    color: entry.value.connected ? Colors.green : Colors.grey,
                    size: 12,
                  ),
                ),
              const SizedBox(height: 24),
              if (isHost)
                FilledButton(
                  onPressed: connectedCount >= 2
                      ? () async {
                          final uids = room.players.entries.toList()
                            ..sort(
                              (a, b) =>
                                  a.value.joinedAt.compareTo(b.value.joinedAt),
                            );
                          final deckOrder = shuffledDeckOrder(
                            DateTime.now().millisecondsSinceEpoch,
                          );
                          await repo.startGame(
                            code,
                            deckOrder: deckOrder,
                            orderedUids: uids.map((e) => e.key).toList(),
                          );
                        }
                      : null,
                  child: Text(
                    connectedCount >= 2
                        ? "Start game"
                        : "Waiting for players ($connectedCount/2 min)",
                  ),
                )
              else
                const Text("Waiting for the host to start..."),
            ],
          );
        },
      ),
    );
  }
}
