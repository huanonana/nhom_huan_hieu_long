import 'package:cloud_firestore/cloud_firestore.dart';

enum AppUserRole { guest, host }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final AppUserRole role;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory AppUser.fromFirestore(Map<String, dynamic> data, {String? id}) {
    final rawCreatedAt = data['createdAt'];
    final createdAt = switch (rawCreatedAt) {
      Timestamp value => value.toDate(),
      DateTime value => value,
      String value => DateTime.tryParse(value) ?? DateTime.now(),
      _ => DateTime.now(),
    };
    final roleName = data['role'] as String?;
    return AppUser(
      uid: data['uid'] as String? ?? id ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: AppUserRole.values.firstWhere(
        (role) => role.name == roleName,
        orElse: () => AppUserRole.guest,
      ),
      createdAt: createdAt,
    );
  }
}
