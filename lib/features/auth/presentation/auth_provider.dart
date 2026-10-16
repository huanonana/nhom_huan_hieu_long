import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// False keeps the existing demo boot flow available until Firebase has been
/// configured. The app entry point enables this after Firebase.initializeApp.
final authModeProvider = Provider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    auth: firebase.FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});
