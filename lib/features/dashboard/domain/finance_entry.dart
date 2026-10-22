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
    required this.bookingCount,
    required this.roomNights,
    required this.availableRoomNights,
  });

  final int revenue;
  final int expenses;
  final int bookingCount;
  final int roomNights;
  final int availableRoomNights;

  int get netRevenue => revenue - expenses;
  int get averageDailyRate => roomNights == 0 ? 0 : revenue ~/ roomNights;
  double get occupancy =>
      availableRoomNights == 0 ? 0 : roomNights / availableRoomNights;
  int get revPar =>
      availableRoomNights == 0 ? 0 : revenue ~/ availableRoomNights;
}
