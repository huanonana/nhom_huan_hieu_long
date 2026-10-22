enum AppUserRole { guest, host }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.isAnonymous = false,
  });

  final String uid;
  final String email;
  final String displayName;
  final AppUserRole role;
  final DateTime createdAt;
  final bool isAnonymous;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(
    Map<String, dynamic> data, {
    String? id,
    bool isAnonymous = false,
  }) {
    final createdAt =
        DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now();
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
      isAnonymous: isAnonymous,
    );
  }
}
