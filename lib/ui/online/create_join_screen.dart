import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../auth/anon_auth.dart";
import "../../core/router.dart";
import "../../core/theme.dart";
import "../../game/online/online_inferno_controller.dart"
    show roomRepositoryProvider;
import "../../storage/active_room_store.dart";

class CreateJoinScreen extends ConsumerStatefulWidget {
  const CreateJoinScreen({super.key});

  @override
  ConsumerState<CreateJoinScreen> createState() => _CreateJoinScreenState();
}

class _CreateJoinScreenState extends ConsumerState<CreateJoinScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController(text: "Player");
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ensureSignedIn(ref.read(firebaseAuthProvider));
      final repo = ref.read(roomRepositoryProvider);
      final code = await repo.createRoom();
      await repo.joinRoom(code, displayName: _nameController.text.trim());
      await ref.read(activeRoomProvider.notifier).save(code);
      if (mounted) context.go(Routes.onlineLobby(code));
    } catch (e) {
      setState(() => _error = "Couldn't create a room: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 5) {
      setState(() => _error = "Enter the 5-letter room code");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ensureSignedIn(ref.read(firebaseAuthProvider));
      await ref.read(roomRepositoryProvider).joinRoom(
            code,
            displayName: _nameController.text.trim(),
          );
      await ref.read(activeRoomProvider.notifier).save(code);
      if (mounted) context.go(Routes.onlineLobby(code));
    } catch (e) {
      setState(() => _error = "Couldn't join: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play Online"),
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Your name"),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text("Create a room"),
            ),
            const SizedBox(height: 32),
            const Text("— or —", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
              decoration: const InputDecoration(labelText: "Room code"),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _join,
              child: const Text("Join"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
