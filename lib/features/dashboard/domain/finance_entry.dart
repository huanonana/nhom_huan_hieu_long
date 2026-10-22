import '../../booking/domain/booking.dart';

enum FinanceEntryStatus { paid, pending }

extension FinanceEntryStatusLabel on FinanceEntryStatus {
  String get label => switch (this) {
    FinanceEntryStatus.paid => 'Đã thanh toán',
    FinanceEntryStatus.pending => 'Chưa thanh toán',
  };
}

class FinanceEntry {
  const FinanceEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.status = FinanceEntryStatus.paid,
  });

  final String id;
  final String title;
  final String category;
  final int amount;
  final DateTime date;
  final String note;
  final FinanceEntryStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'status': status.name,
  };

  factory FinanceEntry.fromJson(Map<String, dynamic> json) => FinanceEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    amount: json['amount'] as int,
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String? ?? '',
    status: FinanceEntryStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => FinanceEntryStatus.paid,
    ),
  );

  FinanceEntry withStatus(FinanceEntryStatus value) => FinanceEntry(
    id: id,
    title: title,
    category: category,
    amount: amount,
    date: date,
    note: note,
    status: value,
  );
}

class FinanceSummary {
  const FinanceSummary({
    required this.revenue,
    required this.expenses,
    required this.stayRevenue,
    required this.bookingCount,
    required this.roomNights,
    required this.availableRoomNights,
  });

  final int revenue;
  final int expenses;

  /// Room revenue earned from nights already stayed, independent of payment date.
  final int stayRevenue;
  final int bookingCount;
  final int roomNights;
  final int availableRoomNights;

  int get netRevenue => revenue - expenses;
  int get averageDailyRate => roomNights == 0 ? 0 : stayRevenue ~/ roomNights;
  double get occupancy =>
      availableRoomNights == 0 ? 0 : roomNights / availableRoomNights;
  int get revPar =>
      availableRoomNights == 0 ? 0 : stayRevenue ~/ availableRoomNights;
}

class RoomPerformance {
  const RoomPerformance({required this.revenue, required this.roomNights});

  final int revenue;
  final int roomNights;
}

/// Calculates earned room revenue by the nights actually stayed in [month].
/// Deposits for future stays affect cash flow, but do not affect ADR or RevPAR.
RoomPerformance calculateRoomPerformance({
  required DateTime month,
  required DateTime asOf,
  required Iterable<Booking> bookings,
}) {
  final monthStart = DateTime.utc(month.year, month.month);
  final monthEnd = DateTime.utc(month.year, month.month + 1);
  final today = vietnamToday(asOf);
  var revenue = 0;
  var roomNights = 0;

  for (final booking in bookings) {
    if (booking.status != BookingStatus.checkedOut &&
        booking.status != BookingStatus.checkedIn) {
      continue;
    }
    final checkIn = stayDate(booking.checkIn);
    final checkOut = stayDate(booking.checkOut);
    var start = checkIn.isAfter(monthStart) ? checkIn : monthStart;
    var end = checkOut.isBefore(monthEnd) ? checkOut : monthEnd;
    if (booking.status == BookingStatus.checkedIn && end.isAfter(today)) {
      end = today;
    }
    if (!end.isAfter(start) || booking.nights <= 0) continue;

    final nights = end.difference(start).inDays;
    roomNights += nights;
    revenue += booking.total * nights ~/ booking.nights;
  }

  return RoomPerformance(revenue: revenue, roomNights: roomNights);
}
