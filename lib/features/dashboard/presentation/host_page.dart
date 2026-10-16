import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../booking/domain/booking.dart';
import '../../homestay/domain/catalog.dart';
import '../domain/monthly_occupancy.dart';
import 'catalog_editor.dart';

class HostPage extends ConsumerWidget {
  const HostPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final now = vietnamToday(repo.now);
    final bookings = repo.bookings
        .where((b) => b.hostId == 'host-demo')
        .toList();
    final homestays = repo.homestays
        .where((home) => home.hostId == 'host-demo')
        .toList();
    final pending = bookings
        .where((b) => b.effectiveStatus(repo.now) == BookingStatus.pending)
        .length;
    final currentlyStaying = bookings
        .where((b) => b.effectiveStatus(repo.now) == BookingStatus.checkedIn)
        .length;
    final completedValue = bookings
        .where((b) => b.status == BookingStatus.checkedOut)
        .fold<int>(0, (sum, b) => sum + b.total);
    final monthStart = DateTime.utc(now.year, now.month);
    final monthlyValues = <int>[];
    final monthLabels = <String>[];
    // Keep seven months visible so the demo can be checked from April onward
    // when the current date is in October.
    for (var back = 6; back >= 0; back--) {
      final month = DateTime.utc(monthStart.year, monthStart.month - back);
      monthLabels.add(_monthLabel(month.month));
      monthlyValues.add(
        bookings
            .where(
              (b) =>
                  b.status == BookingStatus.checkedOut &&
                  b.checkOut.year == month.year &&
                  b.checkOut.month == month.month,
            )
            .fold<int>(0, (sum, b) => sum + b.total),
      );
    }
    final rooms = repo.rooms
        .where(
          (r) => repo.homestays.any(
            (h) => h.id == r.homestayId && h.hostId == 'host-demo',
          ),
        )
        .toList();
    final activeRooms = rooms.where((room) => room.active).length;
    final roomsUnderMaintenance = rooms.length - activeRooms;
    final todayArrivals = bookings
        .where(
          (b) =>
              b.effectiveStatus(repo.now) == BookingStatus.confirmed &&
              b.checkIn == now,
        )
        .toList();
    final todayDepartures = bookings
        .where(
          (b) =>
              b.effectiveStatus(repo.now) == BookingStatus.checkedIn &&
              b.checkOut == now,
        )
        .toList();
    final needsAttention = <_AttentionItem>[
      if (pending > 0)
        _AttentionItem(
          icon: Icons.mark_email_unread_outlined,
          title: '$pending yêu cầu đang chờ duyệt',
          detail: 'Mở danh sách để xác nhận hoặc từ chối',
          color: brand,
          opensBookings: true,
        ),
      if (todayArrivals.isNotEmpty)
        _AttentionItem(
          icon: Icons.login_rounded,
          title: '${todayArrivals.length} lượt nhận phòng hôm nay',
          detail: todayArrivals.take(2).map((b) => b.guestName).join(' · '),
          color: const Color(0xFF218567),
          opensBookings: true,
        ),
      if (todayDepartures.isNotEmpty)
        _AttentionItem(
          icon: Icons.logout_rounded,
          title: '${todayDepartures.length} lượt trả phòng hôm nay',
          detail: todayDepartures.take(2).map((b) => b.guestName).join(' · '),
          color: const Color(0xFFB56A14),
          opensBookings: true,
        ),
      if (roomsUnderMaintenance > 0)
        _AttentionItem(
          icon: Icons.build_outlined,
          title: '$roomsUnderMaintenance phòng đang bảo trì',
          detail: 'Kiểm tra trạng thái phòng trong danh mục',
          color: muted,
        ),
    ];
    final activeRoomList = rooms.where((room) => room.active).toList();
    final occupancy = calculateMonthlyOccupancy(
      month: now,
      activeRooms: activeRoomList,
      bookings: bookings,
    );

    return PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tổng quan quản trị',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Lịch phòng',
              onPressed: () => context.go('/host/calendar'),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text('Quản lý homestay, phòng và các đơn đặt trên hệ thống.'),
        const SizedBox(height: 14),
        _AdminWelcomeCard(
          homestays: homestays.length,
          activeRooms: activeRooms,
          allRooms: rooms.length,
          today: now,
        ),
        const SizedBox(height: 14),
        _QuickActions(
          canAddRoom: homestays.isNotEmpty,
          onAddHomestay: () => editCatalog(context),
          onAddRoom: homestays.isEmpty
              ? null
              : () =>
                    editCatalog(context, home: homestays.first, roomMode: true),
          onCalendar: () => context.go('/host/calendar'),
        ),
        const SizedBox(height: 20),
        Text(
          'Tổng quan kinh doanh',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 500;
            final cardWidth = compact
                ? (constraints.maxWidth - 10) / 2
                : (constraints.maxWidth - 20) / 3;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _Metric(
                    'Chờ duyệt',
                    '$pending',
                    'Cần xử lý',
                    Icons.pending_actions,
                    color: const Color(0xFFFFEFE8),
                    onTap: () => context.go('/bookings'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _Metric(
                    'Đang lưu trú',
                    '$currentlyStaying',
                    'Khách hiện tại',
                    Icons.hotel_rounded,
                    color: const Color(0xFFEAF5EF),
                    onTap: () => context.go('/bookings'),
                  ),
                ),
                SizedBox(
                  width: compact ? constraints.maxWidth : cardWidth,
                  child: _Metric(
                    'Giá trị đơn đã trả phòng',
                    money(completedValue),
                    'Tổng lũy kế · dữ liệu demo',
                    Icons.payments_outlined,
                    color: const Color(0xFFFFE8D9),
                    onTap: () => context.go('/bookings'),
                    highlighted: true,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _RevenueCard(values: monthlyValues, labels: monthLabels),
        const SizedBox(height: 12),
        _OccupancyCard(
          occupancy: occupancy,
          rooms: activeRoomList.length,
          month: now.month,
          onTap: () => context.go('/bookings'),
        ),
        const SizedBox(height: 16),
        _AttentionCard(
          items: needsAttention,
          onOpenBookings: () => context.go('/bookings'),
        ),
        const SizedBox(height: 12),
        _TodayOperationsCard(
          arrivals: todayArrivals,
          departures: todayDepartures,
          homestays: homestays,
          onOpenBookings: () => context.go('/bookings'),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go('/bookings'),
                icon: const Icon(Icons.event_note),
                label: const Text('Xử lý đơn'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/host/calendar'),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Lịch phòng'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Danh mục homestay',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => editCatalog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final h in homestays)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          stayImage(h.id),
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          cacheWidth: 170,
                          semanticLabel: 'Ảnh minh họa ${h.name}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              h.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => editCatalog(context, home: h),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Sửa'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            editCatalog(context, home: h, roomMode: true),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm phòng'),
                      ),
                      TextButton(
                        onPressed: () => confirmCatalogDelete(
                          context,
                          ref,
                          id: h.id,
                          name: h.name,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                  const Divider(),
                  for (final room in repo.rooms.where(
                    (r) => r.homestayId == h.id,
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Slidable(
                        key: ValueKey(room.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.48,
                          children: [
                            SlidableAction(
                              onPressed: (_) => editCatalog(
                                context,
                                home: h,
                                room: room,
                                roomMode: true,
                              ),
                              backgroundColor: brand,
                              foregroundColor: Colors.white,
                              icon: Icons.edit_outlined,
                              label: 'Sửa',
                            ),
                            SlidableAction(
                              onPressed: (_) => confirmCatalogDelete(
                                context,
                                ref,
                                id: room.id,
                                name: room.name,
                                room: true,
                              ),
                              backgroundColor: const Color(0xFFB9382E),
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outline,
                              label: 'Xóa',
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: room.active
                                    ? const Color(0xFFEAF5EF)
                                    : const Color(0xFFF1F0ED),
                                child: Icon(
                                  room.active
                                      ? Icons.bed_outlined
                                      : Icons.build_outlined,
                                  color: room.active
                                      ? const Color(0xFF218567)
                                      : muted,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${room.name}\n${room.capacity} khách · ${money(room.price)} / đêm · ${room.active ? 'Đang mở' : 'Bảo trì'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const Icon(
                                Icons.swipe_left_rounded,
                                size: 18,
                                color: muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (homestays.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Bạn chưa có homestay. Thêm chỗ ở để bắt đầu quản lý phòng và đơn đặt.',
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

String _monthLabel(int month) => const [
  'T1',
  'T2',
  'T3',
  'T4',
  'T5',
  'T6',
  'T7',
  'T8',
  'T9',
  'T10',
  'T11',
  'T12',
][month - 1];

class _AdminWelcomeCard extends StatelessWidget {
  const _AdminWelcomeCard({
    required this.homestays,
    required this.activeRooms,
    required this.allRooms,
    required this.today,
  });

  final int homestays, activeRooms, allRooms;
  final DateTime today;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xFFEC6338), Color(0xFFEF8B5E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: brand.withValues(alpha: .17),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BẢNG ĐIỀU HÀNH · ${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Chào Admin 👋',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 22,
          runSpacing: 8,
          children: [
            _PortfolioStat(value: '$homestays', label: 'homestay'),
            _PortfolioStat(
              value: '$activeRooms/$allRooms',
              label: 'phòng hoạt động',
            ),
          ],
        ),
      ],
    ),
  );
}

class _PortfolioStat extends StatelessWidget {
  const _PortfolioStat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}

class _AttentionItem {
  const _AttentionItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    this.opensBookings = false,
  });
  final IconData icon;
  final String title, detail;
  final Color color;
  final bool opensBookings;
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.items, required this.onOpenBookings});
  final List<_AttentionItem> items;
  final VoidCallback onOpenBookings;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Việc cần chú ý',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFE8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      color: brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF218567)),
                  SizedBox(width: 9),
                  Expanded(child: Text('Không có việc gấp. Danh mục đang ổn.')),
                ],
              ),
            )
          else
            for (final item in items)
              InkWell(
                onTap: item.opensBookings ? onOpenBookings : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: item.color.withValues(alpha: .1),
                        child: Icon(item.icon, color: item.color, size: 19),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.detail,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.opensBookings)
                        const Icon(Icons.chevron_right, color: muted, size: 20),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.canAddRoom,
    required this.onAddHomestay,
    required this.onAddRoom,
    required this.onCalendar,
  });

  final bool canAddRoom;
  final VoidCallback onAddHomestay, onCalendar;
  final VoidCallback? onAddRoom;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Thao tác nhanh', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 9),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 390 ? 2 : 3;
          final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: width,
                child: _QuickActionTile(
                  icon: Icons.add_home_work_outlined,
                  label: 'Thêm homestay',
                  onTap: onAddHomestay,
                ),
              ),
              SizedBox(
                width: width,
                child: _QuickActionTile(
                  icon: Icons.bedroom_parent_outlined,
                  label: 'Thêm phòng',
                  onTap: onAddRoom,
                ),
              ),
              SizedBox(
                width: width,
                child: _QuickActionTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Xem lịch phòng',
                  onTap: onCalendar,
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE7E1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: onTap == null ? muted : brand, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? muted : null,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TodayOperationsCard extends StatelessWidget {
  const _TodayOperationsCard({
    required this.arrivals,
    required this.departures,
    required this.homestays,
    required this.onOpenBookings,
  });

  final List<Booking> arrivals, departures;
  final List<Homestay> homestays;
  final VoidCallback onOpenBookings;

  @override
  Widget build(BuildContext context) {
    final namesById = {for (final home in homestays) home.id: home.name};
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 15, 17, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today_outlined, color: brand, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lịch vận hành hôm nay',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: onOpenBookings,
                  child: const Text('Đơn đặt'),
                ),
              ],
            ),
            if (arrivals.isEmpty && departures.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 7, bottom: 5),
                child: Text(
                  'Hôm nay chưa có lượt nhận hoặc trả phòng.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
            for (final booking in arrivals)
              _OperationRow(
                label: 'NHẬN PHÒNG',
                booking: booking,
                homestayName: namesById[booking.homestayId] ?? 'Homestay',
                color: const Color(0xFF218567),
                onTap: onOpenBookings,
              ),
            for (final booking in departures)
              _OperationRow(
                label: 'TRẢ PHÒNG',
                booking: booking,
                homestayName: namesById[booking.homestayId] ?? 'Homestay',
                color: const Color(0xFFB56A14),
                onTap: onOpenBookings,
              ),
          ],
        ),
      ),
    );
  }
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({
    required this.label,
    required this.booking,
    required this.homestayName,
    required this.color,
    required this.onTap,
  });
  final String label, homestayName;
  final Booking booking;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 43,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label · ${booking.guestName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${booking.roomName} · $homestayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${booking.nights} đêm · ${money(booking.total)}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: muted, size: 19),
        ],
      ),
    ),
  );
}

class _RevenueCard extends StatefulWidget {
  const _RevenueCard({required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;

  @override
  State<_RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<_RevenueCard> {
  late int _selectedIndex = widget.values.isEmpty
      ? 0
      : widget.values.length - 1;

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final labels = widget.labels;
    final maxValue = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.25;
    final interval = maxY / 4;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Doanh thu theo tháng',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    key: ValueKey(_selectedIndex),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${labels[_selectedIndex]}  ·  '
                      '${money(values[_selectedIndex])}',
                      style: const TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Đơn đã trả phòng · chạm vào điểm để xem từng tháng',
              style: TextStyle(fontSize: 11, color: muted),
            ),
            const SizedBox(height: 16),
            if (maxValue == 0)
              Container(
                height: 142,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_outlined, color: brand, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có doanh thu hoàn tất',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Biểu đồ sẽ cập nhật khi có đơn trả phòng',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (values.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        final spots = response?.lineBarSpots;
                        if (spots == null || spots.isEmpty) return;
                        final index = spots.first.x.round().clamp(
                          0,
                          values.length - 1,
                        );
                        if (index != _selectedIndex) {
                          setState(() => _selectedIndex = index);
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (spots) => spots.map((spot) {
                          final index = spot.x.toInt();
                          return LineTooltipItem(
                            '${labels[index]}\n${money(spot.y.toInt())}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFEFECE7),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: interval,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              _compactMoney(value),
                              style: const TextStyle(color: muted, fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) {
                            final index = value.round();
                            if (index < 0 || index >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                labels[index],
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < values.length; i++)
                            FlSpot(i.toDouble(), values[i].toDouble()),
                        ],
                        // Straight segments avoid dipping below zero between
                        // consecutive months with no revenue.
                        isCurved: false,
                        color: brand,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              brand.withValues(alpha: .22),
                              brand.withValues(alpha: .01),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _compactMoney(double value) {
  if (value >= 1000000) return '${(value / 1000000).round()}tr';
  if (value >= 1000) return '${(value / 1000).round()}k';
  return value.round().toString();
}

class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({
    required this.occupancy,
    required this.rooms,
    required this.month,
    required this.onTap,
  });
  final MonthlyOccupancy occupancy;
  final int rooms, month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedroom_parent_outlined, color: brand),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Công suất phòng · tháng $month',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${occupancy.percentage}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: muted),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: occupancy.percentage / 100,
                minHeight: 9,
                backgroundColor: const Color(0xFFF1EEE9),
                color: brand,
                semanticsLabel: 'Công suất phòng tháng $month',
                semanticsValue: '${occupancy.percentage} phần trăm',
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '${occupancy.bookedRoomNights} đêm đã đặt trên '
              '${occupancy.availableRoomNights} đêm phòng có thể bán',
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Tính trên $rooms phòng đang mở · chạm để xem các đơn',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(
    this.label,
    this.value,
    this.caption,
    this.icon, {
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });
  final String label, value, caption;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Card(
    color: highlighted ? Colors.transparent : null,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: highlighted
              ? const LinearGradient(
                  colors: [Color(0xFFFFE3CF), Color(0xFFFFF4EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: brand, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: highlighted ? brand : null,
                        fontWeight: highlighted ? FontWeight.w800 : null,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: muted),
            ],
          ),
        ),
      ),
    ),
  );
}
