import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/landing/presentation/landing_page.dart';
import 'package:nhom_huan_hieu/features/homestay/presentation/explore_page.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets('the public landing page introduces HHL Stay and opens explore', (
    tester,
  ) async {
    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.text('đúng gu.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Tìm'));
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/explore',
    );
    expect(find.byType(ExplorePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
