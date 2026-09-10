import "dart:io";

import "package:flutter_test/flutter_test.dart";

void main() {
  test("game logic packages do not import Flutter or plugins", () {
    const guarded = ["lib/core", "lib/deck", "lib/game/engine"];
    final offenders = <String>[];
    for (final dir in guarded) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final f in d.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith(".dart")) continue;
        final src = f.readAsStringSync();
        final bad = RegExp(
          r'''import\s+["'](package:flutter/|package:flutter_riverpod/|package:shared_preferences/|package:go_router/)''',
        );
        if (bad.hasMatch(src)) offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty, reason: "pure packages must stay Flutter-free");
  });
}
