import "package:flutter/material.dart";

/// Shows a "quit?" confirmation dialog. Returns true iff the user confirmed.
Future<bool> confirmQuit(
  BuildContext context, {
  String title = "Quit run?",
  String message = "Your progress in this run will be lost.",
}) async {
  final quit = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text("Quit"),
        ),
      ],
    ),
  );
  return quit ?? false;
}
