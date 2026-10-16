import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhom_huan_hieu/features/ai/data/ai_service.dart';
import 'package:nhom_huan_hieu/features/ai/domain/ai_message.dart';

void main() {
  test('calls Anthropic messages API for the three AI tasks', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'content': [
            {'type': 'text', 'text': 'Phản hồi mẫu'},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = AiService(apiKey: 'test-key', client: client);

    final chat = await service.chatReply(
      [
        AiMessage(role: AiMessageRole.user, content: 'Tôi muốn đi Đà Lạt'),
        AiMessage(
          role: AiMessageRole.assistant,
          content: 'Bạn định đi ngày nào?',
        ),
      ],
      'Tìm chỗ ở Đà Lạt',
      systemContext: 'Nhà Bên Đồi | Đà Lạt | từ 650.000 ₫',
    );
    final summary = await service.summarizeReviews([
      'Phòng sạch',
      'Vị trí tốt',
    ]);
    final description = await service.generateDescription(
      'Nhà Bên Đồi',
      'Đà Lạt',
      ['Wi-Fi', 'Bếp'],
    );

    expect([chat, summary, description], everyElement('Phản hồi mẫu'));
    expect(requests, hasLength(3));
    for (final request in requests) {
      expect(request.url, Uri.https('api.anthropic.com', '/v1/messages'));
      expect(request.method, 'POST');
      expect(request.headers['x-api-key'], 'test-key');
      expect(request.headers['anthropic-version'], '2023-06-01');
      expect(
        request.headers['anthropic-dangerous-direct-browser-access'],
        'true',
      );
      expect(jsonDecode(request.body)['model'], 'claude-sonnet-4-6');
    }
    final chatBody = jsonDecode(requests.first.body) as Map<String, dynamic>;
    expect(chatBody['system'], contains('Nhà Bên Đồi'));
    expect(chatBody['messages'], [
      {'role': 'user', 'content': 'Tôi muốn đi Đà Lạt'},
      {'role': 'assistant', 'content': 'Bạn định đi ngày nào?'},
      {'role': 'user', 'content': 'Tìm chỗ ở Đà Lạt'},
    ]);
    expect(requests[1].body, contains('Phòng sạch'));
    expect(requests[2].body, contains('Nhà Bên Đồi'));
    service.close();
  });

  test('returns a friendly message when the API request fails', () async {
    final service = AiService(
      apiKey: 'test-key',
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );

    expect(
      await service.generateDescription('Nhà Bên Đồi', 'Đà Lạt', ['Wi-Fi']),
      'Không thể kết nối AI lúc này',
    );
    service.close();
  });

  test(
    'missing API key disables all AI requests with a clear message',
    () async {
      var requestCount = 0;
      final service = AiService(
        apiKey: '  ',
        client: MockClient((_) async {
          requestCount++;
          return http.Response('unexpected', 200);
        }),
      );

      expect(
        await service.summarizeReviews([
          'Phòng sạch',
          'Vị trí tốt',
          'Yên tĩnh',
        ]),
        AiService.unavailableMessage,
      );
      expect(
        await service.generateDescription('Nhà Bên Đồi', 'Đà Lạt', ['Wi-Fi']),
        AiService.unavailableMessage,
      );
      expect(
        await service.chatReply(const [], 'Tìm homestay'),
        AiService.unavailableMessage,
      );
      expect(requestCount, 0);
      service.close();
    },
  );

  test('returns a friendly message when the request times out', () async {
    final service = AiService(
      apiKey: 'test-key',
      client: MockClient(
        (_) => Future.error(TimeoutException('request timed out')),
      ),
    );

    expect(
      await service.summarizeReviews(['Phòng sạch']),
      AiService.friendlyErrorMessage,
    );
    service.close();
  });

  test('returns a friendly message for an invalid API key (401)', () async {
    final service = AiService(
      apiKey: 'invalid-key',
      client: MockClient((_) async => http.Response('unauthorized', 401)),
    );

    expect(
      await service.chatReply(const [], 'Tìm homestay'),
      AiService.friendlyErrorMessage,
    );
    service.close();
  });

  test('returns a friendly message when Anthropic returns 500', () async {
    final service = AiService(
      apiKey: 'test-key',
      client: MockClient((_) async => http.Response('server error', 500)),
    );

    expect(
      await service.generateDescription('Nhà Bên Đồi', 'Đà Lạt', []),
      AiService.friendlyErrorMessage,
    );
    service.close();
  });
}
