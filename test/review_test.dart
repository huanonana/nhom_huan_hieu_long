import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';

void main() {
  test('A confirmed booking needs its matching QR payload for check-in', () {
    final now = DateTime.utc(2026, 9, 28, 5);
    final repo = DemoBookingRepository(clock: () => now, seed: false);
    final start = vietnamToday(now);
    final booking = repo.create(
      roomId: 'sea-1',
      guestId: 'guest-demo',
      guestName: 'Minh',
      checkIn: start,
      checkOut: start.add(const Duration(days: 1)),
      guests: 2,
    );
    repo.transition(booking.id, BookingStatus.confirmed, actorId: 'host-demo');
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    final controller = container.read(changesProvider.notifier);
    expect(
      () => controller.verifyCheckIn(booking.id, 'HHL-STAY|wrong'),
      throwsA(isA<BookingException>()),
    );
    expect(repo.bookings.single.status, BookingStatus.confirmed);
    controller.verifyCheckIn(booking.id, booking.checkInCode);
    expect(repo.bookings.single.status, BookingStatus.checkedIn);
    container.dispose();
  });

  test('Only the guest may leave one review after checkout; it persists', () {
    var clock = DateTime.utc(2026, 9, 28, 5);
    final repo = DemoBookingRepository(clock: () => clock, seed: false);
    final start = vietnamToday(clock);
    final booking = repo.create(
      roomId: 'pine-1',
      guestId: 'guest-demo',
      guestName: 'Minh',
      checkIn: start,
      checkOut: start.add(const Duration(days: 1)),
      guests: 2,
    );
    expect(
      () => repo.addReview(
        booking.id,
        actorId: 'guest-demo',
        rating: 5,
        comment: 'Ấm áp',
      ),
      throwsA(isA<BookingException>()),
    );
    repo.transition(booking.id, BookingStatus.confirmed, actorId: 'host-demo');
    repo.transition(booking.id, BookingStatus.checkedIn, actorId: 'host-demo');
    repo.transition(booking.id, BookingStatus.checkedOut, actorId: 'host-demo');
    expect(
      () => repo.addReview(
        booking.id,
        actorId: 'other-guest',
        rating: 5,
        comment: 'Giả',
      ),
      throwsA(isA<BookingException>()),
    );
    expect(
      () => repo.addReview(
        booking.id,
        actorId: 'guest-demo',
        rating: 0,
        comment: 'Sai sao',
      ),
      throwsA(isA<BookingException>()),
    );
    expect(
      () => repo.addReview(
        booking.id,
        actorId: 'guest-demo',
        rating: 5,
        comment: '   ',
      ),
      throwsA(isA<BookingException>()),
    );
    final review = repo.addReview(
      booking.id,
      actorId: 'guest-demo',
      rating: 5,
      comment: '  Ấm áp và sạch sẽ  ',
    );
    expect(review.comment, 'Ấm áp và sạch sẽ');
    expect(
      () => repo.addReview(
        booking.id,
        actorId: 'guest-demo',
        rating: 4,
        comment: 'Lặp',
      ),
      throwsA(isA<BookingException>()),
    );
    final restored = DemoBookingRepository.fromJson(
      repo.toJson(),
      clock: () => clock,
    );
    expect(restored.reviews.single.bookingId, booking.id);
    expect(restored.reviews.single.rating, 5);
    clock = clock.add(const Duration(days: 2));
    expect(restored.reviews.single.comment, 'Ấm áp và sạch sẽ');
  });
}
