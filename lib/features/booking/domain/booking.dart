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

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.note = '',
  });
  final String id;
  final int amount;
  final String method;
  final DateTime paidAt;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'method': method,
    'paidAt': paidAt.toIso8601String(),
    'note': note,
  };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    id: json['id'] as String,
    amount: json['amount'] as int,
    method: json['method'] as String,
    paidAt: DateTime.parse(json['paidAt'] as String),
    note: json['note'] as String? ?? '',
  );
}

class BookingException implements Exception {
  const BookingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Booking {
  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'homestayId': homestayId,
    'hostId': hostId,
    'guestId': guestId,
    'guestName': guestName,
    'guestPhone': guestPhone,
    'roomName': roomName,
    'checkIn': checkIn.toIso8601String(),
    'checkOut': checkOut.toIso8601String(),
    'guests': guests,
    'pricePerNight': pricePerNight,
    'memberDiscountPercent': memberDiscountPercent,
    'couponDiscountPercent': couponDiscountPercent,
    'couponCode': couponCode,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'status': status.name,
    'note': note,
    'payments': payments.map((payment) => payment.toJson()).toList(),
  };
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as String,
    roomId: j['roomId'] as String,
    homestayId: j['homestayId'] as String,
    hostId: j['hostId'] as String,
    guestId: j['guestId'] as String,
    guestName: j['guestName'] as String,
    guestPhone: j['guestPhone'] as String? ?? '',
    roomName: j['roomName'] as String,
    checkIn: DateTime.parse(j['checkIn'] as String),
    checkOut: DateTime.parse(j['checkOut'] as String),
    guests: j['guests'] as int,
    pricePerNight: j['pricePerNight'] as int,
    memberDiscountPercent: (j['memberDiscountPercent'] as int?) ?? 0,
    couponDiscountPercent: (j['couponDiscountPercent'] as int?) ?? 0,
    couponCode: j['couponCode'] as String? ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
    expiresAt: DateTime.parse(j['expiresAt'] as String),
    status: BookingStatus.values.byName(j['status'] as String),
    note: j['note'] as String,
    payments: (j['payments'] as List<dynamic>? ?? const [])
        .map(
          (payment) =>
              PaymentRecord.fromJson(Map<String, dynamic>.from(payment as Map)),
        )
        .toList(),
  );

  const Booking({
    required this.id,
    required this.roomId,
    required this.homestayId,
    required this.hostId,
    required this.guestId,
    required this.guestName,
    this.guestPhone = '',
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.pricePerNight,
    this.memberDiscountPercent = 0,
    this.couponDiscountPercent = 0,
    this.couponCode = '',
    required this.createdAt,
    required this.expiresAt,
    this.status = BookingStatus.pending,
    this.note = '',
    this.payments = const [],
  });
  final String id,
      roomId,
      homestayId,
      hostId,
      guestId,
      guestName,
      guestPhone,
      roomName,
      note;
  final DateTime checkIn, checkOut, createdAt, expiresAt;
  final int guests, pricePerNight;
  final int memberDiscountPercent;
  final int couponDiscountPercent;
  final String couponCode;
  int get discountPercent => memberDiscountPercent + couponDiscountPercent;
  final BookingStatus status;
  final List<PaymentRecord> payments;
  int get paidAmount =>
      payments.fold(0, (sum, payment) => sum + payment.amount);
  int get outstandingAmount {
    final remaining = total - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isPaid => outstandingAmount == 0;
  int get nights => checkOut.difference(checkIn).inDays;
  int get subtotal => pricePerNight * nights;
  int get discountAmount => subtotal * discountPercent ~/ 100;
  int get total => subtotal - discountAmount;
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
    guestPhone: guestPhone,
    roomName: roomName,
    checkIn: checkIn,
    checkOut: checkOut,
    guests: guests,
    pricePerNight: pricePerNight,
    memberDiscountPercent: memberDiscountPercent,
    couponDiscountPercent: couponDiscountPercent,
    couponCode: couponCode,
    createdAt: createdAt,
    expiresAt: expiresAt,
    status: value,
    note: note,
    payments: payments,
  );

  Booking withPayment(PaymentRecord payment) => Booking(
    id: id,
    roomId: roomId,
    homestayId: homestayId,
    hostId: hostId,
    guestId: guestId,
    guestName: guestName,
    guestPhone: guestPhone,
    roomName: roomName,
    checkIn: checkIn,
    checkOut: checkOut,
    guests: guests,
    pricePerNight: pricePerNight,
    memberDiscountPercent: memberDiscountPercent,
    couponDiscountPercent: couponDiscountPercent,
    couponCode: couponCode,
    createdAt: createdAt,
    expiresAt: expiresAt,
    status: status,
    note: note,
    payments: [...payments, payment],
  );
}
