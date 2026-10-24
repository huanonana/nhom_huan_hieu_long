import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';

void main() {
  test('member discount is applied to the saved booking total', () {
    final booking = Booking(
      id: 'HHL-discount-test',
      roomId: 'room-1',
      homestayId: 'home-1',
      hostId: 'host-1',
      guestId: 'guest-1',
      guestName: 'Khách thành viên',
      roomName: 'Phòng vườn',
      checkIn: DateTime.utc(2026, 10, 22),
      checkOut: DateTime.utc(2026, 10, 24),
      guests: 2,
      pricePerNight: 590000,
      memberDiscountPercent: 5,
      createdAt: DateTime.utc(2026, 10, 21),
      expiresAt: DateTime.utc(2026, 10, 22),
    );

    expect(booking.subtotal, 1180000);
    expect(booking.discountAmount, 59000);
    expect(booking.total, 1121000);
    expect(Booking.fromJson(booking.toJson()).total, 1121000);
  });

  test('member and coupon discounts persist on a new booking', () {
    final repo = DemoBookingRepository(
      clock: () => DateTime.utc(2026, 9, 25, 3),
      seed: false,
    );
    final booking = repo.create(
      roomId: 'pine-1',
      guestId: 'member-1',
      guestName: 'Khách thành viên',
      checkIn: DateTime.utc(2026, 9, 27),
      checkOut: DateTime.utc(2026, 9, 29),
      guests: 2,
      memberDiscountPercent: 5,
      couponDiscountPercent: 10,
      couponCode: 'hhl10',
    );

    expect(booking.subtotal, 1300000);
    expect(booking.discountPercent, 15);
    expect(booking.discountAmount, 195000);
    expect(booking.total, 1105000);
    expect(booking.couponCode, 'HHL10');
    final restored = Booking.fromJson(booking.toJson());
    expect(restored.total, 1105000);
    expect(restored.couponDiscountPercent, 10);
    expect(restored.couponCode, 'HHL10');
  });

  late DateTime clock;
  late DemoBookingRepository repo;
  setUp(() {
    clock = DateTime.utc(2026, 9, 25, 3);
    repo = DemoBookingRepository(clock: () => clock, seed: false);
  });
  Booking book({
    DateTime? start,
    DateTime? end,
    int guests = 2,
    String room = 'pine-1',
    String guest = 'guest-demo',
  }) => repo.create(
    roomId: room,
    guestId: guest,
    guestName: 'Khách thử',
    checkIn: start ?? DateTime.utc(2026, 9, 25),
    checkOut: end ?? DateTime.utc(2026, 9, 27),
    guests: guests,
  );
  test(
    'Calculates nights with normalized calendar dates and snapshots price',
    () {
      final b = book(
        start: DateTime(2026, 9, 25, 23),
        end: DateTime(2026, 9, 27, 1),
      );
      expect(b.nights, 2);
      expect(b.pricePerNight, 650000);
      expect(b.total, 1300000);
      expect(b.status, BookingStatus.pending);
      expect(b.expiresAt.difference(clock), const Duration(hours: 24));
    },
  );
  test(
    'Rejects zero/reversed/overlong stays, past dates and capacity violations',
    () {
      expect(
        () => book(end: DateTime.utc(2026, 9, 25)),
        throwsA(isA<BookingException>()),
      );
      expect(
        () => book(end: DateTime.utc(2026, 9, 24)),
        throwsA(isA<BookingException>()),
      );
      expect(
        () => book(start: DateTime.utc(2026, 9, 24)),
        throwsA(isA<BookingException>()),
      );
      expect(
        () => book(end: DateTime.utc(2026, 10, 26)),
        throwsA(isA<BookingException>()),
      );
      expect(() => book(guests: 0), throwsA(isA<BookingException>()));
      expect(() => book(guests: 3), throwsA(isA<BookingException>()));
      expect(() => book(room: 'garden-2'), throwsA(isA<BookingException>()));
      expect(() => book(room: 'missing'), throwsA(isA<BookingException>()));
      expect(repo.bookings, isEmpty);
    },
  );
  test('A room under maintenance cannot receive a new booking', () {
    final room = repo.rooms.singleWhere((item) => item.id == 'pine-1');
    repo.saveRoom(
      room.withHousekeeping(HousekeepingStatus.maintenance),
      actorId: 'host-demo',
    );

    expect(() => book(), throwsA(isA<BookingException>()));
    expect(repo.bookings, isEmpty);
  });
  test(
    'Pending blocks overlapping bookings, adjacent and other rooms are allowed',
    () {
      book();
      expect(() => book(), throwsA(isA<BookingException>()));
      expect(
        () => book(
          start: DateTime.utc(2026, 9, 26),
          end: DateTime.utc(2026, 9, 28),
        ),
        throwsA(isA<BookingException>()),
      );
      expect(
        book(
          start: DateTime.utc(2026, 9, 27),
          end: DateTime.utc(2026, 9, 28),
        ).nights,
        1,
      );
      expect(book(room: 'pine-2').roomId, 'pine-2');
    },
  );
  test(
    'Local requests issued together cannot create two overlapping bookings',
    () async {
      final results = await Future.wait(
        List.generate(
          2,
          (_) => Future(() {
            try {
              book();
              return true;
            } on BookingException {
              return false;
            }
          }),
        ),
      );
      expect(results.where((v) => v).length, 1);
      expect(repo.bookings.length, 1);
    },
  );
  test('Different registered guests receive distinct booking identifiers', () {
    Booking createFor(String uid) =>
        DemoBookingRepository(clock: () => clock, seed: false).create(
          roomId: 'pine-1',
          guestId: uid,
          guestName: 'Khách thử',
          checkIn: DateTime.utc(2026, 9, 27),
          checkOut: DateTime.utc(2026, 9, 29),
          guests: 2,
        );

    final first = createFor('firebase-guest-a');
    final second = createFor('firebase-guest-b');
    repo.mergeCloudBookings([first, second]);

    expect(first.id, isNot(second.id));
    expect(repo.bookings, hasLength(2));
  });
  test('Expiry frees dates and prevents approving the old request', () {
    final first = book(
      start: DateTime.utc(2026, 9, 27),
      end: DateTime.utc(2026, 9, 29),
    );
    clock = clock.add(const Duration(hours: 24));
    expect(first.effectiveStatus(clock), BookingStatus.expired);
    expect(
      () => repo.transition(
        first.id,
        BookingStatus.confirmed,
        actorId: 'host-demo',
      ),
      throwsA(isA<BookingException>()),
    );
    book(start: first.checkIn, end: first.checkOut);
    expect(repo.bookings.length, 2);
  });
  test('Only owner may cancel pending; cancellation releases availability', () {
    final b = book();
    expect(
      () => repo.transition(b.id, BookingStatus.cancelled, actorId: 'stranger'),
      throwsA(isA<BookingException>()),
    );
    repo.transition(b.id, BookingStatus.cancelled, actorId: 'guest-demo');
    expect(book().status, BookingStatus.pending);
  });
  test('Guest can cancel a confirmed stay until 24 hours before arrival', () {
    final b = book(
      start: DateTime.utc(2026, 9, 27),
      end: DateTime.utc(2026, 9, 29),
    );
    repo.transition(b.id, BookingStatus.confirmed, actorId: 'host-demo');
    repo.transition(b.id, BookingStatus.cancelled, actorId: 'guest-demo');
    expect(repo.bookings.single.status, BookingStatus.cancelled);
    expect(
      repo.available(
        repo.rooms.singleWhere((room) => room.id == b.roomId),
        b.checkIn,
        b.checkOut,
      ),
      isTrue,
    );
  });
  test('A registered guest can cancel their own booking by account id', () {
    final b = repo.create(
      roomId: 'pine-1',
      guestId: 'member-uid-42',
      guestName: 'Khách thành viên',
      checkIn: DateTime.utc(2026, 9, 27),
      checkOut: DateTime.utc(2026, 9, 29),
      guests: 2,
    );
    final controller = BookingController(repo);

    controller.transition(
      b.id,
      BookingStatus.cancelled,
      DemoRole.guest,
      actorId: 'member-uid-42',
    );

    expect(repo.bookings.single.status, BookingStatus.cancelled);
    controller.dispose();
  });
  test(
    'Confirmed stay cannot be cancelled inside the final 24-hour window',
    () {
      final b = book(
        start: DateTime.utc(2026, 9, 27),
        end: DateTime.utc(2026, 9, 29),
      );
      repo.transition(b.id, BookingStatus.confirmed, actorId: 'host-demo');
      clock = DateTime.utc(2026, 9, 26);
      expect(
        () => repo.transition(
          b.id,
          BookingStatus.cancelled,
          actorId: 'guest-demo',
        ),
        throwsA(isA<BookingException>()),
      );
    },
  );
  test('Host approval, check-in and checkout obey ownership and lifecycle', () {
    final b = book();
    expect(
      () =>
          repo.transition(b.id, BookingStatus.confirmed, actorId: 'guest-demo'),
      throwsA(isA<BookingException>()),
    );
    expect(
      () =>
          repo.transition(b.id, BookingStatus.checkedOut, actorId: 'host-demo'),
      throwsA(isA<BookingException>()),
    );
    repo.transition(b.id, BookingStatus.confirmed, actorId: 'host-demo');
    expect(() => book(), throwsA(isA<BookingException>()));
    expect(
      () =>
          repo.transition(b.id, BookingStatus.cancelled, actorId: 'guest-demo'),
      throwsA(isA<BookingException>()),
    );
    repo.transition(b.id, BookingStatus.checkedIn, actorId: 'host-demo');
    expect(
      () =>
          repo.transition(b.id, BookingStatus.checkedIn, actorId: 'host-demo'),
      throwsA(isA<BookingException>()),
    );
    repo.transition(b.id, BookingStatus.checkedOut, actorId: 'host-demo');
    expect(repo.bookings.single.status, BookingStatus.checkedOut);
  });
  test('Cannot check in before arrival or on the checkout day', () {
    final b = book(
      start: DateTime.utc(2026, 9, 27),
      end: DateTime.utc(2026, 9, 29),
    );
    repo.transition(b.id, BookingStatus.confirmed, actorId: 'host-demo');
    expect(
      () =>
          repo.transition(b.id, BookingStatus.checkedIn, actorId: 'host-demo'),
      throwsA(isA<BookingException>()),
    );
    clock = DateTime.utc(2026, 9, 29, 3);
    expect(
      () =>
          repo.transition(b.id, BookingStatus.checkedIn, actorId: 'host-demo'),
      throwsA(isA<BookingException>()),
    );
  });
  test('Vietnam calendar switches date at 17:00 UTC', () {
    expect(
      vietnamToday(DateTime.utc(2026, 9, 24, 16, 59)),
      DateTime.utc(2026, 9, 24),
    );
    expect(
      vietnamToday(DateTime.utc(2026, 9, 24, 17)),
      DateTime.utc(2026, 9, 25),
    );
  });
}
