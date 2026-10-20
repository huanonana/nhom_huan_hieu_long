import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../homestay/domain/catalog.dart';
import '../../booking/presentation/firestore_repository_provider.dart';
import '../domain/ai_message.dart';
import 'ai_provider.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  static const _welcomeText =
      'Xin chào! Mình có thể giúp bạn tìm homestay phù hợp. Bạn dự định '
      'đi đâu, khi nào và có những yêu cầu gì?';
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <AiMessage>[
    AiMessage(role: AiMessageRole.assistant, content: _welcomeText),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _catalogContext(List<Homestay> homes, List<Room> rooms) {
    if (homes.isEmpty) {
      return 'Hiện danh sách homestay đang trống. Không được tự đưa ra tên '
          'homestay hoặc chỗ nghỉ không có trong dữ liệu.';
    }
    final entries = <String>[];
    for (final home in homes) {
      final openRooms = rooms
          .where((room) => room.homestayId == home.id && room.active)
          .toList();
      final price = openRooms.isEmpty
          ? 'chưa có phòng mở'
          : 'từ ${money(openRooms.map((room) => room.price).reduce((a, b) => a < b ? a : b))}/đêm';
      final amenities = home.amenities.isEmpty
          ? 'chưa cập nhật'
          : home.amenities.take(5).join(', ');
      entries.add(
        '- ${home.name} | ${home.city} | $price | tiện nghi chính: $amenities',
      );
    }
    return 'Danh sách homestay hiện có trong ứng dụng:\n'
        '${entries.join('\n')}\n\n'
        'Chỉ tư vấn homestay trong danh sách này. Không bịa tên chỗ ở, giá, '
        'tình trạng còn phòng hoặc tiện nghi. Nếu thiếu thông tin, hãy nói rõ '
        'và hướng dẫn khách mở trang chi tiết để kiểm tra.';
  }

  List<Homestay> _mentionedHomes(String text, List<Homestay> homes) {
    final normalized = text.toLowerCase();
    return homes
        .where(
          (home) =>
              home.name.trim().isNotEmpty &&
              normalized.contains(home.name.toLowerCase()),
        )
        .toList();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(List<Homestay> homes, List<Room> rooms) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(AiMessage(role: AiMessageRole.user, content: text));
      _input.clear();
      _sending = true;
    });
    _scrollToLatest();

    // chatReply appends the current question itself, so pass at most the
    // previous nine messages to keep each request at ten messages total.
    final previous = _messages
        .sublist(0, _messages.length - 1)
        .skip(1)
        .toList();
    final history = previous.length > 9
        ? previous.sublist(previous.length - 9)
        : previous;
    String reply;
    try {
      reply = await ref
          .read(aiServiceProvider)
          .chatReply(
            history,
            text,
            systemContext: _catalogContext(homes, rooms),
          );
    } catch (_) {
      reply = 'Không thể kết nối AI lúc này';
    }
    if (!mounted) return;
    setState(() {
      _messages.add(AiMessage(role: AiMessageRole.assistant, content: reply));
      _sending = false;
    });
    _scrollToLatest();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(useFirebaseBackendProvider)) {
      final homes = ref.watch(firestoreHomestaysProvider);
      final rooms = ref.watch(firestoreRoomsProvider);
      return homes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Không tải được danh sách homestay.')),
        data: (items) => rooms.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Không tải được danh sách phòng.')),
          data: (roomItems) => _buildChat(items, roomItems),
        ),
      );
    }
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final homes = repo.homestays.toList();
    final rooms = repo.rooms.toList();
    return _buildChat(homes, rooms);
  }

  Widget _buildChat(List<Homestay> homes, List<Room> rooms) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE8D9),
                  child: Icon(Icons.auto_awesome_rounded, color: brand),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trợ lý chọn homestay',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Tư vấn theo danh sách chỗ ở của HHL Stay',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingBubble();
                }
                final message = _messages[index];
                final isUser = message.role == AiMessageRole.user;
                final mentioned = isUser
                    ? const <Homestay>[]
                    : _mentionedHomes(message.content, homes);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFF0EAF6),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF8050A6),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFFFFE8D9)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isUser ? 18 : 5),
                                  bottomRight: Radius.circular(isUser ? 5 : 18),
                                ),
                                border: isUser
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFE8E4DF),
                                      ),
                              ),
                              child: Text(
                                message.content,
                                style: const TextStyle(height: 1.4),
                              ),
                            ),
                            if (mentioned.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Wrap(
                                  spacing: 5,
                                  runSpacing: 3,
                                  children: [
                                    for (final home in mentioned)
                                      TextButton.icon(
                                        onPressed: () =>
                                            context.go('/homestays/${home.id}'),
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 15,
                                        ),
                                        label: const Text('Xem chi tiết'),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8E4DF))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Hỏi về địa điểm, giá hoặc tiện nghi…',
                      filled: true,
                      fillColor: const Color(0xFFF7F5F2),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(homes, rooms),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Gửi tin nhắn',
                  onPressed: _sending ? null : () => _send(homes, rooms),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: brand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFF0EAF6),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF8050A6),
            size: 17,
          ),
        ),
        SizedBox(width: 8),
        Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: SizedBox(
              width: 28,
              height: 15,
              child: LinearProgressIndicator(
                color: Color(0xFF8050A6),
                backgroundColor: Color(0xFFF0EAF6),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
