import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../state/demo_storage.dart';
import '../theme/app_theme.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/logout_action.dart';
import '../../features/dashboard/presentation/calendar_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/booking/presentation/booking_form_page.dart';
import '../../features/booking/presentation/bookings_page.dart';
import '../../features/dashboard/presentation/host_page.dart';
import '../../features/dashboard/presentation/finance_page.dart';
import '../../features/dashboard/presentation/housekeeping_page.dart';
import '../../features/dashboard/presentation/guest_directory_page.dart';
import '../../features/dashboard/presentation/staff_page.dart';
import '../../features/ai/presentation/ai_chat_page.dart';
import '../../features/ai/presentation/ai_assistant_button.dart';
import '../../features/homestay/presentation/detail_page.dart';
import '../../features/homestay/presentation/explore_page.dart';
import '../../features/homestay/presentation/home_page.dart';
import '../../features/landing/presentation/landing_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (ref.read(signOutInProgressProvider)) return null;
      final path = state.uri.path;
      // Browsing stays public, but a booking must belong to a signed-in guest.
      // Keep the complete booking URI so login returns to the same room and
      // the in-memory date/guest selection remains available.
      if (path.startsWith('/book/')) {
        final authState = ref.read(currentUserProvider);
        if (authState.isLoading) return null;
        final user = authState.valueOrNull;
        if (user == null) {
          final returnTo = _validReturnPath(state.uri.queryParameters['back']);
          return '/login?from=${Uri.encodeComponent(state.uri.toString())}'
              '&back=${Uri.encodeComponent(returnTo)}';
        }
        if (user.role == AppUserRole.host) return '/host';
      }
      if (ref.read(authModeProvider)) {
        final onAdminLogin = path == '/admin/login';
        final onAuthPage =
            path == '/login' || path == '/register' || onAdminLogin;
        final authState = ref.read(currentUserProvider);
        // Avoid redirecting a signed-in user while the local session restores.
        if (authState.isLoading) return null;
        final user = authState.valueOrNull;
        if (user == null) {
          if (onAuthPage) return null;
          final requiresAccount =
              path.startsWith('/host') ||
              path == '/bookings' ||
              path == '/profile';
          if (!requiresAccount) return null;
          final loginPath = path.startsWith('/host')
              ? '/admin/login'
              : '/login';
          final returnTo = _validReturnPath(state.uri.queryParameters['back']);
          return '$loginPath?from=${Uri.encodeComponent(state.uri.toString())}'
              '&back=${Uri.encodeComponent(returnTo)}';
        }
        if (onAdminLogin) {
          if (user.role == AppUserRole.host) {
            final requested = state.uri.queryParameters['from'];
            return requested != null && requested.startsWith('/host')
                ? requested
                : '/host';
          }
          // Keep guests on the admin sign-in form so it can explain the role
          // mismatch and let them switch to a host account.
          return null;
        }
        if (user.role == AppUserRole.host &&
            (path == '/home' || path == '/explore' || path == '/favorites')) {
          return '/host';
        }
        if (user.role == AppUserRole.host && path == '/') return '/host';
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
      if (!host && path.startsWith('/host')) return '/profile';
      if (host &&
          (path.startsWith('/book/') ||
              path == '/' ||
              path == '/home' ||
              path == '/explore' ||
              path == '/favorites'))
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
      GoRoute(path: '/', builder: (_, _) => const LandingPage()),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/admin/login',
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginPage(adminMode: true),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomePage()),
          GoRoute(path: '/explore', builder: (_, _) => const ExplorePage()),
          GoRoute(
            path: '/favorites',
            builder: (_, _) => const ExplorePage(favoritesOnly: true),
          ),
          GoRoute(
            path: '/homestays/:id',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: DetailPage(id: state.pathParameters['id']!),
              transitionsBuilder: (context, animation, secondary, child) {
                final eased = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: eased,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .035),
                      end: Offset.zero,
                    ).animate(eased),
                    child: child,
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/book/:roomId',
            builder: (_, state) =>
                BookingFormPage(roomId: state.pathParameters['roomId']!),
          ),
          GoRoute(path: '/bookings', builder: (_, _) => const BookingsPage()),
          GoRoute(path: '/host', builder: (_, _) => const HostPage()),
          GoRoute(
            path: '/host/finance',
            builder: (_, _) => const FinancePage(),
          ),
          GoRoute(
            path: '/host/housekeeping',
            builder: (_, _) => const HousekeepingPage(),
          ),
          GoRoute(
            path: '/host/guests',
            builder: (_, _) => const GuestDirectoryPage(),
          ),
          GoRoute(path: '/host/staff', builder: (_, _) => const StaffPage()),
          GoRoute(path: '/ai-chat', builder: (_, _) => const AiChatPage()),
          GoRoute(
            path: '/host/calendar',
            builder: (_, _) => const CalendarPage(),
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
        ],
      ),
    ],
  );
  ref.listen(authModeProvider, (_, _) => router.refresh());
  ref.listen(currentUserProvider, (_, _) => router.refresh());
  ref.listen(roleProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

String _validReturnPath(String? candidate) {
  if (candidate == null ||
      !candidate.startsWith('/') ||
      candidate.startsWith('//') ||
      candidate.startsWith('/login') ||
      candidate.startsWith('/admin/login')) {
    return '/explore';
  }
  return candidate;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authModeProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final host = currentUser != null
        ? currentUser.role == AppUserRole.host
        : ref.watch(roleProvider) == DemoRole.host;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (viewportWidth >= 900 && host) {
      return _AdminWebShell(
        path: path,
        child: child,
        name: currentUser?.displayName ?? 'Quản trị viên',
      );
    }
    if (viewportWidth >= 900) {
      return _GuestWebShell(
        path: path,
        child: child,
        signedIn: currentUser != null,
        name: currentUser?.displayName ?? '',
      );
    }
    final paths = host
        ? [
            '/host',
            '/host/finance',
            '/host/housekeeping',
            '/bookings',
            '/profile',
          ]
        : ['/home', '/explore', '/favorites', '/bookings', '/profile'];
    final selected = paths.indexOf(path);
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(fit: BoxFit.scaleDown, child: _HhlLogo()),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(
              host
                  ? '/profile'
                  : currentUser == null
                  ? '/login'
                  : '/profile',
            ),
            icon: Icon(
              host
                  ? Icons.admin_panel_settings_outlined
                  : currentUser == null
                  ? Icons.login_rounded
                  : Icons.person_outline,
            ),
            label: Text(
              host
                  ? 'Admin'
                  : currentUser == null
                  ? 'Đăng nhập'
                  : 'Tài khoản',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ref.watch(storageNoticeProvider) case final String notice)
            _StorageNotice(notice: notice),
          Expanded(
            child: Stack(children: [Positioned.fill(child: child)]),
          ),
        ],
      ),
      floatingActionButton: path == '/home' || path == '/explore'
          ? const AiAssistantButton()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SizedBox(
        height: 72,
        child: ColoredBox(
          color: Colors.white,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: NavigationBar(
                selectedIndex: selected < 0 ? 0 : selected,
                onDestinationSelected: (i) => context.go(paths[i]),
                destinations: [
                  if (!host)
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Trang chủ',
                    ),
                  NavigationDestination(
                    icon: Icon(
                      host ? Icons.dashboard_outlined : Icons.explore_outlined,
                    ),
                    label: host ? 'Quản lý' : 'Khám phá',
                  ),
                  if (host)
                    const NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                      label: 'Tài chính',
                    ),
                  if (host)
                    const NavigationDestination(
                      icon: Icon(Icons.cleaning_services_outlined),
                      selectedIcon: Icon(Icons.cleaning_services_rounded),
                      label: 'Buồng phòng',
                    ),
                  if (!host) ...[
                    const NavigationDestination(
                      icon: Icon(Icons.favorite_outline),
                      label: 'Yêu thích',
                    ),
                  ],
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
      ),
    );
  }
}

class _HhlLogo extends StatelessWidget {
  const _HhlLogo();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: brand,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.villa_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 10),
      const Text(
        'HHL Stay',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -.4,
        ),
      ),
    ],
  );
}

class _StorageNotice extends StatelessWidget {
  const _StorageNotice({required this.notice});
  final String notice;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFFEEF2FF),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Text(
      notice,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF4338CA), fontSize: 12),
    ),
  );
}

class _GuestWebShell extends ConsumerWidget {
  const _GuestWebShell({
    required this.path,
    required this.child,
    required this.signedIn,
    required this.name,
  });
  final String path;
  final Widget child;
  final bool signedIn;
  final String name;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Column(
      children: [
        Container(
          height: 76,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/home'),
                    child: const _HhlLogo(),
                  ),
                  const Spacer(),
                  if (MediaQuery.sizeOf(context).width >= 1200)
                    _TopNavLink(
                      label: 'Trang chủ',
                      selected: path == '/home',
                      onTap: () => context.go('/home'),
                    ),
                  _TopNavLink(
                    label: 'Khám phá',
                    selected: path == '/explore',
                    onTap: () => context.go('/explore'),
                  ),
                  _TopNavLink(
                    label: 'Yêu thích',
                    selected: path == '/favorites',
                    onTap: () => context.go('/favorites'),
                  ),
                  _TopNavLink(
                    label: 'Đơn đặt',
                    selected: path == '/bookings',
                    onTap: () => context.go('/bookings'),
                  ),
                  const Spacer(),
                  if (signedIn)
                    OutlinedButton.icon(
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.person_outline),
                      label: Text(name.isEmpty ? 'Tài khoản' : name),
                    )
                  else
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Đăng nhập'),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: child),
              if (path == '/home' || path == '/explore')
                const Positioned(
                  right: 28,
                  bottom: 28,
                  child: AiAssistantButton(),
                ),
              if (path == '/home' || path == '/explore')
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(child: _SoftGlow()),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow();
  @override
  Widget build(BuildContext context) => Container(
    height: 380,
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.topLeft,
        radius: 1.1,
        colors: [Color(0x18A5B4FC), Colors.transparent],
      ),
    ),
  );
}

class _TopNavLink extends StatelessWidget {
  const _TopNavLink({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? brand : const Color(0xFF475569),
        textStyle: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      child: Text(label),
    ),
  );
}

class _AdminWebShell extends ConsumerWidget {
  const _AdminWebShell({
    required this.path,
    required this.child,
    required this.name,
  });
  final String path;
  final Widget child;
  final String name;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Row(
      children: [
        Container(
          width: 256,
          color: const Color(0xFF0F172A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 82,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: brand,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.villa_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HHL Stay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'QUẢN TRỊ HỆ THỐNG',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 15, 12, 10),
                child: Text(
                  'QUẢN LÝ',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              _AdminNavItem(
                label: 'Tổng quan',
                icon: Icons.grid_view_rounded,
                selected: path == '/host',
                onTap: () => context.go('/host'),
              ),
              _AdminNavItem(
                label: 'Tài chính',
                icon: Icons.account_balance_wallet_outlined,
                selected: path == '/host/finance',
                onTap: () => context.go('/host/finance'),
              ),
              _AdminNavItem(
                label: 'Buồng phòng',
                icon: Icons.cleaning_services_outlined,
                selected: path == '/host/housekeeping',
                onTap: () => context.go('/host/housekeeping'),
              ),
              _AdminNavItem(
                label: 'Khách hàng',
                icon: Icons.groups_outlined,
                selected: path == '/host/guests',
                onTap: () => context.go('/host/guests'),
              ),
              _AdminNavItem(
                label: 'Nhân sự & ca làm',
                icon: Icons.badge_outlined,
                selected: path == '/host/staff',
                onTap: () => context.go('/host/staff'),
              ),
              _AdminNavItem(
                label: 'Đơn đặt phòng',
                icon: Icons.event_note_rounded,
                selected: path == '/bookings',
                onTap: () => context.go('/bookings'),
              ),
              _AdminNavItem(
                label: 'Lịch phòng',
                icon: Icons.calendar_month_rounded,
                selected: path == '/host/calendar',
                onTap: () => context.go('/host/calendar'),
              ),
              const Spacer(),
              _AdminNavItem(
                label: 'Hồ sơ',
                icon: Icons.person_outline_rounded,
                selected: path == '/profile',
                onTap: () => context.go('/profile'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFF3730A3),
                        child: Text(
                          name.isEmpty
                              ? 'A'
                              : name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Quản trị viên' : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Quản trị viên',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: ref.read(authModeProvider)
                            ? 'Đăng xuất'
                            : 'Tài khoản',
                        onPressed: () {
                          if (ref.read(authModeProvider)) {
                            signOutAndReturnToPublicPage(context, ref);
                          } else {
                            context.go('/profile');
                          }
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 36),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Text(
                      path == '/host'
                          ? 'Tổng quan'
                          : path == '/host/finance'
                          ? 'Tài chính'
                          : path == '/host/housekeeping'
                          ? 'Buồng phòng'
                          : path == '/host/guests'
                          ? 'Khách hàng'
                          : path == '/host/staff'
                          ? 'Nhân sự & ca làm'
                          : path == '/bookings'
                          ? 'Đơn đặt phòng'
                          : path == '/host/calendar'
                          ? 'Lịch phòng'
                          : path == '/profile'
                          ? 'Hồ sơ quản trị'
                          : 'Quản trị',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.circle, size: 9, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      DateTime.now().toString().substring(0, 10),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(color: const Color(0xFFF8FAFC), child: child),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF312E81) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF4338CA) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? const Color(0xFFC7D2FE)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
