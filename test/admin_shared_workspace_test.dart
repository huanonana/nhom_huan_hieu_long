import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/features/booking/presentation/bookings_page.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';

void main() {
  testWidgets('admin sees and can process bookings with legacy host IDs', (
    tester,
  ) async {
    final repository = DemoBookingRepository(seed: false);
    const legacyHostId = 'old-local-admin-id';
    const home = Homestay(
      id: 'legacy-home',
      hostId: legacyHostId,
      name: 'Nhà vườn cũ',
      city: 'Đà Lạt',
      address: 'Đường Hoa',
      description: 'Homestay dùng để kiểm tra dữ liệu chủ sở hữu cũ.',
      amenities: ['Wi-Fi'],
      color: 0xFF2F6757,
    );
    repository.saveHomestay(home, actorId: legacyHostId);
    repository.saveRoom(
      const Room(
        id: 'legacy-room',
        homestayId: 'legacy-home',
        name: 'Phòng ban công',
        price: 500000,
        capacity: 2,
      ),
      actorId: legacyHostId,
    );
    final checkIn = vietnamToday(repository.now).add(const Duration(days: 3));
    final booking = repository.create(
      roomId: 'legacy-room',
      guestId: 'guest-account-1',
      guestName: 'Khách đặt thật',
      checkIn: checkIn,
      checkOut: checkIn.add(const Duration(days: 2)),
      guests: 2,
      note: '',
    );

    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: BookingsPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(booking.id), findsOneWidget);

    final controller = container.read(changesProvider.notifier);
    controller.saveHomestay(home);
    controller.setHousekeeping('legacy-room', HousekeepingStatus.cleaning);
    controller.recordPayment(booking.id, amount: 50000, method: 'Chuyển khoản');
    controller.transition(booking.id, BookingStatus.confirmed, DemoRole.host);
    expect(repository.bookings.single.status, BookingStatus.confirmed);
    expect(repository.bookings.single.paidAmount, 50000);
    expect(
      repository.rooms
          .singleWhere((room) => room.id == 'legacy-room')
          .housekeepingStatus,
      HousekeepingStatus.cleaning,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
