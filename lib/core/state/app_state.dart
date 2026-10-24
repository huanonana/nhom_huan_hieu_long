import 'dart:async';
import '../../features/homestay/domain/catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/booking/data/demo_booking_repository.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/booking/domain/booking_repository.dart';
import '../../features/review/domain/review.dart';
import '../../features/dashboard/domain/finance_entry.dart';
import '../../features/dashboard/domain/staff_shift.dart';
import '../../features/dashboard/domain/staff_member.dart';
import '../firebase/firebase_document_store.dart';
import '../firebase/firebase_providers.dart';

enum DemoRole { guest, host }

// The app is a management project; guest booking is an optional demo mode.
final roleProvider = StateProvider<DemoRole>((ref) => DemoRole.host);
final repositoryProvider = Provider<BookingRepository>(
  (ref) => DemoBookingRepository(),
);
final favoritesProvider = StateProvider<Set<String>>((ref) => {});

/// Recently viewed homestay IDs, newest first. Kept on this device in demo mode.
final recentHomestaysProvider = StateProvider<List<String>>((ref) => const []);
final financeEntriesProvider = StateProvider<List<FinanceEntry>>(
  (ref) => const [],
);
final staffShiftsProvider = StateProvider<List<StaffShift>>((ref) => const []);
final staffMembersProvider = StateProvider<List<StaffMember>>(
  (ref) => const [],
);
final changesProvider = StateNotifierProvider<BookingController, int>(
  (ref) => BookingController(
    ref.watch(repositoryProvider),
    documentStore: ref.watch(firebaseDocumentStoreProvider),
    onSyncError: () => ref.read(firebaseSyncNoticeProvider.notifier).state =
        'Dữ liệu đã đổi trên máy nhưng chưa đồng bộ Firebase. Kiểm tra Rules/kết nối.',
  ),
);

class BookingController extends StateNotifier<int> {
  BookingController(this.repository, {this.documentStore, this.onSyncError})
    : super(0) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => state++);
  }
  final BookingRepository repository;
  final FirebaseDocumentStore? documentStore;
  final void Function()? onSyncError;
  late final Timer _timer;
  void refreshFromStorage() => state++;
  Booking book({
    required String roomId,
    required String name,
    String guestId = 'guest-demo',
    required DateTime start,
    required DateTime end,
    required int guests,
    int memberDiscountPercent = 0,
    int couponDiscountPercent = 0,
    String couponCode = '',
    required String note,
  }) {
    final result = repository.create(
      roomId: roomId,
      guestId: guestId,
      guestName: name,
      checkIn: start,
      checkOut: end,
      guests: guests,
      memberDiscountPercent: memberDiscountPercent,
      couponDiscountPercent: couponDiscountPercent,
      couponCode: couponCode,
      note: note,
    );
    state++;
    return result;
  }

  void transition(
    String id,
    BookingStatus status,
    DemoRole role, {
    String? actorId,
  }) {
    final booking = _booking(id);
    repository.transition(
      id,
      status,
      actorId:
          actorId ?? (role == DemoRole.host ? booking.hostId : booking.guestId),
    );
    _syncBooking(id);
    state++;
  }

  void recordPayment(
    String bookingId, {
    required int amount,
    required String method,
    String note = '',
  }) {
    repository.recordPayment(
      bookingId,
      actorId: _booking(bookingId).hostId,
      amount: amount,
      method: method,
      note: note,
    );
    _syncBooking(bookingId);
    state++;
  }

  void verifyCheckIn(String id, String code) {
    final booking = repository.bookings.where((b) => b.id == id).firstOrNull;
    if (booking == null || booking.checkInCode != code.trim()) {
      throw const BookingException('Mã nhận phòng không khớp đơn này.');
    }
    repository.transition(id, BookingStatus.checkedIn, actorId: booking.hostId);
    _syncBooking(id);
    state++;
  }

  void saveHomestay(Homestay home) {
    final existing = repository.homestays
        .where((item) => item.id == home.id)
        .firstOrNull;
    repository.saveHomestay(home, actorId: existing?.hostId ?? home.hostId);
    _sync(() => documentStore?.saveHomestay(home));
    state++;
  }

  void saveRoom(Room room) {
    repository.saveRoom(room, actorId: _homestay(room.homestayId).hostId);
    _sync(() => documentStore?.saveRoom(room));
    state++;
  }

  void setHousekeeping(String roomId, HousekeepingStatus status) {
    final room = repository.rooms
        .where((item) => item.id == roomId)
        .firstOrNull;
    if (room == null) throw const BookingException('Không tìm thấy phòng.');
    repository.saveRoom(
      room.withHousekeeping(status),
      actorId: _homestay(room.homestayId).hostId,
    );
    _sync(() => documentStore?.saveRoom(room.withHousekeeping(status)));
    state++;
  }

  void deleteRoom(String id) {
    final room = repository.rooms.where((item) => item.id == id).firstOrNull;
    if (room == null) throw const BookingException('Không tìm thấy phòng.');
    repository.deleteRoom(id, actorId: _homestay(room.homestayId).hostId);
    _sync(() => documentStore?.deleteRoom(id));
    state++;
  }

  void deleteHomestay(String id) {
    repository.deleteHomestay(id, actorId: _homestay(id).hostId);
    _sync(() => documentStore?.deleteHomestay(id));
    state++;
  }

  StayReview addReview(
    String bookingId,
    int rating,
    String comment, {
    String actorId = 'guest-demo',
  }) {
    final review = repository.addReview(
      bookingId,
      actorId: actorId,
      rating: rating,
      comment: comment,
    );
    _sync(() => documentStore?.saveReview(review));
    state++;
    return review;
  }

  Booking _booking(String id) =>
      repository.bookings.where((item) => item.id == id).firstOrNull ??
      (throw const BookingException('Không tìm thấy đơn.'));

  Homestay _homestay(String id) =>
      repository.homestays.where((item) => item.id == id).firstOrNull ??
      (throw const BookingException('Không tìm thấy homestay.'));

  void _syncBooking(String id) {
    final booking = repository.bookings
        .where((item) => item.id == id)
        .firstOrNull;
    if (booking != null) _sync(() => documentStore?.saveBooking(booking));
  }

  void _sync(Future<void>? Function() operation) {
    if (documentStore == null) return;
    unawaited(
      Future<void>(() async {
        try {
          await operation();
        } catch (_) {
          onSyncError?.call();
        }
      }),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
