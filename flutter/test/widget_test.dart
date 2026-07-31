import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:property_radar/main.dart';
import 'package:property_radar/core/config/environment.dart';
import 'package:property_radar/core/providers/dependency_injection.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    Environment.init();
    await setupDependencyInjection();

    await tester.pumpWidget(
      const ProviderScope(
        child: PropertyRadarApp(),
      ),
    );

    expect(find.byType(PropertyRadarApp), findsOneWidget);
  });
}
