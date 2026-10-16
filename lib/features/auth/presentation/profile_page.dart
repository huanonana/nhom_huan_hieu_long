import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../booking/domain/booking.dart';
import '../domain/app_user.dart';
import 'auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authModeProvider)) {
      return ref
          .watch(currentUserProvider)
          .when(
            data: (user) => user == null
                ? const PageBody(children: [Text('Bạn chưa đăng nhập.')])
                : _AuthenticatedProfile(user: user),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const PageBody(
              children: [Text('Không tải được hồ sơ. Vui lòng đăng nhập lại.')],
            ),
          );
    }
    final role = ref.watch(roleProvider);
    final isAdmin = role == DemoRole.host;
    final favorites = ref.watch(favoritesProvider);
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final bookings = repo.bookings;
    final guestBookings = bookings.where((b) => b.guestId == 'guest-demo');
    final managedHomes = repo.homestays
        .where((home) => home.hostId == 'host-demo')
        .length;
    final pendingBookings = bookings
        .where(
          (booking) =>
              booking.effectiveStatus(repo.now) == BookingStatus.pending,
        )
        .length;
    return PageBody(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAE3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: brand,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'Xin chào, quản trị viên' : 'Chào bạn!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    isAdmin
                        ? 'Quản lý homestay và hoạt động đặt phòng.'
                        : 'Một tài khoản, nhiều chuyến đi.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: _Stat(
                isAdmin ? '$managedHomes' : '${guestBookings.length}',
                isAdmin ? 'Homestay' : 'Chuyến đi',
                () => context.go(isAdmin ? '/host' : '/bookings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                isAdmin ? '$pendingBookings' : '${favorites.length}',
                isAdmin ? 'Đơn chờ xử lý' : 'Đã lưu',
                () {
                  if (!isAdmin) {
                    ref.read(roleProvider.notifier).state = DemoRole.guest;
                  }
                  context.go(isAdmin ? '/bookings' : '/favorites');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Card(
          child: Column(
            children: [
              if (isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.home_work_outlined, color: brand),
                  title: const Text('Quản lý homestay và phòng'),
                  subtitle: const Text('Danh mục, giá và tình trạng phòng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/host'),
                ),
                ListTile(
                  leading: const Icon(Icons.event_note_outlined, color: brand),
                  title: const Text('Xử lý đơn đặt phòng'),
                  subtitle: const Text('Duyệt yêu cầu và theo dõi lưu trú'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/bookings'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.calendar_month_outlined,
                    color: brand,
                  ),
                  title: const Text('Lịch phòng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/host/calendar'),
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(
                    Icons.confirmation_number_outlined,
                    color: brand,
                  ),
                  title: const Text('Đơn đặt phòng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/bookings'),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: brand),
                  title: const Text('Đặt phòng như thế nào?'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => const SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Một chuyến đi, 3 bước',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              '1. Chọn nơi ở, ngày nhận/trả và số khách.\n\n2. Kiểm tra giá, gửi yêu cầu và chờ chủ nhà duyệt.\n\n3. Theo dõi trạng thái trong Đơn đặt, thanh toán tại homestay.\n\nBạn có thể hủy khi yêu cầu còn chờ duyệt.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          isAdmin ? 'TÀI KHOẢN QUẢN TRỊ' : 'CHẾ ĐỘ TRẢI NGHIỆM',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: brand,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isAdmin
              ? 'Quản trị viên demo có thể quản lý danh mục và đơn đặt. Dữ liệu hiện lưu trên thiết bị, chưa có đăng nhập thật hay đồng bộ Firebase.'
              : 'Đang dùng dữ liệu demo lưu trên máy. Chuyển vai trò để trải nghiệm; chưa phải đăng nhập thật và chưa đồng bộ Firebase.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in DemoRole.values)
              ChoiceChip(
                label: Text(
                  r == DemoRole.guest ? 'Khách đặt phòng' : 'Quản trị viên',
                ),
                selected: role == r,
                onSelected: (_) {
                  ref.read(roleProvider.notifier).state = r;
                  context.go(r == DemoRole.guest ? '/' : '/host');
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Về HHL Stay', style: TextStyle(fontSize: 14)),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Ứng dụng quản lý Homestay\nPhạm Văn Huấn — 23010331\nNguyễn Hữu Lê Hiếu — 23010985\nNguyễn Hải Long — 2301872',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthenticatedProfile extends ConsumerWidget {
  const _AuthenticatedProfile({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageBody(
    children: [
      const SizedBox(height: 12),
      CircleAvatar(
        radius: 34,
        backgroundColor: const Color(0xFFFFEAE3),
        child: Icon(
          user.role == AppUserRole.host
              ? Icons.admin_panel_settings_outlined
              : Icons.person_outline_rounded,
          color: brand,
          size: 34,
        ),
      ),
      const SizedBox(height: 14),
      Text(user.displayName, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text(user.email, style: const TextStyle(color: muted)),
      const SizedBox(height: 16),
      Chip(
        avatar: Icon(
          user.role == AppUserRole.host
              ? Icons.home_work_outlined
              : Icons.travel_explore_outlined,
          size: 18,
        ),
        label: Text(user.role == AppUserRole.host ? 'Chủ nhà' : 'Khách'),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () async {
          await ref.read(authRepositoryProvider).signOut();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Đăng xuất'),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.onTap);
  final String value, label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: brand,
              ),
            ),
            Text(label, style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}
