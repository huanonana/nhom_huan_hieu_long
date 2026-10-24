import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Firebase Authentication backed accounts with a Firestore profile document.
/// Passwords are handled only by Firebase Authentication and are never stored
/// in Firestore or the app's local demo snapshot.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<AppUser?> currentProfile() async {
    final user = _auth.currentUser;
    return user == null ? null : _loadProfile(user);
  }

  @override
  Stream<AppUser?> get currentUser => _auth.authStateChanges().asyncMap(
    (user) async => user == null ? null : _loadProfile(user),
  );

  Future<AppUser> _loadProfile(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      final profile = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        role: AppUserRole.guest,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
      await ref.set(profile.toJson());
      return profile;
    }
    return AppUser.fromJson(snapshot.data()!, id: user.uid);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required AppUserRole role,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Firebase không trả về tài khoản mới.');
    final profile = AppUser(
      uid: user.uid,
      email: user.email ?? email.trim(),
      displayName: displayName?.trim() ?? '',
      role: role,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(profile.toJson());
    return profile;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Không nhận được phiên đăng nhập.');
    return _loadProfile(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateRole(String uid, AppUserRole role) async {
    await _firestore.collection('users').doc(uid).update({'role': role.name});
  }
}
