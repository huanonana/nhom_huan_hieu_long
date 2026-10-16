import '../../booking/domain/booking.dart';
import '../../homestay/domain/catalog.dart';

class MonthlyOccupancy {
  const MonthlyOccupancy({
    required this.bookedRoomNights,
    required this.availableRoomNights,
  });

  final int bookedRoomNights;
  final int availableRoomNights;

  int get percentage => availableRoomNights == 0
      ? 0
      : (bookedRoomNights / availableRoomNights * 100).round().clamp(0, 100);
}

MonthlyOccupancy calculateMonthlyOccupancy({
  required DateTime month,
  required Iterable<Room> activeRooms,
  required Iterable<Booking> bookings,
}) {
  final roomIds = activeRooms
      .where((room) => room.active)
      .map((room) => room.id)
      .toSet();
  final start = DateTime.utc(month.year, month.month);
  final end = DateTime.utc(month.year, month.month + 1);
  final days = end.difference(start).inDays;
  var bookedNights = 0;

  for (final booking in bookings) {
    if (!roomIds.contains(booking.roomId) ||
        !{
          BookingStatus.confirmed,
          BookingStatus.checkedIn,
          BookingStatus.checkedOut,
        }.contains(booking.status)) {
      continue;
    }
    final firstNight = booking.checkIn.isAfter(start) ? booking.checkIn : start;
    final lastNight = booking.checkOut.isBefore(end) ? booking.checkOut : end;
    if (firstNight.isBefore(lastNight)) {
      bookedNights += lastNight.difference(firstNight).inDays;
    }
  }

  final availableNights = roomIds.length * days;
  return MonthlyOccupancy(
    bookedRoomNights: bookedNights.clamp(0, availableNights),
    availableRoomNights: availableNights,
  );
}
