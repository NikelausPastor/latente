import 'package:flutter_test/flutter_test.dart';
import 'package:latente/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Latente home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LatenteApp());
    await tester.pumpAndSettle();

    expect(find.text('Latente'), findsWidgets);
    expect(find.text('Calcolatore e timer per sviluppo analogico'),
        findsOneWidget);
  });
}
