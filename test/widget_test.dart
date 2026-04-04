import 'package:flutter_test/flutter_test.dart';
import 'package:file_crypto/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FileCryptoApp());
    expect(find.text('Encryption'), findsOneWidget);
  });
}
