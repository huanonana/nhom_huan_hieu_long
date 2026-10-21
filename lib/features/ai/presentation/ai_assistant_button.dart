import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Floating customer-support entry point shown on the Explore screen.
class AiAssistantButton extends StatelessWidget {
  const AiAssistantButton({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final radius = BorderRadius.circular(compact ? 20 : 18);
    if (compact) {
      return Tooltip(
        message: 'Tư vấn homestay bằng AI',
        child: Semantics(
          label: 'Hỗ trợ khách hàng, tư vấn homestay bằng AI',
          button: true,
          child: Material(
            color: Colors.transparent,
            elevation: 10,
            shadowColor: brand.withValues(alpha: .32),
            borderRadius: radius,
            child: InkWell(
              onTap: () => context.push('/ai-chat'),
              borderRadius: radius,
              child: Ink(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6758EF), Color(0xFF4938D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: radius,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Tooltip(
      message: 'Tư vấn homestay bằng AI',
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        shadowColor: brand.withValues(alpha: .32),
        borderRadius: radius,
        child: InkWell(
          onTap: () => context.push('/ai-chat'),
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6758EF), Color(0xFF4938D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 18,
                vertical: compact ? 13 : 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Hỗ trợ khách hàng',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Tư vấn homestay ngay',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 17,
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
