import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_widgets.dart';
import '../../../core/widgets/stay_gallery.dart';
import '../../ai/data/ai_service.dart';
import '../../ai/presentation/ai_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../homestay/domain/catalog.dart';
import '../../review/domain/review.dart';
import '../domain/booking.dart';
import 'firestore_repository_provider.dart';
import 'booking_status_badge.dart';

class FirebaseExplorePage extends ConsumerStatefulWidget {
  const FirebaseExplorePage({super.key, this.favoritesOnly = false});
  final bool favoritesOnly;

  @override
  ConsumerState<FirebaseExplorePage> createState() =>
      _FirebaseExplorePageState();
}

class _FirebaseExplorePageState extends ConsumerState<FirebaseExplorePage> {
  String _query = '';
  String _city = 'Tất cả';
  final _resultsKey = GlobalKey();
  static const _destinations = <(String, String)>[
    ('Đà Lạt', 'pine'),
    ('Đà Nẵng', 'sea'),
    ('Hội An', 'garden'),
    ('Sa Pa', 'sapa'),
    ('Hà Nội', 'hanoi'),
    ('Phú Quốc', 'phuquoc'),
  ];

  @override
  Widget build(BuildContext context) {
    final homes = ref.watch(firestoreHomestaysProvider);
    final rooms = ref.watch(firestoreRoomsProvider);
    final reviews = ref.watch(firestoreReviewsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final favorites = user == null
        ? ref.watch(favoritesProvider)
        : ref.watch(favoriteIdsProvider(user.uid)).valueOrNull ??
              const <String>{};
    return PageBody(
      maxWidth: 1180,
      children: [
        if (!widget.favoritesOnly) ...[
          _WelcomeBanner(onExplore: _scrollToStays),
          const SizedBox(height: 14),
          const _TrustRow(),
          const SizedBox(height: 24),
        ],
        Text(
          widget.favoritesOnly ? 'Nơi bạn đã lưu' : 'Chọn nơi nghỉ phù hợp',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          widget.favoritesOnly
              ? 'Những chỗ nghỉ bạn muốn quay lại.'
              : 'Không gian đẹp, giá rõ ràng và đặt phòng an tâm.',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Thành phố, homestay hoặc khu vực',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE9E5E0)),
            ),
          ),
        ),
        if (!widget.favoritesOnly) ...[
          const SectionHeading(
            'Điểm đến nổi bật',
            'Chạm một nơi để lọc homestay.',
          ),
          SizedBox(
            height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _destinations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final destination = _destinations[index];
                final selected = _city == destination.$1;
                final photo = photosFor(destination.$2).first;
                return InkWell(
                  onTap: () => setState(
                    () => _city = selected ? 'Tất cả' : destination.$1,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    width: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: AssetImage(photo.asset),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? brand : Colors.transparent,
                          width: 3,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB8000000)],
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        destination.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SectionHeading(
          'Homestay dành cho bạn',
          'Khám phá nơi ở được chủ nhà đăng tải.',
        ),
        Container(key: _resultsKey),
        homes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _LoadError(message: 'Không tải được danh sách homestay.'),
          data: (allHomes) => rooms.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                const _LoadError(message: 'Không tải được danh sách phòng.'),
            data: (allRooms) => reviews.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _LoadError(message: 'Không tải được đánh giá.'),
              data: (allReviews) {
                final visible = allHomes.where((home) {
                  final matched = '${home.name} ${home.city} ${home.address}'
                      .toLowerCase()
                      .contains(_query);
                  return matched &&
                      (_city == 'Tất cả' ||
                          home.city.toLowerCase().contains(
                            _city.toLowerCase(),
                          )) &&
                      (!widget.favoritesOnly || favorites.contains(home.id)) &&
                      allRooms.any(
                        (room) => room.homestayId == home.id && room.active,
                      );
                }).toList();
                if (visible.isEmpty) {
                  return _EmptyStays(
                    favoritesOnly: widget.favoritesOnly,
                    hasHomes: allHomes.isNotEmpty,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1050
                        ? 3
                        : constraints.maxWidth >= 680
                        ? 2
                        : 1;
                    final cardWidth = columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 18) / 2;
                    return Wrap(
                      spacing: 18,
                      runSpacing: 4,
                      children: [
                        for (final home in visible)
                          SizedBox(
                            width: cardWidth,
                            child: _RemoteStayCard(
                              home: home,
                              rooms: allRooms
                                  .where((room) => room.homestayId == home.id)
                                  .toList(),
                              reviews: allReviews
                                  .where(
                                    (review) => review.homestayId == home.id,
                                  )
                                  .toList(),
                              favorite: favorites.contains(home.id),
                              onFavorite: () => user == null
                                  ? _toggleLocalFavorite(home.id)
                                  : _toggleFavorite(user.uid, home.id),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _scrollToStays() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultsKey.currentContext;
      if (target != null)
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
        );
    });
  }

  void _toggleLocalFavorite(String id) {
    final next = {...ref.read(favoritesProvider)};
    next.contains(id) ? next.remove(id) : next.add(id);
    ref.read(favoritesProvider.notifier).state = next;
  }

  Future<void> _toggleFavorite(String uid, String homeId) async {
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(homeId);
    final exists = (ref.read(favoriteIdsProvider(uid)).valueOrNull ?? {})
        .contains(homeId);
    try {
      if (exists) {
        await doc.delete();
      } else {
        await doc.set({
          'homestayId': homeId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      if (mounted) showError(context, 'Chưa lưu được homestay yêu thích.');
    }
  }
}

final favoriteIdsProvider = StreamProvider.family<Set<String>, String>(
  (ref, uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet()),
);

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final copy = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: wide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22243A),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFC18C),
                  size: 14,
                ),
                SizedBox(width: 7),
                Text(
                  'HHL STAY  ·  HOMESTAY VIỆT NAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .75,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Nghỉ đúng nơi,\n'),
                TextSpan(
                  text: 'vui trọn chuyến đi.',
                  style: TextStyle(color: brand),
                ),
              ],
            ),
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Khám phá những không gian lưu trú có chất riêng tại các điểm đến yêu thích.',
            style: TextStyle(color: muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onExplore,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5147D9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              shadowColor: const Color(0x665147D9),
            ),
            icon: const Icon(Icons.explore_rounded, size: 19),
            label: const Text('Khám phá homestay'),
          ),
        ],
      );
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: wide ? 300 : 188,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(photosFor('phuquoc').first.asset, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x08000000), Color(0x88000000)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _HeroTag(
                  icon: Icons.bedroom_parent_outlined,
                  label: 'Không gian nghỉ dưỡng',
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 13,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Một nơi chốn,\nmột câu chuyện riêng.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: onExplore,
                      tooltip: 'Khám phá homestay',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: brand,
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(wide ? 28 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
          ),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: wide
            ? Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: copy,
                    ),
                  ),
                  Expanded(child: image),
                ],
              )
            : Column(children: [copy, const SizedBox(height: 18), image]),
      );
    },
  );
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .93),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: brand, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: ink,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFECE8E1)),
    ),
    child: const Row(
      children: [
        Expanded(
          child: _TrustItem(
            icon: Icons.verified_user_outlined,
            label: 'Đặt an tâm',
          ),
        ),
        Expanded(
          child: _TrustItem(
            icon: Icons.payments_outlined,
            label: 'Giá rõ ràng',
          ),
        ),
        Expanded(
          child: _TrustItem(
            icon: Icons.home_work_outlined,
            label: 'Chỗ ở có thật',
          ),
        ),
      ],
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 16, color: brand),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ),
    ],
  );
}

class _EmptyStays extends StatelessWidget {
  const _EmptyStays({required this.favoritesOnly, required this.hasHomes});
  final bool favoritesOnly;
  final bool hasHomes;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 29,
            backgroundColor: Color(0xFFEEF2FF),
            child: Icon(Icons.holiday_village_outlined, color: brand, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            favoritesOnly
                ? 'Chưa có nơi nghỉ đã lưu'
                : hasHomes
                ? 'Chưa có phòng đang mở ở lựa chọn này'
                : 'Đang chuẩn bị những chỗ nghỉ đầu tiên',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            favoritesOnly
                ? 'Lưu một homestay bạn thích để xem lại nhanh tại đây.'
                : 'Chưa có homestay được đăng trên hệ thống. Chủ nhà có thể mở trang quản lý để thêm nơi nghỉ và phòng.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

class _RemoteStayCard extends StatelessWidget {
  const _RemoteStayCard({
    required this.home,
    required this.rooms,
    required this.reviews,
    required this.favorite,
    required this.onFavorite,
  });
  final Homestay home;
  final List<Room> rooms;
  final List<StayReview> reviews;
  final bool favorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final active = rooms.where((room) => room.active).toList();
    final price = active.isEmpty
        ? null
        : active.map((room) => room.price).reduce((a, b) => a < b ? a : b);
    final average = reviews.isEmpty
        ? null
        : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
              reviews.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => contextPush(context, '/homestays/${home.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: photosFor(home.id).length,
                    itemBuilder: (context, index) => Image.asset(
                      photosFor(home.id)[index].asset,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      semanticLabel: photosFor(home.id)[index].caption,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
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
                  top: 12,
                  right: 12,
                  child: IconButton.filledTonal(
                    tooltip: favorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
                    onPressed: onFavorite,
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? brand : null,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${home.city} · ${home.address}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    home.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (average != null) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Colors.amber.shade800,
                        ),
                        Text(
                          '${average.toStringAsFixed(1)} · ${reviews.length} đánh giá',
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          home.amenities.take(3).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price == null
                              ? 'Chưa có phòng mở'
                              : 'Từ ${money(price)} / đêm',
                          style: const TextStyle(
                            color: brand,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            contextPush(context, '/homestays/${home.id}'),
                        child: const Text('Xem chi tiết'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void contextPush(BuildContext context, String path) => context.push(path);

class FirebaseDetailPage extends ConsumerWidget {
  const FirebaseDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homes = ref.watch(firestoreHomestaysProvider);
    final rooms = ref.watch(firestoreRoomsProvider);
    final reviews = ref.watch(firestoreReviewsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final favorites = user == null
        ? ref.watch(favoritesProvider)
        : ref.watch(favoriteIdsProvider(user.uid)).valueOrNull ??
              const <String>{};
    return homes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          const _LoadError(message: 'Không tải được homestay.'),
      data: (allHomes) {
        final matches = allHomes.where((home) => home.id == id);
        if (matches.isEmpty)
          return const EmptyState('Không tìm thấy homestay.');
        final home = matches.first;
        return rooms.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              const _LoadError(message: 'Không tải được phòng.'),
          data: (allRooms) => reviews.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                const _LoadError(message: 'Không tải được đánh giá.'),
            data: (allReviews) {
              final homeRooms = allRooms
                  .where((room) => room.homestayId == home.id)
                  .toList();
              final homeReviews = allReviews
                  .where((review) => review.homestayId == home.id)
                  .toList();
              final activeRooms = homeRooms
                  .where((room) => room.active)
                  .toList(growable: false);
              final cheapestRoom = activeRooms.isEmpty
                  ? null
                  : activeRooms.reduce((a, b) => a.price <= b.price ? a : b);
              final favorite = favorites.contains(home.id);
              return Column(
                children: [
                  Expanded(
                    child: PageBody(
                      key: const ValueKey('firebase-detail-body'),
                      maxWidth: 1180,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => context.go('/explore'),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Khám phá'),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              key: const ValueKey('firebase-detail-favorite'),
                              onPressed: () => _toggleDetailFavorite(
                                context,
                                ref,
                                user?.uid,
                                home.id,
                                favorite,
                              ),
                              icon: Icon(
                                favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favorite ? brand : null,
                              ),
                              label: Text(
                                favorite ? 'Đã yêu thích' : 'Yêu thích',
                              ),
                            ),
                          ],
                        ),
                        StayGallery(home.id),
                        const SizedBox(height: 20),
                        Text(
                          home.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${home.address}, ${home.city}',
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 10),
                        if (homeReviews.isNotEmpty) ...[
                          _ReviewRatingSummary(homeReviews),
                          const SizedBox(height: 10),
                        ],
                        Text(home.description),
                        const SizedBox(height: 10),
                        Text('Tiện nghi: ${home.amenities.join(' · ')}'),
                        const SectionHeading(
                          'Danh sách phòng',
                          'Chọn phòng phù hợp với chuyến đi.',
                        ),
                        if (homeRooms.isEmpty)
                          const EmptyState('Homestay chưa có phòng.'),
                        for (final room in homeRooms)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Icon(
                                room.active
                                    ? Icons.bed_outlined
                                    : Icons.build_outlined,
                                color: room.active ? brand : muted,
                              ),
                              title: Text(room.name),
                              subtitle: Text(
                                '${room.capacity} khách · ${room.active ? 'Đang mở đặt phòng' : 'Đang bảo trì'}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(money(room.price)),
                                  if (room.active) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ],
                              ),
                              onTap: room.active
                                  ? () => context.go('/book/${room.id}')
                                  : null,
                            ),
                          ),
                        const SectionHeading(
                          'Đánh giá',
                          'Chia sẻ từ khách đã lưu trú.',
                        ),
                        _FirebaseReviewSummary(homeReviews),
                        if (homeReviews.isEmpty)
                          const Text('Chưa có đánh giá.'),
                        for (final review in homeReviews.reversed)
                          Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.account_circle_outlined,
                              ),
                              title: Text(
                                '${review.guestName} · ${review.rating}/5',
                              ),
                              subtitle: Text(review.comment),
                            ),
                          ),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x140F172A),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Giá từ / đêm',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          cheapestRoom == null
                                              ? 'Chưa mở phòng'
                                              : money(cheapestRoom.price),
                                          style: const TextStyle(
                                            color: brand,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    key: const ValueKey('firebase-detail-book'),
                                    onPressed: cheapestRoom == null
                                        ? null
                                        : () => context.go(
                                            '/book/${cheapestRoom.id}',
                                          ),
                                    icon: const Icon(Icons.bed_outlined),
                                    label: Text(
                                      cheapestRoom == null
                                          ? 'Chưa có phòng trống'
                                          : 'Đặt phòng',
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _FirebaseReviewSummary extends ConsumerStatefulWidget {
  const _FirebaseReviewSummary(this.reviews);
  final List<StayReview> reviews;

  @override
  ConsumerState<_FirebaseReviewSummary> createState() =>
      _FirebaseReviewSummaryState();
}

class _FirebaseReviewSummaryState
    extends ConsumerState<_FirebaseReviewSummary> {
  bool _busy = false;
  String? _summary;

  Future<void> _summarize() async {
    setState(() {
      _busy = true;
      _summary = null;
    });
    final result = await ref.read(aiServiceProvider).summarizeReviews([
      for (final review in widget.reviews)
        '${review.rating}/5 sao: ${review.comment}',
    ]);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == AiService.unavailableMessage ||
        result == AiService.friendlyErrorMessage) {
      showError(
        context,
        result == AiService.unavailableMessage
            ? 'Tính năng AI chưa khả dụng. Bạn vẫn xem được đánh giá bên dưới.'
            : 'Chưa thể kết nối AI. Bạn vẫn xem được đánh giá bên dưới.',
      );
      return;
    }
    setState(() => _summary = result);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.length < 3) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_summary case final summary?)
          Card(
            color: const Color(0xFFF5F0FF),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF68418A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tóm tắt từ AI',
                          style: TextStyle(
                            color: Color(0xFF68418A),
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy ? null : _summarize,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_busy ? 'Đang đọc đánh giá…' : 'Tóm tắt bằng AI'),
          ),
        ),
      ],
    );
  }
}

Future<void> _toggleDetailFavorite(
  BuildContext context,
  WidgetRef ref,
  String? uid,
  String homeId,
  bool currentlyFavorite,
) async {
  if (uid == null) {
    final next = {...ref.read(favoritesProvider)};
    currentlyFavorite ? next.remove(homeId) : next.add(homeId);
    ref.read(favoritesProvider.notifier).state = next;
    return;
  }
  final favoriteRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .doc(homeId);
  try {
    if (currentlyFavorite) {
      await favoriteRef.delete();
    } else {
      await favoriteRef.set({
        'homestayId': homeId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (_) {
    if (context.mounted)
      showError(context, 'Chưa lưu được homestay yêu thích.');
  }
}

class _ReviewRatingSummary extends StatelessWidget {
  const _ReviewRatingSummary(this.reviews);
  final List<StayReview> reviews;

  @override
  Widget build(BuildContext context) {
    final average =
        reviews.fold<int>(0, (sum, review) => sum + review.rating) /
        reviews.length;
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
        const SizedBox(width: 4),
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 6),
        Text(
          '(${reviews.length} đánh giá)',
          style: const TextStyle(color: muted),
        ),
      ],
    );
  }
}

class FirebaseBookingFormPage extends ConsumerStatefulWidget {
  const FirebaseBookingFormPage({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<FirebaseBookingFormPage> createState() =>
      _FirebaseBookingFormPageState();
}

class _FirebaseBookingFormPageState
    extends ConsumerState<FirebaseBookingFormPage> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  DateTimeRange? _dates;
  int _guests = 1;
  bool _busy = false;
  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(firestoreRoomsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user != null && _name.text.isEmpty) _name.text = user.displayName;
    return rooms.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const _LoadError(message: 'Không tải được phòng.'),
      data: (allRooms) {
        final matches = allRooms.where((room) => room.id == widget.roomId);
        if (matches.isEmpty)
          return const EmptyState('Phòng không còn tồn tại.');
        final room = matches.first;
        final nights = _dates == null
            ? 0
            : stayDate(_dates!.end).difference(stayDate(_dates!.start)).inDays;
        final canSubmit =
            user != null &&
            room.active &&
            _dates != null &&
            nights > 0 &&
            nights <= 30;
        return PageBody(
          maxWidth: 480,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/homestays/${room.homestayId}'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Chi tiết homestay'),
            ),
            Text(
              'Đặt phòng',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên khách'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final chosen = await showDateRangePicker(
                  context: context,
                  firstDate: stayDate(now),
                  lastDate: stayDate(now).add(const Duration(days: 365)),
                  initialDateRange: _dates,
                );
                if (chosen != null && mounted) setState(() => _dates = chosen);
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _dates == null
                    ? 'Chọn ngày'
                    : '${dateLabel(_dates!.start)} – ${dateLabel(_dates!.end)}',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _guests.clamp(1, room.capacity),
              decoration: const InputDecoration(labelText: 'Số khách'),
              items: [
                for (var i = 1; i <= room.capacity; i++)
                  DropdownMenuItem(value: i, child: Text('$i khách')),
              ],
              onChanged: (value) => setState(() => _guests = value ?? 1),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
            const SizedBox(height: 16),
            Text(
              _dates == null
                  ? 'Chọn ngày để xem tổng tiền'
                  : 'Tổng cộng: ${money(room.price * nights)}',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: !canSubmit || _busy
                  ? null
                  : () => _submit(room, user.uid),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Gửi yêu cầu đặt phòng'),
            ),
            if (user == null) const Text('Đăng nhập để đặt phòng.'),
          ],
        );
      },
    );
  }

  Future<void> _submit(Room room, String uid) async {
    if (_dates == null || _name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(firestoreBookingRepositoryProvider)
          .create(
            roomId: room.id,
            guestId: uid,
            guestName: _name.text.trim(),
            checkIn: _dates!.start,
            checkOut: _dates!.end,
            guests: _guests,
            note: _note.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu đặt phòng.')),
        );
        context.go('/bookings');
      }
    } catch (error) {
      if (mounted)
        showError(
          context,
          error is BookingException
              ? error.message
              : 'Chưa thể tạo đơn. Kiểm tra ngày và kết nối rồi thử lại.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class FirebaseBookingsPage extends ConsumerWidget {
  const FirebaseBookingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final bookings = ref.watch(firestoreBookingsProvider);
    final reviews =
        ref.watch(firestoreReviewsProvider).valueOrNull ?? const <StayReview>[];
    final homes =
        ref.watch(firestoreHomestaysProvider).valueOrNull ?? const <Homestay>[];
    if (user == null)
      return const _LoadError(message: 'Vui lòng đăng nhập lại.');
    final isHost = user.role.name == 'host';
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadError(
        message: 'Không tải được đơn đặt phòng: $error',
        onRetry: () => ref.invalidate(firestoreBookingsProvider),
      ),
      data: (items) => PageBody(
        maxWidth: 1080,
        children: [
          Text(
            isHost ? 'Quản lý đơn đặt phòng' : 'Chuyến đi của bạn',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty) const EmptyState('Chưa có đơn đặt phòng.'),
          for (final booking in items.reversed)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.id,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        BookingStatusBadge(
                          status: booking.effectiveStatus(DateTime.now()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.roomName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${homes.where((home) => home.id == booking.homestayId).firstOrNull?.name ?? 'Homestay'} · ${booking.guestName}',
                    ),
                    Text(
                      '${dateLabel(booking.checkIn)} – ${dateLabel(booking.checkOut)} · ${booking.nights} đêm · ${money(booking.total)}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (!isHost &&
                            booking.effectiveStatus(DateTime.now()) ==
                                BookingStatus.pending)
                          OutlinedButton(
                            onPressed: () => _transition(
                              context,
                              ref,
                              booking,
                              BookingStatus.cancelled,
                              user.uid,
                            ),
                            child: const Text('Hủy đơn'),
                          ),
                        if (!isHost &&
                            booking.effectiveStatus(DateTime.now()) ==
                                BookingStatus.checkedOut &&
                            !reviews.any(
                              (review) => review.bookingId == booking.id,
                            ))
                          OutlinedButton.icon(
                            onPressed: () =>
                                _review(context, ref, booking, user.uid),
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Đánh giá'),
                          ),
                        if (isHost &&
                            booking.effectiveStatus(DateTime.now()) ==
                                BookingStatus.pending) ...[
                          OutlinedButton(
                            onPressed: () => _transition(
                              context,
                              ref,
                              booking,
                              BookingStatus.rejected,
                              user.uid,
                            ),
                            child: const Text('Từ chối'),
                          ),
                          FilledButton(
                            onPressed: () => _transition(
                              context,
                              ref,
                              booking,
                              BookingStatus.confirmed,
                              user.uid,
                            ),
                            child: const Text('Xác nhận'),
                          ),
                        ],
                        if (isHost &&
                            booking.effectiveStatus(DateTime.now()) ==
                                BookingStatus.confirmed)
                          FilledButton(
                            onPressed: () => _transition(
                              context,
                              ref,
                              booking,
                              BookingStatus.checkedIn,
                              user.uid,
                            ),
                            child: const Text('Nhận phòng'),
                          ),
                        if (isHost &&
                            booking.effectiveStatus(DateTime.now()) ==
                                BookingStatus.checkedIn)
                          FilledButton(
                            onPressed: () => _transition(
                              context,
                              ref,
                              booking,
                              BookingStatus.checkedOut,
                              user.uid,
                            ),
                            child: const Text('Trả phòng'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
    BookingStatus target,
    String uid,
  ) async {
    try {
      await ref
          .read(firestoreBookingRepositoryProvider)
          .transition(booking.id, target, actorId: uid);
    } catch (error) {
      if (context.mounted)
        showError(
          context,
          error is BookingException ? error.message : 'Chưa cập nhật được đơn.',
        );
    }
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
    String uid,
  ) async {
    var rating = 0;
    final comment = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đánh giá chuyến đi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      tooltip: '$star sao',
                      onPressed: () => setDialogState(() => rating = star),
                      icon: Icon(
                        star <= rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: comment,
                maxLength: 500,
                maxLines: 3,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ cảm nhận của bạn',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: rating > 0 && comment.text.trim().isNotEmpty
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Gửi đánh giá'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true) {
      try {
        await ref
            .read(firestoreBookingRepositoryProvider)
            .addReview(
              booking.id,
              actorId: uid,
              rating: rating,
              comment: comment.text,
            );
        if (context.mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã lưu đánh giá.')));
      } catch (error) {
        if (context.mounted)
          showError(
            context,
            error is BookingException
                ? error.message
                : 'Chưa lưu được đánh giá.',
          );
      }
    }
    comment.dispose();
  }
}

class FirebaseCalendarPage extends ConsumerStatefulWidget {
  const FirebaseCalendarPage({super.key});
  @override
  ConsumerState<FirebaseCalendarPage> createState() =>
      _FirebaseCalendarPageState();
}

class _FirebaseCalendarPageState extends ConsumerState<FirebaseCalendarPage> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selected = stayDate(_selected);
    final nextDay = selected.add(const Duration(days: 1));
    final now = DateTime.now();
    final ref = this.ref;
    final homes = ref.watch(firestoreHomestaysProvider);
    final rooms = ref.watch(firestoreRoomsProvider);
    final bookings = ref.watch(firestoreBookingsProvider);
    return homes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _LoadError(message: 'Không tải được dữ liệu.'),
      data: (allHomes) => rooms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _LoadError(message: 'Không tải được phòng.'),
        data: (allRooms) => bookings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(
            message: 'Không tải được đơn: $error',
            onRetry: () => ref.invalidate(firestoreBookingsProvider),
          ),
          data: (allBookings) {
            final user = ref.watch(currentUserProvider).valueOrNull;
            final myHomes = allHomes
                .where((home) => home.hostId == user?.uid)
                .toList();
            final myRooms = allRooms
                .where(
                  (room) => myHomes.any((home) => home.id == room.homestayId),
                )
                .toList();
            return PageBody(
              maxWidth: 1080,
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/host'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Tổng quan'),
                ),
                Text(
                  'Lịch phòng',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  '${myRooms.where((room) => allBookings.any((booking) => booking.roomId == room.id && booking.blocks(now) && overlaps(selected, nextDay, booking.checkIn, booking.checkOut))).length} phòng đã có khách · ${myRooms.where((room) => room.active && !allBookings.any((booking) => booking.roomId == room.id && booking.blocks(now) && overlaps(selected, nextDay, booking.checkIn, booking.checkOut))).length} phòng còn trống',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(
                        () => _selected = selected.subtract(
                          const Duration(days: 1),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selected,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && mounted)
                            setState(() => _selected = picked);
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(dateLabel(selected)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(
                        () => _selected = selected.add(const Duration(days: 1)),
                      ),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _selected = DateTime.now()),
                    child: const Text('Về hôm nay'),
                  ),
                ),
                const SizedBox(height: 12),
                if (myRooms.isEmpty)
                  const EmptyState(
                    'Thêm homestay và phòng để bắt đầu quản lý lịch.',
                  ),
                for (final room in myRooms)
                  Builder(
                    builder: (context) {
                      final occupying = allBookings
                          .where(
                            (booking) =>
                                booking.roomId == room.id &&
                                booking.blocks(now) &&
                                overlaps(
                                  selected,
                                  nextDay,
                                  booking.checkIn,
                                  booking.checkOut,
                                ),
                          )
                          .toList();
                      final available = room.active && occupying.isEmpty;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            available
                                ? Icons.check_circle_outline
                                : Icons.bed_outlined,
                            color: available ? const Color(0xFF218567) : brand,
                          ),
                          title: Text(room.name),
                          subtitle: Text(
                            '${myHomes.where((home) => home.id == room.homestayId).firstOrNull?.name ?? ''} · ${occupying.isNotEmpty
                                ? occupying.first.guestName
                                : room.active
                                ? 'Đang mở'
                                : 'Bảo trì'}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: available
                                  ? const Color(0xFFE7F5EF)
                                  : const Color(0xFFFFEEE5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              available
                                  ? 'Còn trống'
                                  : occupying.isNotEmpty
                                  ? 'Đã đặt'
                                  : 'Bảo trì',
                              style: TextStyle(
                                color: available
                                    ? const Color(0xFF218567)
                                    : brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final firebaseHostHomesProvider = StreamProvider.family<List<Homestay>, String>(
  (ref, uid) => ref.watch(firestoreHomestayRepositoryProvider).watchByHost(uid),
);

class FirebaseHostPage extends ConsumerWidget {
  const FirebaseHostPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null)
      return const _LoadError(message: 'Vui lòng đăng nhập lại.');
    final homes = ref.watch(firebaseHostHomesProvider(user.uid));
    final rooms =
        ref.watch(firestoreRoomsProvider).valueOrNull ?? const <Room>[];
    final bookings =
        ref.watch(firestoreBookingsProvider).valueOrNull ?? const <Booking>[];
    final now = DateTime.now();
    final pendingCount = bookings
        .where(
          (booking) => booking.effectiveStatus(now) == BookingStatus.pending,
        )
        .length;
    final stayingCount = bookings
        .where(
          (booking) => booking.effectiveStatus(now) == BookingStatus.checkedIn,
        )
        .length;
    final monthRevenue = bookings
        .where(
          (booking) =>
              booking.status == BookingStatus.checkedOut &&
              booking.checkOut.year == now.year &&
              booking.checkOut.month == now.month,
        )
        .fold<int>(0, (total, booking) => total + booking.total);
    final monthlyRevenue = <int>[];
    final monthLabels = <String>[];
    for (var back = 6; back >= 0; back--) {
      final month = DateTime(now.year, now.month - back);
      monthLabels.add('${month.month}月');
      monthlyRevenue.add(
        bookings
            .where(
              (booking) =>
                  booking.status == BookingStatus.checkedOut &&
                  booking.checkOut.year == month.year &&
                  booking.checkOut.month == month.month,
            )
            .fold<int>(0, (total, booking) => total + booking.total),
      );
    }
    return PageBody(
      maxWidth: 1180,
      children: [
        Text(
          'Quản lý homestay',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Text('Dữ liệu đồng bộ trực tiếp với Firebase Firestore.'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add_home_work_outlined),
              label: const Text('Thêm homestay'),
              onPressed: () => _editHome(context, ref, user.uid),
            ),
            ActionChip(
              avatar: const Icon(Icons.event_note),
              label: const Text('Đơn đặt'),
              onPressed: () => context.go('/bookings'),
            ),
            ActionChip(
              avatar: const Icon(Icons.calendar_month),
              label: const Text('Lịch phòng'),
              onPressed: () => context.go('/host/calendar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Homestay',
                value: '${homes.valueOrNull?.length ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(label: 'Phòng', value: '${rooms.length}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(label: 'Đơn', value: '${bookings.length}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Chờ duyệt', value: '$pendingCount'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(label: 'Đang lưu trú', value: '$stayingCount'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Doanh thu tháng',
                value: money(monthRevenue),
              ),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doanh thu 7 tháng gần nhất',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tính từ các đơn đã trả phòng trong Firestore.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY:
                          (monthlyRevenue.fold<int>(
                                0,
                                (max, value) => value > max ? value : max,
                              )).toDouble() *
                              1.2 +
                          1,
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              return index >= 0 && index < monthLabels.length
                                  ? SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        monthLabels[index],
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: muted,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: brand,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: brand.withValues(alpha: .12),
                          ),
                          spots: [
                            for (
                              var index = 0;
                              index < monthlyRevenue.length;
                              index++
                            )
                              FlSpot(
                                index.toDouble(),
                                monthlyRevenue[index].toDouble(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SectionHeading(
          'Danh mục homestay',
          'Quản lý thông tin và phòng của bạn.',
        ),
        if (homes.valueOrNull?.isEmpty == true)
          OutlinedButton.icon(
            onPressed: () => _copyDemoCatalog(context, ref, user.uid),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Chép danh mục mẫu lên Firestore'),
          ),
        homes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const _LoadError(message: 'Không tải được homestay của bạn.'),
          data: (items) {
            if (items.isEmpty)
              return const EmptyState(
                'Chưa có homestay. Chọn “Thêm homestay” để tạo nơi lưu trú đầu tiên.',
              );
            return Column(
              children: [
                for (final home in items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 62,
                                        height: 62,
                                        child: StayPhoto(
                                          home.id,
                                          height: 62,
                                          radius: 10,
                                          label: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            home.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            '${home.city} · ${home.address}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit')
                                    _editHome(
                                      context,
                                      ref,
                                      user.uid,
                                      home: home,
                                    );
                                  if (value == 'delete')
                                    _deleteHome(context, ref, home);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Sửa homestay'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa homestay'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          for (final room in rooms.where(
                            (room) => room.homestayId == home.id,
                          ))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(
                                room.active
                                    ? Icons.bed_outlined
                                    : Icons.build_outlined,
                              ),
                              title: Text(room.name),
                              subtitle: Text(
                                '${money(room.price)} / đêm · ${room.capacity} khách',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit')
                                    _editRoom(context, ref, home, room: room);
                                  if (value == 'delete')
                                    _deleteRoom(context, ref, room);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Sửa phòng'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa phòng'),
                                  ),
                                ],
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () => _editRoom(context, ref, home),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm phòng'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _editHome(
    BuildContext context,
    WidgetRef ref,
    String uid, {
    Homestay? home,
  }) async {
    final name = TextEditingController(text: home?.name ?? '');
    final city = TextEditingController(text: home?.city ?? '');
    final address = TextEditingController(text: home?.address ?? '');
    final description = TextEditingController(text: home?.description ?? '');
    final amenities = TextEditingController(
      text: home?.amenities.join(', ') ?? 'Wi-Fi, Điều hòa',
    );
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(home == null ? 'Thêm homestay' : 'Sửa homestay'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in [
                  (name, 'Tên homestay'),
                  (city, 'Thành phố'),
                  (address, 'Địa chỉ'),
                  (description, 'Mô tả'),
                  (amenities, 'Tiện nghi, cách nhau bằng dấu phẩy'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: field.$1,
                      decoration: InputDecoration(labelText: field.$2),
                      validator: field == (name, 'Tên homestay')
                          ? (value) => value == null || value.trim().isEmpty
                                ? 'Nhập tên homestay.'
                                : null
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final id =
          home?.id ??
          '${_cityPhotoKey(city.text)}-${FirebaseFirestore.instance.collection('homestays').doc().id}';
      try {
        await ref
            .read(firestoreHomestayRepositoryProvider)
            .save(
              Homestay(
                id: id,
                hostId: uid,
                name: name.text.trim(),
                city: city.text.trim(),
                address: address.text.trim(),
                description: description.text.trim(),
                amenities: amenities.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                color: home?.color ?? 0xFF2F6757,
              ),
            );
      } catch (_) {
        if (context.mounted) showError(context, 'Homestay chưa lưu được.');
      }
    }
    name.dispose();
    city.dispose();
    address.dispose();
    description.dispose();
    amenities.dispose();
  }

  Future<void> _copyDemoCatalog(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    final local = ref.read(repositoryProvider);
    try {
      for (final home in local.homestays) {
        await ref
            .read(firestoreHomestayRepositoryProvider)
            .save(
              Homestay(
                id: home.id,
                hostId: uid,
                name: home.name,
                city: home.city,
                address: home.address,
                description: home.description,
                amenities: home.amenities,
                color: home.color,
              ),
            );
      }
      for (final room in local.rooms) {
        if (local.homestays.any((home) => home.id == room.homestayId)) {
          await ref.read(firestoreRoomRepositoryProvider).save(room);
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã chép ${local.homestays.length} homestay và ${local.rooms.length} phòng mẫu lên Firestore.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted)
        showError(
          context,
          'Chưa chép được dữ liệu mẫu. Kiểm tra quyền tài khoản rồi thử lại.',
        );
    }
  }

  Future<void> _editRoom(
    BuildContext context,
    WidgetRef ref,
    Homestay home, {
    Room? room,
  }) async {
    final name = TextEditingController(text: room?.name ?? 'Phòng tiêu chuẩn');
    final price = TextEditingController(text: '${room?.price ?? 650000}');
    final capacity = TextEditingController(text: '${room?.capacity ?? 2}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(room == null ? 'Thêm phòng' : 'Sửa phòng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Tên phòng'),
            ),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá mỗi đêm'),
            ),
            TextField(
              controller: capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sức chứa'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final parsedPrice = int.tryParse(price.text) ?? 0,
          parsedCapacity = int.tryParse(capacity.text) ?? 0;
      if (name.text.trim().isEmpty || parsedPrice < 1 || parsedCapacity < 1) {
        if (context.mounted)
          showError(context, 'Nhập tên, giá và sức chứa hợp lệ.');
      } else {
        final id =
            room?.id ?? FirebaseFirestore.instance.collection('rooms').doc().id;
        try {
          await ref
              .read(firestoreRoomRepositoryProvider)
              .save(
                Room(
                  id: id,
                  homestayId: home.id,
                  name: name.text.trim(),
                  price: parsedPrice,
                  capacity: parsedCapacity,
                  active: room?.active ?? true,
                ),
              );
        } catch (_) {
          if (context.mounted) showError(context, 'Phòng chưa lưu được.');
        }
      }
    }
    name.dispose();
    price.dispose();
    capacity.dispose();
  }

  Future<void> _deleteRoom(
    BuildContext context,
    WidgetRef ref,
    Room room,
  ) async {
    if (!await _confirmDelete(context, 'Xóa phòng “${room.name}”?')) return;
    try {
      await ref.read(firestoreRoomRepositoryProvider).delete(room.id);
    } catch (_) {
      if (context.mounted) showError(context, 'Không xóa được phòng.');
    }
  }

  Future<void> _deleteHome(
    BuildContext context,
    WidgetRef ref,
    Homestay home,
  ) async {
    if (!await _confirmDelete(context, 'Xóa homestay “${home.name}”?')) return;
    try {
      await ref.read(firestoreHomestayRepositoryProvider).delete(home.id);
    } catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('$message Thao tác này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Giữ lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      ) ??
      false;
}

String _cityPhotoKey(String city) => switch (city.trim().toLowerCase()) {
  'đà lạt' || 'da lat' => 'pine',
  'đà nẵng' || 'da nang' => 'sea',
  'hội an' || 'hoi an' => 'garden',
  'sa pa' || 'sapa' => 'sapa',
  'hà nội' || 'ha noi' => 'hanoi',
  'ninh bình' || 'ninh binh' => 'ninhbinh',
  'hạ long' || 'ha long' => 'halong',
  'huế' || 'hue' => 'hue',
  'quy nhơn' || 'quy nhon' => 'quynhon',
  'nha trang' => 'nhatrang',
  'phú quốc' || 'phu quoc' => 'phuquoc',
  'tp. hồ chí minh' || 'hồ chí minh' || 'ho chi minh' => 'saigon',
  'vũng tàu' || 'vung tau' => 'vungtau',
  'cần thơ' || 'can tho' => 'cantho',
  _ => 'sea',
};

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SizedBox(height: 36),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 38, color: muted),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (onRetry != null)
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử tải lại'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/profile'),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Mở hồ sơ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
