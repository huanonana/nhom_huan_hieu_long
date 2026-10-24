import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';
import 'package:nhom_huan_hieu/features/review/domain/review.dart';

void main() {
  test(
    'AppUser round-trips its role and profile fields through local JSON',
    () {
      final user = AppUser(
        uid: 'user-1',
        email: 'host@example.com',
        displayName: 'Chủ nhà',
        role: AppUserRole.host,
        createdAt: DateTime.utc(2026, 10, 7),
      );

      final restored = AppUser.fromJson(user.toJson());
      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.role, AppUserRole.host);
      expect(restored.createdAt.isAtSameMomentAs(user.createdAt), isTrue);
    },
  );

  test('catalog models round-trip through local JSON', () {
    const home = Homestay(
      id: 'home-1',
      hostId: 'host-1',
      name: 'Nhà bên đồi',
      city: 'Đà Lạt',
      address: 'Trại Mát',
      description: 'Nhà gỗ',
      amenities: ['Wi-Fi'],
      color: 0xFF2F6757,
    );
    const room = Room(
      id: 'room-1',
      homestayId: 'home-1',
      name: 'Phòng thông',
      price: 650000,
      capacity: 2,
    );
    expect(Homestay.fromJson(home.toJson()).toJson(), home.toJson());
    expect(Room.fromJson(room.toJson()).toJson(), room.toJson());
  });

  test('booking and review dates round-trip through local JSON', () {
    final start = DateTime.utc(2026, 11, 2);
    final booking = Booking(
      id: 'booking-1',
      roomId: 'room-1',
      homestayId: 'home-1',
      hostId: 'host-1',
      guestId: 'guest-1',
      guestName: 'Khách',
      roomName: 'Phòng thông',
      checkIn: start,
      checkOut: start.add(const Duration(days: 2)),
      guests: 2,
      pricePerNight: 650000,
      createdAt: start.subtract(const Duration(days: 4)),
      expiresAt: start.subtract(const Duration(days: 3)),
      status: BookingStatus.confirmed,
    );
    final review = StayReview(
      bookingId: booking.id,
      homestayId: booking.homestayId,
      guestId: booking.guestId,
      guestName: booking.guestName,
      rating: 5,
      comment: 'Rất tốt',
      createdAt: start,
    );

    expect(
      booking.toJson()['checkInEpochMillis'],
      start.millisecondsSinceEpoch,
    );
    final restoredBooking = Booking.fromJson(booking.toJson());
    expect(restoredBooking.id, booking.id);
    expect(restoredBooking.status, booking.status);
    expect(restoredBooking.checkIn.isAtSameMomentAs(booking.checkIn), isTrue);
    expect(restoredBooking.checkOut.isAtSameMomentAs(booking.checkOut), isTrue);
    expect(
      restoredBooking.createdAt.isAtSameMomentAs(booking.createdAt),
      isTrue,
    );
    expect(
      restoredBooking.expiresAt.isAtSameMomentAs(booking.expiresAt),
      isTrue,
    );
    final restoredReview = StayReview.fromJson(review.toJson());
    expect(restoredReview.bookingId, review.bookingId);
    expect(restoredReview.comment, review.comment);
    expect(restoredReview.createdAt.isAtSameMomentAs(review.createdAt), isTrue);
  });
}
