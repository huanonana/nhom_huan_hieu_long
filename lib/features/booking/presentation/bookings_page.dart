import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/common.dart';
import '../domain/booking.dart';
import '../../../core/widgets/stay_widgets.dart';
import 'checkin_qr.dart';
import 'booking_status_badge.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});
  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  BookingStatus? _filter;
  Future<void> _checkIn(Booking booking) async {
    final code = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xác minh mã nhận phòng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${booking.id} · ${booking.roomName}'),
              const SizedBox(height: 12),
              TextField(
                controller: code,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nội dung mã QR của khách',
                  hintText: 'HHL-STAY|...',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dùng máy khác quét QR của khách, rồi dán nội dung vào đây.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xác minh & nhận phòng'),
            ),
          ],
        ),
      );
      if (submitted != true || !mounted) return;
      ref.read(changesProvider.notifier).verifyCheckIn(booking.id, code.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác minh mã và nhận phòng.')),
      );
    } on BookingException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      code.dispose();
    }
  }

  Future<void> _review(Booking booking) async {
    var rating = 0;
    final comment = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: const Text('Đánh giá chuyến đi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.roomName),
                  const SizedBox(height: 12),
                  const Text('Trải nghiệm của bạn thế nào?'),
                  Wrap(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          tooltip: '$i sao',
                          onPressed: () => update(() => rating = i),
                          icon: Icon(
                            i <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                          ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: comment,
                    maxLength: 500,
                    maxLines: 3,
                    onChanged: (_) => update(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Chia sẻ cảm nhận sau khi ở',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Để sau'),
              ),
              FilledButton(
                onPressed: rating > 0 && comment.text.trim().isNotEmpty
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Gửi đánh giá'),
              ),
            ],
          ),
        ),
      );
      if (submitted != true || !mounted) return;
      ref
          .read(changesProvider.notifier)
          .addReview(booking.id, rating, comment.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu đánh giá của bạn.')));
    } on BookingException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      comment.dispose();
    }
  }

  Future<void> _act(
    Booking booking,
    BookingStatus target,
    DemoRole role,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chuyển đơn sang “${target.label}”?'),
        content: Text(
          '${booking.id} · ${booking.roomName}\n${booking.guestName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      ref.read(changesProvider.notifier).transition(booking.id, target, role);
    } on BookingException catch (e) {
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final role = ref.watch(roleProvider);
    final host = role == DemoRole.host;
    final repo = ref.watch(repositoryProvider);
    final bookings = repo.bookings
        .where(
          (b) =>
              (host ? b.hostId == 'host-demo' : b.guestId == 'guest-demo') &&
              (_filter == null || b.effectiveStatus(repo.now) == _filter),
        )
        .toList()
        .reversed;
    return PageBody(
      children: [
        Text(
          host ? 'Quản lý đơn đặt phòng' : 'Chuyến đi của bạn',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          host
              ? 'Duyệt yêu cầu và theo dõi khách lưu trú.'
              : 'Theo dõi yêu cầu và lịch lưu trú ở một nơi.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final s in BookingStatus.values)
              ChoiceChip(
                label: Text(s.label),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (bookings.isEmpty)
          const EmptyState('Chưa có đơn trong danh sách này.'),
        for (final b in bookings)
          Builder(
            builder: (context) {
              final status = b.effectiveStatus(repo.now);
              final today = vietnamToday(repo.now);
              final checkInAllowed =
                  !today.isBefore(b.checkIn) && today.isBefore(b.checkOut);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StayPhoto(b.homestayId, height: 140),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            b.id,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          BookingStatusBadge(status: status),
                        ],
                      ),
                      Text(
                        b.roomName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${dateLabel(b.checkIn)} → ${dateLabel(b.checkOut)} · ${b.nights} đêm',
                      ),
                      Text('${b.guestName} · ${b.guests} khách'),
                      const SizedBox(height: 8),
                      Text(
                        money(b.total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text(
                        'Thanh toán tại homestay • Chưa theo dõi tiền đã thu',
                      ),
                      if (b.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Ghi chú: ${b.note}'),
                        ),
                      if (status == BookingStatus.pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Hết hạn giữ chỗ: ${dateLabel(b.expiresAt.toLocal())} '
                            '${b.expiresAt.toLocal().hour.toString().padLeft(2, '0')}:${b.expiresAt.toLocal().minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!host && status == BookingStatus.pending)
                            OutlinedButton(
                              onPressed: () =>
                                  _act(b, BookingStatus.cancelled, role),
                              child: const Text('Hủy yêu cầu'),
                            ),
                          if (host && status == BookingStatus.pending) ...[
                            FilledButton(
                              onPressed: () =>
                                  _act(b, BookingStatus.confirmed, role),
                              child: const Text('Duyệt đơn'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  _act(b, BookingStatus.rejected, role),
                              child: const Text('Từ chối'),
                            ),
                          ],
                          if (host && status == BookingStatus.confirmed)
                            FilledButton(
                              onPressed: checkInAllowed
                                  ? () => _checkIn(b)
                                  : null,
                              child: const Text('Xác minh mã & nhận phòng'),
                            ),
                          if (host && status == BookingStatus.checkedIn)
                            FilledButton(
                              onPressed: () =>
                                  _act(b, BookingStatus.checkedOut, role),
                              child: const Text('Trả phòng (demo)'),
                            ),
                          if (!host &&
                              status == BookingStatus.checkedOut &&
                              !repo.reviews.any((r) => r.bookingId == b.id))
                            FilledButton.icon(
                              onPressed: () => _review(b),
                              icon: const Icon(Icons.star_outline),
                              label: const Text('Đánh giá nơi ở'),
                            ),
                        ],
                      ),
                      if (repo.reviews
                              .where((r) => r.bookingId == b.id)
                              .firstOrNull
                          case final review?)
                        Text(
                          'Bạn đã đánh giá ${review.rating}/5 sao: ${review.comment}',
                        ),
                      if (status == BookingStatus.confirmed)
                        host
                            ? const Text(
                                'Chờ khách xuất trình QR khi đến nhận phòng.',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Mã nhận phòng của bạn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(child: CheckInQr(b.checkInCode)),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: b.checkInCode),
                                      );
                                      if (context.mounted)
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Đã sao chép mã nhận phòng.',
                                            ),
                                          ),
                                        );
                                    },
                                    icon: const Icon(Icons.copy_outlined),
                                    label: const Text('Sao chép mã'),
                                  ),
                                  const Text(
                                    'Chỉ xuất trình mã này cho chủ nhà khi nhận phòng.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
