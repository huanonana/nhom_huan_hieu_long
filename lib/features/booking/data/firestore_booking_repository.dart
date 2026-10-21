import 'package:cloud_firestore/cloud_firestore.dart';

import '../../review/domain/review.dart';
import '../../homestay/domain/catalog.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';

/// Async Firestore counterpart to the synchronous, local demo repository.
/// Firestore transactions require async reads, so this deliberately exposes
/// Future/Stream methods rather than pretending to implement the demo API.
class FirestoreBookingRepository implements RemoteBookingRepository {
  FirestoreBookingRepository(this._firestore, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _homes =>
      _firestore.collection('homestays');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _roomReservations =>
      _firestore.collection('room_reservations');

  @override
  Stream<List<Booking>> watchAll() => _bookings.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => Booking.fromFirestore(doc.data(), id: doc.id))
        .toList(growable: false),
  );

  @override
  Stream<List<Booking>> watchForGuest(String guestId) => _bookings
      .where('guestId', isEqualTo: guestId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc.data(), id: doc.id))
            .toList(growable: false),
      );

  @override
  Stream<List<Booking>> watchForHost(String hostId) => _bookings
      .where('hostId', isEqualTo: hostId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc.data(), id: doc.id))
            .toList(growable: false),
      );

  @override
  Future<bool> available(Room room, DateTime checkIn, DateTime checkOut) async {
    if (!room.active) return false;
    final start = stayDate(checkIn);
    final end = stayDate(checkOut);
    if (!start.isBefore(end)) return false;
    final now = _clock();
    final snapshot = await _bookings.where('roomId', isEqualTo: room.id).get();
    return !snapshot.docs.any((doc) {
      final booking = Booking.fromFirestore(doc.data(), id: doc.id);
      return booking.blocks(now) &&
          overlaps(start, end, booking.checkIn, booking.checkOut);
    });
  }

  @override
  Future<Booking> create({
    required String roomId,
    required String guestId,
    required String guestName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    String note = '',
  }) async {
    final start = stayDate(checkIn), end = stayDate(checkOut);
    final nights = end.difference(start).inDays;
    if (guestId.trim().isEmpty || guestName.trim().isEmpty) {
      throw const BookingException('Vui lòng nhập tên khách.');
    }
    if (guestName.trim().length > 100 || note.trim().length > 500) {
      throw const BookingException(
        'Tên tối đa 100 ký tự, ghi chú tối đa 500 ký tự.',
      );
    }
    final now = _clock();
    if (start.isBefore(vietnamToday(now))) {
      throw const BookingException('Không thể đặt ngày đã qua.');
    }
    if (nights < 1 || nights > 30) {
      throw const BookingException('Thời gian ở phải từ 1 đến 30 đêm.');
    }

    final roomRef = _rooms.doc(roomId);
    // Keep the public booking ID identical to the Firestore document ID so
    // later transitions and reviews address the same document.
    final bookingRef = _bookings.doc('HHL-${_bookings.doc().id}');
    // Existing demo/migrated bookings may not yet have per-night lock docs.
    // Check those first; new concurrent requests are serialized by lock docs
    // inside the transaction below.
    final existing = await _bookings.where('roomId', isEqualTo: roomId).get();
    final alreadyBooked = existing.docs.any((doc) {
      final booking = Booking.fromFirestore(doc.data(), id: doc.id);
      return booking.blocks(now) &&
          overlaps(start, end, booking.checkIn, booking.checkOut);
    });
    if (alreadyBooked) {
      throw const BookingException(
        'Phòng đang bảo trì hoặc đã có đơn trong thời gian này.',
      );
    }
    final reservationRefs = [
      for (
        var day = start;
        day.isBefore(end);
        day = day.add(const Duration(days: 1))
      )
        _roomReservations.doc(_reservationId(roomId, day)),
    ];
    return _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw const BookingException('Phòng không tồn tại.');
      }
      final room = Room.fromFirestore(roomSnapshot.data()!, id: roomId);
      if (guests < 1 || guests > room.capacity) {
        throw const BookingException(
          'Số khách vượt sức chứa hoặc không hợp lệ.',
        );
      }
      if (!room.active) {
        throw const BookingException('Phòng đang bảo trì.');
      }
      final homeSnapshot = await transaction.get(_homes.doc(room.homestayId));
      if (!homeSnapshot.exists) {
        throw const BookingException('Không tìm thấy homestay của phòng.');
      }
      final home = Homestay.fromFirestore(
        homeSnapshot.data()!,
        id: homeSnapshot.id,
      );
      final reservations =
          <
            (
              DocumentReference<Map<String, dynamic>>,
              DocumentSnapshot<Map<String, dynamic>>,
            )
          >[];
      for (final ref in reservationRefs) {
        reservations.add((ref, await transaction.get(ref)));
      }
      for (final reservation in reservations) {
        final lock = reservation.$2;
        final existingBookingId = lock.data()?['bookingId'] as String?;
        if (existingBookingId == null) continue;
        final oldBookingSnapshot = await transaction.get(
          _bookings.doc(existingBookingId),
        );
        if (!oldBookingSnapshot.exists) continue;
        final oldBooking = Booking.fromFirestore(
          oldBookingSnapshot.data()!,
          id: oldBookingSnapshot.id,
        );
        if (oldBooking.blocks(now)) {
          throw const BookingException(
            'Phòng đang bảo trì hoặc đã có đơn trong thời gian này.',
          );
        }
      }
      final booking = Booking(
        id: bookingRef.id,
        roomId: room.id,
        homestayId: home.id,
        hostId: home.hostId,
        guestId: guestId,
        guestName: guestName.trim(),
        roomName: room.name,
        checkIn: start,
        checkOut: end,
        guests: guests,
        pricePerNight: room.price,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        note: note.trim(),
      );
      transaction.set(bookingRef, booking.toFirestore());
      for (final reservation in reservations) {
        transaction.set(reservation.$1, {
          'roomId': room.id,
          'bookingId': bookingRef.id,
        });
      }
      return booking;
    });
  }

  String _reservationId(String roomId, DateTime day) =>
      '${roomId}_${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';

  @override
  Future<void> transition(
    String id,
    BookingStatus target, {
    required String actorId,
  }) => _firestore.runTransaction((transaction) async {
    final ref = _bookings.doc(id);
    final snapshot = await transaction.get(ref);
    if (!snapshot.exists) throw const BookingException('Không tìm thấy đơn.');
    final booking = Booking.fromFirestore(snapshot.data()!, id: snapshot.id);
    final status = booking.effectiveStatus(_clock());
    final isGuest = actorId == booking.guestId;
    final isHost = actorId == booking.hostId;
    final allowed =
        (isGuest &&
            status == BookingStatus.pending &&
            target == BookingStatus.cancelled) ||
        (isHost &&
            ((status == BookingStatus.pending &&
                    {
                      BookingStatus.confirmed,
                      BookingStatus.rejected,
                    }.contains(target)) ||
                (status == BookingStatus.confirmed &&
                    target == BookingStatus.checkedIn) ||
                (status == BookingStatus.checkedIn &&
                    target == BookingStatus.checkedOut)));
    if (!allowed) {
      throw const BookingException(
        'Không có quyền hoặc trạng thái đơn không cho phép thao tác này.',
      );
    }
    final today = vietnamToday(_clock());
    if (target == BookingStatus.confirmed &&
        !today.isBefore(booking.checkOut)) {
      throw const BookingException('Khoảng lưu trú đã kết thúc.');
    }
    if (target == BookingStatus.checkedIn &&
        (today.isBefore(booking.checkIn) ||
            !today.isBefore(booking.checkOut))) {
      throw const BookingException('Chỉ nhận phòng trong khoảng ngày lưu trú.');
    }
    transaction.update(ref, {'status': target.name});
  });

  @override
  Future<StayReview> addReview(
    String bookingId, {
    required String actorId,
    required int rating,
    required String comment,
  }) => _firestore.runTransaction((transaction) async {
    final bookingSnapshot = await transaction.get(_bookings.doc(bookingId));
    if (!bookingSnapshot.exists) {
      throw const BookingException('Không tìm thấy đơn.');
    }
    final booking = Booking.fromFirestore(
      bookingSnapshot.data()!,
      id: bookingSnapshot.id,
    );
    if (booking.guestId != actorId ||
        booking.effectiveStatus(_clock()) != BookingStatus.checkedOut) {
      throw const BookingException(
        'Chỉ khách đã trả phòng mới được đánh giá đơn này.',
      );
    }
    final reviewRef = _reviews.doc(bookingId);
    final previous = await transaction.get(reviewRef);
    if (previous.exists) {
      throw const BookingException('Đơn này đã được đánh giá.');
    }
    final cleanComment = comment.trim();
    if (rating < 1 ||
        rating > 5 ||
        cleanComment.isEmpty ||
        cleanComment.length > 500) {
      throw const BookingException(
        'Chọn 1–5 sao và viết nhận xét tối đa 500 ký tự.',
      );
    }
    final review = StayReview(
      bookingId: booking.id,
      homestayId: booking.homestayId,
      guestId: actorId,
      guestName: booking.guestName,
      rating: rating,
      comment: cleanComment,
      createdAt: _clock(),
    );
    transaction.set(reviewRef, review.toFirestore());
    return review;
  });
}
