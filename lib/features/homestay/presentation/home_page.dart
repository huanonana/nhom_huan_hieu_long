import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_gallery.dart';
import '../../homestay/domain/catalog.dart';
import '../../../core/state/app_state.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(repositoryProvider);
    return _HomeContent(homes: repository.homestays, rooms: repository.rooms);
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.homes, required this.rooms});

  final List<Homestay> homes;
  final List<Room> rooms;

  @override
  Widget build(BuildContext context) {
    final destinations = <String>{};
    for (final home in homes) {
      destinations.add(home.city);
    }
    final featured = homes.take(6).toList(growable: false);

    // Câu 5 reference: StudySmart mobile dashboard. Keep the desktop landing
    // page intact while using its greeting → stats → primary action → quick
    // links hierarchy for the phone layout.
    if (MediaQuery.sizeOf(context).width < 600) {
      return _MobileHomeDashboard(
        homes: homes,
        rooms: rooms,
        destinations: destinations.toList(growable: false),
        featured: featured,
        onExplore: () => context.go('/explore'),
        onBookings: () => context.go('/bookings'),
        onFavorites: () => context.go('/favorites'),
        onAskAi: () => context.go('/ai-chat'),
      );
    }

    return PageBody(
      maxWidth: 1180,
      children: [
        _HomeHero(
          stayCount: homes.length,
          onExplore: () => context.go('/explore'),
          onAskAi: () => context.go('/ai-chat'),
        ),
        const SizedBox(height: 16),
        _MemberOfferCard(onExplore: () => context.go('/explore')),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đi đâu để nạp lại năng lượng?',
                    style: TextStyle(
                      color: ink,
                      fontSize: 23,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.45,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Chọn một điểm đến, HHL Stay lo phần tìm chỗ nghỉ.',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Tất cả điểm đến'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (destinations.isEmpty)
          const _HomeEmptyState()
        else
          SizedBox(
            height: 164,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final city = destinations.elementAt(index);
                final home = homes.firstWhere((item) => item.city == city);
                return _DestinationTile(
                  city: city,
                  home: home,
                  onTap: () => context.go(
                    '/explore?${Uri(queryParameters: {'city': city}).query}',
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chỗ nghỉ được yêu thích',
                    style: TextStyle(
                      color: ink,
                      fontSize: 23,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.45,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Không gian thật, thông tin rõ ràng, sẵn sàng cho chuyến đi.',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (featured.isEmpty)
          const _HomeEmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth >= 600
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final home in featured)
                    SizedBox(
                      width: cardWidth,
                      child: _FeaturedStayCard(
                        home: home,
                        rooms: rooms
                            .where(
                              (room) =>
                                  room.homestayId == home.id && room.active,
                            )
                            .toList(growable: false),
                        onTap: () => context.push('/homestays/${home.id}'),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 28),
        _HomeTrustStrip(onExplore: () => context.go('/explore')),
      ],
    );
  }
}

class _MobileHomeDashboard extends StatelessWidget {
  const _MobileHomeDashboard({
    required this.homes,
    required this.rooms,
    required this.destinations,
    required this.featured,
    required this.onExplore,
    required this.onBookings,
    required this.onFavorites,
    required this.onAskAi,
  });

  final List<Homestay> homes;
  final List<Room> rooms;
  final List<String> destinations;
  final List<Homestay> featured;
  final VoidCallback onExplore;
  final VoidCallback onBookings;
  final VoidCallback onFavorites;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 520,
      children: [
        const Text(
          'Chào bạn! 👋',
          style: TextStyle(
            color: ink,
            fontSize: 25,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Sẵn sàng cho chuyến đi tiếp theo chưa?',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MobileStayStat(
                icon: Icons.hotel_rounded,
                value: '${homes.length}',
                label: 'Chỗ nghỉ',
                tint: const Color(0xFFECEBFF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MobileStayStat(
                icon: Icons.location_city_rounded,
                value: '${destinations.length}',
                label: 'Điểm đến',
                tint: const Color(0xFFFFF1E7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
          decoration: BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x263B35C8),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BẮT ĐẦU CHUYẾN ĐI',
                      style: TextStyle(
                        color: Color(0xFFDCD9FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Bạn muốn nghỉ ở đâu?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn ngày và tìm chỗ nghỉ hợp gu.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Tìm homestay',
                  onPressed: onExplore,
                  icon: const Icon(Icons.arrow_forward_rounded, color: brand),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Khám phá nhanh',
          style: TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 10),
        _MobileQuickLink(
          icon: Icons.search_rounded,
          title: 'Tìm homestay',
          subtitle: 'Lọc theo điểm đến, ngày ở và tiện nghi',
          onTap: onExplore,
        ),
        const SizedBox(height: 9),
        _MobileQuickLink(
          icon: Icons.bookmark_border_rounded,
          title: 'Đơn đặt phòng',
          subtitle: 'Theo dõi yêu cầu và lịch sử đặt chỗ',
          onTap: onBookings,
        ),
        const SizedBox(height: 9),
        _MobileQuickLink(
          icon: Icons.favorite_border_rounded,
          title: 'Chỗ nghỉ yêu thích',
          subtitle: 'Mở lại những nơi bạn đã lưu',
          onTap: onFavorites,
        ),
        const SizedBox(height: 9),
        _MobileQuickLink(
          icon: Icons.auto_awesome_rounded,
          title: 'Trợ lý chọn homestay',
          subtitle: 'Hỏi về điểm đến, giá và tiện nghi',
          onTap: onAskAi,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Điểm đến nổi bật',
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
            ),
            TextButton(onPressed: onExplore, child: const Text('Xem tất cả')),
          ],
        ),
        if (destinations.isEmpty)
          const _HomeEmptyState()
        else
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final city = destinations[index];
                final home = homes.firstWhere((item) => item.city == city);
                return _DestinationTile(
                  city: city,
                  home: home,
                  onTap: () => context.go(
                    '/explore?${Uri(queryParameters: {'city': city}).query}',
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'Chỗ nghỉ gợi ý',
          style: TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 10),
        if (featured.isEmpty)
          const _HomeEmptyState()
        else
          for (final home in featured) ...[
            _FeaturedStayCard(
              home: home,
              rooms: rooms
                  .where((room) => room.homestayId == home.id && room.active)
                  .toList(growable: false),
              onTap: () => context.push('/homestays/${home.id}'),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 8),
        _MemberOfferCard(onExplore: onExplore),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _MobileStayStat extends StatelessWidget {
  const _MobileStayStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 92),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EAF3)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          child: Icon(icon, color: brand, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MobileQuickLink extends StatelessWidget {
  const _MobileQuickLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7EAF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFECEBFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: brand, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    ),
  );
}

class _MemberOfferCard extends StatelessWidget {
  const _MemberOfferCard({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5ED),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFFFE1CC)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 540;
        final copy = Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.local_offer_outlined, color: Color(0xFFDB6B2D)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ưu đãi chuyến đi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Thử mã HHL10 để giảm 10% khi đặt phòng · Ưu đãi demo',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
        final action = FilledButton(
          onPressed: onExplore,
          child: const Text('Tìm chỗ nghỉ'),
        );
        return narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [copy, const SizedBox(height: 12), action],
              )
            : Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 16),
                  action,
                ],
              );
      },
    ),
  );
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.stayCount,
    required this.onExplore,
    required this.onAskAi,
  });

  final int stayCount;
  final VoidCallback onExplore;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F3FF), Color(0xFFFFFFFF), Color(0xFFE8FBF7)],
        ),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101E293B),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCopy(
                  stayCount: stayCount,
                  onExplore: onExplore,
                  onAskAi: onAskAi,
                ),
                const SizedBox(height: 22),
                _HeroPhoto(),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _HeroCopy(
                    stayCount: stayCount,
                    onExplore: onExplore,
                    onAskAi: onAskAi,
                  ),
                ),
                const SizedBox(width: 30),
                const Expanded(child: _HeroPhoto()),
              ],
            ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.stayCount,
    required this.onExplore,
    required this.onAskAi,
  });
  final int stayCount;
  final VoidCallback onExplore;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          'HHL STAY  ·  HOMESTAY VIỆT NAM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text.rich(
        TextSpan(
          text: 'Chuyến đi mới,\n',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 38, height: 1.12),
          children: const [
            TextSpan(
              text: 'một nơi ở đúng gu.',
              style: TextStyle(color: brand),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Tìm homestay có cá tính riêng, xem rõ tiện nghi và giá trước khi đặt.',
        style: TextStyle(color: muted, fontSize: 15, height: 1.55),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Tìm homestay'),
          ),
          OutlinedButton.icon(
            onPressed: onAskAi,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Hỏi trợ lý AI'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 18,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined, color: brand, size: 18),
          const Text(
            'Đặt an tâm',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Icon(Icons.home_work_outlined, color: brand, size: 18),
          Text(
            '$stayCount chỗ nghỉ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ],
  );
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  @override
  Widget build(BuildContext context) {
    final photo = photosFor('sea').first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              photo.asset,
              fit: BoxFit.cover,
              cacheWidth: 1200,
              semanticLabel: photo.caption,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xBB0F172A)],
                ),
              ),
            ),
            const Positioned(
              top: 14,
              left: 14,
              child: _PhotoPill(
                icon: Icons.location_on_outlined,
                text: 'Đà Nẵng',
              ),
            ),
            const Positioned(
              left: 20,
              bottom: 18,
              right: 20,
              child: Text(
                'Một nơi chốn,\nmột câu chuyện riêng.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPill extends StatelessWidget {
  const _PhotoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: brand),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ],
    ),
  );
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.city,
    required this.home,
    required this.onTap,
  });
  final String city;
  final Homestay home;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final photo = photosFor(home.id, imageSources: home.imageUrls).first;
    return SizedBox(
      width: 230,
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              buildStayImage(photo.asset, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0F172A)],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Khám phá chỗ nghỉ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 12,
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
  }
}

class _FeaturedStayCard extends StatelessWidget {
  const _FeaturedStayCard({
    required this.home,
    required this.rooms,
    required this.onTap,
  });
  final Homestay home;
  final List<Room> rooms;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final photo = photosFor(home.id, imageSources: home.imageUrls).first;
    final prices = rooms.map((room) => room.price).toList()..sort();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.55,
                child: buildStayImage(photo.asset, fit: BoxFit.cover),
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
                    const SizedBox(height: 7),
                    Text(
                      home.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.wifi_rounded, size: 15, color: muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            home.amenities.take(3).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prices.isEmpty
                              ? 'Xem giá'
                              : 'Từ ${money(prices.first)}',
                          style: const TextStyle(
                            color: brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
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

class _HomeTrustStrip extends StatelessWidget {
  const _HomeTrustStrip({required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1B4B),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 12,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sẵn sàng cho chuyến đi tiếp theo?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Khám phá những không gian nghỉ thật hợp gu.',
              style: TextStyle(color: Color(0xFFD8DAFF)),
            ),
          ],
        ),
        FilledButton.tonalIcon(
          onPressed: onExplore,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Khám phá ngay'),
        ),
      ],
    ),
  );
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Text(
        'Chưa có homestay để giới thiệu. Hãy khám phá lại sau nhé.',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted),
      ),
    ),
  );
}
