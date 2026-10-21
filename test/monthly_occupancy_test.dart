import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/features/dashboard/domain/monthly_occupancy.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';

void main() {
  const openRoom = Room(
    id: 'room-open',
    homestayId: 'home',
    name: 'Phòng mở',
    price: 500000,
    capacity: 2,
  );
  const closedRoom = Room(
    id: 'room-closed',
    homestayId: 'home',
    name: 'Phòng bảo trì',
    price: 500000,
    capacity: 2,
    active: false,
  );

  Booking booking({
    required String id,
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required BookingStatus status,
  }) => Booking(
    id: id,
    roomId: roomId,
    homestayId: 'home',
    hostId: 'host-demo',
    guestId: 'guest-demo',
    guestName: 'Khách thử',
    roomName: 'Phòng thử',
    checkIn: checkIn,
    checkOut: checkOut,
    guests: 2,
    pricePerNight: 500000,
    createdAt: DateTime.utc(2026, 9),
    expiresAt: DateTime.utc(2026, 9, 2),
    status: status,
  );

  test('counts booked nights only inside this month and active rooms', () {
    final result = calculateMonthlyOccupancy(
      month: DateTime.utc(2026, 10, 6),
      activeRooms: const [openRoom, closedRoom],
      bookings: [
        booking(
          id: 'past',
          roomId: 'room-open',
          checkIn: DateTime.utc(2026, 10, 1),
          checkOut: DateTime.utc(2026, 10, 3),
          status: BookingStatus.checkedOut,
        ),
        booking(
          id: 'crosses-month',
          roomId: 'room-open',
          checkIn: DateTime.utc(2026, 10, 30),
          checkOut: DateTime.utc(2026, 11, 2),
          status: BookingStatus.confirmed,
        ),
        booking(
          id: 'pending',
          roomId: 'room-open',
          checkIn: DateTime.utc(2026, 10, 5),
          checkOut: DateTime.utc(2026, 10, 15),
          status: BookingStatus.pending,
        ),
        booking(
          id: 'closed-room',
          roomId: 'room-closed',
          checkIn: DateTime.utc(2026, 10, 5),
          checkOut: DateTime.utc(2026, 10, 15),
          status: BookingStatus.confirmed,
        ),
      ],
    );

    expect(result.bookedRoomNights, 4);
    expect(result.availableRoomNights, 31);
    expect(result.percentage, 13);
  });

  test('shows zero when no active rooms are available', () {
    final result = calculateMonthlyOccupancy(
      month: DateTime.utc(2026, 10),
      activeRooms: const [closedRoom],
      bookings: const [],
    );

    expect(result.bookedRoomNights, 0);
    expect(result.availableRoomNights, 0);
    expect(result.percentage, 0);
  });
}
