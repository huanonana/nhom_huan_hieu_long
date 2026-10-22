import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/common.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/booking.dart';
import '../../homestay/domain/catalog.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/domain/app_user.dart';
import 'checkin_qr.dart';
import 'booking_status_badge.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});
  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  BookingStatus? _filter;
  final _search = TextEditingController();
  String _dateWindow = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
          .addReview(
            booking.id,
            rating,
            comment.text,
            actorId:
                ref.read(currentUserProvider).valueOrNull?.uid ?? 'guest-demo',
          );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu đánh giá của bạn.')));
    } on BookingException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      comment.dispose();
    }
  }

  void _bookAgain(Booking booking) {
    final repo = ref.read(repositoryProvider);
    final today = vietnamToday(repo.now);
    final candidates =
        repo.rooms
            .where(
              (room) =>
                  room.homestayId == booking.homestayId &&
                  room.active &&
                  room.capacity >= booking.guests,
            )
            .toList()
          ..sort((a, b) {
            if (a.id == booking.roomId) return -1;
            if (b.id == booking.roomId) return 1;
            return 0;
          });
    for (var offset = 1; offset <= 180; offset++) {
      final start = today.add(Duration(days: offset));
      final end = start.add(const Duration(days: 1));
      for (final room in candidates) {
        if (repo.available(room, start, end)) {
          ref.read(staySearchProvider.notifier).state = StaySearch(
            dates: DateTimeRange(start: start, end: end),
            guests: booking.guests,
          );
          context.push('/book/${room.id}?back=/bookings');
          return;
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chưa tìm thấy ngày trống trong 6 tháng tới cho nơi này.',
        ),
      ),
    );
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
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      ref
          .read(changesProvider.notifier)
          .transition(
            booking.id,
            target,
            role,
            actorId:
                role == DemoRole.guest && currentUser?.role == AppUserRole.guest
                ? currentUser!.uid
                : null,
          );
    } on BookingException catch (e) {
      showError(context, e);
    }
  }

  Future<void> _recordPayment(Booking booking) async {
    final amount = TextEditingController(
      text: booking.outstandingAmount.toString(),
    );
    final note = TextEditingController();
    const methods = ['Tiền mặt', 'Chuyển khoản', 'Thẻ / POS'];
    var method = methods.first;
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: const Text('Ghi nhận thanh toán'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đơn ${booking.id} · Còn phải thu ${money(booking.outstandingAmount)}',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền nhận (₫)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(
                    labelText: 'Hình thức nhận',
                  ),
                  items: methods
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      update(() => method = value ?? methods.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Mã giao dịch / ghi chú (tùy chọn)',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ghi nhận thủ công, không gọi cổng thanh toán.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Lưu giao dịch'),
              ),
            ],
          ),
        ),
      );
      if (submitted != true || !mounted) return;
      final parsed = int.tryParse(
        amount.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (parsed == null) throw const BookingException('Nhập số tiền hợp lệ.');
      ref
          .read(changesProvider.notifier)
          .recordPayment(
            booking.id,
            amount: parsed,
            method: method,
            note: note.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ghi nhận giao dịch thanh toán.')),
        );
      }
    } on BookingException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      amount.dispose();
      note.dispose();
    }
  }

  Future<void> _showReceipt(Booking booking) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phiếu lưu trú'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HHL Stay · ${booking.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Divider(height: 24),
                _receiptLine('Khách lưu trú', booking.guestName),
                _receiptLine('Phòng', booking.roomName),
                _receiptLine(
                  'Thời gian',
                  '${dateLabel(booking.checkIn)} – ${dateLabel(booking.checkOut)} · ${booking.nights} đêm',
                ),
                _receiptLine('Tạm tính', money(booking.subtotal)),
                _receiptLine('Ưu đãi', '- ${money(booking.discountAmount)}'),
                _receiptLine(
                  'Tổng thanh toán',
                  money(booking.total),
                  emphasized: true,
                ),
                _receiptLine('Đã nhận', money(booking.paidAmount)),
                _receiptLine(
                  'Còn phải thu',
                  money(booking.outstandingAmount),
                  emphasized: true,
                ),
                if (booking.payments.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Lịch sử giao dịch',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  for (final payment in booking.payments)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${dateLabel(payment.paidAt.toLocal())} · ${payment.method} · ${money(payment.amount)}${payment.note.isEmpty ? '' : '\n${payment.note}'}',
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Phiếu xem trước của bản demo, không thay thế hóa đơn điện tử hoặc chứng từ thuế.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final role = ref.watch(roleProvider);
    final host = role == DemoRole.host;
    final repo = ref.watch(repositoryProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final guestId = currentUser?.role == AppUserRole.guest
        ? currentUser!.uid
        : 'guest-demo';
    final query = _search.text.trim().toLowerCase();
    final cutoff = _dateWindow == '30'
        ? repo.now.subtract(const Duration(days: 30))
        : _dateWindow == '90'
        ? repo.now.subtract(const Duration(days: 90))
        : null;
    final bookings = repo.bookings
        .where(
          (b) =>
              (host ? b.hostId == 'host-demo' : b.guestId == guestId) &&
              (_filter == null || b.effectiveStatus(repo.now) == _filter) &&
              (query.isEmpty ||
                  '${b.guestName} ${b.id} ${b.roomName}'.toLowerCase().contains(
                    query,
                  )) &&
              (cutoff == null || !b.createdAt.isBefore(cutoff)),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: compact ? constraints.maxWidth : 340,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Tìm khách hoặc mã đơn',
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: compact ? constraints.maxWidth : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _filter?.name ?? 'all',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Tất cả trạng thái'),
                      ),
                      for (final status in BookingStatus.values)
                        DropdownMenuItem(
                          value: status.name,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: (value) => setState(
                      () => _filter = value == null || value == 'all'
                          ? null
                          : BookingStatus.values.byName(value),
                    ),
                  ),
                ),
                SizedBox(
                  width: compact ? constraints.maxWidth : 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: _dateWindow,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian tạo',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Tất cả thời gian'),
                      ),
                      DropdownMenuItem(value: '30', child: Text('30 ngày qua')),
                      DropdownMenuItem(value: '90', child: Text('90 ngày qua')),
                    ],
                    onChanged: (value) =>
                        setState(() => _dateWindow = value ?? 'all'),
                  ),
                ),
              ],
            );
          },
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
                  !today.isBefore(b.checkIn) &&
                  today.isBefore(b.checkOut) &&
                  repo.rooms
                          .where((room) => room.id == b.roomId)
                          .firstOrNull
                          ?.housekeepingStatus ==
                      HousekeepingStatus.ready;
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
                      Text(
                        'Đã nhận ${money(b.paidAmount)} · Còn thu ${money(b.outstandingAmount)}',
                        style: TextStyle(
                          color: b.isPaid
                              ? const Color(0xFF16835D)
                              : const Color(0xFFB56A14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (b.discountAmount > 0)
                        Text(
                          'Đã giảm ${money(b.discountAmount)} (${b.discountPercent}%)'
                          '${b.couponCode.isEmpty ? '' : ' · mã ${b.couponCode}'}',
                          style: const TextStyle(
                            color: Color(0xFF16835D),
                            fontWeight: FontWeight.w600,
                          ),
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
                          OutlinedButton.icon(
                            onPressed: () => _showReceipt(b),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Phiếu lưu trú'),
                          ),
                          if (host &&
                              b.outstandingAmount > 0 &&
                              status != BookingStatus.cancelled &&
                              status != BookingStatus.rejected &&
                              status != BookingStatus.expired)
                            FilledButton.tonalIcon(
                              onPressed: () => _recordPayment(b),
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Ghi thanh toán'),
                            ),
                          if (!host && status == BookingStatus.pending)
                            OutlinedButton(
                              onPressed: () =>
                                  _act(b, BookingStatus.cancelled, role),
                              child: const Text('Hủy yêu cầu'),
                            ),
                          if (!host &&
                              status == BookingStatus.confirmed &&
                              repo.now.isBefore(
                                b.checkIn.subtract(const Duration(hours: 24)),
                              ))
                            OutlinedButton(
                              onPressed: () =>
                                  _act(b, BookingStatus.cancelled, role),
                              child: const Text('Hủy phòng miễn phí'),
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
                          if (!host &&
                              status != BookingStatus.pending &&
                              status != BookingStatus.confirmed &&
                              status != BookingStatus.checkedIn)
                            OutlinedButton.icon(
                              onPressed: () => _bookAgain(b),
                              icon: const Icon(Icons.replay_rounded),
                              label: const Text('Đặt lại'),
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
                                    'Chỉ xuất trình mã này cho chủ nhà khi nhận phòng. Có thể hủy miễn phí trước giờ nhận phòng 24 giờ.',
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

Widget _receiptLine(String label, String value, {bool emphasized = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
