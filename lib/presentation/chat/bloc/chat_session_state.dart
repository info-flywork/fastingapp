import 'package:equatable/equatable.dart';

enum ChatSender { user, ai }

final class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.urgent = false,
  });

  final String id;
  final String text;
  final ChatSender sender;

  /// Sunucu `safety: urgent` (kriz işareti): yanıtın altında yardım uyarısı.
  final bool urgent;

  ChatMessage copyWith({String? text}) => ChatMessage(
    id: id,
    text: text ?? this.text,
    sender: sender,
    urgent: urgent,
  );

  @override
  List<Object?> get props => [id, text, sender, urgent];
}

final class ChatHistoryItem extends Equatable {
  const ChatHistoryItem({
    required this.id,
    required this.title,
    required this.messageCount,
    required this.date,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final int messageCount;
  final DateTime date;
  final bool isPinned;

  ChatHistoryItem copyWith({
    String? title,
    int? messageCount,
    DateTime? date,
    bool? isPinned,
  }) {
    return ChatHistoryItem(
      id: id,
      title: title ?? this.title,
      messageCount: messageCount ?? this.messageCount,
      date: date ?? this.date,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [id, title, messageCount, date, isPinned];
}

final class ChatSessionState extends Equatable {
  const ChatSessionState({
    this.messages = const [],
    this.history = const [],
    this.isAiTyping = false,
    this.isLoadingHistory = false,
    this.activeConversationId,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final List<ChatHistoryItem> history;
  final bool isAiTyping;
  final bool isLoadingHistory;
  final String? activeConversationId;
  final String? errorMessage;

  bool get hasConversation => messages.isNotEmpty || isAiTyping;

  ChatSessionState copyWith({
    List<ChatMessage>? messages,
    List<ChatHistoryItem>? history,
    bool? isAiTyping,
    bool? isLoadingHistory,
    String? activeConversationId,
    String? errorMessage,
    bool clearError = false,
    bool clearActiveConversation = false,
  }) {
    return ChatSessionState(
      messages: messages ?? this.messages,
      history: history ?? this.history,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      activeConversationId: clearActiveConversation
          ? null
          : (activeConversationId ?? this.activeConversationId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    messages,
    history,
    isAiTyping,
    isLoadingHistory,
    activeConversationId,
    errorMessage,
  ];
}
