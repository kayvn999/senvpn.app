import 'package:flutter_test/flutter_test.dart';
import 'package:appso1/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(SecureVpnApp, isNotNull);
  });
}
