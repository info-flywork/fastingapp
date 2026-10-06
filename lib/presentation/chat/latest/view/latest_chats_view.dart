import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
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
    _cubit.ensureSeedHistory();
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
              child: BlocBuilder<ChatSessionCubit, ChatSessionState>(
                bloc: _cubit,
                builder: (context, state) {
                  if (state.history.isEmpty) {
                    return const _LatestChatsEmptyState();
                  }

                  return ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: state.history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ChatHistoryCard(
                        item: state.history[index],
                        onPin: () =>
                            _cubit.togglePinHistory(state.history[index].id),
                        onDelete: () =>
                            _cubit.deleteHistory(state.history[index].id),
                      );
                    },
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
            onPressed: () => context.pop(),
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
          _IconButton(
            onTap: () {},
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

final class _ChatHistoryCard extends StatelessWidget {
  const _ChatHistoryCard({
    required this.item,
    required this.onPin,
    required this.onDelete,
  });

  final ChatHistoryItem item;
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.colorChatSurface,
        borderRadius: BorderRadius.circular(16),
        border: item.isPinned
            ? Border.all(
                color: ColorName.colorChatUserBubble.withValues(alpha: 0.45),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.isPinned) ...[
                const Icon(
                  Icons.push_pin_rounded,
                  size: 16,
                  color: ColorName.colorChatUserBubble,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(item.title, style: AppTextStyles.chatBubbleMessage),
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
              Assets.icons.solarChatDotsLineDuotone.svg(width: 18, height: 18),
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
    );
  }
}

enum _HistoryMenuAction { pin, delete }
