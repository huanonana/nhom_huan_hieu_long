import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../data/demo_booking_repository.dart';
import '../../../core/router/navigation.dart';
import '../../../core/widgets/common.dart';
import '../domain/booking.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_provider.dart';

class BookingFormPage extends ConsumerStatefulWidget {
  const BookingFormPage({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends ConsumerState<BookingFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _note = TextEditingController();
  final _coupon = TextEditingController();
  DateTimeRange? _dates;
  int _guests = 1;
  bool _busy = false;
  bool _couponApplied = false;
  String? _couponMessage;
  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser?.role == AppUserRole.guest) {
      _name.text = currentUser!.displayName.trim();
    }
    final search = ref.read(staySearchProvider);
    _dates = search.dates;
    _guests = search.guests;
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _coupon.dispose();
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
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      final bookingPath = GoRouterState.of(context).uri.toString();
      context.go(
        '/login?from=${Uri.encodeComponent(bookingPath)}'
        '&back=${Uri.encodeComponent('/explore')}',
      );
      return;
    }
    if (user.role != AppUserRole.guest) {
      context.go('/host');
      return;
    }
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
    if (_guests > room.capacity) {
      showError(
        context,
        'Phòng chứa tối đa ${room.capacity} khách. Giảm số khách hoặc chọn phòng khác.',
      );
      return;
    }
    final memberDiscount = 5;
    final couponDiscount = _couponApplied ? 10 : 0;
    final discountPercent = memberDiscount + couponDiscount;
    final nights = _dates!.duration.inDays;
    final subtotal = room.price * nights;
    setState(() => _busy = true);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kiểm tra chuyến đi'),
        actionsAlignment: MainAxisAlignment.end,
        actionsOverflowAlignment: OverflowBarAlignment.end,
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 6,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: Text(
          '${room.name}\n${dateLabel(_dates!.start)} → ${dateLabel(_dates!.end)}\n$_guests khách • $nights đêm\nTiền phòng: ${money(subtotal)}'
          '${discountPercent > 0 ? '\nƯu đãi: −${money(subtotal * discountPercent ~/ 100)} ($discountPercent%)' : ''}'
          '\nTổng cộng: ${money(subtotal - subtotal * discountPercent ~/ 100)}\n\nThanh toán tại homestay. Yêu cầu cần chủ nhà xác nhận; đơn đã xác nhận được hủy miễn phí trước giờ nhận phòng 24 giờ.',
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
      final repository = ref.read(repositoryProvider);
      final beforeBooking = repository is DemoBookingRepository
          ? repository.toJson()
          : null;
      final booking = ref
          .read(changesProvider.notifier)
          .book(
            roomId: widget.roomId,
            name: _name.text,
            guestId: user.uid,
            start: _dates!.start,
            end: _dates!.end,
            guests: _guests,
            memberDiscountPercent: memberDiscount,
            couponDiscountPercent: couponDiscount,
            couponCode: _couponApplied ? _coupon.text : '',
            note: _note.text,
          );
      if (ref.read(firebaseModeProvider)) {
        try {
          await ref.read(firebaseDocumentStoreProvider)!.saveBooking(booking);
        } catch (_) {
          if (repository is DemoBookingRepository && beforeBooking != null) {
            repository.restoreFromJson(beforeBooking);
          }
          ref.read(changesProvider.notifier).refreshFromStorage();
          rethrow;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF312E81),
          content: BookingSuccessMessage(),
        ),
      );
      context.go('/bookings');
    } on BookingException catch (error) {
      showError(context, error);
    } catch (_) {
      showError(
        context,
        'Chưa lưu được đơn lên Firebase. Không tạo đơn để tránh hiển thị đặt phòng chưa đồng bộ.',
      );
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
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final memberDiscount = currentUser?.role == AppUserRole.guest ? 5 : 0;
    final couponDiscount = _couponApplied ? 10 : 0;
    final discountPercent = memberDiscount + couponDiscount;
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
            onPressed: () => navigateBack(
              context,
              fallback: '/homestays/${room.homestayId}',
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
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
        const GuidanceTile(
          steps:
              'Nhập tên khách, chọn ngày nhận và trả phòng, chọn số khách rồi kiểm tra tổng tiền trước khi gửi yêu cầu.',
        ),
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
              GuestCountStepper(
                value: _guests,
                max: room.capacity,
                onChanged: (value) => setState(() => _guests = value),
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
        if (currentUser?.role == AppUserRole.guest)
          _MemberBenefitCard(name: currentUser?.displayName ?? ''),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mã ưu đãi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _coupon,
                        textCapitalization: TextCapitalization.characters,
                        enabled: !_couponApplied,
                        decoration: const InputDecoration(
                          hintText: 'Nhập mã HHL10',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _couponApplied
                          ? () => setState(() {
                              _couponApplied = false;
                              _couponMessage = null;
                            })
                          : () => setState(() {
                              _couponApplied =
                                  _coupon.text.trim().toUpperCase() == 'HHL10';
                              _couponMessage = _couponApplied
                                  ? 'Đã áp dụng giảm 10% cho đơn demo.'
                                  : 'Mã chưa đúng. Hãy thử HHL10.';
                            }),
                      child: Text(_couponApplied ? 'Gỡ mã' : 'Áp dụng'),
                    ),
                  ],
                ),
                if (_couponMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _couponMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _couponApplied
                            ? const Color(0xFF16835D)
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Mã thử nghiệm HHL10 · có thể kết hợp ưu đãi thành viên.',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
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
                if (validDates && discountPercent > 0) ...[
                  const SizedBox(height: 8),
                  if (memberDiscount > 0)
                    Text(
                      'Thành viên · −${money(room.price * nights * memberDiscount ~/ 100)}',
                    ),
                  if (couponDiscount > 0)
                    Text(
                      'Mã HHL10 · −${money(room.price * nights * couponDiscount ~/ 100)}',
                    ),
                ],
                const Divider(),
                Text(
                  validDates
                      ? 'Tổng cộng: ${money(room.price * nights - room.price * nights * discountPercent ~/ 100)}'
                      : 'Chọn ngày để xem tổng tiền',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không phụ phí trong bản thử. Thanh toán tại homestay. '
                  'Đơn chờ giữ phòng tối đa 24 giờ; đơn đã xác nhận được hủy miễn phí trước giờ nhận phòng 24 giờ.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed:
              _busy || !available || !validDates || _guests > room.capacity
              ? null
              : _submit,
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

class _MemberBenefitCard extends StatelessWidget {
  const _MemberBenefitCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFF0FDF7),
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFD1FAE5),
        child: Icon(Icons.loyalty_outlined, color: Color(0xFF16835D)),
      ),
      title: Text(name.isEmpty ? 'Ưu đãi thành viên' : 'Chào $name'),
      subtitle: const Text('Giảm 5% tự động cho tài khoản khách đã đăng nhập.'),
      trailing: const Text(
        '−5%',
        style: TextStyle(color: Color(0xFF16835D), fontWeight: FontWeight.w800),
      ),
    ),
  );
}
