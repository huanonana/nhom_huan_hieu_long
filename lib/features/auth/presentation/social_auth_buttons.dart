import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

/// Presentation-only social sign-in options. OAuth is intentionally not wired
/// yet; tapping a provider explains that it will be available later.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key});

  void _showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đăng nhập $provider sẽ sớm được hỗ trợ.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'HOẶC TIẾP TỤC VỚI',
              style: TextStyle(
                color: muted.withValues(alpha: .82),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _SocialButton(
              label: 'Google',
              mark: const _GoogleMark(),
              onPressed: () => _showComingSoon(context, 'Google'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SocialButton(
              label: 'Apple',
              mark: const Icon(Icons.apple_rounded, size: 19, color: ink),
              onPressed: () => _showComingSoon(context, 'Apple'),
            ),
          ),
        ],
      ),
    ],
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.mark,
    required this.onPressed,
  });

  final String label;
  final Widget mark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => HoverMotion(
    scale: 1.025,
    lift: 2,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE0E6F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: 9),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Tooltip(
              message: 'Sắp ra mắt',
              child: Icon(Icons.schedule_rounded, size: 14, color: muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      fontSize: 20,
      height: 1,
      fontWeight: FontWeight.w900,
      foreground: null,
      color: Color(0xFF4285F4),
    ),
  );
}
