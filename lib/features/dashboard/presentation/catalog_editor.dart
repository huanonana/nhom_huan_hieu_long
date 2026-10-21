import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';
import '../../ai/data/ai_service.dart';
import '../../ai/presentation/ai_provider.dart';
import '../../booking/domain/booking.dart';
import '../../homestay/domain/catalog.dart';

Future<void> editCatalog(
  BuildContext context, {
  Homestay? home,
  Room? room,
  bool roomMode = false,
}) => showDialog<void>(
  context: context,
  builder: (_) => CatalogEditor(home: home, room: room, roomMode: roomMode),
);

class CatalogEditor extends ConsumerStatefulWidget {
  const CatalogEditor({
    super.key,
    this.home,
    this.room,
    required this.roomMode,
  });
  final Homestay? home;
  final Room? room;
  final bool roomMode;
  @override
  ConsumerState<CatalogEditor> createState() => _CatalogEditorState();
}

class _CatalogEditorState extends ConsumerState<CatalogEditor> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  late bool _active;
  bool _generatingDescription = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final h = widget.home, r = widget.room;
    _fields =
        (widget.roomMode
                ? [
                    r?.name ?? '',
                    '${r?.price ?? 650000}',
                    '${r?.capacity ?? 2}',
                  ]
                : [
                    h?.name ?? '',
                    h?.city ?? '',
                    h?.address ?? '',
                    h?.description ?? '',
                    h?.amenities.join(', ') ?? 'Wi-Fi',
                  ])
            .map((v) => TextEditingController(text: v))
            .toList();
    _active = r?.active ?? true;
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final controller = ref.read(changesProvider.notifier);
    final values = _fields.map((c) => c.text.trim()).toList();
    final id = 'custom-${DateTime.now().microsecondsSinceEpoch}';
    try {
      if (ref.read(roleProvider) != DemoRole.host)
        throw const BookingException('Hãy chuyển sang vai trò chủ nhà.');
      if (widget.roomMode) {
        controller.saveRoom(
          Room(
            id: widget.room?.id ?? id,
            homestayId: widget.home!.id,
            name: values[0],
            price: int.tryParse(values[1]) ?? 0,
            capacity: int.tryParse(values[2]) ?? 0,
            active: _active,
          ),
        );
      } else {
        controller.saveHomestay(
          Homestay(
            id: widget.home?.id ?? id,
            hostId: 'host-demo',
            name: values[0],
            city: values[1],
            address: values[2],
            description: values[3],
            amenities: values[4]
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toSet()
                .toList(),
            color: widget.home?.color ?? 0xFF2F6757,
          ),
        );
      }
      Navigator.pop(context);
    } on BookingException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _generateDescription() async {
    if (_fields[0].text.trim().isEmpty || _generatingDescription) return;
    setState(() => _generatingDescription = true);
    try {
      final amenities = _fields[4].text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      final result = await ref
          .read(aiServiceProvider)
          .generateDescription(
            _fields[0].text.trim(),
            _fields[1].text.trim(),
            amenities,
          );
      if (!mounted) return;
      if (result == AiService.unavailableMessage ||
          result == AiService.friendlyErrorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == AiService.unavailableMessage
                  ? 'Tính năng AI chưa khả dụng. Bạn có thể tự nhập mô tả.'
                  : 'Chưa thể kết nối AI. Bạn có thể tự nhập mô tả.',
            ),
          ),
        );
      } else {
        _fields[3].value = TextEditingValue(
          text: result,
          selection: TextSelection.collapsed(offset: result.length),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingDescription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.roomMode
        ? ['Tên phòng', 'Giá mỗi đêm (đ)', 'Sức chứa (khách)']
        : [
            'Tên homestay',
            'Thành phố',
            'Địa chỉ',
            'Mô tả',
            'Tiện nghi (ngăn cách bằng dấu phẩy)',
          ];
    final icons = widget.roomMode
        ? [
            Icons.bed_outlined,
            Icons.payments_outlined,
            Icons.people_alt_outlined,
          ]
        : [
            Icons.home_work_outlined,
            Icons.location_city_outlined,
            Icons.location_on_outlined,
            Icons.description_outlined,
            Icons.wifi_tethering_outlined,
          ];
    return AlertDialog(
      title: Text(
        widget.roomMode
            ? (widget.room == null ? 'Thêm phòng' : 'Sửa phòng')
            : (widget.home == null ? 'Thêm homestay' : 'Sửa homestay'),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _fields[i],
                      decoration: InputDecoration(
                        labelText: labels[i],
                        prefixIcon: Icon(icons[i]),
                      ),
                      keyboardType: widget.roomMode && i > 0
                          ? TextInputType.number
                          : TextInputType.text,
                      onChanged: !widget.roomMode && i == 0
                          ? (_) => setState(() {})
                          : null,
                      maxLength: widget.roomMode
                          ? (i == 0 ? 100 : 9)
                          : [100, 100, 300, 2000, 300][i],
                      minLines: !widget.roomMode && i == 3 ? 3 : 1,
                      maxLines: !widget.roomMode && i == 3 ? 5 : 1,
                      validator: (v) =>
                          i != 4 && (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập ${labels[i].toLowerCase()}.'
                          : null,
                    ),
                  ),
                  if (!widget.roomMode && i == 3)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: _fields[0].text.trim().isEmpty
                            ? 'Nhập tên homestay trước'
                            : 'Để AI gợi ý nội dung mô tả',
                        child: OutlinedButton.icon(
                          onPressed:
                              _fields[0].text.trim().isEmpty ||
                                  _generatingDescription
                              ? null
                              : _generateDescription,
                          icon: _generatingDescription
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _generatingDescription
                                ? 'AI đang viết…'
                                : '✨ Để AI viết giúp',
                          ),
                        ),
                      ),
                    ),
                ],
                if (widget.roomMode)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mở nhận đặt phòng'),
                    subtitle: const Text('Tắt để bảo trì phòng'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton(onPressed: _save, child: const Text('Lưu thay đổi')),
      ],
    );
  }
}

Future<void> confirmCatalogDelete(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
  bool room = false,
}) async {
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Xóa $name?'),
      content: const Text(
        'Lịch sử đơn đặt vẫn được giữ. Thao tác này không có nút hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Giữ lại'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (agreed != true || !context.mounted) return;
  try {
    if (ref.read(roleProvider) != DemoRole.host)
      throw const BookingException('Không có quyền quản lý.');
    final controller = ref.read(changesProvider.notifier);
    room ? controller.deleteRoom(id) : controller.deleteHomestay(id);
  } on BookingException catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
