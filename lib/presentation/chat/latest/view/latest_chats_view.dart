import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_cubit.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Son sohbetler listesi (Figma).
final class LatestChatsView extends StatefulWidget {
  const LatestChatsView({super.key});

  @override
  State<LatestChatsView> createState() => _LatestChatsViewState();
}

class _LatestChatsViewState extends State<LatestChatsView> {
  late final ChatSessionCubit _cubit = getIt<ChatSessionCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadHistory(force: true);
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ColorName.colorButtonDark,
        body: Column(
          children: [
            const _LatestChatsHeader(),
            Expanded(
              child: BlocConsumer<ChatSessionCubit, ChatSessionState>(
                bloc: _cubit,
                listenWhen: (prev, next) =>
                    prev.errorMessage != next.errorMessage,
                listener: (context, state) {
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
                builder: (context, state) {
                  if (state.isLoadingHistory && state.history.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.history.isEmpty) {
                    return const _LatestChatsEmptyState();
                  }

                  return _AnimatedChatHistory(
                    items: state.history,
                    onOpen: (item) async {
                      await _cubit.openConversation(item.id);
                      if (context.mounted) context.pop();
                    },
                    onPin: (item) => _cubit.togglePinHistory(item.id),
                    onDelete: (item) => _cubit.deleteHistory(item.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LatestChatsEmptyState extends StatelessWidget {
  const _LatestChatsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppImages.mascotChat.image(height: 180, fit: BoxFit.contain),
                const SizedBox(height: 28),
                Text(
                  'chat.empty_title'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.chatHistoryEmptyTitle,
                ),
                const SizedBox(height: 10),
                Text(
                  'chat.empty_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.chatHistoryEmptySubtitle,
                ),
              ],
            ),
          ),
          AppButton(
            label: 'chat.start_chat'.tr(),
            onPressed: () {
              getIt<ChatSessionCubit>().startNewChat();
              context.pop();
            },
            showIcon: false,
            decoration: AppButtonDecoration.primary(),
          ),
        ],
      ),
    );
  }
}

final class _LatestChatsHeader extends StatelessWidget {
  const _LatestChatsHeader();

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
          _IconButton(
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
                  'chat.latest_chats'.tr(),
                  style: AppTextStyles.chatCoachName,
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

final class _IconButton extends StatelessWidget {
  const _IconButton({required this.onTap, required this.child});

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

final class _AnimatedChatHistory extends StatefulWidget {
  const _AnimatedChatHistory({
    required this.items,
    required this.onOpen,
    required this.onPin,
    required this.onDelete,
  });

  final List<ChatHistoryItem> items;
  final ValueChanged<ChatHistoryItem> onOpen;
  final ValueChanged<ChatHistoryItem> onPin;
  final ValueChanged<ChatHistoryItem> onDelete;

  @override
  State<_AnimatedChatHistory> createState() => _AnimatedChatHistoryState();
}

class _AnimatedChatHistoryState extends State<_AnimatedChatHistory> {
  static const _motion = Duration(milliseconds: 320);

  final _listKey = GlobalKey<AnimatedListState>();
  late List<ChatHistoryItem> _items = List.of(widget.items);
  var _showEmpty = false;
  var _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _showEmpty = widget.items.isEmpty;
  }

  @override
  void didUpdateWidget(covariant _AnimatedChatHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_same(_items, widget.items)) _scheduleSync();
  }

  bool _same(List<ChatHistoryItem> a, List<ChatHistoryItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted || _same(_items, widget.items)) return;
      _sync(widget.items);
    });
  }

  void _sync(List<ChatHistoryItem> next) {
    final list = _listKey.currentState;
    if (list == null || _showEmpty) {
      setState(() {
        _items = List.of(next);
        _showEmpty = next.isEmpty;
      });
      return;
    }

    for (var i = _items.length - 1; i >= 0; i--) {
      if (next.every((item) => item.id != _items[i].id)) {
        _removeAt(list, i, revealEmpty: next.isEmpty);
      }
    }

    var changedInPlace = false;
    for (var target = 0; target < next.length; target++) {
      final want = next[target];
      final current = _items.indexWhere((item) => item.id == want.id);
      if (current == -1) {
        _items.insert(target, want);
        list.insertItem(target, duration: _motion);
      } else if (current != target) {
        _removeAt(list, current, revealEmpty: false);
        final insertAt = current < target ? target - 1 : target;
        _items.insert(insertAt, want);
        list.insertItem(insertAt, duration: _motion);
      } else if (_items[target] != want) {
        _items[target] = want;
        changedInPlace = true;
      }
    }
    if (changedInPlace) setState(() {});
  }

  void _removeAt(
    AnimatedListState list,
    int index, {
    required bool revealEmpty,
  }) {
    final removed = _items.removeAt(index);
    final leavingLast = revealEmpty && _items.isEmpty;
    var armed = false;
    list.removeItem(index, (context, animation) {
      if (leavingLast && !armed) {
        armed = true;
        animation.addStatusListener((status) {
          if (status == AnimationStatus.dismissed &&
              mounted &&
              _items.isEmpty) {
            setState(() => _showEmpty = true);
          }
        });
      }
      return _row(removed, animation, interactive: false);
    }, duration: _motion);
  }

  Widget _row(
    ChatHistoryItem item,
    Animation<double> animation, {
    required bool interactive,
  }) {
    return _MotionRow(
      animation: animation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ChatHistoryCard(
          item: item,
          onOpen: interactive ? () => widget.onOpen(item) : () {},
          onPin: interactive ? () => widget.onPin(item) : () {},
          onDelete: interactive ? () => widget.onDelete(item) : () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showEmpty) return const _LatestChatsEmptyState();
    return AnimatedList(
      key: _listKey,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) {
        if (index < 0 || index >= _items.length) {
          return const SizedBox.shrink();
        }
        return _row(_items[index], animation, interactive: true);
      },
    );
  }
}

final class _ChatHistoryCard extends StatelessWidget {
  const _ChatHistoryCard({
    required this.item,
    required this.onOpen,
    required this.onPin,
    required this.onDelete,
  });

  final ChatHistoryItem item;
  final VoidCallback onOpen;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  Future<void> _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final action = await showMenu<_HistoryMenuAction>(
      context: context,
      color: ColorName.colorChatSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: _HistoryMenuAction.pin,
          child: Text(
            item.isPinned ? 'chat.unpin'.tr() : 'chat.pin'.tr(),
            style: AppTextStyles.chatHistoryMenuItem,
          ),
        ),
        PopupMenuItem(
          value: _HistoryMenuAction.delete,
          child: Text(
            'chat.delete'.tr(),
            style: AppTextStyles.chatHistoryMenuDelete,
          ),
        ),
      ],
    );

    if (action == null) return;
    switch (action) {
      case _HistoryMenuAction.pin:
        onPin();
      case _HistoryMenuAction.delete:
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = item.date;
    final dateText =
        '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorName.colorChatSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isPinned
                  ? ColorName.colorChatUserBubble.withValues(alpha: 0.45)
                  : const Color(0x00000000),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    child: item.isPinned
                        ? const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 16,
                              color: ColorName.colorChatUserBubble,
                            ),
                          )
                        : const SizedBox(width: 0, height: 16),
                  ),
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTextStyles.chatBubbleMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (menuContext) {
                      return GestureDetector(
                        onTap: () => _showMenu(menuContext),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Assets.icons.charmMenuKebab.svg(
                            width: 16,
                            height: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Assets.icons.solarChatDotsLineDuotone.svg(
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'chat.messages_count'.tr(args: ['${item.messageCount}']),
                    style: AppTextStyles.chatHistoryMeta,
                  ),
                  const Spacer(),
                  Assets.icons.solarCalendarDateLineDuotone.svg(
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(dateText, style: AppTextStyles.chatHistoryMeta),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _HistoryMenuAction { pin, delete }

final class _MotionRow extends StatefulWidget {
  const _MotionRow({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_MotionRow> createState() => _MotionRowState();
}

class _MotionRowState extends State<_MotionRow> {
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: widget.animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0.16, 0),
    end: Offset.zero,
  ).animate(_curved);

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curved,
      child: FadeTransition(
        opacity: _curved,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}
