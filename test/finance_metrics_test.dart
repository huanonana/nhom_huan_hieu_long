import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/features/dashboard/domain/finance_entry.dart';

void main() {
  Booking stay({
    required String id,
    required DateTime checkIn,
    required DateTime checkOut,
    BookingStatus status = BookingStatus.checkedOut,
    int price = 500000,
    int discount = 0,
  }) => Booking(
    id: id,
    roomId: 'room-$id',
    homestayId: 'home',
    hostId: 'host-demo',
    guestId: 'guest-demo',
    guestName: 'Khách thử',
    roomName: 'Phòng thử',
    checkIn: checkIn,
    checkOut: checkOut,
    guests: 2,
    pricePerNight: price,
    memberDiscountPercent: discount,
    createdAt: checkIn.subtract(const Duration(days: 3)),
    expiresAt: checkIn.subtract(const Duration(days: 2)),
    status: status,
  );

  test('ADR and RevPAR use earned room revenue, not payment cash flow', () {
    const summary = FinanceSummary(
      revenue: 2000000,
      expenses: 450000,
      stayRevenue: 1500000,
      bookingCount: 3,
      roomNights: 2,
      availableRoomNights: 558,
    );

    expect(summary.netRevenue, 1550000);
    expect(summary.averageDailyRate, 750000);
    expect(summary.occupancy, closeTo(2 / 558, 0.000001));
    expect(summary.revPar, 2688);
  });

  test(
    'monthly room metrics split cross-month stays and exclude future nights',
    () {
      final metrics = calculateRoomPerformance(
        month: DateTime.utc(2026, 10),
        asOf: DateTime.utc(2026, 10, 22, 5),
        bookings: [
          stay(
            id: 'cross-month',
            checkIn: DateTime.utc(2026, 9, 30),
            checkOut: DateTime.utc(2026, 10, 2),
            price: 600000,
          ),
          stay(
            id: 'in-house',
            checkIn: DateTime.utc(2026, 10, 21),
            checkOut: DateTime.utc(2026, 10, 24),
            status: BookingStatus.checkedIn,
            price: 500000,
          ),
          stay(
            id: 'future',
            checkIn: DateTime.utc(2026, 10, 23),
            checkOut: DateTime.utc(2026, 10, 25),
            status: BookingStatus.confirmed,
            price: 900000,
          ),
          stay(
            id: 'discounted',
            checkIn: DateTime.utc(2026, 10, 5),
            checkOut: DateTime.utc(2026, 10, 6),
            price: 700000,
            discount: 10,
          ),
        ],
      );

      // One October night from the cross-month stay, one elapsed in-house
      // night, and one checked-out night at the discounted room price.
      expect(metrics.roomNights, 3);
      expect(metrics.revenue, 1730000);
    },
  );
}
