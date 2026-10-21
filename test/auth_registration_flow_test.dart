import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';
import 'package:nhom_huan_hieu/features/auth/domain/auth_repository.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/auth_provider.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets('registration layout stays scrollable on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    container.read(routerProvider).go('/register');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('registration validates fields and creates a guest session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _RegistrationAuthRepository();
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
    container.read(routerProvider).go('/register');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng ký').first);
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên hiển thị.'), findsOneWidget);
    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(find.text('Mật khẩu tối thiểu 6 ký tự.'), findsOneWidget);
    expect(auth.signUpCalls, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(0), 'Khách kiểm thử');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'guest-test@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'test-pass-123');
    await tester.tap(find.text('Đăng ký').first);
    await tester.pumpAndSettle();

    expect(auth.signUpCalls, hasLength(1));
    expect(auth.signUpCalls.single.$1, 'guest-test@example.invalid');
    expect(auth.signUpCalls.single.$3, AppUserRole.guest);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/explore',
    );

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    auth.dispose();
  });

  testWidgets('host registration routes into management after sign-up', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _RegistrationAuthRepository();
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
    container.read(routerProvider).go('/register?role=host');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Chủ nhà test');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'host-test@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'test-pass-456');
    await tester.tap(find.text('Đăng ký').first);
    await tester.pumpAndSettle();

    expect(auth.signUpCalls, hasLength(1));
    expect(auth.signUpCalls.single.$3, AppUserRole.host);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/host',
    );
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Đơn đặt phòng'), findsOneWidget);
    expect(find.text('Lịch phòng'), findsOneWidget);
    expect(find.text('Khám phá'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    auth.dispose();
  });
}

class _RegistrationAuthRepository implements AuthRepository {
  final _updates = StreamController<AppUser?>.broadcast();
  final List<(String, String, AppUserRole)> signUpCalls = [];
  AppUser? _user;

  @override
  Stream<AppUser?> get currentUser => Stream.multi((controller) {
    controller.add(_user);
    final subscription = _updates.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required AppUserRole role,
    String? displayName,
  }) async {
    signUpCalls.add((email, password, role));
    _user = AppUser(
      uid: 'test-${role.name}',
      email: email,
      displayName: displayName ?? '',
      role: role,
      createdAt: DateTime(2026),
    );
    _updates.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {
    _user = null;
    _updates.add(null);
  }

  @override
  Future<void> updateRole(String uid, AppUserRole role) =>
      throw UnimplementedError();

  void dispose() => _updates.close();
}
