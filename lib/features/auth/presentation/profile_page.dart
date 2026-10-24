import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../booking/domain/booking.dart';
import '../domain/app_user.dart';
import 'auth_provider.dart';
import 'logout_action.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    if (currentUser != null) return _AuthenticatedProfile(user: currentUser);
    if (ref.watch(authModeProvider)) {
      return ref
          .watch(currentUserProvider)
          .when(
            data: (user) => user == null
                ? PageBody(
                    maxWidth: 520,
                    children: [
                      const EmptyState('Bạn chưa đăng nhập.'),
                      FilledButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Đăng nhập để tiếp tục'),
                      ),
                    ],
                  )
                : _AuthenticatedProfile(user: user),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => PageBody(
              maxWidth: 1000,
              children: [
                const SizedBox(height: 36),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 38,
                          color: muted,
                        ),
                        const SizedBox(height: 12),
                        const Text('Chưa tải được hồ sơ tài khoản.'),
                        const SizedBox(height: 6),
                        Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(currentUserProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tải lại hồ sơ'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    final managedHomes = repo.homestays.length;
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
                color: const Color(0xFFEEF2FF),
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
                icon: isAdmin
                    ? Icons.home_work_outlined
                    : Icons.luggage_outlined,
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
                icon: isAdmin
                    ? Icons.pending_actions_rounded
                    : Icons.favorite_border_rounded,
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
                  leading: const Icon(
                    Icons.favorite_border_rounded,
                    color: brand,
                  ),
                  title: const Text('Homestay yêu thích'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/favorites'),
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
                const ExpansionTile(
                  leading: Icon(Icons.settings_outlined, color: brand),
                  title: Text('Cài đặt và thông tin'),
                  children: [
                    ListTile(
                      leading: Icon(Icons.receipt_long_outlined),
                      title: Text('Thông tin hóa đơn'),
                      subtitle: Text(
                        'Bản demo thanh toán tại homestay, chưa phát hành hóa đơn.',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.notifications_none_rounded),
                      title: Text('Thông báo'),
                      subtitle: Text(
                        'Trạng thái đặt phòng hiển thị trong mục Đơn đặt.',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.language_rounded),
                      title: Text('Ngôn ngữ · Khu vực'),
                      subtitle: Text('Tiếng Việt · Việt Nam'),
                    ),
                    ListTile(
                      leading: Icon(Icons.shield_outlined),
                      title: Text('Điều khoản và quyền riêng tư'),
                      subtitle: Text(
                        'Dữ liệu đặt phòng demo được lưu trên thiết bị.',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Phiên bản'),
                      subtitle: Text('HHL Stay · Bản demo học thuật'),
                    ),
                  ],
                ),
                ListTile(
                  leading: const Icon(
                    Icons.support_agent_rounded,
                    color: brand,
                  ),
                  title: const Text('Liên hệ trợ lý HHL Stay'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/ai-chat'),
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
              ? 'Quản trị viên demo có thể quản lý danh mục và đơn đặt. Dữ liệu được lưu trên thiết bị, không đồng bộ lên máy chủ.'
              : 'Đang dùng dữ liệu demo lưu trên máy. Chuyển vai trò để trải nghiệm; đơn đặt và yêu thích chỉ có trên thiết bị này.',
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
    maxWidth: 760,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFEEF2FF),
                child: Icon(
                  user.role == AppUserRole.host
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline_rounded,
                  color: brand,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.displayName.isEmpty ? 'Hồ sơ của bạn' : user.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 14),
              Chip(
                avatar: Icon(
                  user.role == AppUserRole.host
                      ? Icons.home_work_outlined
                      : Icons.travel_explore_outlined,
                  size: 18,
                ),
                label: Text(
                  user.role == AppUserRole.host ? 'Chủ nhà' : 'Khách',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => signOutAndReturnToPublicPage(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ),
      ),
      if (user.role == AppUserRole.guest) ...[
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFFFFF4EC),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.card_giftcard_rounded, color: brand),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mã thành viên HHL Stay',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'HHL-${user.uid.length > 6 ? user.uid.substring(user.uid.length - 6).toUpperCase() : user.uid.toUpperCase()}',
                        style: const TextStyle(color: muted),
                      ),
                      const Text(
                        'Ưu đãi thành viên được áp dụng khi đặt phòng. Tích điểm giới thiệu chưa khả dụng trong bản demo.',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép mã',
                  onPressed: () async {
                    final suffix = user.uid.length > 6
                        ? user.uid.substring(user.uid.length - 6).toUpperCase()
                        : user.uid.toUpperCase();
                    await Clipboard.setData(ClipboardData(text: 'HHL-$suffix'));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép mã thành viên.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.favorite_border_rounded,
                  color: brand,
                ),
                title: const Text('Homestay yêu thích'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/favorites'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.luggage_outlined, color: brand),
                title: const Text('Chuyến đi và đơn đặt'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/bookings'),
              ),
              const Divider(height: 1, indent: 56),
              const ExpansionTile(
                leading: Icon(Icons.settings_outlined, color: brand),
                title: Text('Cài đặt và hỗ trợ'),
                children: [
                  ListTile(
                    leading: Icon(Icons.notifications_none_rounded),
                    title: Text('Thông báo đặt phòng'),
                    subtitle: Text(
                      'Thông báo trong ứng dụng khi bạn mở HHL Stay',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.language_rounded),
                    title: Text('Ngôn ngữ và khu vực'),
                    subtitle: Text('Tiếng Việt · Việt Nam'),
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline_rounded),
                    title: Text('Hỏi đáp'),
                    subtitle: Text(
                      'Đơn chờ chủ nhà xác nhận; thanh toán tại homestay.',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.shield_outlined),
                    title: Text('Điều khoản và quyền riêng tư'),
                    subtitle: Text('Dữ liệu demo được lưu trên thiết bị này.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.support_agent_rounded),
                    title: Text('Liên hệ hỗ trợ'),
                    subtitle: Text('Mở Trợ lý HHL Stay để được hướng dẫn.'),
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined, color: brand),
                title: const Text('Trợ lý HHL Stay'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/ai-chat'),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.onTap, {required this.icon});
  final String value, label;
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEEF2FF),
              child: Icon(icon, color: brand, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: brand,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}
