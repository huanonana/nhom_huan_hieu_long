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
    expect(find.text('vui trọn chuyến đi.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(LandingPage.featuresKey),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Trợ lý AI'), findsOneWidget);
    expect(find.byTooltip('Tư vấn homestay bằng AI'), findsNothing);
    final aiCta = find.text('Hỏi trợ lý AI');
    await tester.scrollUntilVisible(
      aiCta,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final aiButton = find.byKey(const ValueKey('landing-ai-cta'));
    expect(tester.widget<TextButton>(aiButton).onPressed, isNotNull);
    final exploreCta = find.text('Khám phá homestay');
    await tester.scrollUntilVisible(
      exploreCta,
      -350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(exploreCta);
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/explore',
    );
    expect(find.byType(ExplorePage), findsOneWidget);
    expect(find.byTooltip('Tư vấn homestay bằng AI'), findsNothing);
    expect(find.text('Bắt đầu ngay'), findsNothing);
    expect(find.text('Dành cho chủ nhà'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
