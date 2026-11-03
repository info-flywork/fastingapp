import 'dart:async';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/domain/chat/ai_consent.dart';
import 'package:fastingapp/domain/chat/chat_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_cubit.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  /// Kullanıcı yukarı kaydırdıysa otomatik kaydırmayı durdur.
  var _stickToBottom = true;

  /// Aynı frame'de birden fazla scroll isteğini tek jump'ta birleştir.
  var _scrollScheduled = false;

  /// Sunucu önerileri gelene kadar (veya gelmezse) yerel metinler.
  static const _fallbackSuggestions = <String>[
    'chat.suggestion_hungry',
    'chat.suggestion_coffee',
    'chat.suggestion_weight',
    'chat.suggestion_eat',
  ];

  List<String>? _serverSuggestions;

  List<String> get _suggestions =>
      _serverSuggestions ?? [for (final k in _fallbackSuggestions) k.tr()];

  @override
  void initState() {
    super.initState();
    // Ana sayfadan her giriş yeni sohbet. Önceki konuşma saat ikonundaki
    // geçmişte durur; buradan açılırsa aynı ekran yeniden kurulmaz.
    unawaited(_cubit.startNewChat());
    _cubit.loadHistory();
    unawaited(_loadSuggestions());
    unawaited(_loadQuota());
    unawaited(AiConsent.warmUp());
  }

  /// Ücretsiz kullanıcıya bugün kalan mesaj (önceden sınır ancak 402'de
  /// öğreniliyordu).
  int? _remaining;

  Future<void> _loadQuota() async {
    try {
      final remaining = await getIt<ChatRepository>().remainingMessages();
      if (mounted) setState(() => _remaining = remaining);
    } on Object {
      // Gösterge ikincil.
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final items = await getIt<ChatRepository>().suggestions();
      if (mounted && items.isNotEmpty) {
        setState(() => _serverSuggestions = items.take(4).toList());
      }
    } on Object {
      // Yerel öneriler kalır.
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_stickToBottom || _scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!_stickToBottom || !mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final target = position.maxScrollExtent;
      if ((position.pixels - target).abs() < 1) return;
      _scrollController.jumpTo(target);
    });
  }

  bool _chatContentChanged(ChatSessionState prev, ChatSessionState next) {
    if (prev.messages.length != next.messages.length) return true;
    if (prev.isAiTyping != next.isAiTyping) return true;
    if (prev.isStreaming != next.isStreaming) return true;
    if (prev.messages.isEmpty || next.messages.isEmpty) {
      return prev.messages.isNotEmpty != next.messages.isNotEmpty;
    }
    final pl = prev.messages.last;
    final nl = next.messages.last;
    return pl.id != nl.id || pl.text != nl.text || pl.urgent != nl.urgent;
  }

  Future<void> _sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _cubit.isBusy) return;
    _stickToBottom = true;
    _controller.clear();
    _focusNode.unfocus();
    // warmUp ile çoğu zaman anında; yoksa diyalog. Mesaj emit'i hemen ardından.
    if (!await AiConsent.ensure(context)) {
      if (mounted && _controller.text.isEmpty) _controller.text = text;
      return;
    }
    if (!mounted) return;
    final delivered = await _cubit.sendMessage(text);
    unawaited(_loadQuota());
    // Ulaşmadıysa yazılan metin kaybolmasın.
    if (!delivered && mounted && _controller.text.isEmpty) {
      _controller.text = text;
    }
  }

  void _onSuggestionTap(String text) => _sendText(text);

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
        for (final text in _suggestions) ...[
          _SuggestionChip(label: text, onTap: () => _onSuggestionTap(text)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildConversation(ChatSessionState state) {
    final messages = state.messages;
    final isTyping = state.isAiTyping;
    final lastAiIndex = messages.lastIndexWhere((m) => m.sender == ChatSender.ai);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_scrollController.hasClients) return false;
        // Yalnızca kullanıcı jesti; programatik jumpTo stick'i bozmasın.
        if (notification is UserScrollNotification) {
          if (notification.direction == ScrollDirection.reverse) {
            _stickToBottom = false;
          } else if (notification.direction == ScrollDirection.forward) {
            final pos = _scrollController.position;
            if (pos.maxScrollExtent - pos.pixels <= 72) {
              _stickToBottom = true;
            }
          }
        }
        return false;
      },
      child: ListView.builder(
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
          final typewriter =
              message.sender == ChatSender.ai && index == lastAiIndex;
          return _AppearOnce(
            key: ValueKey(message.id),
            child: _MessageBubble(
              message: message,
              typewriter: typewriter,
              streaming: typewriter && state.isStreaming,
              onReveal: _scrollToBottom,
            ),
          );
        },
      ),
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
                    _chatContentChanged(prev, next) ||
                    prev.errorMessage != next.errorMessage,
                listener: (context, state) {
                  _scrollToBottom();
                  final error = state.errorMessage;
                  if (error != null && error.isNotEmpty) {
                    AppSnackbar.show(
                      context: context,
                      text: error,
                      type: SnackBarType.failure,
                    );
                    _cubit.clearError();
                  }
                },
                buildWhen: _chatContentChanged,
                builder: (context, state) {
                  // Boş → konuşma geçişi animasyonsuz; öneri tıkı anında gelsin.
                  if (state.hasConversation) {
                    return _buildConversation(state);
                  }
                  return _buildEmptyState();
                },
              ),
            ),
            if (_remaining case final remaining?)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'chat.quota_left'.plural(remaining),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.chatHistoryEmptySubtitle.copyWith(
                    color: ColorName.colorWhite.withValues(alpha: 0.7),
                  ),
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
/// SizeTransition yok: her karede liste yüksekliği değişip scroll savaşı çıkıyordu.
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
    duration: const Duration(milliseconds: 280),
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
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_curved),
        child: widget.child,
      ),
    );
  }
}

final class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.typewriter = false,
    this.streaming = false,
    this.onReveal,
  });

  final ChatMessage message;
  final bool typewriter;
  final bool streaming;
  final VoidCallback? onReveal;

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
      child: isUser || !typewriter
          ? Text(message.text, style: AppTextStyles.chatBubbleMessage)
          : _TypewriterText(
              text: message.text,
              streaming: streaming,
              onReveal: onReveal,
            ),
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
          Flexible(
            child: message.urgent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bubble,
                      const SizedBox(height: 8),
                      const _UrgentHelpCard(),
                    ],
                  )
                : bubble,
          ),
        ],
      ),
    );
  }
}

/// ChatGPT benzeri yazma; grapheme (emoji) bütünlüğünü korur.
final class _TypewriterText extends StatefulWidget {
  const _TypewriterText({
    required this.text,
    required this.streaming,
    this.onReveal,
  });

  final String text;
  final bool streaming;
  final VoidCallback? onReveal;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

final class _TypewriterTextState extends State<_TypewriterText> {
  static const _tick = Duration(milliseconds: 24);
  var _visibleCount = 0;
  var _scrollTick = 0;
  Timer? _timer;

  Characters get _target => widget.text.characters;

  String get _visible => _target.take(_visibleCount).toString();

  @override
  void initState() {
    super.initState();
    if (widget.streaming || widget.text.isEmpty) {
      _visibleCount = 0;
      _arm();
    } else {
      // Geçmişten açılan tam metin — animasyonsuz.
      _visibleCount = _target.length;
    }
  }

  @override
  void didUpdateWidget(covariant _TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == oldWidget.text &&
        widget.streaming == oldWidget.streaming) {
      return;
    }
    // Metin kısaldıysa / değiştiyse: eski görünür önekse koru, değilse sıfırla.
    final next = _target;
    if (_visibleCount > next.length) {
      final oldVisible = oldWidget.text.characters.take(_visibleCount).toString();
      if (widget.text.startsWith(oldVisible)) {
        _visibleCount = next.length;
      } else if (!widget.text.startsWith(_visible) && _visible.isNotEmpty) {
        // Farklı içerik — geri zıplatma; mevcut önek kadar tut.
        var keep = 0;
        final oldChars = oldVisible.characters.toList();
        final newChars = next.toList();
        while (keep < oldChars.length &&
            keep < newChars.length &&
            oldChars[keep] == newChars[keep]) {
          keep++;
        }
        _visibleCount = keep;
      } else {
        _visibleCount = next.length;
      }
    }
    // Akış bitti ve az kaldıysa tamamını göster (tamamlanma titremesini kes).
    if (!widget.streaming &&
        oldWidget.streaming &&
        next.length - _visibleCount <= 12) {
      _visibleCount = next.length;
      _timer?.cancel();
      _timer = null;
      return;
    }
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    if (_visibleCount >= _target.length && !widget.streaming) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(_tick, (_) => _tickReveal());
  }

  void _tickReveal() {
    if (!mounted) return;
    final total = _target.length;
    if (_visibleCount >= total) {
      if (!widget.streaming) {
        _timer?.cancel();
        _timer = null;
      }
      return;
    }
    // Grapheme adımı: emoji ortasından bölünmesin.
    final step = widget.streaming ? 1 : 4;
    setState(() {
      _visibleCount = math.min(_visibleCount + step, total);
    });
    // Her harfte scroll = tamamlanınca zıplama; seyrek tut.
    _scrollTick++;
    if (_scrollTick % 3 == 0 || _visibleCount >= total) {
      widget.onReveal?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _visibleCount == 0 ? ' ' : _visible,
      style: AppTextStyles.chatBubbleMessage,
    );
  }
}

/// Kriz işaretli mesajlarda (sunucu `safety: urgent`) yardım yönlendirmesi.
final class _UrgentHelpCard extends StatelessWidget {
  const _UrgentHelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'chat.safety_urgent'.tr(),
        style: AppTextStyles.chatBubbleMessage.copyWith(
          color: Colors.red.shade900,
        ),
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
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorName.colorCtaGradientTop,
                ColorName.colorCtaGradientBottom,
              ],
            ),
          ),
          child: Center(
            child: Assets.icons.solarPlainBold.svg(width: 22, height: 22),
          ),
        ),
      ),
    );
  }
}
