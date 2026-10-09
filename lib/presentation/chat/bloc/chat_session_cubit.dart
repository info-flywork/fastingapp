import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/domain/chat/chat_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_state.dart';
import 'package:uuid/uuid.dart';

/// Aktif sohbet + geçmiş; backend `/v1/chat` ile konuşur.
final class ChatSessionCubit extends Cubit<ChatSessionState> {
  ChatSessionCubit(this._repository, this._revenueCat)
    : super(const ChatSessionState());

  final ChatRepository _repository;
  final RevenueCatService _revenueCat;
  static const _uuid = Uuid();

  var _replyToken = 0;
  var _consentGranted = false;
  var _historyLoaded = false;

  Future<void> loadHistory({bool force = false}) async {
    if (_historyLoaded && !force) return;
    emit(state.copyWith(isLoadingHistory: true, clearError: true));
    try {
      final items = await _repository.listConversations();
      _historyLoaded = true;
      emit(
        state.copyWith(
          history: items.map(_toHistoryItem).toList(),
          isLoadingHistory: false,
        ),
      );
    } on NetworkException catch (e) {
      emit(state.copyWith(isLoadingHistory: false, errorMessage: e.message));
    } on Object catch (e) {
      emit(state.copyWith(isLoadingHistory: false, errorMessage: e.toString()));
    }
  }

  /// Geçmiş kartından konuşma aç.
  Future<void> openConversation(String conversationId) async {
    if (state.isAiTyping) return;
    emit(state.copyWith(isAiTyping: true, clearError: true));
    try {
      final messages = await _repository.listMessages(conversationId);
      emit(
        state.copyWith(
          activeConversationId: conversationId,
          messages: messages
              .map(
                (m) => ChatMessage(
                  id: m.id,
                  text: m.text,
                  sender: m.isUser ? ChatSender.user : ChatSender.ai,
                ),
              )
              .toList(),
          isAiTyping: false,
        ),
      );
    } on NetworkException catch (e) {
      emit(state.copyWith(isAiTyping: false, errorMessage: e.message));
    } on Object catch (e) {
      emit(state.copyWith(isAiTyping: false, errorMessage: e.toString()));
    }
  }

  Future<void> startNewChat() async {
    _replyToken++;
    emit(
      state.copyWith(
        messages: const [],
        isAiTyping: false,
        clearActiveConversation: true,
        clearError: true,
      ),
    );
  }

  Future<void> sendMessage(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.isAiTyping) return;

    final token = ++_replyToken;
    final localUserId = 'local_${_uuid.v4()}';
    final clientMessageId = _uuid.v4();

    final userMessage = ChatMessage(
      id: localUserId,
      text: text,
      sender: ChatSender.user,
    );
    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isAiTyping: true,
        clearError: true,
      ),
    );

    try {
      await _ensureConsent();
      final conversationId = await _ensureConversation();
      if (token != _replyToken || isClosed) return;

      final result = await _sendWithConsentRetry(
        conversationId: conversationId,
        text: text,
        clientMessageId: clientMessageId,
        onStreamUpdate: (update) {
          if (token != _replyToken || isClosed) return;
          final nextMessages = [...state.messages];

          if (update.fullText == null) {
            final userIdx = nextMessages.indexWhere((m) => m.id == localUserId);
            if (userIdx >= 0 && update.userMessageId != null) {
              nextMessages[userIdx] = ChatMessage(
                id: update.userMessageId!,
                text: text,
                sender: ChatSender.user,
              );
            }
            emit(state.copyWith(messages: nextMessages));
            return;
          }

          final assistantId = update.assistantMessageId;
          if (assistantId == null) return;
          final assistantIdx = nextMessages.indexWhere(
            (m) => m.id == assistantId,
          );
          final assistantMessage = ChatMessage(
            id: assistantId,
            text: update.fullText!,
            sender: ChatSender.ai,
          );
          if (assistantIdx >= 0) {
            nextMessages[assistantIdx] = assistantMessage;
          } else {
            nextMessages.add(assistantMessage);
          }
          emit(
            state.copyWith(
              messages: nextMessages,
              isAiTyping: false,
              activeConversationId: conversationId,
            ),
          );
        },
      );
      if (token != _replyToken || isClosed) return;

      final assistant = result.assistant;
      if (assistant == null || assistant.text.isEmpty) {
        emit(
          state.copyWith(
            isAiTyping: false,
            activeConversationId: conversationId,
          ),
        );
      } else {
        final nextMessages = [...state.messages];
        final userIdx = nextMessages.indexWhere((m) => m.id == localUserId);
        if (userIdx >= 0 && result.userMessageId != null) {
          nextMessages[userIdx] = ChatMessage(
            id: result.userMessageId!,
            text: text,
            sender: ChatSender.user,
          );
        }
        final assistantIdx = nextMessages.indexWhere(
          (m) => m.id == assistant.id,
        );
        if (assistantIdx >= 0) {
          nextMessages[assistantIdx] = ChatMessage(
            id: assistant.id,
            text: assistant.text,
            sender: ChatSender.ai,
          );
        } else {
          nextMessages.add(
            ChatMessage(
              id: assistant.id,
              text: assistant.text,
              sender: ChatSender.ai,
            ),
          );
        }
        emit(
          state.copyWith(
            messages: nextMessages,
            isAiTyping: false,
            activeConversationId: conversationId,
          ),
        );
      }
      await loadHistory(force: true);
    } on NetworkException catch (e) {
      if (token != _replyToken || isClosed) return;
      // Günlük kota doldu ve premium'da artar → paywall.
      if (RevenueCatService.needsUpgrade(e)) {
        unawaited(_revenueCat.presentPaywall());
      }
      emit(
        state.copyWith(
          isAiTyping: false,
          errorMessage: _friendlyError(e),
          messages: state.messages.where((m) => m.id != localUserId).toList(),
        ),
      );
    } on Object catch (e) {
      if (token != _replyToken || isClosed) return;
      emit(
        state.copyWith(
          isAiTyping: false,
          errorMessage: e.toString(),
          messages: state.messages.where((m) => m.id != localUserId).toList(),
        ),
      );
    }
  }

  Future<ChatSendResult> _sendWithConsentRetry({
    required String conversationId,
    required String text,
    required String clientMessageId,
    void Function(ChatStreamUpdate update)? onStreamUpdate,
  }) async {
    try {
      return await _repository.sendMessage(
        conversationId: conversationId,
        text: text,
        clientMessageId: clientMessageId,
        onStreamUpdate: onStreamUpdate,
      );
    } on NetworkException catch (e) {
      if (e.code == 'CONSENT_REQUIRED') {
        await _repository.grantAiProcessingConsent();
        _consentGranted = true;
        return _repository.sendMessage(
          conversationId: conversationId,
          text: text,
          clientMessageId: clientMessageId,
          onStreamUpdate: onStreamUpdate,
        );
      }
      rethrow;
    }
  }

  Future<void> _ensureConsent() async {
    if (_consentGranted) return;
    try {
      await _repository.grantAiProcessingConsent();
      _consentGranted = true;
    } on NetworkException {
      // Rıza zaten varsa veya uç hata verirse gönderimde tekrar denenecek.
    }
  }

  Future<String> _ensureConversation() async {
    final existing = state.activeConversationId;
    if (existing != null) return existing;
    final created = await _repository.createConversation();
    emit(state.copyWith(activeConversationId: created.id));
    return created.id;
  }

  Future<void> togglePinHistory(String id) async {
    ChatHistoryItem? item;
    for (final e in state.history) {
      if (e.id == id) {
        item = e;
        break;
      }
    }
    if (item == null) return;
    try {
      await _repository.updateConversation(id, isPinned: !item.isPinned);
      await loadHistory(force: true);
    } on NetworkException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> deleteHistory(String id) async {
    try {
      await _repository.deleteConversation(id);
      final clearingActive = state.activeConversationId == id;
      if (clearingActive) _replyToken++;
      emit(
        state.copyWith(
          history: state.history.where((e) => e.id != id).toList(),
          messages: clearingActive ? const [] : null,
          isAiTyping: clearingActive ? false : null,
          clearActiveConversation: clearingActive,
        ),
      );
    } on NetworkException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void clearActiveChat() {
    _replyToken++;
    emit(
      state.copyWith(
        messages: const [],
        isAiTyping: false,
        clearActiveConversation: true,
        clearError: true,
      ),
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  ChatHistoryItem _toHistoryItem(ChatConversation c) => ChatHistoryItem(
    id: c.id,
    title: c.title.isEmpty ? 'Coach Mochi' : c.title,
    messageCount: c.messageCount,
    date: c.lastMessageAt ?? c.createdAt,
    isPinned: c.isPinned,
  );

  String _friendlyError(NetworkException e) {
    if (e.code == 'QUOTA_EXCEEDED') {
      return e.message;
    }
    if (e.code == 'UNAVAILABLE') {
      return e.message;
    }
    return e.message;
  }
}
