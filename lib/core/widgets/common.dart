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

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(error.toString())));
}
