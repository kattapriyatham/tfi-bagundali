import "dart:io";

import "package:flutter_test/flutter_test.dart";

void main() {
  test("game logic stays free of Flutter and plugin imports", () {
    // Pure logic: deck maths, the round engine, and the seeded RNG. UI-facing
    // helpers (theme, router) also live under lib/core and are excluded here.
    const guardedDirs = ["lib/deck", "lib/game/engine"];
    const guardedFiles = ["lib/core/rng.dart"];

    // deck_loader.dart is the asset-I/O boundary; it is allowed Flutter.
    const allowed = {"deck_loader.dart"};
    final targets = <File>[
      for (final p in guardedFiles) File(p),
      for (final dir in guardedDirs)
        if (Directory(dir).existsSync())
          ...Directory(dir)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => !allowed.contains(f.uri.pathSegments.last)),
    ];

    final bad = RegExp(
      r'''import\s+["'](package:flutter/|package:flutter_riverpod/|package:shared_preferences/|package:go_router/)''',
    );
    final offenders = <String>[];
    for (final f in targets) {
      if (!f.path.endsWith(".dart")) continue;
      if (bad.hasMatch(f.readAsStringSync())) offenders.add(f.path);
    }

    expect(offenders, isEmpty, reason: "pure packages must stay Flutter-free");
  });
}
