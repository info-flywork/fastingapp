import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/domain/chat/ai_consent.dart';
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
  var _historyLoaded = false;

  /// Çıkış / hesap değişimi: önceki kullanıcının konuşması ve geçmişi
  /// bırakılır; uçuştaki yanıt akışı yok sayılır.
  void reset() {
    _replyToken++;
    _streaming = false;
    _historyLoaded = false;
    emit(const ChatSessionState());
  }

  Future<void> loadHistory({bool force = false}) async {
    if (_historyLoaded && !force) return;
    emit(state.copyWith(isLoadingHistory: true, clearError: true));
    try {
      final items = await _repository.listConversations();
      _historyLoaded = true;
      emit(
        state.copyWith(
          history: _orderedHistory(items.map(_toHistoryItem).toList()),
          isLoadingHistory: false,
        ),
      );
    } on NetworkException catch (e) {
      emit(state.copyWith(isLoadingHistory: false, errorMessage: e.message));
    } on Object catch (e) {
      emit(
        state.copyWith(
          isLoadingHistory: false,
          errorMessage: errorMessageOf(e),
        ),
      );
    }
  }

  /// Geçmiş kartından konuşma aç.
  Future<void> openConversation(String conversationId) async {
    if (isBusy) return;
    // Uçuştaki eski yanıt bu konuşmaya akmasın.
    _replyToken++;
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
                  urgent: !m.isUser && m.safety == 'urgent',
                ),
              )
              .toList(),
          isAiTyping: false,
        ),
      );
    } on NetworkException catch (e) {
      emit(state.copyWith(isAiTyping: false, errorMessage: e.message));
    } on Object catch (e) {
      emit(state.copyWith(isAiTyping: false, errorMessage: errorMessageOf(e)));
    }
  }

  Future<void> startNewChat() async {
    _replyToken++;
    _streaming = false;
    emit(
      state.copyWith(
        messages: const [],
        isAiTyping: false,
        clearActiveConversation: true,
        clearError: true,
      ),
    );
  }

  /// Yanıt akışı sürüyor (ilk parça gelince `isAiTyping` düşer ama akış
  /// biter bitmez değil): bu sırada yeni mesaj / konuşma açılmaz; yoksa
  /// yanıt yanlış konuşmaya akıyordu.
  var _streaming = false;

  bool get isBusy => _streaming || state.isAiTyping;

  /// `false`: mesaj sunucuya ulaşmadı (metin giriş alanına geri konmalı).
  Future<bool> sendMessage(String raw) async {
    if (raw.trim().isEmpty || isBusy) return true;
    _streaming = true;
    final token = _replyToken + 1;
    try {
      return await _send(raw);
    } finally {
      if (_replyToken == token) _streaming = false;
    }
  }

  Future<bool> _send(String raw) async {
    final text = raw.trim();

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

    String? conversationId;
    // Sunucu kullanıcı mesajını kaydetti mi (akış ortasında hata olursa
    // mesaj silinmez, konuşma sunucudan yeniden yüklenir).
    var storedOnServer = false;
    try {
      // Rıza UI katmanında (AiConsent.ensure); burada sessiz grant yok.
      conversationId = await _ensureConversation();
      if (token != _replyToken || isClosed) return true;

      final result = await _repository.sendMessage(
        conversationId: conversationId,
        text: text,
        clientMessageId: clientMessageId,
        onStreamUpdate: (update) {
          if (token != _replyToken || isClosed) return;
          if (update.fullText == null) {
            // Sunucu kimliği balonun anahtarını değiştirirse düşme
            // animasyonu ikinci kez oynar. Yerel kimlik ekranda kalır.
            if (update.userMessageId != null) storedOnServer = true;
            return;
          }

          final nextMessages = [...state.messages];

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
      if (token != _replyToken || isClosed) return true;

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
        if (result.userMessageId != null) storedOnServer = true;
        final assistantIdx = nextMessages.indexWhere(
          (m) => m.id == assistant.id,
        );
        if (assistantIdx >= 0) {
          nextMessages[assistantIdx] = ChatMessage(
            id: assistant.id,
            text: assistant.text,
            sender: ChatSender.ai,
            urgent: assistant.safety == 'urgent',
          );
        } else {
          nextMessages.add(
            ChatMessage(
              id: assistant.id,
              text: assistant.text,
              sender: ChatSender.ai,
              urgent: assistant.safety == 'urgent',
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
      return true;
    } on NetworkException catch (e) {
      AiConsent.onError(e);
      if (token != _replyToken || isClosed) return true;
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
      _reloadAfterFailure(conversationId, storedOnServer);
      return storedOnServer;
    } on Object catch (e) {
      if (token != _replyToken || isClosed) return true;
      emit(
        state.copyWith(
          isAiTyping: false,
          errorMessage: errorMessageOf(e),
          messages: state.messages.where((m) => m.id != localUserId).toList(),
        ),
      );
      _reloadAfterFailure(conversationId, storedOnServer);
      return storedOnServer;
    }
  }

  /// Akış yarıda kaldıysa sunucuda kullanıcı mesajı (ve yarım yanıt)
  /// saklıdır: ekran sunucudaki gerçek konuşmayı göstersin.
  void _reloadAfterFailure(String? conversationId, bool storedOnServer) {
    if (conversationId == null || !storedOnServer) return;
    unawaited(openConversation(conversationId));
  }

  Future<String> _ensureConversation() async {
    final existing = state.activeConversationId;
    if (existing != null) return existing;
    final created = await _repository.createConversation();
    emit(state.copyWith(activeConversationId: created.id));
    return created.id;
  }

  Future<void> togglePinHistory(String id) async {
    final previous = state.history;
    final index = previous.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final wasPinned = previous[index].isPinned;
    final updated = [
      for (final item in previous)
        if (item.id == id) item.copyWith(isPinned: !wasPinned) else item,
    ];
    emit(state.copyWith(history: _orderedHistory(updated), clearError: true));
    try {
      await _repository.updateConversation(id, isPinned: !wasPinned);
    } on Object catch (e) {
      if (isClosed) return;
      _rollbackPin(id, wasPinned, _historyError(e));
    }
  }

  Future<void> deleteHistory(String id) async {
    final snapshot = state;
    final index = snapshot.history.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final removed = snapshot.history[index];
    final clearingActive = snapshot.activeConversationId == id;
    if (clearingActive) _replyToken++;
    emit(
      snapshot.copyWith(
        history: [
          for (final item in snapshot.history)
            if (item.id != id) item,
        ],
        messages: clearingActive ? const [] : null,
        isAiTyping: clearingActive ? false : null,
        clearActiveConversation: clearingActive,
        clearError: true,
      ),
    );
    try {
      await _repository.deleteConversation(id);
    } on Object catch (e) {
      if (isClosed) return;
      _rollbackDelete(
        removed: removed,
        snapshot: snapshot,
        clearingActive: clearingActive,
        message: _historyError(e),
      );
    }
  }

  void _rollbackPin(String id, bool wasPinned, String message) {
    if (!state.history.any((item) => item.id == id)) {
      emit(state.copyWith(errorMessage: message));
      return;
    }
    final restored = [
      for (final item in state.history)
        if (item.id == id) item.copyWith(isPinned: wasPinned) else item,
    ];
    emit(
      state.copyWith(history: _orderedHistory(restored), errorMessage: message),
    );
  }

  void _rollbackDelete({
    required ChatHistoryItem removed,
    required ChatSessionState snapshot,
    required bool clearingActive,
    required String message,
  }) {
    if (state.history.any((item) => item.id == removed.id)) {
      emit(state.copyWith(errorMessage: message));
      return;
    }
    final stillClearing =
        clearingActive &&
        state.activeConversationId == null &&
        state.messages.isEmpty;
    emit(
      state.copyWith(
        history: _orderedHistory([...state.history, removed]),
        messages: stillClearing ? snapshot.messages : null,
        isAiTyping: stillClearing ? snapshot.isAiTyping : null,
        activeConversationId: stillClearing
            ? snapshot.activeConversationId
            : null,
        errorMessage: message,
      ),
    );
  }

  String _historyError(Object error) {
    if (error is NetworkException) return error.message;
    return errorMessageOf(error);
  }

  /// Sabitlenenler üstte, sonra son mesaj zamanına göre.
  List<ChatHistoryItem> _orderedHistory(List<ChatHistoryItem> items) {
    return [...items]..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.id.compareTo(a.id);
    });
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
