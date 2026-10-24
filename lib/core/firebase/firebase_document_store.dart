import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/booking/domain/booking.dart';
import '../../features/dashboard/domain/finance_entry.dart';
import '../../features/dashboard/domain/staff_member.dart';
import '../../features/dashboard/domain/staff_shift.dart';
import '../../features/homestay/domain/catalog.dart';
import '../../features/review/domain/review.dart';

/// Small document mapper for Firestore's collections used by HHL Stay.
/// Document IDs are stable domain IDs so an offline retry updates the same
/// record instead of creating a duplicate.
class FirebaseDocumentStore {
  FirebaseDocumentStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _homestays =>
      _firestore.collection('homestays');
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _finance =>
      _firestore.collection('financeEntries');
  CollectionReference<Map<String, dynamic>> get _staff =>
      _firestore.collection('staffMembers');
  CollectionReference<Map<String, dynamic>> get _shifts =>
      _firestore.collection('staffShifts');

  Future<void> saveBooking(Booking value) => _bookings
      // Include the guest UID to avoid collisions between per-device sequence
      // numbers such as HHL-0001.
      .doc('${value.guestId}_${value.id}')
      .set(value.toJson(), SetOptions(merge: true));

  Future<void> saveHomestay(Homestay value) =>
      _homestays.doc(value.id).set(value.toJson(), SetOptions(merge: true));

  Future<void> saveRoom(Room value) =>
      _rooms.doc(value.id).set(value.toJson(), SetOptions(merge: true));

  Future<void> saveReview(StayReview value) => _reviews
      .doc(value.bookingId)
      .set(value.toJson(), SetOptions(merge: true));

  Future<void> saveFinanceEntry(FinanceEntry value) =>
      _finance.doc(value.id).set(value.toJson(), SetOptions(merge: true));

  Future<void> saveStaffMember(StaffMember value) =>
      _staff.doc(value.id).set(value.toJson(), SetOptions(merge: true));

  Future<void> saveStaffShift(StaffShift value) =>
      _shifts.doc(value.id).set(value.toJson(), SetOptions(merge: true));

  Future<void> deleteHomestay(String id) => _homestays.doc(id).delete();
  Future<void> deleteRoom(String id) => _rooms.doc(id).delete();

  Future<List<Homestay>> publicHomestays() async =>
      _readList(_homestays, (map) => Homestay.fromJson(map));

  Future<List<Room>> publicRooms() async =>
      _readList(_rooms, (map) => Room.fromJson(map));

  Future<List<StayReview>> publicReviews() async =>
      _readList(_reviews, (map) => StayReview.fromJson(map));

  Future<List<FinanceEntry>> allFinanceEntries() async =>
      _readList(_finance, (map) => FinanceEntry.fromJson(map));

  Future<List<StaffMember>> allStaffMembers() async =>
      _readList(_staff, (map) => StaffMember.fromJson(map));

  Future<List<StaffShift>> allStaffShifts() async =>
      _readList(_shifts, (map) => StaffShift.fromJson(map));

  Future<List<Booking>> bookingsForGuest(String uid) async {
    final result = await _bookings.where('guestId', isEqualTo: uid).get();
    return result.docs.map((doc) => Booking.fromJson(doc.data())).toList();
  }

  Future<List<Booking>> bookingsForHost(String uid) async {
    final result = await _bookings.where('hostId', isEqualTo: uid).get();
    return result.docs.map((doc) => Booking.fromJson(doc.data())).toList();
  }

  /// Development-mode sync for the current small classroom dataset. The
  /// production version should query by tenant and paginate rather than fetch
  /// the entire collection.
  Future<List<Booking>> allBookingsForDemo() async {
    final result = await _bookings.get();
    return result.docs.map((doc) => Booking.fromJson(doc.data())).toList();
  }

  Future<List<T>> _readList<T>(
    CollectionReference<Map<String, dynamic>> collection,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data.putIfAbsent('id', () => doc.id);
      return decode(data);
    }).toList();
  }
}
