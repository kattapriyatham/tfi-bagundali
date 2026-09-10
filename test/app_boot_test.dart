import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/app.dart";

void main() {
  testWidgets("app boots to the home route", (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    expect(find.text("FOR THE LOVE OF TFI."), findsOneWidget);
  });
}
