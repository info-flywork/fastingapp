import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_state.dart';

/// Aktif sohbet + geçmiş; sayfa kapansa da typing devam eder.
final class ChatSessionCubit extends Cubit<ChatSessionState> {
  ChatSessionCubit() : super(const ChatSessionState());

  var _seq = 0;
  var _replyToken = 0;
  var _didSeedHistory = false;

  void ensureSeedHistory() {
    if (_didSeedHistory || state.history.isNotEmpty) return;
    _didSeedHistory = true;
    emit(
      state.copyWith(
        history: [
          ChatHistoryItem(
            id: 'h1',
            title: 'chat.suggestion_hungry'.tr(),
            messageCount: 24,
            date: DateTime(2026, 4, 12),
          ),
          ChatHistoryItem(
            id: 'h2',
            title: 'chat.suggestion_coffee'.tr(),
            messageCount: 24,
            date: DateTime(2026, 4, 12),
          ),
        ],
      ),
    );
  }

  String _nextId() => 'm_${_seq++}';

  List<String> _repliesFor(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('aç') ||
        lower.contains('hungry') ||
        lower.contains('starving') ||
        lower.contains('hunger') ||
        lower.contains('boz')) {
      return ['chat.reply_hungry_1'.tr(), 'chat.reply_hungry_2'.tr()];
    }
    if (lower.contains('kahve') || lower.contains('coffee')) {
      return ['chat.reply_coffee'.tr()];
    }
    if (lower.contains('kilo') ||
        lower.contains('weight') ||
        lower.contains('ab')) {
      return ['chat.reply_weight'.tr()];
    }
    if (lower.contains('ye') ||
        lower.contains('eat') ||
        lower.contains('essen') ||
        lower.contains('bitince')) {
      return ['chat.reply_eat'.tr()];
    }
    return ['chat.reply_default'.tr()];
  }

  Future<void> sendMessage(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.isAiTyping) return;

    final token = ++_replyToken;
    final userMessage = ChatMessage(
      id: _nextId(),
      text: text,
      sender: ChatSender.user,
    );

    var messages = [...state.messages, userMessage];
    emit(
      state.copyWith(
        messages: messages,
        isAiTyping: true,
        history: _withActiveHistory(
          title: text,
          messageCount: messages.length,
        ),
      ),
    );

    final replies = _repliesFor(text);

    for (var i = 0; i < replies.length; i++) {
      await Future<void>.delayed(
        Duration(milliseconds: i == 0 ? 900 : 750),
      );
      if (isClosed || token != _replyToken) return;

      messages = [
        ...state.messages,
        ChatMessage(
          id: _nextId(),
          text: replies[i],
          sender: ChatSender.ai,
        ),
      ];
      final stillTyping = i < replies.length - 1;
      String? activeTitle;
      for (final e in state.history) {
        if (e.id == 'active') {
          activeTitle = e.title;
          break;
        }
      }
      emit(
        state.copyWith(
          messages: messages,
          isAiTyping: stillTyping,
          history: _withActiveHistory(
            title: activeTitle ?? text,
            messageCount: messages.length,
          ),
        ),
      );
    }
  }

  List<ChatHistoryItem> _withActiveHistory({
    required String title,
    required int messageCount,
  }) {
    const activeId = 'active';
    final existing = state.history.where((e) => e.id == activeId).toList();
    final item = ChatHistoryItem(
      id: activeId,
      title: existing.isNotEmpty ? existing.first.title : title,
      messageCount: messageCount,
      date: DateTime.now(),
      isPinned: existing.isNotEmpty && existing.first.isPinned,
    );
    final rest = state.history.where((e) => e.id != activeId).toList();
    return _sortedHistory([item, ...rest]);
  }

  List<ChatHistoryItem> _sortedHistory(List<ChatHistoryItem> items) {
    final pinned = items.where((e) => e.isPinned).toList();
    final others = items.where((e) => !e.isPinned).toList();
    return [...pinned, ...others];
  }

  void togglePinHistory(String id) {
    final updated = state.history.map((e) {
      if (e.id != id) return e;
      return e.copyWith(isPinned: !e.isPinned);
    }).toList();
    emit(state.copyWith(history: _sortedHistory(updated)));
  }

  void deleteHistory(String id) {
    final updated = state.history.where((e) => e.id != id).toList();
    if (id == 'active') {
      _replyToken++;
      emit(
        state.copyWith(
          history: updated,
          messages: const [],
          isAiTyping: false,
        ),
      );
      return;
    }
    emit(state.copyWith(history: updated));
  }

  void clearActiveChat() {
    _replyToken++;
    emit(state.copyWith(messages: const [], isAiTyping: false));
  }
}
