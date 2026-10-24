import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets(
    'guest and admin routes render without phone-sized layout errors',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      final guestRoutes = [
        '/home',
        '/explore',
        '/favorites',
        '/homestays/pine',
        '/bookings',
        '/ai-chat',
        '/profile',
      ];
      container.read(roleProvider.notifier).state = DemoRole.guest;
      for (final route in guestRoutes) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          route,
          reason: 'Guest route $route should remain reachable on a phone.',
        );
        expect(tester.takeException(), isNull, reason: 'Guest route $route');
      }

      router.go('/book/pine-1');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/login',
        reason: 'A guest must sign in before opening the booking form.',
      );
      expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Phone login route');

      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Narrow phone login route',
      );

      container.read(roleProvider.notifier).state = DemoRole.host;
      router.go('/admin/login');
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập quản lý'), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Narrow admin login route',
      );

      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      final adminRoutes = [
        '/host',
        '/bookings',
        '/host/calendar',
        '/host/finance',
        '/host/housekeeping',
        '/host/guests',
        '/host/staff',
        '/profile',
      ];
      for (final route in adminRoutes) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          route,
          reason: 'Admin route $route should remain reachable on a phone.',
        );
        expect(tester.takeException(), isNull, reason: 'Admin route $route');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
