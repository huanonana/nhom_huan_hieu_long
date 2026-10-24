import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../booking/domain/booking.dart';
import '../domain/finance_entry.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  late DateTime _month = DateTime(
    vietnamToday(DateTime.now()).year,
    vietnamToday(DateTime.now()).month,
  );

  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final entries = ref.watch(financeEntriesProvider);
    final hostBookings = repo.bookings.toList();
    final bookings =
        hostBookings
            .where(
              (booking) => booking.payments.any(
                (payment) =>
                    payment.paidAt.year == _month.year &&
                    payment.paidAt.month == _month.month,
              ),
            )
            .toList()
          ..sort(
            (a, b) => b.payments.last.paidAt.compareTo(a.payments.last.paidAt),
          );
    final monthEntries =
        entries
            .where(
              (entry) =>
                  entry.date.year == _month.year &&
                  entry.date.month == _month.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final revenue = bookings.fold<int>(
      0,
      (sum, booking) =>
          sum +
          booking.payments
              .where(
                (payment) =>
                    payment.paidAt.year == _month.year &&
                    payment.paidAt.month == _month.month,
              )
              .fold<int>(
                0,
                (paymentSum, payment) => paymentSum + payment.amount,
              ),
    );
    final roomPerformance = calculateRoomPerformance(
      month: _month,
      asOf: DateTime.now(),
      bookings: hostBookings,
    );
    final receivables = hostBookings
        .where(
          (booking) => !{
            BookingStatus.cancelled,
            BookingStatus.rejected,
            BookingStatus.expired,
          }.contains(booking.status),
        )
        .fold<int>(0, (sum, booking) => sum + booking.outstandingAmount);
    final expenses = monthEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final payables = monthEntries
        .where((entry) => entry.status == FinanceEntryStatus.pending)
        .fold<int>(0, (sum, entry) => sum + entry.amount);
    final roomNights = roomPerformance.roomNights;
    final roomCount = repo.rooms.where((room) => room.active).length;
    final availableRoomNights =
        roomCount * DateUtils.getDaysInMonth(_month.year, _month.month);
    final summary = FinanceSummary(
      revenue: revenue,
      expenses: expenses,
      stayRevenue: roomPerformance.revenue,
      bookingCount: bookings.length,
      roomNights: roomNights,
      availableRoomNights: availableRoomNights,
    );
    final trendMonths = List.generate(
      7,
      (index) => DateTime(_month.year, _month.month - 6 + index),
    );
    final trendRevenue = trendMonths
        .map(
          (month) => hostBookings
              .expand((booking) => booking.payments)
              .where(
                (payment) =>
                    payment.paidAt.year == month.year &&
                    payment.paidAt.month == month.month,
              )
              .fold<int>(0, (sum, payment) => sum + payment.amount),
        )
        .toList();
    final trendExpenses = trendMonths
        .map(
          (month) => entries
              .where(
                (entry) =>
                    entry.date.year == month.year &&
                    entry.date.month == month.month,
              )
              .fold<int>(0, (sum, entry) => sum + entry.amount),
        )
        .toList();
    final width = MediaQuery.sizeOf(context).width;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tài chính',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Theo dõi doanh thu, chi phí và hiệu quả khai thác phòng.',
          style: TextStyle(color: muted),
        ),
      ],
    );
    final addExpenseButton = FilledButton.icon(
      onPressed: () => _addExpense(context),
      icon: const Icon(Icons.add),
      label: const Text('Thêm khoản chi'),
    );
    final contentWidth = width >= 900
        ? (width - 256).clamp(0.0, 1260.0)
        : width;
    final columns = contentWidth >= 1050
        ? 4
        : contentWidth >= 620
        ? 2
        : 1;
    final cardWidth = (contentWidth - 48 - (columns - 1) * 12) / columns;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1260),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              children: [
                if (width < 600) ...[
                  titleBlock,
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: addExpenseButton),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: 20),
                      addExpenseButton,
                    ],
                  ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Tháng trước',
                          onPressed: () => setState(
                            () => _month = DateTime(
                              _month.year,
                              _month.month - 1,
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _monthLabel(_month),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tháng sau',
                          onPressed: _isCurrentMonth
                              ? null
                              : () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month + 1,
                                  ),
                                ),
                          icon: const Icon(Icons.chevron_right),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _month = DateTime.now()),
                          child: const Text('Tháng này'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FinanceMetric(
                      width: cardWidth,
                      title: 'Tiền đã thu',
                      value: _money(summary.revenue),
                      caption:
                          '${summary.bookingCount} đơn có giao dịch trong tháng',
                      icon: Icons.south_west_rounded,
                      color: const Color(0xFF059669),
                    ),
                    _FinanceMetric(
                      width: cardWidth,
                      title: 'Chi phí vận hành',
                      value: _money(summary.expenses),
                      caption: '${monthEntries.length} khoản đã ghi nhận',
                      icon: Icons.north_east_rounded,
                      color: const Color(0xFFEA8A16),
                    ),
                    _FinanceMetric(
                      width: cardWidth,
                      title: 'Thu sau chi',
                      value: _money(summary.netRevenue),
                      caption: 'Tiền đã thu trừ chi phí đã ghi nhận',
                      icon: Icons.account_balance_wallet_outlined,
                      color: brand,
                    ),
                    _FinanceMetric(
                      width: cardWidth,
                      title: 'Chưa thu',
                      value: _money(receivables),
                      caption: 'Số dư trên các đơn đang mở',
                      icon: Icons.pending_actions_outlined,
                      color: const Color(0xFFDC2626),
                    ),
                    _FinanceMetric(
                      width: cardWidth,
                      title: 'Khoản chi chưa trả',
                      value: _money(payables),
                      caption: 'Công nợ nhà cung cấp trong kỳ',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFFB45309),
                    ),
                    _FinanceMetric(
                      width: cardWidth,
                      title: 'Công suất · ADR',
                      value:
                          '${(summary.occupancy * 100).toStringAsFixed(1)}% · ${_money(summary.averageDailyRate)}',
                      caption:
                          'Đã phát sinh ${_money(roomPerformance.revenue)} · RevPAR ${_money(summary.revPar)} · ${summary.roomNights} đêm phòng',
                      icon: Icons.hotel_class_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FinanceTrendCard(
                  months: trendMonths,
                  revenue: trendRevenue,
                  expenses: trendExpenses,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Doanh thu đã ghi nhận',
                  subtitle:
                      'Ghi theo ngày admin xác nhận đã nhận tiền. Giao dịch thanh toán được nhập từ chi tiết đơn.',
                  trailing: Text(
                    '${bookings.length} đơn',
                    style: const TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: bookings.isEmpty
                      ? const _EmptyLine(
                          text: 'Tháng này chưa có đơn hoàn tất.',
                        )
                      : Column(
                          children: [
                            for (final booking in bookings)
                              _FinanceRow(
                                icon: Icons.bed_outlined,
                                title:
                                    '${booking.roomName} · ${booking.guestName}',
                                subtitle:
                                    'Mã ${booking.id} · ${booking.payments.where((p) => p.paidAt.year == _month.year && p.paidAt.month == _month.month).length} giao dịch · ${_shortDate(booking.payments.last.paidAt)}',
                                amount: booking.payments
                                    .where(
                                      (p) =>
                                          p.paidAt.year == _month.year &&
                                          p.paidAt.month == _month.month,
                                    )
                                    .fold<int>(0, (sum, p) => sum + p.amount),
                                amountColor: const Color(0xFF059669),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Chi phí vận hành',
                  subtitle:
                      'Các khoản chi được lưu trên thiết bị này và dùng để tính doanh thu ròng.',
                  trailing: TextButton.icon(
                    onPressed: () => _addExpense(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ghi chi phí'),
                  ),
                  child: monthEntries.isEmpty
                      ? const _EmptyLine(
                          text:
                              'Chưa có chi phí nào trong kỳ. Thêm chi phí vệ sinh, điện nước, sửa chữa hoặc khoản khác để theo dõi lãi ròng.',
                        )
                      : Column(
                          children: [
                            for (final entry in monthEntries)
                              _FinanceRow(
                                icon: _categoryIcon(entry.category),
                                title: entry.title,
                                subtitle:
                                    '${entry.category} · ${entry.status.label} · ${_shortDate(entry.date)}${entry.note.isEmpty ? '' : ' · ${entry.note}'}',
                                amount: entry.amount,
                                amountColor: const Color(0xFFEA8A16),
                                onToggleStatus: () =>
                                    ref
                                        .read(financeEntriesProvider.notifier)
                                        .state = entries
                                        .map(
                                          (item) => item.id == entry.id
                                              ? item.withStatus(
                                                  entry.status ==
                                                          FinanceEntryStatus
                                                              .paid
                                                      ? FinanceEntryStatus
                                                            .pending
                                                      : FinanceEntryStatus.paid,
                                                )
                                              : item,
                                        )
                                        .toList(),
                                onDelete: () =>
                                    ref
                                        .read(financeEntriesProvider.notifier)
                                        .state = entries
                                        .where((item) => item.id != entry.id)
                                        .toList(),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFEEF2FF),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: brand),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Báo cáo hiện lưu offline trên thiết bị. Doanh thu là các giao dịch admin ghi nhận thủ công; chi phí được nhập thủ công. Chưa có kết nối cổng thanh toán, đối soát ngân hàng hoặc hóa đơn điện tử.',
                            style: TextStyle(
                              color: Color(0xFF3730A3),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (width < 900) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/host'),
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text('Về tổng quan'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isCurrentMonth =>
      _month.year == DateTime.now().year &&
      _month.month == DateTime.now().month;

  Future<void> _addExpense(BuildContext context) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    const categories = [
      'Vệ sinh',
      'Điện nước',
      'Sửa chữa',
      'Vật tư',
      'Nhân sự',
      'Khác',
    ];
    var category = categories.first;
    var status = FinanceEntryStatus.paid;
    final result = await showDialog<FinanceEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ghi nhận chi phí'),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 128).clamp(180.0, 420.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Tên khoản chi',
                      hintText: 'Ví dụ: Vệ sinh phòng',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền (₫)',
                      hintText: '250000',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: categories
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(
                      () => category = value ?? categories.first,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FinanceEntryStatus>(
                    isExpanded: true,
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Tình trạng thanh toán',
                    ),
                    items: FinanceEntryStatus.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(
                      () => status = value ?? FinanceEntryStatus.paid,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(
                  amount.text.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (title.text.trim().isEmpty || parsed == null || parsed <= 0)
                  return;
                Navigator.pop(
                  dialogContext,
                  FinanceEntry(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: title.text.trim(),
                    category: category,
                    amount: parsed,
                    date: DateTime(
                      _month.year,
                      _month.month,
                      DateTime.now().day
                          .clamp(
                            1,
                            DateUtils.getDaysInMonth(_month.year, _month.month),
                          )
                          .toInt(),
                    ),
                    note: note.text.trim(),
                    status: status,
                  ),
                );
              },
              child: const Text('Lưu khoản chi'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      title.dispose();
      amount.dispose();
      note.dispose();
    });
    if (result != null && mounted) {
      ref.read(financeEntriesProvider.notifier).state = [
        ...ref.read(financeEntriesProvider),
        result,
      ];
    }
  }
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({
    required this.width,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });
  final double width;
  final String title, value, caption;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: .1),
                  child: Icon(icon, color: color, size: 19),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: muted.withValues(alpha: .7)),
              ],
            ),
            const SizedBox(height: 17),
            Text(title, style: const TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FinanceTrendCard extends StatelessWidget {
  const _FinanceTrendCard({
    required this.months,
    required this.revenue,
    required this.expenses,
  });

  final List<DateTime> months;
  final List<int> revenue;
  final List<int> expenses;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      ...revenue,
      ...expenses,
    ].fold<int>(0, (max, value) => value > max ? value : max);
    final chartMax = maxValue == 0 ? 1000000.0 : maxValue * 1.25;
    final interval = chartMax / 4;

    return _SectionCard(
      title: 'Xu hướng thu · chi',
      subtitle: 'Dòng tiền ghi nhận trong 7 tháng gần nhất',
      trailing: Wrap(
        spacing: 12,
        children: [
          _TrendLegend(label: 'Thu', color: const Color(0xFF059669)),
          _TrendLegend(label: 'Chi', color: const Color(0xFFEA8A16)),
        ],
      ),
      child: SizedBox(
        height: 210,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (months.length - 1).toDouble(),
            minY: 0,
            maxY: chartMax,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) => spots
                    .map(
                      (spot) => LineTooltipItem(
                        '${months[spot.x.round()].monthLabel}\n${_money(spot.y.round())}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
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
                  reservedSize: 38,
                  interval: interval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 5,
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
                    if (index < 0 || index >= months.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 6,
                      child: Text(
                        'T${months[index].month}',
                        style: const TextStyle(color: muted, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              _trendLine(revenue, const Color(0xFF059669)),
              _trendLine(expenses, const Color(0xFFEA8A16)),
            ],
          ),
          duration: const Duration(milliseconds: 260),
        ),
      ),
    );
  }

  LineChartBarData _trendLine(List<int> values, Color color) =>
      LineChartBarData(
        spots: [
          for (var index = 0; index < values.length; index++)
            FlSpot(index.toDouble(), values[index].toDouble()),
        ],
        isCurved: false,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      );
}

class _TrendLegend extends StatelessWidget {
  const _TrendLegend({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: muted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    ],
  );
}

extension on DateTime {
  String get monthLabel => 'Tháng $month';
}

String _compactMoney(double value) {
  if (value >= 1000000) {
    final millions = value / 1000000;
    return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}tr';
  }
  if (value >= 1000) return '${(value / 1000).round()}k';
  return value.round().toString();
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title, subtitle;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    this.onDelete,
    this.onToggleStatus,
  });
  final IconData icon;
  final String title, subtitle;
  final int amount;
  final Color amountColor;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFF1F5F9),
          child: Icon(icon, size: 18, color: muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _money(amount),
          style: TextStyle(fontWeight: FontWeight.w800, color: amountColor),
        ),
        if (onDelete != null)
          IconButton(
            tooltip: 'Đổi tình trạng thanh toán',
            onPressed: onToggleStatus,
            icon: const Icon(
              Icons.published_with_changes_outlined,
              size: 19,
              color: muted,
            ),
          ),
        if (onDelete != null)
          IconButton(
            tooltip: 'Xóa khoản chi',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 19, color: muted),
          ),
      ],
    ),
  );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(text, style: const TextStyle(color: muted)),
  );
}

IconData _categoryIcon(String category) => switch (category) {
  'Vệ sinh' => Icons.cleaning_services_outlined,
  'Điện nước' => Icons.bolt_outlined,
  'Sửa chữa' => Icons.build_outlined,
  'Vật tư' => Icons.inventory_2_outlined,
  'Nhân sự' => Icons.groups_outlined,
  _ => Icons.receipt_long_outlined,
};

String _monthLabel(DateTime date) =>
    'Tháng ${date.month.toString().padLeft(2, '0')}/${date.year}';
String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String _money(int value) =>
    '${value < 0 ? '-' : ''}${value.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} ₫';
