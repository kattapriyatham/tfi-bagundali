import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/app.dart";

void main() {
  testWidgets("app boots", (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text("TFI Bagundaali"), findsOneWidget);
  });
}
