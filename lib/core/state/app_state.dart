import 'dart:async';
import '../../features/homestay/domain/catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/booking/data/demo_booking_repository.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/booking/domain/booking_repository.dart';
import '../../features/review/domain/review.dart';

enum DemoRole { guest, host }

// The app is a management project; guest booking is an optional demo mode.
final roleProvider = StateProvider<DemoRole>((ref) => DemoRole.host);
final repositoryProvider = Provider<BookingRepository>(
  (ref) => DemoBookingRepository(),
);
final favoritesProvider = StateProvider<Set<String>>((ref) => {});
final changesProvider = StateNotifierProvider<BookingController, int>(
  (ref) => BookingController(ref.watch(repositoryProvider)),
);

class BookingController extends StateNotifier<int> {
  BookingController(this.repository) : super(0) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => state++);
  }
  final BookingRepository repository;
  late final Timer _timer;
  Booking book({
    required String roomId,
    required String name,
    required DateTime start,
    required DateTime end,
    required int guests,
    required String note,
  }) {
    final result = repository.create(
      roomId: roomId,
      guestId: 'guest-demo',
      guestName: name,
      checkIn: start,
      checkOut: end,
      guests: guests,
      note: note,
    );
    state++;
    return result;
  }

  void transition(String id, BookingStatus status, DemoRole role) {
    repository.transition(
      id,
      status,
      actorId: role == DemoRole.host ? 'host-demo' : 'guest-demo',
    );
    state++;
  }

  void verifyCheckIn(String id, String code) {
    final booking = repository.bookings.where((b) => b.id == id).firstOrNull;
    if (booking == null || booking.checkInCode != code.trim()) {
      throw const BookingException('Mã nhận phòng không khớp đơn này.');
    }
    repository.transition(id, BookingStatus.checkedIn, actorId: 'host-demo');
    state++;
  }

  void saveHomestay(Homestay home) {
    repository.saveHomestay(home, actorId: 'host-demo');
    state++;
  }

  void saveRoom(Room room) {
    repository.saveRoom(room, actorId: 'host-demo');
    state++;
  }

  void deleteRoom(String id) {
    repository.deleteRoom(id, actorId: 'host-demo');
    state++;
  }

  void deleteHomestay(String id) {
    repository.deleteHomestay(id, actorId: 'host-demo');
    state++;
  }

  StayReview addReview(String bookingId, int rating, String comment) {
    final review = repository.addReview(
      bookingId,
      actorId: 'guest-demo',
      rating: rating,
      comment: comment,
    );
    state++;
    return review;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
