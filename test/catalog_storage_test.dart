import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/core/state/demo_storage.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';

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
    first.read(changesProvider.notifier).saveRoom(room());
    await storage.settled;
    first.dispose();
    final second = await storage.load();
    expect(second.read(favoritesProvider), {'pine'});
    expect(second.read(repositoryProvider).rooms.first.name, 'Tên mới');
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
    expect(demoBookings, hasLength(6));
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
    first.dispose();

    final second = await storage.load();
    await storage.settled;
    expect(
      second
          .read(repositoryProvider)
          .bookings
          .where((booking) => booking.id.startsWith('HHL-DEMO-')),
      hasLength(6),
    );
    second.dispose();
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
