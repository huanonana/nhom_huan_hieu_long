import 'package:flutter/material.dart';
import '../domain/booking.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      BookingStatus.pending => (
        Icons.schedule_rounded,
        const Color(0xFFC86A13),
      ),
      BookingStatus.confirmed => (
        Icons.verified_outlined,
        const Color(0xFF2875B9),
      ),
      BookingStatus.checkedIn => (Icons.hotel_rounded, const Color(0xFF8050A6)),
      BookingStatus.checkedOut => (
        Icons.task_alt_rounded,
        const Color(0xFF218567),
      ),
      BookingStatus.rejected || BookingStatus.cancelled => (
        Icons.cancel_outlined,
        const Color(0xFFB9382E),
      ),
      BookingStatus.expired => (
        Icons.timer_off_outlined,
        const Color(0xFF77736D),
      ),
    };
    return StatusBadge(label: status.label, icon: icon, color: color);
  }
}
