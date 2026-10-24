import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/state/app_state.dart';
import '../../ai/data/ai_service.dart';
import '../../ai/domain/local_stay_assistant.dart';
import '../../ai/presentation/ai_provider.dart';
import '../../booking/domain/booking.dart';
import '../../homestay/domain/catalog.dart';
import '../../../core/widgets/stay_gallery.dart';

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
  bool _pickingImages = false;
  String? _error;
  late final List<String> _images;
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
                    if (h == null) ...['Phòng đầu tiên', '650000', '2'],
                  ])
            .map((v) => TextEditingController(text: v))
            .toList();
    _images = List<String>.from(h?.imageUrls ?? const []);
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
            housekeepingStatus:
                widget.room?.housekeepingStatus ?? HousekeepingStatus.ready,
          ),
        );
      } else {
        controller.saveHomestay(
          Homestay(
            id: widget.home?.id ?? id,
            hostId: widget.home?.hostId ?? 'host-demo',
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
            imageUrls: List<String>.from(_images),
          ),
        );
        if (widget.home == null) {
          controller.saveRoom(
            Room(
              id: '${id}-room-1',
              homestayId: id,
              name: values[5],
              price: int.tryParse(values[6]) ?? 0,
              capacity: int.tryParse(values[7]) ?? 0,
            ),
          );
        }
      }
      Navigator.pop(context);
    } on BookingException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _pickImages() async {
    if (_pickingImages) return;
    final remaining = 4 - _images.length;
    if (remaining <= 0) {
      setState(() => _error = 'Mỗi homestay có thể tải tối đa 4 ảnh.');
      return;
    }
    setState(() {
      _pickingImages = true;
      _error = null;
    });
    try {
      final selected = await ImagePicker().pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 72,
      );
      for (final image in selected.take(remaining)) {
        final bytes = await image.readAsBytes();
        final mime = image.mimeType ?? 'image/jpeg';
        _images.add('data:$mime;base64,${base64Encode(bytes)}');
      }
    } catch (_) {
      _error = 'Không đọc được ảnh. Hãy chọn ảnh JPG, PNG hoặc WebP.';
    } finally {
      if (mounted) setState(() => _pickingImages = false);
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
      final service = ref.read(aiServiceProvider);
      final localResult = () => LocalStayAssistant.generateDescription(
        _fields[0].text,
        _fields[1].text,
        amenities,
      );
      var usedOffline = !service.isConfigured;
      var result = usedOffline
          ? localResult()
          : await service.generateDescription(
              _fields[0].text.trim(),
              _fields[1].text.trim(),
              amenities,
            );
      if (!mounted) return;
      if (AiService.isErrorMessage(result)) {
        result = localResult();
        usedOffline = true;
      }
      _fields[3].value = TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
      if (usedOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã tạo mô tả offline từ tên, địa điểm và tiện nghi bạn nhập.',
            ),
          ),
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
            if (widget.home == null) ...[
              'Tên phòng đầu tiên',
              'Giá mỗi đêm (đ)',
              'Sức chứa (khách)',
            ],
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
            if (widget.home == null) ...[
              Icons.bed_outlined,
              Icons.payments_outlined,
              Icons.people_alt_outlined,
            ],
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
                if (!widget.roomMode && widget.home == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Thêm thông tin, ảnh và phòng đầu tiên trong cùng một bước.',
                    ),
                  ),
                if (!widget.roomMode) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ảnh chỗ nghỉ · khách sẽ nhìn thấy',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_images.isEmpty)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 128),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCD6FE)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 30,
                            color: Color(0xFF5145E5),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Thêm ảnh phòng hoặc không gian chung để khách nhận ra chỗ nghỉ.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _pickingImages ? null : _pickImages,
                            icon: _pickingImages
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined),
                            label: Text(
                              _pickingImages ? 'Đang tải ảnh…' : 'Chọn ảnh',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _images.length; i++)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: buildStayImage(
                                  _images[i],
                                  width: 86,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton.filledTonal(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      setState(() => _images.removeAt(i)),
                                  icon: const Icon(Icons.close, size: 15),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  if (_images.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _pickingImages ? null : _pickImages,
                        icon: _pickingImages
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          _pickingImages ? 'Đang tải ảnh…' : 'Thêm ảnh khác',
                        ),
                      ),
                    ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chọn tối đa 4 ảnh JPG, PNG hoặc WebP. Ảnh lưu trên thiết bị này.',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (var i = 0; i < labels.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _fields[i],
                      decoration: InputDecoration(
                        labelText: labels[i],
                        prefixIcon: Icon(icons[i]),
                      ),
                      keyboardType:
                          (widget.roomMode && i > 0) ||
                              (!widget.roomMode &&
                                  widget.home == null &&
                                  i >= 6)
                          ? TextInputType.number
                          : TextInputType.text,
                      onChanged: !widget.roomMode && i == 0
                          ? (_) => setState(() {})
                          : null,
                      maxLength: widget.roomMode
                          ? (i == 0 ? 100 : 9)
                          : [100, 100, 300, 2000, 300, 100, 9, 3][i],
                      minLines: !widget.roomMode && i == 3 ? 3 : 1,
                      maxLines: !widget.roomMode && i == 3 ? 5 : 1,
                      validator: (v) {
                        if (i != 4 && (v == null || v.trim().isEmpty)) {
                          return 'Vui lòng nhập ${labels[i].toLowerCase()}.';
                        }
                        final priceIndex = widget.roomMode ? 1 : 6;
                        final capacityIndex = widget.roomMode ? 2 : 7;
                        if ((widget.roomMode || widget.home == null) &&
                            i == priceIndex) {
                          final price = int.tryParse(v ?? '');
                          if (price == null ||
                              price < 10000 ||
                              price > 100000000) {
                            return 'Giá phải từ 10.000 đến 100.000.000 ₫.';
                          }
                        }
                        if ((widget.roomMode || widget.home == null) &&
                            i == capacityIndex) {
                          final capacity = int.tryParse(v ?? '');
                          if (capacity == null ||
                              capacity < 1 ||
                              capacity > 30) {
                            return 'Sức chứa phải từ 1 đến 30 khách.';
                          }
                        }
                        return null;
                      },
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
