import 'dart:math' as math;

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_cubit.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ana sayfa / profil header AI ikonu — typing iken yeşil balon badge.
final class AiChatHeaderIcon extends StatelessWidget {
  const AiChatHeaderIcon({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatSessionCubit, ChatSessionState>(
      bloc: getIt<ChatSessionCubit>(),
      buildWhen: (prev, next) => prev.isAiTyping != next.isAiTyping,
      builder: (context, state) {
        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.colorWhite,
                      boxShadow: [
                        BoxShadow(
                          color: ColorName.colorBlack.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Assets.images.aiChat.image(
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (state.isAiTyping)
                  const Positioned(
                    right: -2,
                    top: -4,
                    child: _TypingBadge(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _TypingBadge extends StatefulWidget {
  const _TypingBadge();

  @override
  State<_TypingBadge> createState() => _TypingBadgeState();
}

class _TypingBadgeState extends State<_TypingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = 0.92 + 0.08 * math.sin(_controller.value * math.pi * 2);
        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: 22,
            height: 22,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Assets.icons.solarChatRoundDotsBoldSvg.svg(
                  width: 22,
                  height: 22,
                ),
                // SVG içindeki sabit noktaların üstüne animasyonlu noktalar
                Positioned(
                  left: 5,
                  top: 7,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final t = (_controller.value + i * 0.2) % 1.0;
                      final bounce = math.sin(t * math.pi);
                      return Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 2.2),
                        child: Transform.translate(
                          offset: Offset(0, -1.6 * bounce),
                          child: Opacity(
                            opacity: 0.45 + 0.55 * bounce,
                            child: Container(
                              width: 2.6,
                              height: 2.6,
                              decoration: const BoxDecoration(
                                color: ColorName.colorWhite,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
