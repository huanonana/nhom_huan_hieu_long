import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ai_message.dart';

class AiService {
  AiService({
    required this.apiKey,
    http.Client? client,
    this.model = 'claude-sonnet-4-6',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static final Uri _endpoint = Uri.https('api.anthropic.com', '/v1/messages');

  static const String unavailableMessage = 'Tính năng AI chưa khả dụng';
  static const String friendlyErrorMessage = 'Không thể kết nối AI lúc này';
  final String apiKey;
  final String model;
  final http.Client _client;
  final bool _ownsClient;

  Future<String> chatReply(
    List<AiMessage> history,
    String userInput, {
    String? systemContext,
  }) async {
    try {
      if (apiKey.trim().isEmpty) return unavailableMessage;
      final messages = [
        for (final message in history)
          {'role': message.role.name, 'content': message.content},
        {'role': 'user', 'content': userInput},
      ];
      return await _send(
        messages: messages,
        system:
            'Bạn là trợ lý tư vấn đặt homestay tại Việt Nam. Trả lời bằng '
            'tiếng Việt, ngắn gọn, hữu ích; không tự bịa thông tin về chỗ ở.'
            '${systemContext == null || systemContext.isEmpty ? '' : '\n\n$systemContext'}',
        maxTokens: 700,
      );
    } catch (_) {
      return friendlyErrorMessage;
    }
  }

  Future<String> summarizeReviews(List<String> reviewTexts) async {
    try {
      if (apiKey.trim().isEmpty) return unavailableMessage;
      if (reviewTexts.isEmpty) return 'Chưa có đánh giá để tóm tắt.';
      return await _send(
        messages: [
          {
            'role': 'user',
            'content':
                'Tóm tắt các đánh giá homestay dưới đây bằng tiếng Việt. '
                'Nêu điểm được khen, điểm cần cải thiện và cảm nhận chung. '
                'Chỉ dựa trên nội dung được cung cấp:\n\n'
                '${reviewTexts.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}',
          },
        ],
        maxTokens: 500,
      );
    } catch (_) {
      return friendlyErrorMessage;
    }
  }

  Future<String> generateDescription(
    String homestayName,
    String city,
    List<String> amenities,
  ) async {
    try {
      if (apiKey.trim().isEmpty) return unavailableMessage;
      return await _send(
        messages: [
          {
            'role': 'user',
            'content':
                'Viết mô tả tiếng Việt tự nhiên, hấp dẫn và trung thực cho '
                'homestay "$homestayName" tại $city. Tiện nghi đã biết: '
                '${amenities.isEmpty ? 'chưa cung cấp' : amenities.join(', ')}. '
                'Không tự thêm tiện nghi hay cam kết chưa được cung cấp. '
                'Giới hạn khoảng 80 từ.',
          },
        ],
        maxTokens: 250,
      );
    } catch (_) {
      return friendlyErrorMessage;
    }
  }

  Future<String> _send({
    required List<Map<String, String>> messages,
    String? system,
    required int maxTokens,
  }) async {
    if (apiKey.trim().isEmpty) return unavailableMessage;
    final response = await _client
        .post(
          _endpoint,
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': maxTokens,
            if (system != null) 'system': system,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('Anthropic returned ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>? ?? const [];
    final text = content
        .whereType<Map<String, dynamic>>()
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String? ?? '')
        .where((block) => block.isNotEmpty)
        .join('\n')
        .trim();
    if (text.isEmpty) throw const FormatException('Empty AI response');
    return text;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
