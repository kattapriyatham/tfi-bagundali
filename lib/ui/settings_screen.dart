import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../core/router.dart";
import "../core/theme.dart";
import "../storage/settings_store.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Haptics"),
            subtitle: const Text("Vibrate on match and mistakes"),
            value: settings.haptics,
            onChanged: (v) => ctrl.setHaptics(enabled: v),
          ),
          SwitchListTile(
            title: const Text("Sound effects"),
            subtitle: const Text("Match, mistake, and countdown cues"),
            value: settings.sound,
            onChanged: (v) => ctrl.setSound(enabled: v),
          ),
          const Divider(),
          const ListTile(
            title: Text("Privacy policy"),
            subtitle: Text("Added before store release"),
            trailing: Icon(Icons.open_in_new),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: "TFI Bagundaali",
            applicationVersion: "0.1.0",
            applicationLegalese: "A Telugu cinema party game.",
            child: Text("Credits"),
          ),
        ],
      ),
    );
  }
}
