import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/firebase/firebase_providers.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';
import 'package:nhom_huan_hieu/features/auth/domain/auth_repository.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/auth_provider.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets(
    'booking redirects signed-out visitors to login and preserves return path',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final userUpdates = StreamController<AppUser?>.broadcast();
      final container = ProviderContainer(
        overrides: [
          authModeProvider.overrideWithValue(true),
          currentUserProvider.overrideWith((ref) => userUpdates.stream),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pump();
      userUpdates.add(null);
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/host');
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/admin/login',
      );

      container.read(routerProvider).go('/book/room-1');
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/login',
      );
      expect(
        container
            .read(routerProvider)
            .routeInformationProvider
            .value
            .uri
            .queryParameters['from'],
        '/book/room-1',
      );

      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await userUpdates.close();
    },
  );

  testWidgets('login guidance matches device-persisted demo accounts', (
    tester,
  ) async {
    final container = ProviderContainer();
    container.read(routerProvider).go('/login');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hướng dẫn thao tác'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Tài khoản, đơn đặt và yêu thích được lưu trên thiết bị này',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('chỉ lưu tạm trong bộ nhớ'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

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

  testWidgets('Firebase registration cannot self-select a management role', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        firebaseModeProvider.overrideWithValue(true),
        authModeProvider.overrideWithValue(true),
      ],
    );
    container.read(routerProvider).go('/register?role=host');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(find.text('Chủ nhà'), findsNothing);
    expect(
      find.textContaining('Quyền quản lý chỉ do quản trị viên dự án cấp.'),
      findsOneWidget,
    );
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

  testWidgets('guest login restores the requested booking route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _LoginAuthRepository();
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
    container.read(routerProvider).go('/login?from=%2Fbook%2Fpine-1');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'guest-test@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'guest-pass-123');
    await tester.tap(find.text('Đăng nhập').first);
    await tester.pumpAndSettle();

    expect(auth.signInCalls, hasLength(1));
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/book/pine-1',
    );
    expect(container.read(roleProvider).name, 'guest');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    auth.dispose();
  });

  testWidgets('host login enters management dashboard', (tester) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _LoginAuthRepository();
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
    container.read(routerProvider).go('/admin/login?from=%2Fhost');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'host-test@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'host-pass-123');
    await tester.tap(find.text('Đăng nhập quản lý').last);
    await tester.pumpAndSettle();

    expect(auth.signInCalls, hasLength(1));
    expect(auth.currentUserNow?.role, AppUserRole.host);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/host',
    );
    expect(find.text('Đơn đặt phòng'), findsOneWidget);
    expect(find.text('Khám phá'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    auth.dispose();
  });

  testWidgets('guest credentials cannot open the host management login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _LoginAuthRepository();
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
    container.read(routerProvider).go('/admin/login');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'guest-test@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'guest-pass-123');
    await tester.tap(find.text('Đăng nhập quản lý').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Chủ nhà/Admin'), findsOneWidget);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/admin/login',
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    auth.dispose();
  });

  testWidgets('Firebase admin login explains that role must be provisioned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _LoginAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authModeProvider.overrideWithValue(true),
        firebaseModeProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(auth),
        currentUserProvider.overrideWith((ref) => auth.currentUser),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/admin/login');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'guest-test@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'guest-pass-123');
    await tester.tap(find.text('Đăng nhập quản lý').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('liên hệ quản trị viên dự án để được cấp quyền'),
      findsOneWidget,
    );
    expect(find.textContaining('đăng ký vai trò Chủ nhà'), findsNothing);
    expect(tester.takeException(), isNull);

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

class _LoginAuthRepository implements AuthRepository {
  final _updates = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  final signInCalls = <(String, String)>[];
  AppUser? get currentUserNow => _user;

  @override
  Stream<AppUser?> get currentUser => Stream.multi((controller) {
    controller.add(_user);
    final subscription = _updates.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email, password));
    final role = switch (email) {
      'guest-test@example.invalid' when password == 'guest-pass-123' =>
        AppUserRole.guest,
      'host-test@example.invalid' when password == 'host-pass-123' =>
        AppUserRole.host,
      _ => throw Exception('Email hoặc mật khẩu không đúng.'),
    };
    _user = AppUser(
      uid: 'test-${role.name}',
      email: email,
      displayName: role == AppUserRole.host
          ? 'Chủ nhà kiểm thử'
          : 'Khách kiểm thử',
      role: role,
      createdAt: DateTime(2026),
    );
    _updates.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required AppUserRole role,
    String? displayName,
  }) => throw UnimplementedError();

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
