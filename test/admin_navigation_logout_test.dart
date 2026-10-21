import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';
import 'package:nhom_huan_hieu/features/auth/domain/auth_repository.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/auth_provider.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets('admin navigation contains management pages, not Explore', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1518, 933);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Đơn đặt phòng'), findsOneWidget);
    expect(find.text('Lịch phòng'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
    expect(find.text('Khám phá'), findsNothing);
    expect(find.text('Trang khách'), findsNothing);

    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ quản trị'), findsOneWidget);
    expect(find.text('Tài khoản'), findsNothing);

    container.read(routerProvider).go('/explore');
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/host',
    );

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('admin logout ends at the public landing page', (tester) async {
    tester.view.physicalSize = const Size(1518, 933);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authModeProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(auth),
        currentUserProvider.overrideWith((ref) => auth.currentUser),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/host');
    await tester.pumpAndSettle();

    auth.failSignOut = true;
    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa thể đăng xuất. Vui lòng thử lại.'), findsOneWidget);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/host',
    );

    auth.failSignOut = false;
    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/',
    );

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    auth.dispose();
  });
}

class _FakeAuthRepository implements AuthRepository {
  bool _signedIn = true;
  bool failSignOut = false;
  final _updates = StreamController<AppUser?>.broadcast();
  final _user = AppUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    displayName: 'Admin',
    role: AppUserRole.host,
    createdAt: DateTime(2026),
  );

  @override
  Stream<AppUser?> get currentUser => Stream.multi((controller) {
    controller.add(_signedIn ? _user : null);
    final subscription = _updates.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> signOut() async {
    if (failSignOut) throw StateError('Simulated sign-out failure');
    _signedIn = false;
    _updates.add(null);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required AppUserRole role,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> updateRole(String uid, AppUserRole role) =>
      throw UnimplementedError();

  void dispose() => _updates.close();
}
