import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../booking/domain/booking.dart';
import '../../homestay/domain/catalog.dart';

/// Seven-day room availability grid. Cells are calculated from the same
/// booking overlap rules as the room detail list below it.
class RoomTimeline extends StatelessWidget {
  const RoomTimeline({
    super.key,
    required this.rooms,
    required this.bookings,
    required this.start,
    required this.now,
    required this.homestayNames,
    required this.onSelectDate,
  });

  final List<Room> rooms;
  final List<Booking> bookings;
  final DateTime start;
  final DateTime now;
  final Map<String, String> homestayNames;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final first = stayDate(start);
    final days = List.generate(7, (index) => first.add(Duration(days: index)));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 4),
            child: Text(
              'Tình trạng phòng · 7 ngày',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Legend(color: Color(0xFF218567), label: 'Trống'),
                _Legend(color: Color(0xFF8050A6), label: 'Đã đặt'),
                _Legend(color: Color(0xFFB56A14), label: 'Chờ duyệt'),
                _Legend(color: Color(0xFF77736D), label: 'Bảo trì'),
              ],
            ),
          ),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chưa có phòng để hiển thị.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 180, child: _GridHeading('Phòng')),
                      for (final date in days)
                        SizedBox(
                          width: 64,
                          child: InkWell(
                            onTap: () => onSelectDate(date),
                            child: _GridHeading(
                              '${_weekday(date.weekday)}\n${date.day}/${date.month}',
                              selected: date == first,
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (final room in rooms)
                    Row(
                      children: [
                        SizedBox(
                          width: 180,
                          height: 50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  homestayNames[room.homestayId] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (final date in days)
                          SizedBox(
                            width: 64,
                            height: 50,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: _Cell(
                                room: room,
                                date: date,
                                bookings: bookings,
                                now: now,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GridHeading extends StatelessWidget {
  const _GridHeading(this.text, {this.selected = false});
  final String text;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
      border: const Border(bottom: BorderSide(color: Color(0xFFE7E8EF))),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: selected ? brand : muted,
        fontSize: 10,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.room,
    required this.date,
    required this.bookings,
    required this.now,
  });
  final Room room;
  final DateTime date;
  final List<Booking> bookings;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final next = date.add(const Duration(days: 1));
    final booking = bookings
        .where(
          (item) =>
              item.roomId == room.id &&
              item.blocks(now) &&
              overlaps(date, next, item.checkIn, item.checkOut),
        )
        .firstOrNull;
    final color = !room.active
        ? const Color(0xFF77736D)
        : booking == null
        ? const Color(0xFF218567)
        : booking.effectiveStatus(now) == BookingStatus.pending
        ? const Color(0xFFB56A14)
        : const Color(0xFF8050A6);
    return Tooltip(
      message: !room.active ? 'Bảo trì' : booking?.guestName ?? 'Còn trống',
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Center(
          child: Icon(
            !room.active
                ? Icons.build_outlined
                : booking == null
                ? Icons.check_rounded
                : Icons.bed_rounded,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: muted, fontSize: 10)),
    ],
  );
}

String _weekday(int day) =>
    const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][day - 1];
