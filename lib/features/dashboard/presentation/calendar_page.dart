import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../booking/domain/booking.dart';
import '../../booking/presentation/booking_status_badge.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime? _selected;
  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final day = _selected ?? vietnamToday(repo.now);
    final end = day.add(const Duration(days: 1));
    final rooms = repo.rooms
        .where(
          (r) => repo.homestays.any(
            (h) => h.id == r.homestayId && h.hostId == 'host-demo',
          ),
        )
        .toList();
    final free = rooms.where((r) => repo.available(r, day, end)).length;
    return PageBody(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/host'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Tổng quan'),
          ),
        ),
        Text('Lịch phòng', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          '$free / ${rooms.length} phòng trống trong đêm đã chọn',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            IconButton(
              tooltip: 'Ngày trước',
              onPressed: () => setState(
                () => _selected = day.subtract(const Duration(days: 1)),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: day,
                    firstDate: DateTime.utc(2020),
                    lastDate: DateTime.utc(2100),
                  );
                  if (date != null && mounted)
                    setState(() => _selected = stayDate(date));
                },
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(dateLabel(day)),
              ),
            ),
            IconButton(
              tooltip: 'Ngày sau',
              onPressed: () =>
                  setState(() => _selected = day.add(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _selected = vietnamToday(repo.now)),
            child: const Text('Về hôm nay'),
          ),
        ),
        const Text(
          'Theo dõi từng đêm: đơn chờ còn hạn, đã xác nhận và đang ở đều giữ chỗ.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        const SizedBox(height: 20),
        for (final room in rooms)
          Builder(
            builder: (context) {
              final bookings = repo.bookings
                  .where(
                    (b) =>
                        b.roomId == room.id &&
                        b.blocks(repo.now) &&
                        overlaps(day, end, b.checkIn, b.checkOut),
                  )
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                stayImage(room.homestayId),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                cacheWidth: 140,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    repo.homestays
                                        .singleWhere(
                                          (h) => h.id == room.homestayId,
                                        )
                                        .name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!room.active)
                          const StatusBadge(
                            label: 'Bảo trì',
                            icon: Icons.build_outlined,
                            color: muted,
                          )
                        else if (bookings.isEmpty)
                          const StatusBadge(
                            label: 'Còn trống',
                            icon: Icons.check_circle_outline_rounded,
                            color: Color(0xFF218567),
                          )
                        else
                          BookingStatusBadge(
                            status: bookings.first.effectiveStatus(repo.now),
                          ),
                        for (final b in bookings)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${b.id} · ${b.guestName}\n${dateLabel(b.checkIn)} → ${dateLabel(b.checkOut)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        if (bookings.isNotEmpty)
                          TextButton(
                            onPressed: () => context.go('/bookings'),
                            child: const Text('Xử lý đơn đặt →'),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (rooms.isEmpty)
          const EmptyState('Chưa có phòng. Thêm phòng trong Tổng quan.'),
      ],
    );
  }
}
