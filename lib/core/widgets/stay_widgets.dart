import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'stay_gallery.dart';
import '../../features/booking/domain/booking.dart';

String stayImage(String id) => photosFor(id).first.asset;

class StayPhoto extends StatelessWidget {
  const StayPhoto(
    this.id, {
    super.key,
    this.height = 220,
    this.radius = 18,
    this.label = true,
  });
  final String id;
  final double height, radius;
  final bool label;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Stack(
      children: [
        Image.asset(
          stayImage(id),
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          cacheWidth: 1200,
          semanticLabel: 'Ảnh minh họa homestay',
        ),
        if (label)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Ảnh chụp tham khảo',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    ),
  );
}

class StaySearch {
  const StaySearch({this.dates, this.guests = 1});
  final DateTimeRange? dates;
  final int guests;
}

final staySearchProvider = StateProvider<StaySearch>(
  (ref) => const StaySearch(),
);

class StayModePicker extends ConsumerWidget {
  const StayModePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(staySearchProvider);
    final overnight = search.dates?.duration.inDays == 1;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          showCheckmark: false,
          avatar: Icon(
            Icons.nightlight_outlined,
            size: 18,
            color: overnight ? brand : muted,
          ),
          label: const Text('Qua đêm'),
          selected: overnight,
          onSelected: (_) {
            final today = vietnamToday(ref.read(repositoryProvider).now);
            final start =
                search.dates != null &&
                    !stayDate(search.dates!.start).isBefore(today)
                ? search.dates!.start
                : today;
            ref.read(staySearchProvider.notifier).state = StaySearch(
              dates: DateTimeRange(
                start: start,
                end: start.add(const Duration(days: 1)),
              ),
              guests: search.guests,
            );
          },
        ),
        ChoiceChip(
          showCheckmark: false,
          avatar: Icon(
            Icons.wb_sunny_outlined,
            size: 18,
            color: !overnight ? brand : muted,
          ),
          label: const Text('Theo ngày'),
          selected: !overnight,
          onSelected: (_) async {
            final today = vietnamToday(ref.read(repositoryProvider).now);
            final initial =
                search.dates != null &&
                    !stayDate(search.dates!.start).isBefore(today)
                ? search.dates
                : null;
            final dates = await showDateRangePicker(
              context: context,
              firstDate: today,
              lastDate: today.add(const Duration(days: 365)),
              initialDateRange: initial,
              helpText: 'Chọn ngày nhận và trả phòng',
            );
            if (dates == null || !context.mounted) return;
            if (dates.duration.inDays < 1 || dates.duration.inDays > 30) {
              showError(context, 'Chọn từ 1 đến 30 đêm.');
              return;
            }
            ref.read(staySearchProvider.notifier).state = StaySearch(
              dates: dates,
              guests: search.guests,
            );
          },
        ),
      ],
    );
  }
}

class StaySearchBar extends ConsumerWidget {
  const StaySearchBar({super.key, this.showGuests = true});
  final bool showGuests;

  Future<void> _pickDates(
    BuildContext context,
    WidgetRef ref,
    StaySearch value,
  ) async {
    final today = vietnamToday(ref.read(repositoryProvider).now);
    final initial =
        value.dates != null && !stayDate(value.dates!.start).isBefore(today)
        ? value.dates
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: initial,
      helpText: 'Chọn ngày nhận và trả phòng',
    );
    if (picked == null || !context.mounted) return;
    if (picked.duration.inDays < 1 || picked.duration.inDays > 30) {
      showError(context, 'Chọn từ 1 đến 30 đêm.');
      return;
    }
    ref.read(staySearchProvider.notifier).state = StaySearch(
      dates: picked,
      guests: value.guests,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(staySearchProvider);
    Widget dateCell(String title, DateTime? date, IconData icon) => Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickDates(context, ref, value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFECECF0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: brand, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 10, color: muted),
                    ),
                    Text(
                      date == null ? 'Thêm ngày' : dateLabel(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            dateCell('Nhận phòng', value.dates?.start, Icons.login),
            const SizedBox(width: 8),
            dateCell('Trả phòng', value.dates?.end, Icons.logout),
          ],
        ),
        if (showGuests) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PopupMenuButton<int>(
                tooltip: 'Chọn số khách',
                initialValue: value.guests,
                onSelected: (n) => ref.read(staySearchProvider.notifier).state =
                    StaySearch(dates: value.dates, guests: n),
                itemBuilder: (_) => [
                  for (var i = 1; i <= 10; i++)
                    PopupMenuItem(value: i, child: Text('$i khách')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E5EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 18, color: muted),
                      const SizedBox(width: 8),
                      Text(
                        value.guests.toString() + ' khách',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Icon(Icons.expand_more, size: 16),
                    ],
                  ),
                ),
              ),
              if (value.dates != null)
                TextButton.icon(
                  onPressed: () => ref.read(staySearchProvider.notifier).state =
                      StaySearch(guests: value.guests),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Bỏ ngày'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
}
