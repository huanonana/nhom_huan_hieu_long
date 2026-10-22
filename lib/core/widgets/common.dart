import 'package:flutter/material.dart';

String money(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => '${m[1]}.')} ₫';
String dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.eager = false,
    this.controller,
    this.maxWidth = 1200,
  });
  final List<Widget> children;
  final bool eager;
  final ScrollController? controller;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth,
        height: constraints.maxHeight,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width >= 900 ? 32 : 18,
            vertical: MediaQuery.sizeOf(context).width >= 900 ? 32 : 18,
          ),
          children: eager
              ? [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ]
              : children,
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        const Icon(Icons.travel_explore, size: 48),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class BookingSuccessMessage extends StatelessWidget {
  const BookingSuccessMessage({
    super.key,
    this.text = 'Đã gửi yêu cầu đặt phòng. Chủ nhà sẽ duyệt trong 24 giờ.',
  });

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: .4, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        ),
        child: const Icon(Icons.check_circle_rounded, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}

class GuidanceTile extends StatelessWidget {
  const GuidanceTile({super.key, required this.steps});

  final String steps;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 250;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: compact
              ? null
              : const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF4F46E5),
                ),
          title: Text(
            compact ? 'Hướng dẫn' : 'Hướng dẫn thao tác',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                steps,
                style: const TextStyle(color: Color(0xFF475569), height: 1.5),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Adds a clear lift and scale response for pointer users while keeping the
/// same layout and tap behavior on touch screens.
class HoverMotion extends StatefulWidget {
  const HoverMotion({
    super.key,
    required this.child,
    this.scale = 1.025,
    this.lift = 5,
  });

  final Widget child;
  final double scale;
  final double lift;

  @override
  State<HoverMotion> createState() => _HoverMotionState();
}

class _HoverMotionState extends State<HoverMotion> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? widget.scale : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -widget.lift : 0, 0),
        child: widget.child,
      ),
    ),
  );
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(error.toString())));
}
