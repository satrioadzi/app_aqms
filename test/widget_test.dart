import 'package:flutter_test/flutter_test.dart';

import 'package:app_aqms/main.dart';

void main() {
  testWidgets('AQMS Dashboard Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AirMonitoringApp());

    // Verify that our app bar title or main dashboard content is displayed.
    expect(find.text('LoRa AQMS'), findsOneWidget);
    expect(find.text('Node Sensor Aktif'), findsOneWidget);
  });
}
