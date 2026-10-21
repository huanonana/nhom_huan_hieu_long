import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Returns to the route underneath the current page, with a safe fallback for
/// deep links opened without any in-app navigation history.
void navigateBack(BuildContext context, {required String fallback}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
