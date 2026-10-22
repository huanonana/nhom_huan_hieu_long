import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stay_gallery.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _contentWidth = 1180.0;
  static final featuresKey = GlobalKey();
  static final howItWorksKey = GlobalKey();

  static void scrollTo(BuildContext context, GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 960;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _LandingHeader(compact: compact)),
            SliverToBoxAdapter(
              child: _Centered(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 40,
                    compact ? 26 : 72,
                    compact ? 20 : 40,
                    64,
                  ),
                  child: _Entrance(
                    child: compact ? const _MobileHero() : const _DesktopHero(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _Centered(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 40),
                  child: const _TrustStrip(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _FeatureSection(compact: compact)),
            SliverToBoxAdapter(child: _HowItWorks(compact: compact)),
            SliverToBoxAdapter(child: _LandingCta(compact: compact)),
            SliverToBoxAdapter(child: _LandingFooter(compact: compact)),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: LandingPage._contentWidth),
      child: child,
    ),
  );
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 36),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LandingPage._contentWidth),
        child: Row(
          children: [
            _BrandLogo(compact: compact),
            const Spacer(),
            if (!compact) ...[
              _HeaderLink(
                label: 'Trang chủ',
                onTap: () => Scrollable.ensureVisible(
                  context,
                  duration: const Duration(milliseconds: 300),
                ),
              ),
              _HeaderLink(
                label: 'Tính năng',
                onTap: () =>
                    LandingPage.scrollTo(context, LandingPage.featuresKey),
              ),
              _HeaderLink(
                label: 'Cách hoạt động',
                onTap: () =>
                    LandingPage.scrollTo(context, LandingPage.howItWorksKey),
              ),
              const Spacer(),
            ],
            if (compact)
              IconButton(
                tooltip: 'Đăng nhập',
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_rounded),
              )
            else
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Đăng nhập'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: brand,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.villa_rounded, color: Colors.white, size: 21),
      ),
      const SizedBox(width: 10),
      Text(
        compact ? 'HHL' : 'HHL Stay',
        style: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 17 : 19,
          letterSpacing: -.5,
        ),
      ),
    ],
  );
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: _HoverLift(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF475569)),
        child: Text(label),
      ),
    ),
  );
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(flex: 11, child: _HeroCopy(compact: false)),
      const SizedBox(width: 72),
      const Expanded(flex: 10, child: _StayDashboardPreview()),
    ],
  );
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _HeroCopy(compact: true),
      SizedBox(height: 34),
      _StayDashboardPreview(),
    ],
  );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: compact
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFC4B5FD),
              size: 15,
            ),
            SizedBox(width: 8),
            Text(
              compact ? 'HHL STAY' : 'HHL STAY  ·  HOMESTAY VIỆT NAM',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),
      Text(
        'Tìm chốn nghỉ đúng gu,\n',
        textAlign: compact ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: ink,
          fontSize: compact ? 40 : 60,
          height: 1.04,
          fontWeight: FontWeight.w900,
          letterSpacing: compact ? -1.2 : -1.7,
        ),
      ),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [brand, Color(0xFF14B8A6)],
        ).createShader(bounds),
        child: Text(
          'để chuyến đi đáng nhớ.',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 40 : 60,
            height: 1.04,
            fontWeight: FontWeight.w900,
            letterSpacing: compact ? -1.2 : -1.7,
          ),
        ),
      ),
      const SizedBox(height: 20),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 510),
        child: Text(
          'Khám phá homestay có cá tính riêng, xem rõ tiện nghi và giá trước khi chọn nơi dừng chân cho chuyến đi.',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: const TextStyle(color: muted, fontSize: 17, height: 1.7),
        ),
      ),
      const SizedBox(height: 27),
      Wrap(
        alignment: compact ? WrapAlignment.center : WrapAlignment.start,
        spacing: 12,
        runSpacing: 10,
        children: [
          _HoverLift(
            scale: 1.045,
            lift: 3,
            child: FilledButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.travel_explore_rounded, size: 19),
              label: const Text('Khám phá homestay'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                elevation: 3,
                shadowColor: brand.withValues(alpha: .25),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _TrustLine extends StatefulWidget {
  const _TrustLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  State<_TrustLine> createState() => _TrustLineState();
}

class _TrustLineState extends State<_TrustLine> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _hovered ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _hovered ? 1.16 : 1,
            duration: const Duration(milliseconds: 220),
            child: Icon(widget.icon, size: 17, color: brand),
          ),
          const SizedBox(width: 7),
          Text(
            widget.text,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child, this.scale = 1.025, this.lift = 4});
  final Widget child;
  final double scale;
  final double lift;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

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

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: const Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 20,
      runSpacing: 12,
      children: [
        _TrustLine(icon: Icons.verified_user_outlined, text: 'Đặt an tâm'),
        _TrustLine(icon: Icons.payments_outlined, text: 'Giá rõ ràng'),
        _TrustLine(
          icon: Icons.info_outline_rounded,
          text: 'Thông tin minh bạch',
        ),
      ],
    ),
  );
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 850),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: child,
      ),
    ),
  );
}

class _StayDashboardPreview extends StatefulWidget {
  const _StayDashboardPreview();

  @override
  State<_StayDashboardPreview> createState() => _StayDashboardPreviewState();
}

class _StayDashboardPreviewState extends State<_StayDashboardPreview> {
  final _pageController = PageController();
  int _activePhoto = 0;
  bool _hovered = false;
  Timer? _autoAdvance;
  late final _slides = [
    for (final destination in const [
      ('Đà Nẵng', 'sea'),
      ('Đà Lạt', 'pine'),
      ('Hội An', 'garden'),
      ('Sa Pa', 'sapa'),
    ])
      if (photosFor(destination.$2).isNotEmpty)
        (destination.$1, photosFor(destination.$2).first),
  ];

  @override
  void initState() {
    super.initState();
    _autoAdvance = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _pageController.hasClients && _slides.length > 1) {
        _nextPhoto();
      }
    });
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPhoto() {
    if (_slides.isEmpty) return;
    final next = (_activePhoto + 1) % _slides.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? 1.015 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF1E293B,
                  ).withValues(alpha: _hovered ? .14 : .09),
                  blurRadius: _hovered ? 54 : 40,
                  offset: Offset(0, _hovered ? 26 : 20),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _WindowDot(color: Color(0xFFFF5F57)),
                      SizedBox(width: 6),
                      _WindowDot(color: Color(0xFFFFBD2E)),
                      SizedBox(width: 6),
                      _WindowDot(color: Color(0xFF28C840)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'HHL Stay  ·  Chỗ nghỉ dành cho bạn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFEEF2FF),
                        child: Icon(
                          Icons.villa_rounded,
                          color: brand,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HHL Stay',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Gợi ý cho chuyến đi của bạn',
                              style: TextStyle(color: muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Sẵn sàng',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 250,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: (index) =>
                              setState(() => _activePhoto = index),
                          itemBuilder: (context, index) => Image.asset(
                            _slides[index].$2.asset,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xCC0F172A)],
                              stops: [.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: _PreviewBadge(
                            icon: Icons.location_on_outlined,
                            text: _slides.isEmpty
                                ? 'Homestay Việt Nam'
                                : _slides[_activePhoto].$1,
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 14,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _nextPhoto,
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: brand,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 18,
                          right: 18,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHỌN CHỐN NGHỈ ĐÚNG GU',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Một kỳ nghỉ đáng nhớ,\nbắt đầu từ nơi bạn chọn.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 18,
                          child: Row(
                            children: List.generate(_slides.length, (index) {
                              final selected = index == _activePhoto;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: selected ? 19 : 6,
                                height: 6,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white60,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    _MiniMetric(
                      icon: Icons.star_rounded,
                      value: '4.9',
                      label: 'Đánh giá tốt',
                      countTo: 4.9,
                      decimals: 1,
                    ),
                    SizedBox(width: 9),
                    _MiniMetric(
                      icon: Icons.home_work_outlined,
                      value: '14+',
                      label: 'Điểm đến',
                      countTo: 14,
                      suffix: '+',
                    ),
                    SizedBox(width: 9),
                    _MiniMetric(
                      icon: Icons.verified_outlined,
                      value: 'An tâm',
                      label: 'Đặt phòng',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            right: -15,
            top: 116,
            child: _HoverLift(
              child: _FloatingBenefitCard(
                icon: Icons.verified_rounded,
                color: Color(0xFF059669),
                title: 'Đặt phòng an tâm',
                detail: 'Giá minh bạch, thông tin rõ ràng',
              ),
            ),
          ),
          const Positioned(
            left: -16,
            bottom: 94,
            child: _HoverLift(
              child: _FloatingBenefitCard(
                icon: Icons.favorite_rounded,
                color: brand,
                title: 'Chọn nơi hợp gu',
                detail: 'Lưu lại chốn nghỉ yêu thích',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _FloatingBenefitCard extends StatelessWidget {
  const _FloatingBenefitCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final Color color;
  final String title, detail;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 205),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x260F172A),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: brand),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.countTo,
    this.decimals = 0,
    this.suffix = '',
  });
  final IconData icon;
  final String value;
  final String label;
  final double? countTo;
  final int decimals;
  final String suffix;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: brand),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: countTo ?? 0),
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeOutCubic,
                  builder: (context, count, _) => Text(
                    countTo == null
                        ? value
                        : '${count.toStringAsFixed(decimals)}$suffix',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    key: LandingPage.featuresKey,
    color: Colors.white,
    padding: EdgeInsets.symmetric(vertical: compact ? 56 : 88),
    child: _Centered(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _Eyebrow('TÍNH NĂNG CỐT LÕI'),
            const SizedBox(height: 13),
            Text(
              'Một chuyến đi dễ dàng hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 31 : 44,
                fontWeight: FontWeight.w900,
                color: ink,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Từ lúc tìm chỗ nghỉ đến khi quản lý đặt phòng, mọi thứ được thiết kế gọn gàng trong một nơi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 640
                    ? 1
                    : constraints.maxWidth < 960
                    ? 2
                    : 4;
                final width =
                    (constraints.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: const _FeatureCard(
                        icon: Icons.travel_explore_rounded,
                        title: 'Khám phá chỗ ở',
                        text:
                            'Tìm homestay theo thành phố, tiện nghi và ngân sách với hình ảnh, thông tin rõ ràng.',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: const _FeatureCard(
                        icon: Icons.event_available_rounded,
                        title: 'Đặt phòng thuận tiện',
                        text:
                            'Chọn ngày, số khách và gửi yêu cầu đặt phòng chỉ với vài thao tác.',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: const _FeatureCard(
                        icon: Icons.dashboard_customize_rounded,
                        title: 'Quản lý tập trung',
                        text:
                            'Chủ nhà theo dõi homestay, phòng, lịch đặt và doanh thu từ trang quản trị.',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _FeatureCard(
                        icon: Icons.support_agent_rounded,
                        title: 'Trợ lý AI',
                        text:
                            'Hỏi đáp để tìm chỗ nghỉ theo điểm đến, ngân sách và tiện nghi bạn cần.',
                        actionLabel: 'Hỏi trợ lý AI',
                        onPressed: () => context.push('/ai-chat'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: brand,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
    ),
  );
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onPressed,
  });
  final IconData icon;
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..setEntry(0, 0, _hovered ? 1.02 : 1.0)
        ..setEntry(1, 1, _hovered ? 1.02 : 1.0)
        ..setEntry(1, 3, _hovered ? -5.0 : 0.0),
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: _hovered ? const Color(0xFFFCFCFF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hovered ? const Color(0xFFBFC5FF) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF0F172A,
            ).withValues(alpha: _hovered ? .12 : .03),
            blurRadius: _hovered ? 28 : 20,
            offset: Offset(0, _hovered ? 14 : 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: brand),
          ),
          const SizedBox(height: 18),
          Text(
            widget.title,
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.text,
            style: const TextStyle(color: muted, height: 1.6, fontSize: 13),
          ),
          if (widget.actionLabel case final label?) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              key: const ValueKey('landing-ai-cta'),
              onPressed: widget.onPressed,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
              label: Text(label),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ],
      ),
    ),
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => _Centered(
    key: LandingPage.howItWorksKey,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 40,
        vertical: compact ? 56 : 88,
      ),
      child: Column(
        children: [
          const _Eyebrow('CÁCH HOẠT ĐỘNG'),
          const SizedBox(height: 13),
          Text(
            'Bắt đầu dễ dàng trong 3 bước.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 29 : 43,
              fontWeight: FontWeight.w900,
              color: ink,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Một hành trình liền mạch từ lúc tìm kiếm đến khi xác nhận nơi nghỉ.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 15),
          ),
          const SizedBox(height: 38),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 640 ? 1 : 3;
              final width =
                  (constraints.maxWidth - 16 * (columns - 1)) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: const _StepCard(
                      number: '01',
                      title: 'Chọn điểm đến',
                      text:
                          'Tìm thành phố và kiểu homestay phù hợp với chuyến đi của bạn.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const _StepCard(
                      number: '02',
                      title: 'Chọn phòng và ngày',
                      text:
                          'Xem thông tin phòng, giá và tình trạng còn trống trước khi đặt.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const _StepCard(
                      number: '03',
                      title: 'Gửi yêu cầu đặt',
                      text:
                          'Theo dõi trạng thái đơn trong tài khoản và chuẩn bị cho kỳ nghỉ.',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _StepCard extends StatefulWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.text,
  });
  final String number;
  final String title;
  final String text;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _hovered ? -7 : 0, 0),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _hovered ? const Color(0xFFFAFAFF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _hovered ? const Color(0xFFA5B4FC) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF312E81,
            ).withValues(alpha: _hovered ? .13 : .025),
            blurRadius: _hovered ? 24 : 12,
            offset: Offset(0, _hovered ? 12 : 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedScale(
            scale: _hovered ? 1.18 : 1,
            duration: const Duration(milliseconds: 240),
            child: Text(
              widget.number,
              style: const TextStyle(
                color: brand,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.text,
                  style: const TextStyle(
                    color: muted,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LandingCta extends StatelessWidget {
  const _LandingCta({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => _Centered(
    child: Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 40, 8, compact ? 20 : 40, 72),
      child: _HoverLift(
        scale: 1.012,
        lift: 4,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 23 : 52,
            vertical: compact ? 34 : 46,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: compact
              ? Column(
                  children: [
                    const Text(
                      'Sẵn sàng cho chuyến đi tiếp theo?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 11),
                    const Text(
                      'Khám phá những không gian nghỉ ngơi thật hợp gu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFE0E7FF), height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    _HoverLift(
                      scale: 1.045,
                      lift: 3,
                      child: FilledButton(
                        onPressed: () => context.go('/explore'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: brand,
                        ),
                        child: const Text('Tìm homestay ngay'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sẵn sàng cho chuyến đi tiếp theo?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.7,
                            ),
                          ),
                          SizedBox(height: 9),
                          Text(
                            'Khám phá những không gian nghỉ ngơi thật hợp gu.',
                            style: TextStyle(
                              color: Color(0xFFE0E7FF),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 22),
                    _HoverLift(
                      scale: 1.045,
                      lift: 3,
                      child: FilledButton(
                        onPressed: () => context.go('/explore'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: brand,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Tìm homestay ngay'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 40, vertical: 24),
    child: _Centered(
      child: Row(
        children: [
          const _BrandLogo(),
          const Spacer(),
          if (!compact) ...[
            _HoverLift(
              child: TextButton(
                onPressed: () => context.go('/explore'),
                child: const Text('Khám phá'),
              ),
            ),
            _HoverLift(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Đăng nhập'),
              ),
            ),
          ],
          const Text(
            '© 2026 HHL Stay',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
