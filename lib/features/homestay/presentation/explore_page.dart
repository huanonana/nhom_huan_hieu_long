import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../../core/widgets/stay_gallery.dart';
import '../domain/catalog.dart';
import '../../review/presentation/review_widgets.dart';
import '../../review/domain/review.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key, this.favoritesOnly = false});
  final bool favoritesOnly;
  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _heroPage = PageController();
  int _heroIndex = 0;
  Timer? _heroTimer;
  static const _regions = <String, List<String>>{
    'Miền Bắc': ['Hà Nội', 'Sa Pa', 'Ninh Bình', 'Hạ Long'],
    'Miền Trung': ['Huế', 'Đà Nẵng', 'Hội An', 'Quy Nhơn', 'Nha Trang'],
    'Miền Nam': [
      'Đà Lạt',
      'TP. Hồ Chí Minh',
      'Vũng Tàu',
      'Cần Thơ',
      'Phú Quốc',
    ],
  };
  static const _featuredDestinations = <(String, String)>[
    ('Đà Lạt', 'pine'),
    ('Đà Nẵng', 'sea'),
    ('Hội An', 'garden'),
    ('Sa Pa', 'sapa'),
    ('Hà Nội', 'hanoi'),
    ('Ninh Bình', 'ninhbinh'),
    ('Hạ Long', 'halong'),
    ('Huế', 'hue'),
    ('Quy Nhơn', 'quynhon'),
    ('Nha Trang', 'nhatrang'),
    ('Phú Quốc', 'phuquoc'),
    ('TP. Hồ Chí Minh', 'saigon'),
    ('Vũng Tàu', 'vungtau'),
    ('Cần Thơ', 'cantho'),
  ];
  static const _heroDestinations = <(String, String)>[
    ('Đà Lạt', 'pine'),
    ('Đà Nẵng', 'sea'),
    ('Hội An', 'garden'),
    ('Sa Pa', 'sapa'),
  ];
  String _region = 'Tất cả';
  final _query = TextEditingController();
  final _resultsKey = GlobalKey();
  void _showResults() {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultsKey.currentContext;
      if (target != null)
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
        );
    });
  }

  String _city = 'Tất cả', _amenity = 'Tất cả', _sort = 'Gợi ý';
  int? _price;
  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_heroPage.hasClients || !mounted) return;
      _heroPage.animateToPage(
        (_heroIndex + 1) % _heroDestinations.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSearch() async {
    var city = _city;
    final cities = [
      'Tất cả',
      ...ref.read(repositoryProvider).homestays.map((h) => h.city).toSet(),
    ];
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tìm chuyến đi của bạn',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '01  ĐI ĐÂU?',
                    style: TextStyle(
                      color: brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: city,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.place_outlined),
                      labelText: 'Điểm đến',
                    ),
                    items: [
                      for (final place in cities)
                        DropdownMenuItem(value: place, child: Text(place)),
                    ],
                    onChanged: (value) =>
                        update(() => city = value ?? 'Tất cả'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _query,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tên homestay, khu vực hoặc tiện nghi',
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '02  KHI NÀO?',
                    style: TextStyle(
                      color: brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const StayModePicker(),
                  const SizedBox(height: 10),
                  const StaySearchBar(showGuests: false),
                  const SizedBox(height: 12),
                  const Text(
                    '03  MẤY KHÁCH?',
                    style: TextStyle(
                      color: brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final value = ref.watch(staySearchProvider);
                      return PopupMenuButton<int>(
                        tooltip: 'Chọn số khách',
                        initialValue: value.guests,
                        onSelected: (n) =>
                            ref.read(staySearchProvider.notifier).state =
                                StaySearch(dates: value.dates, guests: n),
                        itemBuilder: (_) => [
                          for (var i = 1; i <= 10; i++)
                            PopupMenuItem(value: i, child: Text('$i khách')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3EF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline, color: brand),
                              const SizedBox(width: 10),
                              Text(
                                '${value.guests} khách',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.search),
                    label: const Text('Xem chỗ ở phù hợp'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() => _city = city);
      _showResults();
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPage.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _filters() async {
    var price = _price;
    var amenity = _amenity;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tìm đúng không gian của bạn',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Ngân sách mỗi đêm',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in <int?>[null, 700000, 1000000, 1500000])
                      ChoiceChip(
                        label: Text(
                          p == null ? 'Không giới hạn' : '≤ ${money(p)}',
                        ),
                        selected: price == p,
                        onSelected: (_) => update(() => price = p),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tiện nghi bạn cần',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final a in [
                      'Tất cả',
                      'Wi-Fi',
                      'Bếp',
                      'Hồ bơi',
                      'Bãi đỗ xe',
                      'Điều hòa',
                    ])
                      ChoiceChip(
                        label: Text(a),
                        selected: amenity == a,
                        onSelected: (_) => update(() => amenity = a),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => update(() {
                        price = null;
                        amenity = 'Tất cả';
                      }),
                      child: const Text('Đặt lại'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Áp dụng bộ lọc'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted)
      setState(() {
        _price = price;
        _amenity = amenity;
      });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final favorites = ref.watch(favoritesProvider);
    final search = ref.watch(staySearchProvider);
    final featured = _featuredDestinations
        .where((d) => _region == 'Tất cả' || _regions[_region]!.contains(d.$1))
        .toList();
    bool matches(Room r) =>
        r.active &&
        r.capacity >= search.guests &&
        (_price == null || r.price <= _price!) &&
        (search.dates == null ||
            repo.available(r, search.dates!.start, search.dates!.end));
    int minimum(Homestay h) => repo.rooms
        .where((r) => r.homestayId == h.id && matches(r))
        .map((r) => r.price)
        .reduce((a, b) => a < b ? a : b);
    final homes = repo.homestays
        .where(
          (h) =>
              '${h.name} ${h.city} ${h.address} ${h.amenities.join(' ')}'
                  .toLowerCase()
                  .contains(_query.text.trim().toLowerCase()) &&
              (!widget.favoritesOnly || favorites.contains(h.id)) &&
              (_city == 'Tất cả' || h.city == _city) &&
              (_amenity == 'Tất cả' || h.amenities.contains(_amenity)) &&
              repo.rooms.any((r) => r.homestayId == h.id && matches(r)),
        )
        .toList();
    if (_sort != 'Gợi ý')
      homes.sort(
        (a, b) => _sort == 'Giá tăng dần'
            ? minimum(a).compareTo(minimum(b))
            : minimum(b).compareTo(minimum(a)),
      );
    final heroCity = _heroDestinations[_heroIndex].$1;
    if (widget.favoritesOnly) {
      final saved = repo.homestays
          .where(
            (h) =>
                favorites.contains(h.id) &&
                repo.rooms.any((r) => r.homestayId == h.id && r.active),
          )
          .toList();
      return PageBody(
        maxWidth: 1200,
        children: [
          const SectionHeading(
            'Nơi bạn đã lưu',
            'Những chỗ ở dành cho chuyến đi tiếp theo.',
          ),
          if (saved.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 70,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Color(0xFFEEF2FF),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 42,
                        color: brand,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Chưa có nơi yêu thích',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chạm biểu tượng trái tim ở một homestay bạn thích để lưu vào đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => context.go('/explore'),
                      child: const Text('Đi khám phá'),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 850
                    ? 3
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 20,
                  children: [
                    for (final home in saved)
                      SizedBox(
                        width: width,
                        child: HomeCard(
                          home: home,
                          price: repo.rooms
                              .where((r) => r.homestayId == home.id && r.active)
                              .map((r) => r.price)
                              .reduce((a, b) => a < b ? a : b),
                          reviews: repo.reviews
                              .where((r) => r.homestayId == home.id)
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageBody(
          eager: true,
          maxWidth: 1200,
          children: [
            if (!widget.favoritesOnly) ...[
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() => _city = heroCity);
                  _showResults();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 195,
                        child: PageView.builder(
                          controller: _heroPage,
                          itemCount: _heroDestinations.length,
                          onPageChanged: (index) =>
                              setState(() => _heroIndex = index),
                          itemBuilder: (context, index) => Image.asset(
                            photosFor(_heroDestinations[index].$2).first.asset,
                            width: double.infinity,
                            height: 195,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xD32B211A),
                                Color(0x55382512),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 18,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HHL STAY  /  GỢI Ý CUỐI TUẦN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Trốn phố.\nChạm bình yên.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Khám phá $heroCity  →',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 20,
                        child: Row(
                          children: [
                            for (var i = 0; i < _heroDestinations.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 4),
                                width: i == _heroIndex ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _heroIndex
                                      ? Colors.white
                                      : Colors.white60,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else
              const SectionHeading(
                'Bộ sưu tập của bạn',
                'Lưu một nơi đẹp, dành cho chuyến đi tiếp theo.',
              ),
            if (!widget.favoritesOnly)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                elevation: 3,
                shadowColor: const Color(0x18000000),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _openSearch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: brand,
                          size: 27,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _query.text.isNotEmpty
                                    ? _query.text
                                    : _city == 'Tất cả'
                                    ? 'Bạn muốn đi đâu?'
                                    : _city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                search.dates == null
                                    ? 'Điểm đến · Thêm ngày · ${search.guests} khách'
                                    : '${dateLabel(search.dates!.start)} – ${dateLabel(search.dates!.end)} · ${search.guests} khách',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CircleAvatar(
                          radius: 19,
                          backgroundColor: Color(0xFFEEF2FF),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            if (!widget.favoritesOnly) ...[
              const SectionHeading(
                'Khám phá Việt Nam',
                'Tìm một điểm đến cho chuyến đi tiếp theo.',
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (final region in ['Tất cả', ..._regions.keys])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(region),
                          selected: _region == region,
                          onSelected: (_) => setState(() {
                            _region = region;
                            _city = 'Tất cả';
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 136,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final destination = featured[index];
                    final count = repo.homestays
                        .where((h) => h.city == destination.$1)
                        .length;
                    return SizedBox(
                      width: 180,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() => _city = destination.$1);
                          _showResults();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              StayPhoto(
                                destination.$2,
                                height: 136,
                                radius: 0,
                                label: false,
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xBF171815),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 14,
                                right: 10,
                                bottom: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      destination.$1,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '$count chỗ ở',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
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
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                tooltip: 'Chọn điểm đến',
                onSelected: (city) {
                  setState(() => _city = city);
                  _showResults();
                },
                itemBuilder: (_) => [
                  for (final city in [
                    'Tất cả',
                    ...repo.homestays
                        .map((h) => h.city)
                        .toSet()
                        .where(
                          (city) =>
                              _region == 'Tất cả' ||
                              _regions[_region]!.contains(city),
                        ),
                  ])
                    PopupMenuItem(value: city, child: Text(city)),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9E5DF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: brand),
                      const SizedBox(width: 7),
                      Text(
                        _city == 'Tất cả' ? 'Xem mọi điểm đến' : _city,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, size: 17),
                    ],
                  ),
                ),
              ),
            ),
            if (!widget.favoritesOnly) ...[
              const SectionHeading(
                'Đi theo cách của bạn',
                'Lọc nhanh theo tiện nghi và mức giá.',
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (final item in const <(IconData, String, String, int?)>[
                      (Icons.explore_outlined, 'Tất cả', 'Tất cả', null),
                      (Icons.wifi_rounded, 'Wi-Fi', 'Wi-Fi', null),
                      (Icons.kitchen_outlined, 'Có bếp', 'Bếp', null),
                      (Icons.pool_rounded, 'Có hồ bơi', 'Hồ bơi', null),
                      (Icons.ac_unit_rounded, 'Điều hòa', 'Điều hòa', null),
                      (Icons.local_parking_rounded, 'Đỗ xe', 'Bãi đỗ xe', null),
                      (Icons.savings_outlined, 'Giá tốt', 'budget', 700000),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(item.$1, size: 17),
                          label: Text(item.$2),
                          selected: item.$3 == 'budget'
                              ? _price == item.$4 && _amenity == 'Tất cả'
                              : _amenity == item.$3 && _price == null,
                          onSelected: (_) {
                            setState(() {
                              _amenity =
                                  item.$3 == 'budget' || item.$3 == 'Tất cả'
                                  ? 'Tất cả'
                                  : item.$3;
                              _price = item.$3 == 'budget' ? item.$4 : null;
                              _city = 'Tất cả';
                              _query.clear();
                            });
                            _showResults();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
            Container(
              key: _resultsKey,
              child: const SectionHeading(
                'Không gian dành cho bạn',
                'Chọn ngày để xem phòng còn trống và giá phù hợp.',
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _filters,
                  icon: const Icon(Icons.tune, size: 17),
                  label: Text(
                    'Bộ lọc${_price != null || _amenity != 'Tất cả' ? ' • Đang bật' : ''}',
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Sắp xếp',
                  onSelected: (s) => setState(() => _sort = s),
                  itemBuilder: (_) => [
                    for (final s in ['Gợi ý', 'Giá tăng dần', 'Giá giảm dần'])
                      PopupMenuItem(value: s, child: Text(s)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert, size: 17),
                        const SizedBox(width: 6),
                        Text(_sort, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${homes.length} homestay phù hợp',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (homes.isEmpty) ...[
              const EmptyState(
                'Chưa có kết quả. Thử đổi bộ lọc hoặc thêm homestay vào yêu thích.',
              ),
              TextButton(
                onPressed: () {
                  ref.read(staySearchProvider.notifier).state =
                      const StaySearch();
                  setState(() {
                    _query.clear();
                    _city = _amenity = 'Tất cả';
                    _price = null;
                  });
                },
                child: const Text('Xóa bộ lọc'),
              ),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 850
                    ? 3
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 20,
                  children: [
                    for (final home in homes)
                      SizedBox(
                        width: width,
                        child: HomeCard(
                          home: home,
                          price: minimum(home),
                          reviews: repo.reviews
                              .where((r) => r.homestayId == home.id)
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'HHL STAY  /  NHỮNG CHUYẾN ĐI THẬT GẦN',
              style: TextStyle(fontSize: 10, letterSpacing: 1.3, color: muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}

class HomeCard extends ConsumerStatefulWidget {
  const HomeCard({
    super.key,
    required this.home,
    required this.price,
    required this.reviews,
  });
  final Homestay home;
  final int price;
  final List<StayReview> reviews;
  @override
  ConsumerState<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends ConsumerState<HomeCard> {
  int _photo = 0;
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final home = widget.home;
    final price = widget.price;
    final reviews = widget.reviews;
    final favorites = ref.watch(favoritesProvider);
    final photos = photosFor(home.id);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Card(
          elevation: _hovered ? 8 : 2,
          shadowColor: brand.withValues(alpha: _hovered ? .18 : .06),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 244,
                    child: PageView.builder(
                      itemCount: photos.length,
                      onPageChanged: (index) => setState(() => _photo = index),
                      itemBuilder: (context, index) {
                        final image = Image.asset(
                          photos[index].asset,
                          width: double.infinity,
                          height: 244,
                          fit: BoxFit.cover,
                          semanticLabel: photos[index].caption,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded || frame != null) {
                                  return child;
                                }
                                return Shimmer.fromColors(
                                  baseColor: const Color(0xFFEAE6E0),
                                  highlightColor: const Color(0xFFF8F6F3),
                                  loop: 1,
                                  child: const ColoredBox(color: Colors.white),
                                );
                              },
                        );
                        return GestureDetector(
                          onTap: () => context.go('/homestays/${home.id}'),
                          child: index == 0
                              ? Hero(
                                  tag: 'homestay-cover-${home.id}',
                                  child: image,
                                )
                              : image,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        home.city,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: favorites.contains(home.id)
                            ? brand
                            : ink,
                      ),
                      tooltip: favorites.contains(home.id)
                          ? 'Bỏ yêu thích'
                          : 'Yêu thích',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final next = {...favorites};
                        next.contains(home.id)
                            ? next.remove(home.id)
                            : next.add(home.id);
                        ref.read(favoritesProvider.notifier).state = next;
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          favorites.contains(home.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          key: ValueKey(favorites.contains(home.id)),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < photos.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: i == _photo ? 15 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _photo
                                  ? Colors.white
                                  : Colors.white70,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: muted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            home.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      home.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 7),
                    if (reviews.isNotEmpty) ReviewScore(reviews),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        for (final amenity in home.amenities.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3EF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              amenity,
                              style: const TextStyle(fontSize: 11, color: ink),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giá từ mỗi đêm',
                                style: TextStyle(fontSize: 11, color: muted),
                              ),
                              Text(
                                money(price),
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: brand,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => context.go('/homestays/${home.id}'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEEF2FF),
                            foregroundColor: brand,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Xem phòng'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
