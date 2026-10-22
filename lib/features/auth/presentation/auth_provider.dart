import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Authentication guards stay disabled in the offline demo build.
final authModeProvider = Provider<bool>((ref) => false);

/// Prevents the protected-route guard from interrupting the logout transition.
final signOutInProgressProvider = StateProvider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DemoAuthRepository.instance;
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});
