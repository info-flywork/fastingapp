import 'package:equatable/equatable.dart';

enum ChatSender { user, ai }

final class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
  });

  final String id;
  final String text;
  final ChatSender sender;

  @override
  List<Object?> get props => [id, text, sender];
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
  });

  final List<ChatMessage> messages;
  final List<ChatHistoryItem> history;
  final bool isAiTyping;

  bool get hasConversation => messages.isNotEmpty || isAiTyping;

  ChatSessionState copyWith({
    List<ChatMessage>? messages,
    List<ChatHistoryItem>? history,
    bool? isAiTyping,
  }) {
    return ChatSessionState(
      messages: messages ?? this.messages,
      history: history ?? this.history,
      isAiTyping: isAiTyping ?? this.isAiTyping,
    );
  }

  @override
  List<Object?> get props => [messages, history, isAiTyping];
}
