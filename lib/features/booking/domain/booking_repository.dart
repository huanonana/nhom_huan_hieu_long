import '../../homestay/domain/catalog.dart';
import 'booking.dart';
import '../../review/domain/review.dart';

abstract class BookingRepository {
  List<Homestay> get homestays;
  List<Room> get rooms;
  List<Booking> get bookings;
  List<StayReview> get reviews;
  DateTime get now;
  void saveHomestay(Homestay home, {required String actorId});
  void saveRoom(Room room, {required String actorId});
  void deleteRoom(String id, {required String actorId});
  void deleteHomestay(String id, {required String actorId});
  bool available(Room room, DateTime checkIn, DateTime checkOut);
  Booking create({
    required String roomId,
    required String guestId,
    required String guestName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    String note = '',
  });
  void transition(String id, BookingStatus target, {required String actorId});
  StayReview addReview(
    String bookingId, {
    required String actorId,
    required int rating,
    required String comment,
  });
}

/// Remote counterpart for Firestore's asynchronous API. The original
/// BookingRepository remains synchronous for the local demo implementation.
abstract interface class RemoteBookingRepository {
  Stream<List<Booking>> watchAll();
  Stream<List<Booking>> watchForGuest(String guestId);
  Stream<List<Booking>> watchForHost(String hostId);
  Future<bool> available(Room room, DateTime checkIn, DateTime checkOut);
  Future<Booking> create({
    required String roomId,
    required String guestId,
    required String guestName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    String note = '',
  });
  Future<void> transition(
    String id,
    BookingStatus target, {
    required String actorId,
  });
  Future<StayReview> addReview(
    String bookingId, {
    required String actorId,
    required int rating,
    required String comment,
  });
}
