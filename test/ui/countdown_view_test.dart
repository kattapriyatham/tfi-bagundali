import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/ui/widgets/countdown_view.dart";

void main() {
  testWidgets("counts 3-2-1-GO then fires onDone", (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CountdownView(
          step: const Duration(milliseconds: 10),
          onDone: () => done = true,
        ),
      ),
    );
    expect(find.text("3"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text("2"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text("1"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text("GO!"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 10));
    expect(done, isTrue);
  });
}
