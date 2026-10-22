class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.hourlyRate,
    this.email = '',
    this.active = true,
  });

  final String id;
  final String name;
  final String role;
  final String phone;
  final String email;
  final int hourlyRate;
  final bool active;

  StaffMember copyWith({
    String? name,
    String? role,
    String? phone,
    String? email,
    int? hourlyRate,
    bool? active,
  }) => StaffMember(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'phone': phone,
    'email': email,
    'hourlyRate': hourlyRate,
    'active': active,
  };

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    hourlyRate: json['hourlyRate'] as int? ?? 0,
    active: json['active'] as bool? ?? true,
  );
}
