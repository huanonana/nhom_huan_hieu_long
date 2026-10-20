import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../state/demo_storage.dart';
import '../theme/app_theme.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/dashboard/presentation/calendar_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/booking/presentation/booking_form_page.dart';
import '../../features/booking/presentation/bookings_page.dart';
import '../../features/booking/presentation/firebase_pages.dart';
import '../../features/booking/presentation/firestore_repository_provider.dart';
import '../../features/dashboard/presentation/host_page.dart';
import '../../features/ai/presentation/ai_chat_page.dart';
import '../../features/homestay/presentation/detail_page.dart';
import '../../features/homestay/presentation/explore_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (ref.read(authModeProvider)) {
        final path = state.uri.path;
        final onAuthPage = path == '/login' || path == '/register';
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user == null) {
          if (onAuthPage) return null;
          final requiresAccount =
              path.startsWith('/book/') ||
              path.startsWith('/host') ||
              path == '/bookings' ||
              path == '/profile';
          if (!requiresAccount) return null;
          return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
        }
        if (onAuthPage) {
          final requested = state.uri.queryParameters['from'];
          if (requested != null &&
              requested.startsWith('/') &&
              (user.role == AppUserRole.host ||
                  !requested.startsWith('/host'))) {
            return requested;
          }
          return user.role == AppUserRole.host ? '/host' : '/';
        }
        if (user.role != AppUserRole.host && path.startsWith('/host')) {
          return '/';
        }
        return null;
      }
      final host = ref.read(roleProvider) == DemoRole.host;
      final path = state.uri.path;
      if (!host && path.startsWith('/host')) return '/profile';
      if (host &&
          (path.startsWith('/book/') || path == '/' || path == '/favorites'))
        return '/host';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Trang không tồn tại — Về trang đầu'),
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => ref.read(useFirebaseBackendProvider)
                ? const FirebaseExplorePage()
                : const ExplorePage(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (_, _) => ref.read(useFirebaseBackendProvider)
                ? const FirebaseExplorePage(favoritesOnly: true)
                : const ExplorePage(favoritesOnly: true),
          ),
          GoRoute(
            path: '/homestays/:id',
            builder: (_, state) => ref.read(useFirebaseBackendProvider)
                ? FirebaseDetailPage(id: state.pathParameters['id']!)
                : DetailPage(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/book/:roomId',
            builder: (_, state) => ref.read(useFirebaseBackendProvider)
                ? FirebaseBookingFormPage(
                    roomId: state.pathParameters['roomId']!,
                  )
                : BookingFormPage(roomId: state.pathParameters['roomId']!),
          ),
          GoRoute(
            path: '/bookings',
            builder: (_, _) => ref.read(useFirebaseBackendProvider)
                ? const FirebaseBookingsPage()
                : const BookingsPage(),
          ),
          GoRoute(
            path: '/host',
            builder: (_, _) => ref.read(useFirebaseBackendProvider)
                ? const FirebaseHostPage()
                : const HostPage(),
          ),
          GoRoute(path: '/ai-chat', builder: (_, _) => const AiChatPage()),
          GoRoute(
            path: '/host/calendar',
            builder: (_, _) => ref.read(useFirebaseBackendProvider)
                ? const FirebaseCalendarPage()
                : const CalendarPage(),
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
        ],
      ),
    ],
  );
  ref.listen(authModeProvider, (_, _) => router.refresh());
  if (ref.read(authModeProvider)) {
    ref.listen(currentUserProvider, (_, _) => router.refresh());
  }
  ref.listen(roleProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authMode = ref.watch(authModeProvider);
    final currentUser = authMode
        ? ref.watch(currentUserProvider).valueOrNull
        : null;
    final host = authMode
        ? currentUser?.role == AppUserRole.host
        : ref.watch(roleProvider) == DemoRole.host;
    final paths = host
        ? ['/host', '/', '/bookings', '/profile']
        : ['/', '/favorites', '/bookings', '/profile'];
    final selected = paths.indexOf(path);
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.holiday_village_rounded, color: brand, size: 28),
              SizedBox(width: 8),
              Text(
                'hhl',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                ' stay',
                style: TextStyle(
                  fontSize: 20,
                  color: brand,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(host ? '/profile' : '/host'),
            icon: Icon(
              host
                  ? Icons.admin_panel_settings_outlined
                  : authMode && currentUser == null
                  ? Icons.storefront_outlined
                  : Icons.person_outline,
            ),
            label: Text(
              host
                  ? 'Admin'
                  : authMode && currentUser == null
                  ? 'Chủ nhà'
                  : 'Tài khoản',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ref.watch(storageNoticeProvider) case final String notice)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(notice),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.white,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: NavigationBar(
              selectedIndex: selected < 0 ? 0 : selected,
              onDestinationSelected: (i) => context.go(paths[i]),
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    host ? Icons.dashboard_outlined : Icons.explore_outlined,
                  ),
                  label: host ? 'Quản lý' : 'Khám phá',
                ),
                if (!host)
                  const NavigationDestination(
                    icon: Icon(Icons.favorite_outline),
                    label: 'Yêu thích',
                  )
                else
                  const NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    label: 'Khám phá',
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.event_note),
                  label: 'Đơn đặt',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Tài khoản',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
