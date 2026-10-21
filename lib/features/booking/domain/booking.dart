import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  checkedOut,
  rejected,
  cancelled,
  expired,
}

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
    BookingStatus.pending => 'Chờ duyệt',
    BookingStatus.confirmed => 'Đã xác nhận',
    BookingStatus.checkedIn => 'Đang lưu trú',
    BookingStatus.checkedOut => 'Đã trả phòng',
    BookingStatus.rejected => 'Từ chối',
    BookingStatus.cancelled => 'Đã hủy',
    BookingStatus.expired => 'Hết hạn',
  };
}

// Date-only values: UTC components represent a calendar date, not an instant.
DateTime stayDate(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);
DateTime vietnamToday(DateTime now) =>
    stayDate(now.toUtc().add(const Duration(hours: 7)));
bool overlaps(DateTime aIn, DateTime aOut, DateTime bIn, DateTime bOut) =>
    aIn.isBefore(bOut) && aOut.isAfter(bIn);

class BookingException implements Exception {
  const BookingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Booking {
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'roomId': roomId,
    'homestayId': homestayId,
    'hostId': hostId,
    'guestId': guestId,
    'guestName': guestName,
    'roomName': roomName,
    'checkIn': Timestamp.fromDate(checkIn),
    'checkOut': Timestamp.fromDate(checkOut),
    'guests': guests,
    'pricePerNight': pricePerNight,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'status': status.name,
    'note': note,
  };

  factory Booking.fromFirestore(Map<String, dynamic> data, {String? id}) =>
      Booking(
        id: data['id'] as String? ?? id ?? '',
        roomId: data['roomId'] as String? ?? '',
        homestayId: data['homestayId'] as String? ?? '',
        hostId: data['hostId'] as String? ?? '',
        guestId: data['guestId'] as String? ?? '',
        guestName: data['guestName'] as String? ?? '',
        roomName: data['roomName'] as String? ?? '',
        checkIn: _readFirestoreDate(data['checkIn']),
        checkOut: _readFirestoreDate(data['checkOut']),
        guests: (data['guests'] as num?)?.toInt() ?? 1,
        pricePerNight: (data['pricePerNight'] as num?)?.toInt() ?? 0,
        createdAt: _readFirestoreDate(data['createdAt']),
        expiresAt: _readFirestoreDate(data['expiresAt']),
        status: BookingStatus.values.firstWhere(
          (status) => status.name == data['status'],
          orElse: () => BookingStatus.pending,
        ),
        note: data['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'homestayId': homestayId,
    'hostId': hostId,
    'guestId': guestId,
    'guestName': guestName,
    'roomName': roomName,
    'checkIn': checkIn.toIso8601String(),
    'checkOut': checkOut.toIso8601String(),
    'guests': guests,
    'pricePerNight': pricePerNight,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'status': status.name,
    'note': note,
  };
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as String,
    roomId: j['roomId'] as String,
    homestayId: j['homestayId'] as String,
    hostId: j['hostId'] as String,
    guestId: j['guestId'] as String,
    guestName: j['guestName'] as String,
    roomName: j['roomName'] as String,
    checkIn: DateTime.parse(j['checkIn'] as String),
    checkOut: DateTime.parse(j['checkOut'] as String),
    guests: j['guests'] as int,
    pricePerNight: j['pricePerNight'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
    expiresAt: DateTime.parse(j['expiresAt'] as String),
    status: BookingStatus.values.byName(j['status'] as String),
    note: j['note'] as String,
  );

  const Booking({
    required this.id,
    required this.roomId,
    required this.homestayId,
    required this.hostId,
    required this.guestId,
    required this.guestName,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.pricePerNight,
    required this.createdAt,
    required this.expiresAt,
    this.status = BookingStatus.pending,
    this.note = '',
  });
  final String id,
      roomId,
      homestayId,
      hostId,
      guestId,
      guestName,
      roomName,
      note;
  final DateTime checkIn, checkOut, createdAt, expiresAt;
  final int guests, pricePerNight;
  final BookingStatus status;
  int get nights => checkOut.difference(checkIn).inDays;
  int get total => pricePerNight * nights;
  String get checkInCode => 'HHL-STAY|$id|$roomId|${checkIn.toIso8601String()}';
  BookingStatus effectiveStatus(DateTime now) =>
      status == BookingStatus.pending && !now.isBefore(expiresAt)
      ? BookingStatus.expired
      : status;
  bool blocks(DateTime now) => {
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.checkedIn,
  }.contains(effectiveStatus(now));
  Booking withStatus(BookingStatus value) => Booking(
    id: id,
    roomId: roomId,
    homestayId: homestayId,
    hostId: hostId,
    guestId: guestId,
    guestName: guestName,
    roomName: roomName,
    checkIn: checkIn,
    checkOut: checkOut,
    guests: guests,
    pricePerNight: pricePerNight,
    createdAt: createdAt,
    expiresAt: expiresAt,
    status: value,
    note: note,
  );
}

DateTime _readFirestoreDate(Object? value) => switch (value) {
  Timestamp timestamp => timestamp.toDate(),
  DateTime date => date,
  String date =>
    DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0),
  _ => DateTime.fromMillisecondsSinceEpoch(0),
};
