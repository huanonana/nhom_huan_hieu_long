import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/core/state/demo_storage.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';
import 'package:nhom_huan_hieu/features/auth/data/demo_auth_repository.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/auth_provider.dart';
import 'package:nhom_huan_hieu/features/dashboard/domain/finance_entry.dart';
import 'package:nhom_huan_hieu/features/dashboard/domain/staff_shift.dart';
import 'package:nhom_huan_hieu/features/dashboard/domain/staff_member.dart';

void main() {
  final today = DateTime.utc(2026, 9, 26);
  Room room({bool active = true, int price = 900000}) => Room(
    id: 'pine-1',
    homestayId: 'pine',
    name: 'Tên mới',
    price: price,
    capacity: 2,
    active: active,
  );
  test('Ownership, validation, booking protection and immutable quote', () {
    final repo = DemoBookingRepository(seed: false, clock: () => today);
    final booking = repo.create(
      roomId: 'pine-1',
      guestId: 'guest-demo',
      guestName: 'Khách',
      checkIn: today,
      checkOut: today.add(const Duration(days: 2)),
      guests: 2,
    );
    expect(
      () => repo.saveRoom(room(), actorId: 'stranger'),
      throwsA(isA<BookingException>()),
    );
    expect(
      () => repo.saveRoom(room(price: 0), actorId: 'host-demo'),
      throwsA(isA<BookingException>()),
    );
    expect(
      () => repo.saveRoom(room(active: false), actorId: 'host-demo'),
      throwsA(isA<BookingException>()),
    );
    expect(
      () => repo.deleteRoom('pine-1', actorId: 'host-demo'),
      throwsA(isA<BookingException>()),
    );
    repo.saveRoom(room(), actorId: 'host-demo');
    expect(booking.total, 1300000);
    expect(booking.roomName, 'Phòng thông xanh');
    repo.transition(booking.id, BookingStatus.cancelled, actorId: 'guest-demo');
    repo.saveRoom(room(active: false), actorId: 'host-demo');
    expect(
      repo.available(
        repo.rooms.first,
        today,
        today.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    repo.deleteRoom('pine-1', actorId: 'host-demo');
    expect(repo.bookings.single.id, booking.id);
  });
  test('Payment ledger validates amounts and persists room checkout state', () {
    final repo = DemoBookingRepository(seed: false, clock: () => today);
    final booking = repo.create(
      roomId: 'pine-1',
      guestId: 'guest-demo',
      guestName: 'Khách',
      checkIn: today,
      checkOut: today.add(const Duration(days: 2)),
      guests: 2,
    );
    repo.recordPayment(
      booking.id,
      actorId: 'host-demo',
      amount: 300000,
      method: 'Tiền mặt',
    );
    expect(repo.bookings.single.paidAmount, 300000);
    expect(repo.bookings.single.outstandingAmount, booking.total - 300000);
    expect(
      () => repo.recordPayment(
        booking.id,
        actorId: 'host-demo',
        amount: booking.total,
        method: 'Tiền mặt',
      ),
      throwsA(isA<BookingException>()),
    );
    final restored = DemoBookingRepository.fromJson(
      jsonDecode(jsonEncode(repo.toJson())),
      clock: () => today,
    );
    expect(restored.bookings.single.payments.single.method, 'Tiền mặt');

    repo.transition(booking.id, BookingStatus.confirmed, actorId: 'host-demo');
    repo.transition(booking.id, BookingStatus.checkedIn, actorId: 'host-demo');
    repo.transition(booking.id, BookingStatus.checkedOut, actorId: 'host-demo');
    expect(
      repo.rooms.first.housekeepingStatus,
      HousekeepingStatus.needsCleaning,
    );
    final room = repo.rooms.first;
    repo.saveRoom(
      room.withHousekeeping(HousekeepingStatus.maintenance),
      actorId: 'host-demo',
    );
    final maintenanceSnapshot = DemoBookingRepository.fromJson(
      jsonDecode(jsonEncode(repo.toJson())),
      clock: () => today,
    );
    expect(
      maintenanceSnapshot.rooms.first.housekeepingStatus,
      HousekeepingStatus.maintenance,
    );
  });
  test(
    'Cannot remove a homestay with rooms; empty custom home can be removed',
    () {
      final repo = DemoBookingRepository(seed: false);
      expect(
        () => repo.deleteHomestay('pine', actorId: 'host-demo'),
        throwsA(isA<BookingException>()),
      );
      const home = Homestay(
        id: 'custom',
        hostId: 'host-demo',
        name: 'Nhà mới',
        city: 'Huế',
        address: 'Địa chỉ mẫu',
        description: 'Mô tả mẫu',
        amenities: [],
        color: 0xFF2F6757,
      );
      repo.saveHomestay(home, actorId: 'host-demo');
      repo.deleteHomestay(home.id, actorId: 'host-demo');
      expect(repo.homestays.any((h) => h.id == home.id), isFalse);
    },
  );
  test('Homestay photo data survives model serialization', () {
    final home = Homestay(
      id: 'with-photos',
      hostId: 'host-demo',
      name: 'Nhà có ảnh',
      city: 'Cần Thơ',
      address: 'Địa chỉ demo',
      description: 'Mô tả',
      amenities: const ['Wi-Fi'],
      color: 0xFF2F6757,
      imageUrls: const ['data:image/jpeg;base64,/9j/2Q=='],
    );
    final restored = Homestay.fromJson(home.toJson());
    expect(restored.imageUrls, home.imageUrls);
  });
  test(
    'Snapshot restores dates, sequence, edited rooms and booking status',
    () {
      final repo = DemoBookingRepository(seed: false, clock: () => today);
      final b = repo.create(
        roomId: 'pine-1',
        guestId: 'guest-demo',
        guestName: 'Khách',
        checkIn: today,
        checkOut: today.add(const Duration(days: 1)),
        guests: 1,
      );
      repo.transition(b.id, BookingStatus.confirmed, actorId: 'host-demo');
      repo.saveRoom(room(), actorId: 'host-demo');
      final restored = DemoBookingRepository.fromJson(
        jsonDecode(jsonEncode(repo.toJson())),
        clock: () => today,
      );
      expect(restored.bookings.single.status, BookingStatus.confirmed);
      expect(restored.bookings.single.checkIn, today);
      expect(restored.rooms.first.price, 900000);
      final next = restored.create(
        roomId: 'pine-2',
        guestId: 'guest-demo',
        guestName: 'Khách',
        checkIn: today,
        checkOut: today.add(const Duration(days: 1)),
        guests: 1,
      );
      expect(next.id, 'HHL-0002');
    },
  );
  test('Storage survives a new container and preserves favorites', () async {
    String? disk;
    final storage = DemoStorage(
      read: () async => disk,
      write: (value) async {
        disk = value;
      },
    );
    final first = await storage.load();
    first.read(favoritesProvider.notifier).state = {'pine'};
    first.read(recentHomestaysProvider.notifier).state = ['pine', 'cantho'];
    first.read(financeEntriesProvider.notifier).state = [
      FinanceEntry(
        id: 'cost-1',
        title: 'Vệ sinh phòng',
        category: 'Vệ sinh',
        amount: 120000,
        date: today,
      ),
    ];
    first.read(staffShiftsProvider.notifier).state = [
      StaffShift(
        id: 'shift-1',
        staffId: 'staff-1',
        staffName: 'Nhân viên demo',
        role: 'Lễ tân',
        date: today,
        startHour: 8,
        endHour: 16,
        hourlyRate: 30000,
      ),
    ];
    first.read(staffMembersProvider.notifier).state = [
      const StaffMember(
        id: 'staff-1',
        name: 'Nhân viên demo',
        role: 'Lễ tân',
        phone: '0900000000',
        hourlyRate: 30000,
      ),
    ];
    first.read(changesProvider.notifier).saveRoom(room());
    await storage.settled;
    first.dispose();
    final second = await storage.load();
    expect(second.read(favoritesProvider), {'pine'});
    expect(second.read(recentHomestaysProvider), ['pine', 'cantho']);
    expect(second.read(financeEntriesProvider).single.amount, 120000);
    expect(second.read(staffShiftsProvider).single.estimatedPay, 240000);
    expect(second.read(staffShiftsProvider).single.staffId, 'staff-1');
    expect(second.read(staffMembersProvider).single.phone, '0900000000');
    expect(second.read(repositoryProvider).rooms.first.name, 'Tên mới');
    await storage.settled;
    second.dispose();
  });
  testWidgets('Storage syncs staff profiles and linked shifts across tabs', (
    tester,
  ) async {
    String? disk;
    final storage = DemoStorage(
      read: () async => disk,
      write: (value) async => disk = value,
      syncInterval: const Duration(milliseconds: 10),
    );
    final firstTab = await storage.load();
    await storage.settled;
    final secondTab = await storage.load();
    await storage.settled;

    const member = StaffMember(
      id: 'shared-staff',
      name: 'Nhân viên dùng chung',
      role: 'Lễ tân',
      phone: '',
      hourlyRate: 30000,
    );
    firstTab.read(staffMembersProvider.notifier).state = [member];
    firstTab.read(staffShiftsProvider.notifier).state = [
      StaffShift(
        id: 'shared-shift',
        staffId: member.id,
        staffName: member.name,
        role: member.role,
        date: today,
        startHour: 8,
        endHour: 16,
        hourlyRate: member.hourlyRate,
      ),
    ];
    await storage.settled;
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(secondTab.read(staffMembersProvider).single.id, member.id);
    expect(secondTab.read(staffShiftsProvider).single.staffId, member.id);
    firstTab.dispose();
    secondTab.dispose();
    storage.dispose();
  });
  test(
    'Host account and session survive reload with admin booking access',
    () async {
      String? disk;
      String? authDisk;
      final auth = DemoAuthRepository.instance;
      await auth.signOut();
      final storage = DemoStorage(
        read: () async => disk,
        write: (value) async => disk = value,
        readAuth: () async => authDisk,
        writeAuth: (value) async => authDisk = value,
      );
      final first = await storage.load();
      expect(first.read(authModeProvider), isTrue);
      final user = await first
          .read(authRepositoryProvider)
          .signUp(
            email:
                'manager-${DateTime.now().microsecondsSinceEpoch}@example.test',
            password: 'test-password-123',
            role: AppUserRole.host,
            displayName: 'Quản trị demo',
          );
      first
          .read(changesProvider.notifier)
          .book(
            roomId: 'cantho-1',
            name: 'Khách đặt thật',
            guestId: 'guest-test-1',
            start: DateTime.utc(2026, 10, 27),
            end: DateTime.utc(2026, 10, 28),
            guests: 2,
            note: '',
          );
      await storage.settled;
      first.dispose();

      final second = await storage.load();
      final restoredUser = await second.read(currentUserProvider.future);
      expect(restoredUser?.uid, user.uid);
      expect(restoredUser?.email, user.email);
      expect(restoredUser?.displayName, user.displayName);
      expect(restoredUser?.role, user.role);
      expect(second.read(roleProvider), DemoRole.host);
      final visibleBookings = second
          .read(repositoryProvider)
          .bookings
          .where((booking) => booking.hostId == 'host-demo');
      expect(
        visibleBookings.any((booking) => booking.guestName == 'Khách đặt thật'),
        isTrue,
      );
      expect(authDisk, isNotNull);
      expect(authDisk, isNot(contains('test-password-123')));
      await second.read(authRepositoryProvider).signOut();
      await storage.settled;
      second.dispose();
    },
  );

  test('Guest account, session, and booking history survive reload', () async {
    String? disk;
    String? authDisk;
    final auth = DemoAuthRepository.instance;
    await auth.signOut();
    final storage = DemoStorage(
      read: () async => disk,
      write: (value) async => disk = value,
      readAuth: () async => authDisk,
      writeAuth: (value) async => authDisk = value,
    );
    final first = await storage.load();
    final user = await first
        .read(authRepositoryProvider)
        .signUp(
          email: 'guest-${DateTime.now().microsecondsSinceEpoch}@example.test',
          password: 'guest-password-123',
          role: AppUserRole.guest,
          displayName: 'Khách kiểm thử',
        );
    final repo = first.read(repositoryProvider);
    DateTime? checkIn;
    Room? selectedRoom;
    for (var offset = 1; offset <= 365 && selectedRoom == null; offset++) {
      final candidate = vietnamToday(repo.now).add(Duration(days: offset));
      for (final room in repo.rooms.where(
        (room) => room.active && room.capacity >= 2,
      )) {
        if (repo.available(
          room,
          candidate,
          candidate.add(const Duration(days: 1)),
        )) {
          selectedRoom = room;
          checkIn = candidate;
          break;
        }
      }
    }
    expect(selectedRoom, isNotNull);
    expect(checkIn, isNotNull);
    final roomForBooking = selectedRoom!;
    final dateForBooking = checkIn!;
    final booking = first
        .read(changesProvider.notifier)
        .book(
          roomId: roomForBooking.id,
          name: user.displayName,
          guestId: user.uid,
          start: dateForBooking,
          end: dateForBooking.add(const Duration(days: 1)),
          guests: 2,
          note: '',
        );
    await storage.settled;
    first.dispose();

    final second = await storage.load();
    final restoredUser = await second.read(currentUserProvider.future);
    expect(second.read(authModeProvider), isTrue);
    expect(restoredUser?.uid, user.uid);
    expect(restoredUser?.role, AppUserRole.guest);
    expect(second.read(roleProvider), DemoRole.guest);
    expect(
      second
          .read(repositoryProvider)
          .bookings
          .any((item) => item.id == booking.id && item.guestId == user.uid),
      isTrue,
    );
    expect(authDisk, isNotNull);
    await second.read(authRepositoryProvider).signOut();
    await storage.settled;
    second.dispose();
  });

  test('Local demo adds monthly revenue samples only once', () async {
    String? disk;
    final storage = DemoStorage(
      read: () async => disk,
      write: (value) async {
        disk = value;
      },
    );
    final first = await storage.load();
    await storage.settled;
    final firstBookings = first.read(repositoryProvider).bookings;
    final demoBookings = firstBookings
        .where((booking) => booking.id.startsWith('HHL-DEMO-'))
        .toList();
    expect(demoBookings, hasLength(7));
    final expectedMonthlyTotals = <int, int>{
      4: 1300000,
      5: 1500000,
      6: 1600000,
      7: 720000,
      8: 1360000,
      9: 980000,
    };
    for (final entry in expectedMonthlyTotals.entries) {
      final month = entry.key.toString().padLeft(2, '0');
      final booking = demoBookings
          .where((item) => item.id.endsWith('-$month'))
          .single;
      expect(booking.total, entry.value);
      expect(booking.status, BookingStatus.checkedOut);
    }
    final october = demoBookings.singleWhere(
      (booking) => booking.id.endsWith('-10'),
    );
    expect(october.total, 1500000);
    expect(october.status, BookingStatus.pending);
    final activeStay = firstBookings.singleWhere(
      (booking) => booking.id == 'HHL-0001',
    );
    expect(activeStay.status, BookingStatus.checkedIn);
    expect(activeStay.guestName, startsWith('Dữ liệu demo'));
    first.dispose();

    final second = await storage.load();
    await storage.settled;
    expect(
      second
          .read(repositoryProvider)
          .bookings
          .where((booking) => booking.id.startsWith('HHL-DEMO-')),
      hasLength(7),
    );
    second.dispose();
  });

  test(
    'Stable client/admin demo accounts, guest history and expenses persist',
    () async {
      String? disk;
      String? authDisk;
      final auth = DemoAuthRepository.instance;
      auth.setPersistence(null);
      auth.restoreSnapshot(
        jsonEncode({'version': 1, 'currentUid': null, 'accounts': []}),
      );
      final storage = DemoStorage(
        read: () async => disk,
        write: (value) async => disk = value,
        readAuth: () async => authDisk,
        writeAuth: (value) async => authDisk = value,
      );

      final first = await storage.load();
      await storage.settled;
      expect(
        auth.userByEmail(DemoAuthRepository.demoGuestEmail)?.role,
        AppUserRole.guest,
      );
      expect(
        auth.userByEmail(DemoAuthRepository.demoHostEmail)?.role,
        AppUserRole.host,
      );
      expect(
        auth.signedInUser,
        isNull,
        reason: 'Seeding accounts must not log out or switch the current user.',
      );
      expect(
        first
            .read(financeEntriesProvider)
            .where((entry) => entry.id.startsWith('HHL-COST-DEMO-')),
        hasLength(12),
      );

      final guest = await auth.signIn(
        email: DemoAuthRepository.demoGuestEmail,
        password: DemoAuthRepository.demoGuestPassword,
      );
      expect(
        first
            .read(repositoryProvider)
            .bookings
            .where((item) => item.guestId == guest.uid),
        hasLength(6),
      );
      expect(
        first
            .read(repositoryProvider)
            .reviews
            .where((item) => item.guestId == guest.uid),
        hasLength(3),
      );
      await storage.settled;
      first.dispose();

      final second = await storage.load();
      await storage.settled;
      expect((await second.read(currentUserProvider.future))?.uid, guest.uid);
      expect(
        second
            .read(repositoryProvider)
            .bookings
            .where((item) => item.guestId == guest.uid),
        hasLength(6),
      );
      expect(
        second
            .read(financeEntriesProvider)
            .where((entry) => entry.id.startsWith('HHL-COST-DEMO-')),
        hasLength(12),
      );
      expect(
        () => auth.signIn(
          email: DemoAuthRepository.demoGuestEmail,
          password: 'wrong-password',
        ),
        throwsA(isA<DemoAuthException>()),
      );

      final manager = await auth.signIn(
        email: DemoAuthRepository.demoHostEmail,
        password: DemoAuthRepository.demoHostPassword,
      );
      expect(manager.role, AppUserRole.host);
      await storage.settled;
      second.dispose();

      final third = await storage.load();
      await storage.settled;
      expect(
        (await third.read(currentUserProvider.future))?.email,
        DemoAuthRepository.demoHostEmail,
      );
      expect(
        third
            .read(financeEntriesProvider)
            .where((entry) => entry.id.startsWith('HHL-COST-DEMO-')),
        hasLength(12),
      );
      expect(authDisk, isNotNull);
      expect(authDisk, isNot(contains(DemoAuthRepository.demoGuestPassword)));
      expect(authDisk, isNot(contains(DemoAuthRepository.demoHostPassword)));
      await auth.signOut();
      await storage.settled;
      third.dispose();
      storage.dispose();
      auth.setPersistence(null);
      auth.restoreSnapshot(
        jsonEncode({'version': 1, 'currentUid': null, 'accounts': []}),
      );
    },
  );

  testWidgets('Favorites and recent homes are isolated by signed-in account', (
    tester,
  ) async {
    String? disk;
    String? authDisk;
    final auth = DemoAuthRepository.instance;
    auth.setPersistence(null);
    auth.restoreSnapshot(
      jsonEncode({'version': 1, 'currentUid': null, 'accounts': []}),
    );
    final storage = DemoStorage(
      read: () async => disk,
      write: (value) async => disk = value,
      readAuth: () async => authDisk,
      writeAuth: (value) async => authDisk = value,
    );
    final first = await storage.load();
    await tester.pumpAndSettle();

    await auth.signIn(
      email: DemoAuthRepository.demoGuestEmail,
      password: DemoAuthRepository.demoGuestPassword,
    );
    await tester.pumpAndSettle();
    first.read(favoritesProvider.notifier).state = {'garden'};
    first.read(recentHomestaysProvider.notifier).state = ['garden'];
    await storage.settled;

    await auth.signIn(
      email: DemoAuthRepository.demoHostEmail,
      password: DemoAuthRepository.demoHostPassword,
    );
    await tester.pumpAndSettle();
    expect(first.read(favoritesProvider), isEmpty);
    expect(first.read(recentHomestaysProvider), isEmpty);
    first.read(favoritesProvider.notifier).state = {'sea'};
    first.read(recentHomestaysProvider.notifier).state = ['sea'];
    await storage.settled;

    await auth.signIn(
      email: DemoAuthRepository.demoGuestEmail,
      password: DemoAuthRepository.demoGuestPassword,
    );
    await tester.pumpAndSettle();
    expect(first.read(favoritesProvider), {'garden'});
    expect(first.read(recentHomestaysProvider), ['garden']);
    await auth.signOut();
    await tester.pumpAndSettle();
    await storage.settled;
    first.dispose();

    final second = await storage.load();
    await tester.pumpAndSettle();
    await auth.signIn(
      email: DemoAuthRepository.demoGuestEmail,
      password: DemoAuthRepository.demoGuestPassword,
    );
    await tester.pump();
    expect(second.read(favoritesProvider), {'garden'});
    expect(second.read(recentHomestaysProvider), ['garden']);
    await auth.signOut();
    await tester.pump();
    await storage.settled;
    second.dispose();
    storage.dispose();
    auth.setPersistence(null);
    auth.restoreSnapshot(
      jsonEncode({'version': 1, 'currentUid': null, 'accounts': []}),
    );
  });

  test('Version 1 snapshot gains new destinations without losing edits', () {
    final old = DemoBookingRepository(seed: false, clock: () => today);
    old.saveRoom(room(), actorId: 'host-demo');
    final snapshot = old.toJson();
    snapshot['version'] = 1;
    snapshot['homestays'] = (snapshot['homestays'] as List)
        .where((h) => {'pine', 'sea', 'garden'}.contains(h['id']))
        .toList();
    snapshot['rooms'] = (snapshot['rooms'] as List)
        .where((r) => {'pine', 'sea', 'garden'}.contains(r['homestayId']))
        .toList();
    final restored = DemoBookingRepository.fromJson(
      snapshot,
      clock: () => today,
    );
    expect(restored.homestays.length, 14);
    expect(restored.homestays.map((h) => h.city).toSet().length, 14);
    expect(restored.rooms.first.name, 'Tên mới');
    expect(restored.rooms.any((r) => r.id == 'phuquoc-1'), isTrue);
    final current = restored.toJson();
    current['homestays'] = (current['homestays'] as List)
        .where((h) => h['id'] != 'phuquoc')
        .toList();
    current['rooms'] = (current['rooms'] as List)
        .where((r) => r['homestayId'] != 'phuquoc')
        .toList();
    final again = DemoBookingRepository.fromJson(current, clock: () => today);
    expect(again.homestays.any((h) => h.id == 'phuquoc'), isFalse);
  });
  test('Unreadable stored data is preserved and warning is visible', () async {
    var writes = 0;
    final storage = DemoStorage(
      read: () async => '{broken',
      write: (_) async {
        writes++;
      },
    );
    final container = await storage.load();
    container.read(favoritesProvider.notifier).state = {'pine'};
    await storage.settled;
    expect(writes, 0);
    expect(container.read(storageNoticeProvider), contains('Không đọc được'));
    container.dispose();
  });
  test(
    'Write failure is reported and subsequent changes retry saving',
    () async {
      var failing = true;
      final storage = DemoStorage(
        read: () async => null,
        write: (_) async {
          if (failing) throw StateError('full disk');
        },
      );
      final container = await storage.load();
      await storage.settled;
      expect(container.read(storageNoticeProvider), contains('Chưa lưu được'));
      failing = false;
      container.read(favoritesProvider.notifier).state = {'pine'};
      await storage.settled;
      expect(container.read(storageNoticeProvider), isNull);
      container.dispose();
    },
  );
}
