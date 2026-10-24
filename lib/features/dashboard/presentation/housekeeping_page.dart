import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../booking/domain/booking.dart';
import '../../booking/presentation/booking_status_badge.dart';
import '../../homestay/domain/catalog.dart';

class HousekeepingPage extends ConsumerWidget {
  const HousekeepingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(changesProvider);
    final repository = ref.watch(repositoryProvider);
    final rooms = repository.rooms.toList();
    final needsCleaning = rooms
        .where(
          (room) =>
              room.active &&
              room.housekeepingStatus != HousekeepingStatus.ready,
        )
        .length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Buồng phòng',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$needsCleaning phòng cần xử lý · cập nhật trạng thái sau mỗi lượt trả phòng',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              Card(
                color: const Color(0xFFEEF2FF),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cleaning_services_outlined, color: brand),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Khi admin hoàn tất trả phòng, phòng tự chuyển sang “Cần dọn”. Chỉ phòng “Sẵn sàng” mới được xác nhận nhận khách tiếp theo.',
                          style: TextStyle(
                            color: Color(0xFF3730A3),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (rooms.isEmpty) const EmptyState('Chưa có phòng để quản lý.'),
              for (final room in rooms)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 108,
                          height: 76,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: StayPhoto(room.homestayId, height: 76),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                repository.homestays
                                    .firstWhere(
                                      (home) => home.id == room.homestayId,
                                    )
                                    .name,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 7),
                              if (!room.active)
                                const StatusBadge(
                                  label: 'Bảo trì',
                                  icon: Icons.build_outlined,
                                  color: Color(0xFFB45309),
                                )
                              else
                                StatusBadge(
                                  label: room.housekeepingStatus.label,
                                  icon: switch (room.housekeepingStatus) {
                                    HousekeepingStatus.ready =>
                                      Icons.check_circle_outline,
                                    HousekeepingStatus.needsCleaning =>
                                      Icons.cleaning_services_outlined,
                                    HousekeepingStatus.cleaning =>
                                      Icons.hourglass_top_rounded,
                                    HousekeepingStatus.maintenance =>
                                      Icons.build_outlined,
                                  },
                                  color: switch (room.housekeepingStatus) {
                                    HousekeepingStatus.ready => const Color(
                                      0xFF059669,
                                    ),
                                    HousekeepingStatus.needsCleaning =>
                                      const Color(0xFFDC2626),
                                    HousekeepingStatus.cleaning => const Color(
                                      0xFFB45309,
                                    ),
                                    HousekeepingStatus.maintenance =>
                                      const Color(0xFF7C3AED),
                                  },
                                ),
                            ],
                          ),
                        ),
                        if (room.active)
                          PopupMenuButton<HousekeepingStatus>(
                            tooltip: 'Cập nhật vệ sinh',
                            onSelected: (status) {
                              try {
                                ref
                                    .read(changesProvider.notifier)
                                    .setHousekeeping(room.id, status);
                              } on BookingException catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.message)),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              for (final status in HousekeepingStatus.values)
                                PopupMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.more_vert),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
