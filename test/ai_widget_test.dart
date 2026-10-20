import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/ai/data/ai_service.dart';
import 'package:nhom_huan_hieu/features/ai/presentation/ai_provider.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/main.dart';

http.Response aiResponse(String text) => http.Response(
  jsonEncode({
    'content': [
      {'type': 'text', 'text': text},
    ],
  }),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  testWidgets(
    'homestay details offer an AI review summary from three reviews',
    (tester) async {
      final now = DateTime.utc(2026, 10, 7, 10);
      final repo = DemoBookingRepository(clock: () => now, seed: false);
      final start = vietnamToday(now);
      for (var i = 0; i < 3; i++) {
        final booking = repo.create(
          roomId: 'pine-1',
          guestId: 'guest-demo',
          guestName: 'Khách $i',
          checkIn: start,
          checkOut: start.add(const Duration(days: 1)),
          guests: 2,
        );
        repo.transition(
          booking.id,
          BookingStatus.confirmed,
          actorId: 'host-demo',
        );
        repo.transition(
          booking.id,
          BookingStatus.checkedIn,
          actorId: 'host-demo',
        );
        repo.transition(
          booking.id,
          BookingStatus.checkedOut,
          actorId: 'host-demo',
        );
        repo.addReview(
          booking.id,
          actorId: 'guest-demo',
          rating: 5 - i,
          comment: 'Đánh giá mẫu $i',
        );
      }
      final client = MockClient(
        (_) async => aiResponse('Phòng sạch, vị trí thuận tiện.'),
      );
      expect(repo.reviews, hasLength(3));
      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(
            AiService(apiKey: 'test-key', client: client),
          ),
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      container.read(roleProvider.notifier).state = DemoRole.guest;
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/homestays/pine');
      await tester.pumpAndSettle();

      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/homestays/pine',
      );
      expect(find.text('Nhà Bên Đồi'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Đánh giá'));
      await tester.pumpAndSettle();
      expect(find.text('Khách đã ở nói gì?'), findsOneWidget);
      final summarizeButton = find.textContaining('Tóm tắt bằng AI');
      expect(summarizeButton, findsOneWidget);
      await tester.ensureVisible(summarizeButton);
      expect(summarizeButton, findsOneWidget);
      await tester.tap(summarizeButton);
      await tester.pumpAndSettle();
      expect(find.text('Tóm tắt từ AI'), findsOneWidget);
      expect(find.text('Phòng sạch, vị trí thuận tiện.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      container.dispose();
      client.close();
    },
  );

  testWidgets('guest can chat with catalog context and open a mentioned home', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return aiResponse('Nhà Bên Đồi ở Đà Lạt phù hợp với bạn.');
    });
    final container = ProviderContainer(
      overrides: [
        aiServiceProvider.overrideWithValue(
          AiService(apiKey: 'test-key', client: client),
        ),
        repositoryProvider.overrideWithValue(DemoBookingRepository()),
      ],
    );
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('landing-ai-cta')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('landing-ai-cta')));
    await tester.pumpAndSettle();
    expect(find.text('Trợ lý chọn homestay'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'Tìm homestay ở Đà Lạt',
    );
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pumpAndSettle();
    expect(find.text('Nhà Bên Đồi ở Đà Lạt phù hợp với bạn.'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsOneWidget);

    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['system'], contains('Nhà Bên Đồi | Đà Lạt'));
    expect(body['system'], contains('650.000'));
    expect((body['messages'] as List).length, lessThanOrEqualTo(10));
    await tester.tap(find.text('Xem chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('Nhà Bên Đồi'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    client.close();
  });

  testWidgets(
    'description button is disabled until name, then fills the field',
    (tester) async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return aiResponse('Một góc nghỉ yên bình với Wi-Fi tiện lợi.');
      });
      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(
            AiService(apiKey: 'test-key', client: client),
          ),
          repositoryProvider.overrideWithValue(DemoBookingRepository()),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm homestay'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Tên homestay'), findsOneWidget);

      final aiTooltip = find.byTooltip('Nhập tên homestay trước');
      expect(aiTooltip, findsOneWidget);
      final aiButton = find.descendant(
        of: aiTooltip,
        matching: find.bySubtype<OutlinedButton>(),
      );
      expect(aiButton, findsOneWidget);
      expect(tester.widget<OutlinedButton>(aiButton).onPressed, isNull);
      final fields = find.byType(TextFormField);
      final nameField = fields.at(0);
      final cityField = fields.at(1);
      final descriptionField = fields.at(3);
      await tester.enterText(nameField, 'Nhà của An');
      await tester.enterText(cityField, 'Đà Lạt');
      await tester.pump();
      final enabledAiButton = find.descendant(
        of: find.byTooltip('Để AI gợi ý nội dung mô tả'),
        matching: find.bySubtype<OutlinedButton>(),
      );
      expect(
        tester.widget<OutlinedButton>(enabledAiButton).onPressed,
        isNotNull,
      );
      await tester.ensureVisible(enabledAiButton);
      await tester.tap(enabledAiButton);
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextFormField>(descriptionField).controller!.text,
        'Một góc nghỉ yên bình với Wi-Fi tiện lợi.',
      );
      expect(requests, hasLength(1));
      expect(requests.single.body, contains('Nhà của An'));
      expect(requests.single.body, contains('Đà Lạt'));

      await tester.pumpWidget(const SizedBox());
      container.dispose();
      client.close();
    },
  );
}
