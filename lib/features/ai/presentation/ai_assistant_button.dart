import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

final aiAssistantEntryVisibleProvider = StateProvider<bool>((ref) => true);

/// A clear, persistent entry point to the homestay assistant.
class AiAssistantButton extends ConsumerWidget {
  const AiAssistantButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(aiAssistantEntryVisibleProvider)) {
      return const SizedBox.shrink();
    }
    final compact = MediaQuery.sizeOf(context).width < 900;
    final onPressed = () => context.push('/ai-chat');
    return Tooltip(
      message: 'Tư vấn homestay bằng AI',
      child: Material(
        color: Colors.transparent,
        elevation: compact ? 14 : 12,
        shadowColor: brand.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(compact ? 18 : 20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6758EF), Color(0xFF4938D4)],
              ),
              borderRadius: BorderRadius.circular(compact ? 18 : 20),
              border: Border.all(color: Colors.white.withValues(alpha: .45)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: compact ? 188 : 0),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 13,
                  compact ? 9 : 10,
                  compact ? 16 : 17,
                  compact ? 9 : 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: compact ? 38 : 42,
                          height: compact ? 38 : 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: compact ? 23 : 24,
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: const Color(0xFF65D69A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF5746E8),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 9),
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
                        const SizedBox(height: 2),
                        Text(
                          compact
                              ? 'Tư vấn homestay ngay'
                              : 'Tư vấn homestay nhanh',
                          style: TextStyle(
                            color: const Color(0xFFE6E2FF),
                            fontSize: compact ? 9 : 10,
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
