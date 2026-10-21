import 'app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get currentUser;

  Future<AppUser> signUp({
    required String email,
    required String password,
    required AppUserRole role,
    String? displayName,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> updateRole(String uid, AppUserRole role);
}
