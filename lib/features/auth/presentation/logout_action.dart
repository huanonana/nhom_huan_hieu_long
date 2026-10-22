import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'auth_provider.dart';
import '../../../core/state/app_state.dart';

Future<bool> signOutAndReturnToPublicPage(
  BuildContext context,
  WidgetRef ref,
) async {
  final userCleared = Completer<void>();
  final userSubscription = ref.listenManual(currentUserProvider, (_, next) {
    if (next.valueOrNull == null && !userCleared.isCompleted) {
      userCleared.complete();
    }
  });
  if (ref.read(currentUserProvider).valueOrNull == null) {
    userCleared.complete();
  }
  ref.read(signOutInProgressProvider.notifier).state = true;
  try {
    final auth = ref.read(authRepositoryProvider);
    await auth.signOut();
    ref.read(roleProvider.notifier).state = DemoRole.guest;
    await userCleared.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
    if (context.mounted) context.go('/');
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Chưa thể đăng xuất. Vui lòng thử lại.'),
          ),
        );
    }
    return false;
  } finally {
    userSubscription.close();
    ref.read(signOutInProgressProvider.notifier).state = false;
  }
}
