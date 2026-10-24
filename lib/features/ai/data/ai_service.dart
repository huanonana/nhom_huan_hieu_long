import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ai_message.dart';

/// Gemini Developer API client. The default model currently has a free tier;
/// usage is still subject to Google's quotas and terms.
class AiService {
  AiService({
    required this.apiKey,
    http.Client? client,
    this.model = 'gemini-3.8-flash',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const String unavailableMessage = 'Tính năng AI chưa khả dụng';
  static const String friendlyErrorMessage =
      'Không thể kết nối Gemini. Kiểm tra Internet rồi thử lại.';
  static const String invalidKeyMessage =
      'API key Gemini không hợp lệ. Hãy tạo key mới trong Google AI Studio.';
  static const String blockedKeyMessage =
      'Google đã chặn API key này. Hãy dùng key mới trong Google AI Studio.';
  static const String permissionDeniedMessage =
      'Gemini chưa cho phép key này gọi API. Kiểm tra quyền của key trong Google AI Studio.';
  static const String serviceDisabledMessage =
      'Gemini API chưa được bật cho project của key. Trong Google Cloud Console, '
      'mở APIs & Services → Library, bật Generative Language API rồi thử lại.';
  static const String quotaExceededMessage =
      'Gemini đã hết lượt miễn phí tạm thời. Hãy thử lại sau.';
  static const String modelUnavailableMessage =
      'Model Gemini hiện không khả dụng. Hãy cập nhật cấu hình AI.';
  static const String serviceBusyMessage =
      'Gemini đang bận. Hãy thử lại sau ít phút.';
  static const String timeoutMessage =
      'Gemini phản hồi quá lâu. Hãy thử lại khi mạng ổn định hơn.';
  static const String _endpoint = 'generativelanguage.googleapis.com';

  final String apiKey;
  final String model;
  final http.Client _client;
  final bool _ownsClient;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Includes project-specific Google diagnostics, which are shown verbatim
  /// to help debug but must never be mistaken for a successful AI reply.
  static bool isErrorMessage(String message) =>
      const {
        unavailableMessage,
        friendlyErrorMessage,
        invalidKeyMessage,
        blockedKeyMessage,
        permissionDeniedMessage,
        serviceDisabledMessage,
        quotaExceededMessage,
        modelUnavailableMessage,
        serviceBusyMessage,
        timeoutMessage,
      }.contains(message) ||
      message.startsWith('Gemini từ chối yêu cầu (403):');

  Future<String> chatReply(
    List<AiMessage> history,
    String userInput, {
    String? systemContext,
  }) async {
    try {
      if (apiKey.trim().isEmpty) return unavailableMessage;
      final prompt = StringBuffer(
        'Bạn là trợ lý tư vấn đặt homestay tại Việt Nam. Trả lời bằng '
        'tiếng Việt, ngắn gọn, hữu ích; không tự bịa thông tin về chỗ ở.',
      );
      if (systemContext != null && systemContext.isNotEmpty) {
        prompt.write('\n\n$systemContext');
      }
      final contents = [
        for (final message in history)
          {
            'role': message.role == AiMessageRole.assistant ? 'model' : 'user',
            'parts': [
              {'text': message.content},
            ],
          },
        {
          'role': 'user',
          'parts': [
            {'text': userInput},
          ],
        },
      ];
      return await _send(contents: contents, system: prompt.toString());
    } catch (error) {
      return _messageFor(error);
    }
  }

  Future<String> summarizeReviews(List<String> reviewTexts) async {
    try {
      if (apiKey.trim().isEmpty) return unavailableMessage;
      if (reviewTexts.isEmpty) return 'Chưa có đánh giá để tóm tắt.';
      final reviews = reviewTexts
          .asMap()
          .entries
          .map((entry) => '${entry.key + 1}. ${entry.value}')
          .join('\n');
      return await _send(
        contents: [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    'Tóm tắt các đánh giá homestay dưới đây bằng tiếng Việt. '
                    'Nêu điểm được khen, điểm cần cải thiện và cảm nhận chung. '
                    'Chỉ dựa trên nội dung được cung cấp:\n\n$reviews',
              },
            ],
          },
        ],
      );
    } catch (error) {
      return _messageFor(error);
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
        contents: [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    'Viết mô tả tiếng Việt tự nhiên, hấp dẫn và trung thực '
                    'cho homestay "$homestayName" tại $city. Tiện nghi đã biết: '
                    '${amenities.isEmpty ? 'chưa cung cấp' : amenities.join(', ')}. '
                    'Không tự thêm tiện nghi hay cam kết chưa được cung cấp. '
                    'Giới hạn khoảng 80 từ.',
              },
            ],
          },
        ],
      );
    } catch (error) {
      return _messageFor(error);
    }
  }

  Future<String> _send({
    required List<Map<String, Object>> contents,
    String? system,
  }) async {
    if (apiKey.trim().isEmpty) return unavailableMessage;
    final uri = Uri.https(_endpoint, '/v1beta/models/$model:generateContent');
    final response = await _client
        .post(
          uri,
          headers: {
            'content-type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            if (system != null)
              'systemInstruction': {
                'parts': [
                  {'text': system},
                ],
              },
            'contents': contents,
            'generationConfig': {
              'maxOutputTokens': 512,
              'thinkingConfig': {'thinkingLevel': 'LOW'},
            },
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _GeminiRequestFailure(
        _messageForStatus(response.statusCode, response.body),
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>? ?? const [];
    final candidate = candidates.whereType<Map<String, dynamic>>().firstOrNull;
    final content = candidate?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];
    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'] as String? ?? '')
        .where((part) => part.isNotEmpty)
        .join('\n')
        .trim();
    if (text.isEmpty) throw const FormatException('Empty AI response');
    return text;
  }

  static String _messageFor(Object error) {
    if (error is _GeminiRequestFailure) return error.message;
    if (error is TimeoutException) return timeoutMessage;
    return friendlyErrorMessage;
  }

  static String _messageForStatus(int statusCode, String body) {
    final payload = _decodeError(body);
    final error = payload?['error'];
    final status = error is Map ? '${error['status'] ?? ''}' : '';
    final message = error is Map ? '${error['message'] ?? ''}' : '';
    final details = error is Map && error['details'] is List
        ? (error['details'] as List).whereType<Map>()
        : const <Map>[];
    final reason = details
        .map((detail) => '${detail['reason'] ?? ''}')
        .join(' ');
    final diagnostic = '$status $reason $message'.toUpperCase();

    if (diagnostic.contains('SERVICE_DISABLED') ||
        diagnostic.contains('API HAS NOT BEEN USED') ||
        diagnostic.contains('API IS DISABLED')) {
      return serviceDisabledMessage;
    }
    if (diagnostic.contains('API_KEY_SERVICE_BLOCKED') ||
        diagnostic.contains('REPORTED AS LEAKED')) {
      return blockedKeyMessage;
    }
    if (diagnostic.contains('API_KEY_INVALID') || statusCode == 401) {
      return invalidKeyMessage;
    }
    if (statusCode == 403) {
      final detail = _safeDiagnostic(
        [
          status,
          reason,
          message,
        ].where((part) => part.trim().isNotEmpty).join(' · '),
      );
      if (detail.isNotEmpty) {
        return 'Gemini từ chối yêu cầu (403): $detail';
      }
      return permissionDeniedMessage;
    }
    if (statusCode == 429) return quotaExceededMessage;
    if (statusCode == 404) return modelUnavailableMessage;
    if (statusCode >= 500) return serviceBusyMessage;
    return friendlyErrorMessage;
  }

  static Map<String, dynamic>? _decodeError(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String _safeDiagnostic(String value) {
    // Google error messages are useful for troubleshooting, but never echo a
    // credential if an upstream response unexpectedly includes one.
    final redacted = value.replaceAll(
      RegExp(r'AIza[0-9A-Za-z_-]{20,}'),
      '[đã ẩn API key]',
    );
    return redacted
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .substring(
          0,
          redacted.trim().length > 240 ? 240 : redacted.trim().length,
        );
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class _GeminiRequestFailure implements Exception {
  const _GeminiRequestFailure(this.message);
  final String message;
}
