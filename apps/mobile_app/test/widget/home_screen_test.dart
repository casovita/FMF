import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/home/application/home_provider.dart';
import 'package:mobile_app/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows skill module cards when data loads', (tester) async {
    final fakeModules = [
      const AcademyModuleEntry(
        skillId: 'handstand',
        title: 'Handstand',
        description: 'Test description for handstand',
        route: '/skill/handstand',
      ),
    ];

    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academyModulesProvider.overrideWith((_) async => fakeModules),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Pump to resolve the async provider
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Handstand'), findsOneWidget);
    expect(find.text('Test description for handstand'), findsOneWidget);
  });

  testWidgets('HomeScreen shows loading indicator while data is loading', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academyModulesProvider.overrideWith(
            (_) => Future<List<AcademyModuleEntry>>.delayed(
              const Duration(seconds: 10),
              () => <AcademyModuleEntry>[],
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
