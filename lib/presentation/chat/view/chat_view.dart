import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_cubit.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Coach Mochi AI sohbet — boş durum + konuşma baloncukları.
final class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late final ChatSessionCubit _cubit = getIt<ChatSessionCubit>();

  static const _suggestions = <String>[
    'chat.suggestion_hungry',
    'chat.suggestion_coffee',
    'chat.suggestion_weight',
    'chat.suggestion_eat',
  ];

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _cubit.state.isAiTyping) return;
    _controller.clear();
    _focusNode.unfocus();
    await _cubit.sendMessage(text);
  }

  void _onSuggestionTap(String key) => _sendText(key.tr());

  void _onSend() => _sendText(_controller.text);

  Widget _buildEmptyState() {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Text(
          'chat.greeting'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.chatGreeting,
        ),
        const SizedBox(height: 8),
        Center(
          child: AppImages.mascotChat.image(height: 220, fit: BoxFit.contain),
        ),
        const SizedBox(height: 24),
        for (final key in _suggestions) ...[
          _SuggestionChip(label: key.tr(), onTap: () => _onSuggestionTap(key)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildConversation(ChatSessionState state) {
    final messages = state.messages;
    final isTyping = state.isAiTyping;

    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (isTyping && index == messages.length) {
          return const _AppearOnce(
            key: ValueKey('typing'),
            child: _TypingRow(),
          );
        }
        final message = messages[index];
        return _AppearOnce(
          key: ValueKey(message.id),
          child: _MessageBubble(message: message),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ColorName.colorButtonDark,
        body: Column(
          children: [
            const _ChatHeader(),
            Expanded(
              child: BlocConsumer<ChatSessionCubit, ChatSessionState>(
                bloc: _cubit,
                listenWhen: (prev, next) =>
                    prev.messages.length != next.messages.length ||
                    prev.isAiTyping != next.isAiTyping,
                listener: (context, state) => _scrollToBottom(),
                builder: (context, state) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: state.hasConversation
                        ? KeyedSubtree(
                            key: const ValueKey('conversation'),
                            child: _buildConversation(state),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('empty'),
                            child: _buildEmptyState(),
                          ),
                  );
                },
              ),
            ),
            _ChatInputBar(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _onSend,
            ),
          ],
        ),
      ),
    );
  }
}

/// Key sabit kaldığı sürece animasyon bir kez çalışır.
final class _AppearOnce extends StatefulWidget {
  const _AppearOnce({required this.child, super.key});

  final Widget child;

  @override
  State<_AppearOnce> createState() => _AppearOnceState();
}

class _AppearOnceState extends State<_AppearOnce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(_curved),
        child: SizeTransition(
          sizeFactor: _curved,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
      ),
    );
  }
}

final class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser
            ? ColorName.colorChatUserBubble
            : ColorName.colorChatSurface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(isUser ? 24 : 8),
          bottomRight: Radius.circular(isUser ? 8 : 24),
        ),
      ),
      child: Text(message.text, style: AppTextStyles.chatBubbleMessage),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            ClipOval(
              child: AppImages.mascotChatPp.image(
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

final class _TypingRow extends StatelessWidget {
  const _TypingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [_TypingAvatar(), SizedBox(width: 10), _TypingBubble()],
      ),
    );
  }
}

final class _TypingAvatar extends StatelessWidget {
  const _TypingAvatar();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: AppImages.mascotChatPp.image(
        width: 32,
        height: 32,
        fit: BoxFit.cover,
      ),
    );
  }
}

final class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: ColorName.colorChatSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: const _TypingDots(),
    );
  }
}

final class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value + i * 0.18) % 1.0;
            final bounce = math.sin(t * math.pi);
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
              child: Transform.translate(
                offset: Offset(0, -4 * bounce),
                child: Opacity(
                  opacity: 0.35 + 0.65 * bounce,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ColorName.colorWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

final class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10, top + 10, 10, 20),
      decoration: BoxDecoration(
        color: ColorName.colorHomeChipBg.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            onTap: () => context.pop(),
            child: Assets.icons.solarAltArrowUpLineDuotone.svg(
              width: 24,
              height: 24,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: AppImages.mascotChatPp.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'chat.coach_name'.tr(),
                  style: AppTextStyles.chatCoachName,
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            onTap: () => context.pushNamed(RoutePaths.latestChats.name),
            child: Assets.icons.solarHistory2LineDuotone1.svg(
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }
}

final class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    );
  }
}

final class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorChatSurface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.chatSuggestion)),
              const SizedBox(width: 10),
              Assets.icons.solarArrowLeftDownLinear.svg(width: 20, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorButtonDark,
        border: Border(
          top: BorderSide(color: ColorName.colorWhite.withValues(alpha: 0.1)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 24, 10, bottom > 0 ? bottom : 32),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: ColorName.colorChatSurface,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: AppTextStyles.chatInputText,
                  cursorColor: ColorName.colorWhite,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'chat.hint'.tr(),
                    hintStyle: AppTextStyles.chatInputHint,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(onTap: onSend),
          ],
        ),
      ),
    );
  }
}

final class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorName.colorCtaGradientTop,
                ColorName.colorCtaGradientBottom,
              ],
            ),
            border: Border.all(
              color: ColorName.colorWhite.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorName.colorWhite.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Center(
            child: Assets.icons.solarPlainBold.svg(width: 22, height: 22),
          ),
        ),
      ),
    );
  }
}
