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
  // Keep the provider handles before the route can be removed. Signing out
  // changes router state and may dispose the Consumer that supplied `ref`
  // while this asynchronous operation is still unwinding.
  final auth = ref.read(authRepositoryProvider);
  final roleController = ref.read(roleProvider.notifier);
  final signOutProgress = ref.read(signOutInProgressProvider.notifier);
  final userCleared = Completer<void>();
  final userSubscription = ref.listenManual(currentUserProvider, (_, next) {
    if (next.valueOrNull == null && !userCleared.isCompleted) {
      userCleared.complete();
    }
  });
  if (ref.read(currentUserProvider).valueOrNull == null) {
    userCleared.complete();
  }
  signOutProgress.state = true;
  try {
    await auth.signOut();
    roleController.state = DemoRole.guest;
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
    signOutProgress.state = false;
  }
}
