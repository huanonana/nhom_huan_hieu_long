import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/staff_member.dart';
import '../domain/staff_shift.dart';

class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});
  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> {
  late DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allShifts = ref.watch(staffShiftsProvider);
    final allStaff = ref.watch(staffMembersProvider);
    final activeStaff = allStaff.where((member) => member.active).toList();
    final shifts =
        allShifts
            .where(
              (shift) =>
                  shift.date.year == _month.year &&
                  shift.date.month == _month.month,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final hours = shifts.fold<int>(0, (sum, shift) => sum + shift.hours);
    final payroll = shifts
        .where((shift) => shift.status == ShiftStatus.completed)
        .fold<int>(0, (sum, shift) => sum + shift.estimatedPay);
    final nameCount = activeStaff.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhân sự & ca làm',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Quản lý hồ sơ nhân viên, xếp ca và theo dõi chấm công.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addStaff(context),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Thêm nhân viên'),
                      ),
                      FilledButton.icon(
                        onPressed: activeStaff.isEmpty
                            ? null
                            : () => _addShift(context, activeStaff),
                        icon: const Icon(Icons.add),
                        label: const Text('Xếp ca'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month - 1),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Tháng ${_month.month.toString().padLeft(2, '0')}/${_month.year}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month + 1),
                        ),
                        icon: const Icon(Icons.chevron_right),
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
                  _StaffMetric(
                    label: 'Nhân sự có ca',
                    value: '$nameCount',
                    icon: Icons.groups_outlined,
                  ),
                  _StaffMetric(
                    label: 'Ca trong tháng',
                    value: '${shifts.length}',
                    icon: Icons.calendar_month_outlined,
                  ),
                  _StaffMetric(
                    label: 'Tổng giờ dự kiến',
                    value: '$hours giờ',
                    icon: Icons.schedule_rounded,
                  ),
                  _StaffMetric(
                    label: 'Lương ca hoàn tất',
                    value: money(payroll),
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Hồ sơ nhân viên',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (allStaff.isEmpty)
                const EmptyState(
                  'Chưa có hồ sơ nhân viên. Thêm nhân viên trước khi xếp ca.',
                ),
              for (final member in allStaff)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: member.active
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFF1F5F9),
                      child: Icon(
                        _shiftIcon(member.role),
                        color: member.active ? brand : muted,
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${member.role} · ${member.phone.isEmpty ? 'Chưa có số điện thoại' : member.phone} · ${money(member.hourlyRate)}/giờ',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        ref.read(staffMembersProvider.notifier).state = allStaff
                            .map(
                              (item) => item.id == member.id
                                  ? item.copyWith(active: action == 'activate')
                                  : item,
                            )
                            .toList();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: member.active ? 'deactivate' : 'activate',
                          child: Text(
                            member.active ? 'Ngừng hoạt động' : 'Kích hoạt lại',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'Lịch ca trong tháng',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (shifts.isEmpty)
                const EmptyState(
                  'Chưa xếp ca trong tháng này. Thêm ca để bắt đầu quản lý lịch và chấm công.',
                ),
              for (final shift in shifts)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Icon(_shiftIcon(shift.role), color: brand),
                    ),
                    title: Text(
                      shift.staffName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${shift.role} · ${_date(shift.date)} · ${_hour(shift.startHour)}–${_hour(shift.endHour)} (${shift.hours} giờ)${shift.note.isEmpty ? '' : '\n${shift.note}'}',
                    ),
                    isThreeLine: shift.note.isNotEmpty,
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Cập nhật ca',
                      onSelected: (action) {
                        if (action == 'delete') {
                          ref
                              .read(staffShiftsProvider.notifier)
                              .state = allShifts
                              .where((item) => item.id != shift.id)
                              .toList();
                        } else {
                          final status = ShiftStatus.values.byName(action);
                          ref
                              .read(staffShiftsProvider.notifier)
                              .state = allShifts
                              .map(
                                (item) => item.id == shift.id
                                    ? item.withStatus(status)
                                    : item,
                              )
                              .toList();
                        }
                      },
                      itemBuilder: (context) => [
                        for (final status in ShiftStatus.values.where(
                          (status) => status.index > shift.status.index,
                        ))
                          PopupMenuItem(
                            value: status.name,
                            child: Text(status.label),
                          ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa ca'),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ShiftBadge(status: shift.status),
                            const SizedBox(width: 8),
                            Text(
                              money(shift.estimatedPay),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Card(
                color: Color(0xFFEEF2FF),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Bản demo lưu lịch ca trên thiết bị. Lương là ước tính theo giờ xếp ca, chưa thay thế bảng lương, chấm công thực tế hoặc dữ liệu nhân sự dùng chung.',
                    style: TextStyle(color: Color(0xFF3730A3), height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addStaff(BuildContext context) async {
    final name = TextEditingController();
    final role = TextEditingController(text: 'Lễ tân');
    final phone = TextEditingController();
    final email = TextEditingController();
    final rate = TextEditingController(text: '30000');
    final result = await showDialog<StaffMember>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm hồ sơ nhân viên'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: role,
                  decoration: const InputDecoration(
                    labelText: 'Vị trí / bộ phận',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (không bắt buộc)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: rate,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lương theo giờ (₫)',
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
              final hourlyRate = int.tryParse(
                rate.text.replaceAll(RegExp(r'[^0-9]'), ''),
              );
              if (name.text.trim().isEmpty ||
                  role.text.trim().isEmpty ||
                  hourlyRate == null ||
                  hourlyRate <= 0)
                return;
              Navigator.pop(
                dialogContext,
                StaffMember(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name.text.trim(),
                  role: role.text.trim(),
                  phone: phone.text.trim(),
                  email: email.text.trim(),
                  hourlyRate: hourlyRate,
                ),
              );
            },
            child: const Text('Lưu nhân viên'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      name.dispose();
      role.dispose();
      phone.dispose();
      email.dispose();
      rate.dispose();
    });
    if (result != null && mounted) {
      final members = ref.read(staffMembersProvider);
      ref.read(staffMembersProvider.notifier).state = [...members, result];
    }
  }

  Future<void> _addShift(BuildContext context, List<StaffMember> staff) async {
    final note = TextEditingController();
    var date = DateTime(
      _month.year,
      _month.month,
      DateTime.now().day
          .clamp(1, DateUtils.getDaysInMonth(_month.year, _month.month))
          .toInt(),
    );
    var startHour = 8;
    var endHour = 16;
    var selectedStaff = staff.first;
    final result = await showDialog<StaffShift>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Xếp ca nhân sự'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<StaffMember>(
                    isExpanded: true,
                    initialValue: selectedStaff,
                    decoration: const InputDecoration(labelText: 'Nhân viên'),
                    items: [
                      for (final member in staff)
                        DropdownMenuItem(
                          value: member,
                          child: Text('${member.name} · ${member.role}'),
                        ),
                    ],
                    onChanged: (member) =>
                        update(() => selectedStaff = member ?? staff.first),
                  ),
                  const SizedBox(height: 8),
                  Text('Lương ca: ${money(selectedStaff.hourlyRate)}/giờ'),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(_month.year, _month.month),
                        lastDate: DateTime(_month.year, _month.month + 1, 0),
                      );
                      if (selected != null) update(() => date = selected);
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_date(date)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: startHour,
                          decoration: const InputDecoration(
                            labelText: 'Bắt đầu',
                          ),
                          items: [
                            for (var hour = 0; hour < 24; hour++)
                              DropdownMenuItem(
                                value: hour,
                                child: Text(_hour(hour)),
                              ),
                          ],
                          onChanged: (value) =>
                              update(() => startHour = value ?? 8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: endHour,
                          decoration: const InputDecoration(
                            labelText: 'Kết thúc',
                          ),
                          items: [
                            for (var hour = 0; hour < 24; hour++)
                              DropdownMenuItem(
                                value: hour,
                                child: Text(_hour(hour)),
                              ),
                          ],
                          onChanged: (value) =>
                              update(() => endHour = value ?? 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                if (endHour == startHour) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Thời điểm kết thúc phải khác lúc bắt đầu.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  StaffShift(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    staffId: selectedStaff.id,
                    staffName: selectedStaff.name,
                    role: selectedStaff.role,
                    date: date,
                    startHour: startHour,
                    endHour: endHour,
                    hourlyRate: selectedStaff.hourlyRate,
                    note: note.text.trim(),
                  ),
                );
              },
              child: const Text('Lưu ca'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 250), note.dispose);
    if (result != null && mounted)
      ref.read(staffShiftsProvider.notifier).state = [
        ...ref.read(staffShiftsProvider),
        result,
      ];
  }
}

class _StaffMetric extends StatelessWidget {
  const _StaffMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEEF2FF),
              child: Icon(icon, color: brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.status});
  final ShiftStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ShiftStatus.scheduled => const Color(0xFF2563EB),
      ShiftStatus.onDuty => const Color(0xFFB45309),
      ShiftStatus.completed => const Color(0xFF059669),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _shiftIcon(String role) => role.toLowerCase().contains('vệ sinh')
    ? Icons.cleaning_services_outlined
    : role.toLowerCase().contains('lễ tân')
    ? Icons.support_agent_rounded
    : Icons.work_outline_rounded;
String _hour(int hour) => '${hour.toString().padLeft(2, '0')}:00';
String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
