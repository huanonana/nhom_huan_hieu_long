import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/auth/data/demo_auth_repository.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/auth_provider.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/dashboard/presentation/guest_directory_page.dart';

void main() {
  testWidgets('guest directory uses the account name for matching bookings', (
    tester,
  ) async {
    final auth = DemoAuthRepository.instance;
    final originalSnapshot = auth.exportSnapshot();
    auth.restoreSnapshot(null);
    final guest = await auth.signUp(
      email: 'directory-guest@example.com',
      password: 'DirectoryGuest2026!',
      role: AppUserRole.guest,
      displayName: 'Khách Hồ Sơ Thử',
    );
    await auth.signUp(
      email: 'directory-admin@example.com',
      password: 'DirectoryAdmin2026!',
      role: AppUserRole.host,
      displayName: 'Quản lý thử',
    );
    await auth.signIn(
      email: 'directory-admin@example.com',
      password: 'DirectoryAdmin2026!',
    );

    final repository = DemoBookingRepository(seed: false);
    final booking = repository.create(
      roomId: 'garden-1',
      guestId: guest.uid,
      guestName: 'Tên nhập trước đây',
      checkIn: DateTime(2026, 10, 23),
      checkOut: DateTime(2026, 10, 24),
      guests: 1,
    );
    repository.recordPayment(
      booking.id,
      actorId: 'host-demo',
      amount: 200000,
      method: 'Tiền mặt',
      note: 'Khoản demo',
    );
    repository.create(
      roomId: 'garden-1',
      guestId: 'legacy-account',
      guestName: 'Khách Demo HHL',
      checkIn: DateTime(2026, 10, 25),
      checkOut: DateTime(2026, 10, 26),
      guests: 1,
    );
    repository.create(
      roomId: 'garden-1',
      guestId: 'legacy-account',
      guestName: 'Khách trải nghiệm',
      checkIn: DateTime(2026, 10, 26),
      checkOut: DateTime(2026, 10, 27),
      guests: 1,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        currentUserProvider.overrideWith((ref) => auth.currentUser),
        repositoryProvider.overrideWithValue(repository),
      ],
    );
    container.read(roleProvider.notifier).state = DemoRole.host;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GuestDirectoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khách Hồ Sơ Thử'), findsOneWidget);
    await tester.tap(find.text('Khách Hồ Sơ Thử'));
    await tester.pumpAndSettle();
    expect(find.text('200.000 ₫'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Khách Hồ Sơ Thử');
    await tester.pumpAndSettle();
    expect(find.text('Khách Hồ Sơ Thử'), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'Khách Demo HHL');
    await tester.pumpAndSettle();
    expect(find.text('Khách Demo HHL'), findsNWidgets(2));
    expect(find.text('Khách trải nghiệm'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    auth.restoreSnapshot(originalSnapshot);
  });
}
