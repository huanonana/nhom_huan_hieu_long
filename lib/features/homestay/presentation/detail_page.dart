import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/router/navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../../core/widgets/stay_gallery.dart';
import '../../ai/data/ai_service.dart';
import '../../ai/presentation/ai_provider.dart';
import '../../review/domain/review.dart';
import '../../review/presentation/review_widgets.dart';

class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  final _scroll = ScrollController();
  int _activeTab = 0;
  final _roomsKey = GlobalKey();
  final _reviewsKey = GlobalKey();
  final _amenitiesKey = GlobalKey();
  final _introKey = GlobalKey();
  final _policyKey = GlobalKey();
  bool _summarizingReviews = false;
  String? _reviewSummary;
  List<GlobalKey> get _sectionKeys => [
    _roomsKey,
    _reviewsKey,
    _amenitiesKey,
    _introKey,
    _policyKey,
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackSection);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordView());
  }

  void _recordView() {
    if (!mounted) return;
    final recent = ref.read(recentHomestaysProvider);
    ref.read(recentHomestaysProvider.notifier).state = [
      widget.id,
      ...recent.where((id) => id != widget.id),
    ].take(8).toList();
  }

  @override
  void didUpdateWidget(covariant DetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recordView());
    }
  }

  void _trackSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var next = 0;
      // Keep this list in the same order as the page. A later heading may
      // already be visible below the current one; it should become active
      // only after it reaches the sticky-tab reading line.
      final sections = <(GlobalKey, int)>[
        (_introKey, 3),
        (_amenitiesKey, 2),
        (_roomsKey, 0),
        (_policyKey, 4),
        (_reviewsKey, 1),
      ];
      for (final section in sections) {
        final object = section.$1.currentContext?.findRenderObject();
        if (object is RenderBox &&
            object.hasSize &&
            object.localToGlobal(Offset.zero).dy <= 145) {
          next = section.$2;
        }
      }
      if (next != _activeTab) setState(() => _activeTab = next);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_trackSection);
    _scroll.dispose();
    super.dispose();
  }

  void _jumpTo(GlobalKey key) {
    final index = _sectionKeys.indexOf(key);
    if (index >= 0 && index != _activeTab) setState(() => _activeTab = index);
    final target = key.currentContext;
    if (target != null)
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        alignment: 0,
      );
  }

  void _showAllPhotos(String homestayId) {
    final home = ref
        .read(repositoryProvider)
        .homestays
        .where((item) => item.id == homestayId)
        .firstOrNull;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: SafeArea(
          child: StayGallery(
            homestayId,
            fullscreen: true,
            imageUrls: home?.imageUrls ?? const [],
          ),
        ),
      ),
    );
  }

  Future<void> _summarizeReviews(List<StayReview> reviews) async {
    setState(() {
      _summarizingReviews = true;
      _reviewSummary = null;
    });
    final summary = await ref.read(aiServiceProvider).summarizeReviews([
      for (final review in reviews) '${review.rating}/5 sao: ${review.comment}',
    ]);
    if (!mounted) return;
    setState(() => _summarizingReviews = false);
    if (AiService.isErrorMessage(summary)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$summary Bạn vẫn xem được đánh giá bên dưới.')),
      );
      return;
    }
    setState(() => _reviewSummary = summary);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider);
    final home = repo.homestays.where((h) => h.id == widget.id).firstOrNull;
    if (home == null) return const EmptyState('Không tìm thấy homestay.');
    final rooms = repo.rooms.where((r) => r.homestayId == home.id).toList();
    final active = rooms.where((r) => r.active).toList();
    final minimum = active.isEmpty
        ? null
        : active.map((r) => r.price).reduce((a, b) => a < b ? a : b);
    final search = ref.watch(staySearchProvider);
    final favorites = ref.watch(favoritesProvider);
    final reviews = repo.reviews
        .where((r) => r.homestayId == home.id)
        .toList()
        .reversed
        .toList();
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width < 1180
              ? MediaQuery.sizeOf(context).width
              : 1180,
          maxWidth: 1180,
        ),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 300,
                    foregroundColor: Colors.white,
                    backgroundColor: brand,
                    leading: IconButton(
                      tooltip: 'Quay lại',
                      onPressed: () =>
                          navigateBack(context, fallback: '/explore'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    actions: [
                      IconButton(
                        tooltip: favorites.contains(home.id)
                            ? 'Bỏ yêu thích'
                            : 'Yêu thích',
                        onPressed: () {
                          final next = {...favorites};
                          next.contains(home.id)
                              ? next.remove(home.id)
                              : next.add(home.id);
                          ref.read(favoritesProvider.notifier).state = next;
                        },
                        icon: Icon(
                          favorites.contains(home.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        home.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'homestay-cover-${home.id}',
                            child: buildStayImage(
                              photosFor(
                                home.id,
                                imageSources: home.imageUrls,
                              ).first.asset,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x33000000),
                                  Colors.transparent,
                                  Color(0x99000000),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 68,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _showAllPhotos(home.id),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Xem tất cả ảnh'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DetailTabsDelegate(
                      activeTab: _activeTab,
                      onSelected: (index) => _jumpTo(_sectionKeys[index]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            home.city.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w700,
                              color: brand,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ReviewScore(reviews),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 17,
                                color: muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  home.address,
                                  style: const TextStyle(color: muted),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Một khoảng nghỉ cho riêng bạn',
                            key: _introKey,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(home.description),
                          SectionHeading(
                            'Tiện nghi',
                            'Những điều giúp bạn cảm thấy như ở nhà.',
                            key: _amenitiesKey,
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final a in home.amenities)
                                Chip(
                                  avatar: Icon(
                                    a == 'Wi-Fi'
                                        ? Icons.wifi
                                        : a == 'Bếp'
                                        ? Icons.kitchen_outlined
                                        : a == 'Hồ bơi'
                                        ? Icons.pool
                                        : a == 'Bãi đỗ xe'
                                        ? Icons.local_parking
                                        : Icons.ac_unit,
                                    size: 17,
                                  ),
                                  label: Text(a),
                                ),
                            ],
                          ),
                          Container(
                            key: _roomsKey,
                            child: const SectionHeading(
                              'Chọn không gian của bạn',
                              'Giá theo đêm • Thanh toán tại homestay',
                            ),
                          ),
                          const StaySearchBar(),
                          const SizedBox(height: 16),
                          if (rooms.isEmpty)
                            const EmptyState('Chủ nhà chưa mở phòng để đặt.'),
                          for (final room in rooms)
                            Builder(
                              builder: (context) {
                                final roomPhotos = photosFor(
                                  home.id,
                                  imageSources: home.imageUrls,
                                );
                                final fits = room.capacity >= search.guests;
                                final free =
                                    room.active &&
                                    (search.dates == null ||
                                        repo.available(
                                          room,
                                          search.dates!.start,
                                          search.dates!.end,
                                        ));
                                final bookable =
                                    fits &&
                                    free &&
                                    ref.watch(roleProvider) == DemoRole.guest;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: buildStayImage(
                                                  roomPhotos[rooms.indexOf(
                                                            room,
                                                          ) %
                                                          roomPhotos.length]
                                                      .asset,
                                                  width: 76,
                                                  height: 76,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 200,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      room.name,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.titleMedium,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'Tối đa ${room.capacity} khách',
                                                      style: const TextStyle(
                                                        color: muted,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      !room.active
                                                          ? 'Đang bảo trì'
                                                          : !fits
                                                          ? 'Không đủ sức chứa'
                                                          : !free
                                                          ? 'Hết phòng trong ngày đã chọn'
                                                          : 'Sẵn sàng đón bạn',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: bookable
                                                            ? const Color(
                                                                0xFF218567,
                                                              )
                                                            : muted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(),
                                          Text(
                                            '${money(room.price)} / đêm',
                                            style: const TextStyle(
                                              fontSize: 19,
                                              color: brand,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton(
                                              onPressed: bookable
                                                  ? () => context.go(
                                                      '/book/${room.id}?${Uri(queryParameters: {'back': '/homestays/${home.id}'}).query}',
                                                    )
                                                  : null,
                                              child: const Text(
                                                'Chọn ngày & đặt phòng',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          SectionHeading(
                            'Trước khi bạn đặt',
                            'Thông tin rõ ràng cho một chuyến đi nhẹ nhàng.',
                            key: _policyKey,
                          ),
                          const Text(
                            '• Yêu cầu đặt phòng chờ chủ nhà duyệt trong tối đa 24 giờ.\n• Bạn có thể hủy miễn phí khi đơn đang chờ duyệt.\n• Đơn đã xác nhận có thể hủy miễn phí trước giờ nhận phòng 24 giờ.\n• Giá hiển thị không thêm phụ phí trong bản trải nghiệm.',
                          ),
                          SectionHeading(
                            'Khách đã ở nói gì?',
                            'Chỉ hiển thị đánh giá từ đơn đã trả phòng.',
                            key: _reviewsKey,
                          ),
                          if (reviews.length >= 3) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: _summarizingReviews
                                    ? null
                                    : () => _summarizeReviews(reviews),
                                icon: _summarizingReviews
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  _summarizingReviews
                                      ? 'Đang đọc đánh giá…'
                                      : '✨ Tóm tắt bằng AI',
                                ),
                              ),
                            ),
                            if (_reviewSummary case final summary?)
                              Card(
                                color: const Color(0xFFEEF2FF),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: brand,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Tóm tắt từ AI',
                                              style: TextStyle(
                                                color: brand,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(summary),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                          if (reviews.isEmpty)
                            const Text(
                              'Chưa có đánh giá. Hãy là người đầu tiên chia sẻ sau chuyến đi.',
                              style: TextStyle(color: muted),
                            ),
                          ReviewList(reviews),
                          const SectionHeading(
                            'Có thể bạn thích',
                            'Thêm vài chỗ ở để so sánh trước khi đặt.',
                          ),
                          SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: repo.homestays
                                  .where(
                                    (h) =>
                                        h.id != home.id &&
                                        repo.rooms.any(
                                          (r) =>
                                              r.homestayId == h.id && r.active,
                                        ),
                                  )
                                  .length,
                              separatorBuilder: (_, i) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final other = repo.homestays
                                    .where(
                                      (h) =>
                                          h.id != home.id &&
                                          repo.rooms.any(
                                            (r) =>
                                                r.homestayId == h.id &&
                                                r.active,
                                          ),
                                    )
                                    .elementAt(i);
                                final price = repo.rooms
                                    .where(
                                      (r) =>
                                          r.homestayId == other.id && r.active,
                                    )
                                    .map((r) => r.price)
                                    .reduce((a, b) => a < b ? a : b);
                                return InkWell(
                                  onTap: () =>
                                      context.push('/homestays/${other.id}'),
                                  borderRadius: BorderRadius.circular(15),
                                  child: SizedBox(
                                    width: 190,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        StayPhoto(
                                          other.id,
                                          height: 132,
                                          radius: 14,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          other.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          other.city,
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Từ ${money(price)} / đêm',
                                          style: const TextStyle(
                                            color: brand,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Homestay và hình ảnh trong bản này là dữ liệu minh họa. Chưa có đánh giá của khách thực tế.',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giá từ / đêm',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                        Text(
                          minimum == null ? 'Chưa mở phòng' : money(minimum),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => _jumpTo(_roomsKey),
                        icon: const Icon(Icons.bed_outlined),
                        label: const Text('Chọn phòng'),
                        style: FilledButton.styleFrom(
                          elevation: 7,
                          shadowColor: brand.withValues(alpha: 0.32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTabsDelegate extends SliverPersistentHeaderDelegate {
  const _DetailTabsDelegate({
    required this.activeTab,
    required this.onSelected,
  });

  final int activeTab;
  final ValueChanged<int> onSelected;
  static const _labels = [
    'Phòng',
    'Đánh giá',
    'Tiện nghi',
    'Giới thiệu',
    'Chính sách',
  ];

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: Colors.white,
    elevation: overlapsContent ? 3 : 0,
    child: SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Text(_labels[i]),
                  selected: activeTab == i,
                  onSelected: (_) => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  bool shouldRebuild(covariant _DetailTabsDelegate oldDelegate) =>
      oldDelegate.activeTab != activeTab ||
      oldDelegate.onSelected != onSelected;
}
