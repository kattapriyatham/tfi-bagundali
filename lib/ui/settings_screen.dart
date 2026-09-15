import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:url_launcher/url_launcher.dart";

import "../auth/account_deletion.dart";
import "../auth/anon_auth.dart";
import "../core/links.dart";
import "../core/router.dart";
import "../core/theme.dart";
import "../storage/best_time_store.dart";
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
          ListTile(
            title: const Text("Privacy policy"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openPrivacyPolicy(context),
          ),
          ListTile(
            title: const Text("Delete my data"),
            subtitle: const Text("Erases your stats and account permanently"),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: "TFI Bagundali",
            applicationVersion: "0.1.0",
            applicationLegalese: "A Telugu cinema party game.",
            child: Text("Credits"),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete my data?"),
      content: const Text(
        "This permanently deletes your stats and account. "
        "This cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await deleteAccountAndData(
      auth: ref.read(firebaseAuthProvider),
      firestore: FirebaseFirestore.instance,
      bestTimeStore: BestTimeStore(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your data has been deleted.")),
      );
      context.go(Routes.home);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't delete data: $e")),
      );
    }
  }
}

Future<void> _openPrivacyPolicy(BuildContext context) async {
  final uri = Uri.parse(AppLinks.privacyPolicy);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open the privacy policy.")),
    );
  }
}
