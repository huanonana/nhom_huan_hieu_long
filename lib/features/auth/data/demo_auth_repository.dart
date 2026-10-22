import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Device-local authentication for the offline classroom demo.
///
/// This is not production authentication: accounts live in browser/device
/// storage and cannot be shared across devices. Passwords are never persisted
/// in plaintext; the local snapshot stores salted SHA-256 verifiers.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository._();

  static final DemoAuthRepository instance = DemoAuthRepository._();

  final Map<String, ({String salt, String passwordHash, AppUser user})>
  _accounts = {};
  final StreamController<AppUser?> _changes =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;
  Future<void> Function(String snapshot)? _persistSnapshot;

  AppUser? get signedInUser => _user;

  void setPersistence(Future<void> Function(String snapshot)? callback) {
    _persistSnapshot = callback;
  }

  /// Restores a previously saved local demo session before providers start.
  void restoreSnapshot(String? snapshot) {
    if (snapshot == null || snapshot.isEmpty) return;
    final data = jsonDecode(snapshot) as Map<String, dynamic>;
    final restored =
        <String, ({String salt, String passwordHash, AppUser user})>{};
    for (final item in data['accounts'] as List? ?? const []) {
      final account = Map<String, dynamic>.from(item as Map);
      final user = AppUser.fromJson(
        Map<String, dynamic>.from(account['user'] as Map),
      );
      final email = user.email.trim().toLowerCase();
      final salt = account['salt'] as String?;
      final hash = account['passwordHash'] as String?;
      if (email.isEmpty || salt == null || hash == null) continue;
      restored[email] = (salt: salt, passwordHash: hash, user: user);
    }
    _accounts
      ..clear()
      ..addAll(restored);
    final uid = data['currentUid'] as String?;
    _user = _accounts.values
        .map((account) => account.user)
        .where((user) => user.uid == uid)
        .firstOrNull;
  }

  String exportSnapshot() => jsonEncode({
    'version': 1,
    'currentUid': _user?.uid,
    'accounts': _accounts.values
        .map(
          (account) => {
            'salt': account.salt,
            'passwordHash': account.passwordHash,
            'user': account.user.toJson(),
          },
        )
        .toList(),
  });

  @override
  Stream<AppUser?> get currentUser async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required AppUserRole role,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      throw const DemoAuthException('Email này đã được đăng ký trên thiết bị.');
    }
    final salt = _newSalt();
    final user = AppUser(
      uid: 'local-${DateTime.now().microsecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName?.trim() ?? '',
      role: role,
      createdAt: DateTime.now(),
    );
    _accounts[normalizedEmail] = (
      salt: salt,
      passwordHash: _hash(password, salt),
      user: user,
    );
    _setUser(user);
    await _persist();
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null ||
        account.passwordHash != _hash(password, account.salt)) {
      throw const DemoAuthException('Email hoặc mật khẩu không đúng.');
    }
    _setUser(account.user);
    await _persist();
    return account.user;
  }

  @override
  Future<void> signOut() async {
    _setUser(null);
    await _persist();
  }

  @override
  Future<void> updateRole(String uid, AppUserRole role) async {
    final entry = _accounts.entries.where(
      (entry) => entry.value.user.uid == uid,
    );
    if (entry.isEmpty) return;
    final found = entry.first;
    final updated = AppUser(
      uid: found.value.user.uid,
      email: found.value.user.email,
      displayName: found.value.user.displayName,
      role: role,
      createdAt: found.value.user.createdAt,
    );
    _accounts[found.key] = (
      salt: found.value.salt,
      passwordHash: found.value.passwordHash,
      user: updated,
    );
    if (_user?.uid == uid) _setUser(updated);
    await _persist();
  }

  Future<void> _persist() async {
    await _persistSnapshot?.call(exportSnapshot());
  }

  String _newSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(24, (_) => random.nextInt(256)));
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  void _setUser(AppUser? user) {
    _user = user;
    _changes.add(user);
  }
}

class DemoAuthException implements Exception {
  const DemoAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
