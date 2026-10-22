import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/demo_auth_repository.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../booking/domain/booking.dart';

String _displayNameForGuest(
  String guestId,
  List<Booking> stays,
  Object authRepository,
) {
  if (authRepository is DemoAuthRepository) {
    final accountName = authRepository.userByUid(guestId)?.displayName.trim();
    if (accountName != null && accountName.isNotEmpty) return accountName;
  }
  const genericNames = {'', 'khách', 'khách trải nghiệm'};
  for (final stay in stays) {
    final name = stay.guestName.trim();
    if (!genericNames.contains(name.toLowerCase()) &&
        !name.toLowerCase().startsWith('dữ liệu demo')) {
      return name;
    }
  }
  return stays.first.guestName;
}

class GuestDirectoryPage extends ConsumerStatefulWidget {
  const GuestDirectoryPage({super.key});
  @override
  ConsumerState<GuestDirectoryPage> createState() => _GuestDirectoryPageState();
}

class _GuestDirectoryPageState extends ConsumerState<GuestDirectoryPage> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final repository = ref.watch(repositoryProvider);
    final authRepository = ref.watch(authRepositoryProvider);
    final staysByGuest = <String, List<Booking>>{};
    for (final booking in repository.bookings.where(
      (item) => item.hostId == 'host-demo',
    )) {
      staysByGuest.putIfAbsent(booking.guestId, () => []).add(booking);
    }
    final query = _search.text.trim().toLowerCase();
    final guests =
        staysByGuest.entries.where((entry) {
          entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final latest = entry.value.first;
          final displayName = _displayNameForGuest(
            entry.key,
            entry.value,
            authRepository,
          );
          return query.isEmpty ||
              '$displayName ${latest.guestPhone} ${entry.key}'
                  .toLowerCase()
                  .contains(query);
        }).toList()..sort(
          (a, b) => b.value
              .map((item) => item.createdAt)
              .reduce((x, y) => x.isAfter(y) ? x : y)
              .compareTo(
                a.value
                    .map((item) => item.createdAt)
                    .reduce((x, y) => x.isAfter(y) ? x : y),
              ),
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Khách hàng',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${staysByGuest.length} hồ sơ từ lịch sử đặt phòng',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm theo tên, số điện thoại hoặc mã khách',
                ),
              ),
              const SizedBox(height: 14),
              if (guests.isEmpty)
                const EmptyState(
                  'Chưa có khách phù hợp. Hồ sơ khách sẽ tự tổng hợp từ các đơn đặt.',
                ),
              for (final guest in guests)
                Builder(
                  builder: (context) {
                    final stays = guest.value
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final completed = stays
                        .where(
                          (stay) => stay.status == BookingStatus.checkedOut,
                        )
                        .toList();
                    final spent = stays.fold<int>(
                      0,
                      (sum, stay) => sum + stay.paidAmount,
                    );
                    final outstanding = stays
                        .where(
                          (stay) => !{
                            BookingStatus.cancelled,
                            BookingStatus.rejected,
                            BookingStatus.expired,
                          }.contains(stay.status),
                        )
                        .fold<int>(
                          0,
                          (sum, stay) => sum + stay.outstandingAmount,
                        );
                    final first = stays.first;
                    final displayName = _displayNameForGuest(
                      guest.key,
                      stays,
                      authRepository,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: Text(
                            displayName.isEmpty
                                ? '?'
                                : displayName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: brand,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${first.guestPhone.isEmpty ? 'Chưa có số điện thoại' : first.guestPhone} · ${stays.length} lượt đặt',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _GuestStat(
                                label: 'Đã hoàn tất',
                                value: '${completed.length} lượt',
                              ),
                              _GuestStat(
                                label: 'Đã thanh toán',
                                value: money(spent),
                              ),
                              _GuestStat(
                                label: 'Công nợ đơn mở',
                                value: money(outstanding),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          for (final review in repository.reviews.where(
                            (review) => stays.any(
                              (stay) => stay.id == review.bookingId,
                            ),
                          ))
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFEA8A16),
                              ),
                              title: Text(
                                '${review.rating}/5 · ${review.comment}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Đánh giá ${review.createdAt.day.toString().padLeft(2, '0')}/${review.createdAt.month.toString().padLeft(2, '0')}/${review.createdAt.year}',
                              ),
                            ),
                          for (final stay in stays.take(8))
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.hotel_outlined),
                              title: Text('${stay.id} · ${stay.roomName}'),
                              subtitle: Text(
                                '${dateLabel(stay.checkIn)} – ${dateLabel(stay.checkOut)} · ${stay.status.label}',
                              ),
                              trailing: Text(
                                money(stay.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const Text(
                            'Hồ sơ được tổng hợp từ đơn demo trên thiết bị; chưa đồng bộ CRM đa thiết bị.',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestStat extends StatelessWidget {
  const _GuestStat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
