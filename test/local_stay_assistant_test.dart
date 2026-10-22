import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/features/ai/domain/local_stay_assistant.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';

void main() {
  const homestays = [
    Homestay(
      id: 'dalat-1',
      hostId: 'host-1',
      name: 'Nhà Bên Đồi',
      city: 'Đà Lạt',
      address: 'Phường 3',
      description: 'Không gian yên tĩnh',
      amenities: ['Wi-Fi', 'Bếp'],
      color: 0xFF2F6757,
    ),
    Homestay(
      id: 'hanoi-1',
      hostId: 'host-1',
      name: 'Nhà Phố',
      city: 'Hà Nội',
      address: 'Hoàn Kiếm',
      description: 'Gần trung tâm',
      amenities: ['Điều hòa'],
      color: 0xFF2F6757,
    ),
  ];

  const rooms = [
    Room(
      id: 'room-dalat',
      homestayId: 'dalat-1',
      name: 'Phòng đôi',
      price: 650000,
      capacity: 2,
    ),
    Room(
      id: 'room-hanoi',
      homestayId: 'hanoi-1',
      name: 'Phòng tiêu chuẩn',
      price: 900000,
      capacity: 2,
    ),
  ];

  test(
    'offline recommendations use real catalog entries for requested city',
    () {
      final answer = LocalStayAssistant.reply(
        query: 'Tìm homestay ở Đà Lạt',
        homestays: homestays,
        rooms: rooms,
      );

      expect(answer, contains('Nhà Bên Đồi'));
      expect(answer, contains('650.000'));
      expect(answer, contains('Wi-Fi, Bếp'));
      expect(answer, isNot(contains('Nhà Phố')));
      expect(answer, contains('Gemini chưa được cấu hình'));
    },
  );

  test('offline assistant does not invent a home for unknown city', () {
    final answer = LocalStayAssistant.reply(
      query: 'Tìm homestay ở Tokyo',
      homestays: homestays,
      rooms: rooms,
    );

    expect(answer, contains('Nhà Bên Đồi'));
    expect(answer, contains('Nhà Phố'));
    expect(answer, isNot(contains('Tokyo —')));
  });

  test('offline review summary reports only supplied ratings and comments', () {
    final summary = LocalStayAssistant.summarizeReviews([
      '5/5 sao: Phòng sạch và yên tĩnh.',
      '2/5 sao: Phòng tắm cần sửa.',
    ]);

    expect(summary, contains('3.5/5 từ 2 đánh giá'));
    expect(summary, contains('Phòng sạch và yên tĩnh.'));
    expect(summary, contains('Phòng tắm cần sửa.'));
    expect(summary, contains('offline'));
  });

  test('offline description uses the provided home facts only', () {
    final description = LocalStayAssistant.generateDescription(
      'Nhà Bên Đồi',
      'Đà Lạt',
      ['Wi-Fi', 'Bếp'],
    );

    expect(description, contains('Nhà Bên Đồi tại Đà Lạt'));
    expect(description, contains('Wi-Fi, Bếp'));
    expect(description, contains('offline'));
    expect(description, isNot(contains('hồ bơi')));
  });
}
