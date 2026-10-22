enum ShiftStatus { scheduled, onDuty, completed }

extension ShiftStatusLabel on ShiftStatus {
  String get label => switch (this) {
    ShiftStatus.scheduled => 'Đã xếp ca',
    ShiftStatus.onDuty => 'Đang làm',
    ShiftStatus.completed => 'Đã hoàn tất',
  };
}

class StaffShift {
  const StaffShift({
    required this.id,
    this.staffId = '',
    required this.staffName,
    required this.role,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.hourlyRate,
    this.status = ShiftStatus.scheduled,
    this.note = '',
  });

  final String id;
  final String staffId;
  final String staffName;
  final String role;
  final DateTime date;
  final int startHour;
  final int endHour;
  final int hourlyRate;
  final ShiftStatus status;
  final String note;

  int get hours =>
      endHour > startHour ? endHour - startHour : 24 - startHour + endHour;
  int get estimatedPay => hours * hourlyRate;

  StaffShift withStaffId(String value) => StaffShift(
    id: id,
    staffId: value,
    staffName: staffName,
    role: role,
    date: date,
    startHour: startHour,
    endHour: endHour,
    hourlyRate: hourlyRate,
    status: status,
    note: note,
  );

  StaffShift withStatus(ShiftStatus value) => StaffShift(
    id: id,
    staffId: staffId,
    staffName: staffName,
    role: role,
    date: date,
    startHour: startHour,
    endHour: endHour,
    hourlyRate: hourlyRate,
    status: value,
    note: note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffId': staffId,
    'staffName': staffName,
    'role': role,
    'date': date.toIso8601String(),
    'startHour': startHour,
    'endHour': endHour,
    'hourlyRate': hourlyRate,
    'status': status.name,
    'note': note,
  };

  factory StaffShift.fromJson(Map<String, dynamic> json) => StaffShift(
    id: json['id'] as String,
    staffId: json['staffId'] as String? ?? '',
    staffName: json['staffName'] as String,
    role: json['role'] as String,
    date: DateTime.parse(json['date'] as String),
    startHour: json['startHour'] as int,
    endHour: json['endHour'] as int,
    hourlyRate: json['hourlyRate'] as int,
    status: ShiftStatus.values.byName(json['status'] as String),
    note: json['note'] as String? ?? '',
  );
}
