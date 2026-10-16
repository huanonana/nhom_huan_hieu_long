import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required firebase.FirebaseAuth auth,
    required FirebaseFirestore firestore,
    DateTime Function()? clock,
  }) : _auth = auth,
       _firestore = firestore,
       _clock = clock ?? DateTime.now;

  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> get currentUser =>
      _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(null);
        return _users.doc(user.uid).snapshots().map((snapshot) {
          if (snapshot.exists) {
            return AppUser.fromFirestore(snapshot.data()!, id: user.uid);
          }
          return AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            role: AppUserRole.guest,
            createdAt: user.metadata.creationTime ?? _clock(),
          );
        });
      });

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
    if (user == null) throw StateError('Firebase did not return a user.');
    final profile = AppUser(
      uid: user.uid,
      email: user.email ?? email.trim(),
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (user.email?.split('@').first ?? ''),
      role: role,
      createdAt: user.metadata.creationTime ?? _clock(),
    );
    await _users.doc(user.uid).set(profile.toFirestore());
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
    if (user == null) throw StateError('Firebase did not return a user.');
    final snapshot = await _users.doc(user.uid).get();
    if (snapshot.exists)
      return AppUser.fromFirestore(snapshot.data()!, id: user.uid);
    final profile = AppUser(
      uid: user.uid,
      email: user.email ?? email.trim(),
      displayName: user.displayName ?? '',
      role: AppUserRole.guest,
      createdAt: user.metadata.creationTime ?? _clock(),
    );
    await _users.doc(user.uid).set(profile.toFirestore());
    return profile;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateRole(String uid, AppUserRole role) =>
      _users.doc(uid).update({'role': role.name});
}
