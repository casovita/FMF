import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/app/bootstrap/bootstrap.dart';
import 'package:mobile_app/app/flavor/app_flavor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and home screen renders', (tester) async {
    await bootstrap(
      const FlavorConfig(
        flavor: AppFlavor.dev,
        appName: 'FMF [DEV]',
        envLabel: 'dev',
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify the app root scaffold is present
    expect(find.byType(Scaffold), findsWidgets);
  });
}
