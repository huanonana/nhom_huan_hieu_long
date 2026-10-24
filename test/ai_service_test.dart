import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhom_huan_hieu/features/ai/data/ai_service.dart';
import 'package:nhom_huan_hieu/features/ai/domain/ai_message.dart';

void main() {
  test('calls Gemini API for the three AI tasks', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Phản hồi mẫu'},
                ],
              },
            },
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
      expect(request.url.host, 'generativelanguage.googleapis.com');
      expect(
        request.url.path,
        contains('/v1beta/models/gemini-3.6-flash:generateContent'),
      );
      expect(request.method, 'POST');
      expect(request.headers['x-goog-api-key'], 'test-key');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final generationConfig = body['generationConfig'] as Map<String, dynamic>;
      expect(generationConfig['maxOutputTokens'], 512);
      expect(
        (generationConfig['thinkingConfig'] as Map)['thinkingLevel'],
        'LOW',
      );
    }
    final chatBody = jsonDecode(requests.first.body) as Map<String, dynamic>;
    expect(
      (chatBody['systemInstruction'] as Map)['parts'].toString(),
      contains('Nhà Bên Đồi'),
    );
    expect(chatBody['contents'], [
      {
        'role': 'user',
        'parts': [
          {'text': 'Tôi muốn đi Đà Lạt'},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Bạn định đi ngày nào?'},
        ],
      },
      {
        'role': 'user',
        'parts': [
          {'text': 'Tìm chỗ ở Đà Lạt'},
        ],
      },
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
      AiService.serviceBusyMessage,
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

  test('explains when the request times out', () async {
    final service = AiService(
      apiKey: 'test-key',
      client: MockClient(
        (_) => Future.error(TimeoutException('request timed out')),
      ),
    );

    expect(
      await service.summarizeReviews(['Phòng sạch']),
      AiService.timeoutMessage,
    );
    expect(AiService.isErrorMessage(AiService.timeoutMessage), isTrue);
    service.close();
  });

  test('explains when an API key is invalid (401)', () async {
    final service = AiService(
      apiKey: 'invalid-key',
      client: MockClient((_) async => http.Response('unauthorized', 401)),
    );

    expect(
      await service.chatReply(const [], 'Tìm homestay'),
      AiService.invalidKeyMessage,
    );
    service.close();
  });

  test('explains when Gemini returns 500', () async {
    final service = AiService(
      apiKey: 'test-key',
      client: MockClient((_) async => http.Response('server error', 500)),
    );

    expect(
      await service.generateDescription('Nhà Bên Đồi', 'Đà Lạt', []),
      AiService.serviceBusyMessage,
    );
    service.close();
  });

  test('shows a sanitized Google reason for other 403 responses', () async {
    const leakedLookingKey = 'AIza0123456789abcdefghijklmnopqrstuv';
    final service = AiService(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 403,
              'status': 'PERMISSION_DENIED',
              'message': 'Project has no access. $leakedLookingKey',
              'details': [
                {'reason': 'PROJECT_DENIED'},
              ],
            },
          }),
          403,
        ),
      ),
    );

    final reply = await service.chatReply(const [], 'Tìm homestay');
    expect(reply, contains('PROJECT_DENIED'));
    expect(reply, contains('Project has no access.'));
    expect(reply, isNot(contains(leakedLookingKey)));
    expect(reply, contains('[đã ẩn API key]'));
    expect(AiService.isErrorMessage(reply), isTrue);
    service.close();
  });

  test('explains when Google blocks a key before it reaches the API', () async {
    final service = AiService(
      apiKey: 'blocked-key',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 403,
              'status': 'PERMISSION_DENIED',
              'message': 'Requests to this API are blocked.',
              'details': [
                {'reason': 'API_KEY_SERVICE_BLOCKED'},
              ],
            },
          }),
          403,
        ),
      ),
    );

    expect(
      await service.chatReply(const [], 'Tìm homestay'),
      AiService.blockedKeyMessage,
    );
    service.close();
  });

  test(
    'explains when the Gemini API is disabled for the key project',
    () async {
      final service = AiService(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 403,
                'status': 'PERMISSION_DENIED',
                'message': 'Requests to this API method are blocked.',
                'details': [
                  {'reason': 'SERVICE_DISABLED'},
                ],
              },
            }),
            403,
          ),
        ),
      );

      expect(
        await service.chatReply(const [], 'Tìm homestay'),
        AiService.serviceDisabledMessage,
      );
      service.close();
    },
  );

  test('explains free-tier quota exhaustion (429)', () async {
    final service = AiService(
      apiKey: 'test-key',
      client: MockClient((_) async => http.Response('quota', 429)),
    );

    expect(
      await service.summarizeReviews(['Phòng sạch']),
      AiService.quotaExceededMessage,
    );
    service.close();
  });
}
