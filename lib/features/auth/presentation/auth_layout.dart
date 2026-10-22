import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/stay_gallery.dart';

/// Shared responsive frame for guest and host authentication screens.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    this.adminMode = false,
  });

  final Widget child;
  final String title;
  final String description;
  final bool adminMode;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8FC),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        final visual = _AuthVisual(
          title: title,
          description: description,
          adminMode: adminMode,
          compact: !wide,
        );
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 36 : 20,
              vertical: wide ? 32 : 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: HoverMotion(
                              scale: 1.012,
                              lift: 4,
                              child: visual,
                            ),
                          ),
                          const SizedBox(width: 56),
                          SizedBox(
                            width: 430,
                            child: HoverMotion(
                              scale: 1.008,
                              lift: 3,
                              child: _FormCard(child: child),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HoverMotion(scale: 1.012, lift: 3, child: visual),
                          const SizedBox(height: 18),
                          HoverMotion(
                            scale: 1.008,
                            lift: 2,
                            child: _FormCard(child: child),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFE7E8EF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C172554),
          blurRadius: 32,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}

class _AuthVisual extends StatelessWidget {
  const _AuthVisual({
    required this.title,
    required this.description,
    required this.adminMode,
    required this.compact,
  });

  final String title;
  final String description;
  final bool adminMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final image = photosFor(adminMode ? 'dalat' : 'sea').first.asset;
    final showBenefits = title.startsWith('Tạo tài khoản');
    return Container(
      height: compact ? (showBenefits ? 420 : 190) : (showBenefits ? 660 : 600),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: adminMode ? const Color(0xFF111827) : const Color(0xFF24205A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!compact) Image.asset(image, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: compact ? Alignment.topLeft : Alignment.bottomLeft,
                end: compact ? Alignment.bottomRight : Alignment.topRight,
                colors: compact
                    ? adminMode
                          ? const [Color(0xFFE2E8F0), Color(0xFFCBD5E1)]
                          : const [Color(0xFFF0EDFF), Color(0xFFE0E7FF)]
                    : adminMode
                    ? const [Color(0xF011172A), Color(0x3011172A)]
                    : const [Color(0xE6171734), Color(0x16171734)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 22 : 38),
            child: compact
                ? _CompactVisual(
                    title: title,
                    description: description,
                    adminMode: adminMode,
                    showBenefits: showBenefits,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _BrandMark(adminMode: adminMode),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFFE8EAF5),
                          fontSize: 16,
                          height: 1.65,
                        ),
                      ),
                      if (showBenefits) ...[
                        const SizedBox(height: 18),
                        const _AuthBenefits(),
                      ],
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          _TrustPill(
                            icon: Icons.verified_user_outlined,
                            label: 'An tâm',
                          ),
                          SizedBox(width: 10),
                          _TrustPill(
                            icon: Icons.info_outline_rounded,
                            label: 'Giá minh bạch',
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactVisual extends StatelessWidget {
  const _CompactVisual({
    required this.title,
    required this.description,
    required this.adminMode,
    required this.showBenefits,
  });
  final String title;
  final String description;
  final bool adminMode;
  final bool showBenefits;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _BrandMark(adminMode: adminMode, compact: true),
      const Spacer(),
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: muted, fontSize: 12, height: 1.35),
      ),
      if (showBenefits) ...[
        const SizedBox(height: 12),
        const _AuthBenefits(compact: true),
      ],
    ],
  );
}

class _AuthBenefits extends StatelessWidget {
  const _AuthBenefits({this.compact = false});
  final bool compact;

  static const _items = [
    'Giảm 5% giá phòng cho thành viên',
    'Hủy miễn phí trước giờ nhận phòng 24 giờ',
    'Thông tin tài khoản được bảo vệ',
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in _items) ...[
        if (item != _items.first) SizedBox(height: compact ? 6 : 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: compact ? .72 : .16),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: compact ? const Color(0xFFE2E8F0) : Colors.white24,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: compact ? 12 : 14,
                backgroundColor: const Color(0xFFDCFCE7),
                child: Icon(
                  Icons.check_rounded,
                  size: compact ? 15 : 17,
                  color: const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: compact ? ink : Colors.white,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.adminMode, this.compact = false});
  final bool adminMode;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 38 : 48,
        height: compact ? 38 : 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          adminMode
              ? Icons.dashboard_customize_rounded
              : Icons.holiday_village_rounded,
          color: brand,
          size: compact ? 21 : 26,
        ),
      ),
      const SizedBox(width: 11),
      Text(
        'HHL Stay',
        style: TextStyle(
          fontSize: compact ? 17 : 20,
          fontWeight: FontWeight.w800,
          color: compact ? ink : Colors.white,
        ),
      ),
    ],
  );
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: .28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
