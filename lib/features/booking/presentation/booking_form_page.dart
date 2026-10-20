import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/common.dart';
import '../domain/booking.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../../core/theme/app_theme.dart';

class BookingFormPage extends ConsumerStatefulWidget {
  const BookingFormPage({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends ConsumerState<BookingFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Khách trải nghiệm');
  final _note = TextEditingController();
  DateTimeRange? _dates;
  int _guests = 1;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final search = ref.read(staySearchProvider);
    _dates = search.dates;
    final room = ref
        .read(repositoryProvider)
        .rooms
        .where((r) => r.id == widget.roomId)
        .firstOrNull;
    _guests = search.guests.clamp(1, room?.capacity ?? 1);
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final today = vietnamToday(ref.read(repositoryProvider).now);
    final result = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _dates,
      helpText: 'Ngày nhận và trả phòng',
    );
    if (result != null && mounted) setState(() => _dates = result);
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_dates == null) {
      showError(context, 'Vui lòng chọn ngày ở.');
      return;
    }
    final room = ref
        .read(repositoryProvider)
        .rooms
        .where((r) => r.id == widget.roomId)
        .firstOrNull;
    if (room == null) {
      showError(context, 'Phòng không còn tồn tại.');
      return;
    }
    setState(() => _busy = true);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kiểm tra chuyến đi'),
        content: Text(
          '${room.name}\n${dateLabel(_dates!.start)} → ${dateLabel(_dates!.end)}\n$_guests khách • ${_dates!.duration.inDays} đêm\nTổng cộng: ${money(room.price * _dates!.duration.inDays)}\n\nThanh toán tại homestay. Yêu cầu cần chủ nhà xác nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chỉnh sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (agreed != true) {
      setState(() => _busy = false);
      return;
    }
    try {
      ref
          .read(changesProvider.notifier)
          .book(
            roomId: widget.roomId,
            name: _name.text,
            start: _dates!.start,
            end: _dates!.end,
            guests: _guests,
            note: _note.text,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu. Chủ nhà sẽ duyệt trong 24 giờ.'),
        ),
      );
      context.go('/bookings');
    } on BookingException catch (error) {
      showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final matches = repo.rooms.where((r) => r.id == widget.roomId);
    if (matches.isEmpty) return const EmptyState('Không tìm thấy phòng.');
    final room = matches.single;
    final nights = _dates == null
        ? 0
        : stayDate(_dates!.end).difference(stayDate(_dates!.start)).inDays;
    final validDates = nights >= 1 && nights <= 30;
    final available =
        _dates == null || repo.available(room, _dates!.start, _dates!.end);
    return PageBody(
      maxWidth: 680,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/homestays/${room.homestayId}'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Chi tiết homestay'),
          ),
        ),
        Text(
          'Hoàn tất đặt phòng',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text('${room.name} · Tối đa ${room.capacity} khách'),
        const SizedBox(height: 16),
        StayPhoto(room.homestayId, height: 160),
        const SizedBox(height: 16),
        const Text(
          '01  THÔNG TIN CHUYẾN ĐI',
          style: TextStyle(
            color: brand,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Tên khách nhận phòng',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nhập tên khách.' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _dates == null
                      ? 'Chọn ngày nhận / trả phòng'
                      : '${dateLabel(_dates!.start)} – ${dateLabel(_dates!.end)}',
                ),
              ),
              if (_dates != null && !validDates)
                const Text(
                  'Chọn từ 1 đến 30 đêm.',
                  style: TextStyle(color: Colors.red),
                ),
              if (!available)
                const Text(
                  'Phòng không còn trống trong khoảng ngày đã chọn.',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _guests,
                decoration: const InputDecoration(labelText: 'Số khách'),
                items: [
                  for (var i = 1; i <= room.capacity; i++)
                    DropdownMenuItem(value: i, child: Text('$i khách')),
                ],
                onChanged: (v) => setState(() => _guests = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi phí lưu trú',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text('${money(room.price)} × ${validDates ? nights : '—'} đêm'),
                const Divider(),
                Text(
                  validDates
                      ? 'Tổng cộng: ${money(room.price * nights)}'
                      : 'Chọn ngày để xem tổng tiền',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không phụ phí trong bản thử. Thanh toán tại homestay. '
                  'Đơn chờ giữ phòng tối đa 24 giờ; bạn có thể hủy khi chưa được duyệt.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy || !available || !validDates ? null : _submit,
          icon: const Icon(Icons.check),
          label: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('Xác nhận yêu cầu đặt phòng'),
          ),
        ),
      ],
    );
  }
}
