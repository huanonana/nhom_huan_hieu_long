import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// A clear, persistent entry point to the homestay assistant.
class AiAssistantButton extends StatelessWidget {
  const AiAssistantButton({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final onPressed = () => context.push('/ai-chat');
    if (compact) {
      return Tooltip(
        message: 'Tư vấn homestay bằng AI',
        child: FloatingActionButton(
          heroTag: 'hhl-ai-assistant',
          onPressed: onPressed,
          backgroundColor: const Color(0xFF5746E8),
          foregroundColor: Colors.white,
          elevation: 10,
          child: const Icon(Icons.auto_awesome_rounded, size: 24),
        ),
      );
    }
    return Tooltip(
      message: 'Tư vấn homestay bằng AI',
      child: Material(
        color: Colors.transparent,
        elevation: 12,
        shadowColor: brand.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6758EF), Color(0xFF4938D4)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 17, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Trợ lý AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tìm chỗ nghỉ hợp gu',
                        style: TextStyle(
                          color: Color(0xFFE6E2FF),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
