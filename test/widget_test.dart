import 'package:flutter_test/flutter_test.dart';
import 'package:manbar_almasjid/main.dart';

void main() {
  testWidgets('App widget instantiation test', (WidgetTester tester) async {
    // Verify that ManbarAlmasjidApp is instantiated.
    const app = ManbarAlmasjidApp();
    expect(app, isNotNull);
  });
}
