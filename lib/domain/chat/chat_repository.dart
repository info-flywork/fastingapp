import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/base/model/base_response.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/no_content.dart';
import 'package:uuid/uuid.dart';

/// Coach Mochi sohbet (`/v1/chat/*`, backend doküman 04 §14).
final class ChatRepository {
  ChatRepository(this._network, this._dio);

  final NetworkManager _network;
  final Dio _dio;
  static const _uuid = Uuid();

  List<String>? _suggestions;
  String? _suggestionsLang;

  /// `GET /chat/suggestions` (dile göre metinler); dil değişene kadar önbellekte.
  Future<List<String>> suggestions() async {
    final lang = LocalizationManager.current.languageCode;
    final cached = _suggestions;
    if (cached != null && _suggestionsLang == lang) return cached;
    _suggestionsLang = lang;
    final result = await _network.send<_SuggestionList>(
      path: '/chat/suggestions',
      method: RequestType.get,
      parserModel: _SuggestionList.fromJson,
    );
    return _suggestions = result?.items ?? const [];
  }

  /// `GET /chat/quota` → bugün kalan sohbet mesajı; premium ya da sınırsızsa
  /// null.
  Future<int?> remainingMessages() async {
    final result = await _network.send<_ChatQuota>(
      path: '/chat/quota',
      method: RequestType.get,
      parserModel: _ChatQuota.fromJson,
    );
    if (result == null || result.isPremium) return null;
    return result.remaining;
  }

  /// Dil değişince / çıkışta önerileri yeniden çekmek için.
  void clearSuggestions() => _suggestions = null;

  Future<ChatConversation> createConversation({
    String contextSource = 'direct',
  }) async {
    final result = await _network.send<_ConversationEnvelope>(
      path: '/chat/conversations',
      method: RequestType.post,
      data: {'contextSource': contextSource},
      parserModel: _ConversationEnvelope.fromJson,
    );
    final conversation = result?.conversation;
    if (conversation == null) {
      throw NetworkException('common.error_generic'.tr());
    }
    return conversation;
  }

  Future<List<ChatConversation>> listConversations({int limit = 50}) async {
    final page = await _network.send<_ConversationPage>(
      path: '/chat/conversations',
      method: RequestType.get,
      queryParameters: {'limit': limit},
      parserModel: _ConversationPage.fromJson,
    );
    return page?.items ?? const [];
  }

  Future<List<ChatApiMessage>> listMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final page = await _network.send<_MessagePage>(
      path: '/chat/conversations/$conversationId/messages',
      method: RequestType.get,
      queryParameters: {'limit': limit},
      parserModel: _MessagePage.fromJson,
    );
    return page?.items ?? const [];
  }

  Future<ChatConversation> updateConversation(
    String id, {
    bool? isPinned,
    String? title,
  }) async {
    final body = <String, dynamic>{
      if (isPinned != null) 'isPinned': isPinned,
      if (title != null) 'title': title,
    };
    final result = await _network.send<_ConversationEnvelope>(
      path: '/chat/conversations/$id',
      method: RequestType.patch,
      data: body,
      parserModel: _ConversationEnvelope.fromJson,
    );
    final conversation = result?.conversation;
    if (conversation == null) {
      throw NetworkException('common.error_generic'.tr());
    }
    return conversation;
  }

  Future<void> deleteConversation(String id) => _network.send<NoContent>(
    path: '/chat/conversations/$id',
    method: RequestType.delete,
    parserModel: NoContent.fromJson,
  );

  /// `GET /user/consents` — `aiProcessing` en son kayıtta granted mi?
  Future<bool> hasAiProcessingConsent() async {
    final result = await _network.send<_ConsentList>(
      path: '/user/consents',
      method: RequestType.get,
      parserModel: _ConsentList.fromJson,
    );
    for (final item in result?.items ?? const <_ConsentItem>[]) {
      if (item.type == 'aiProcessing') return item.granted;
    }
    return false;
  }

  /// AI işleme rızası (sohbet / fotoğraf analizi önkoşulu).
  Future<void> grantAiProcessingConsent({String version = '2026-10'}) =>
      _network.send<NoContent>(
        path: '/user/consents',
        method: RequestType.post,
        data: {
          'type': 'aiProcessing',
          'version': version,
          'granted': true,
          'source': 'prompt',
        },
        parserModel: NoContent.fromJson,
      );

  /// SSE akışı (`Accept: text/event-stream`); [onStreamUpdate] her delta ile çağrılır.
  Future<ChatSendResult> sendMessage({
    required String conversationId,
    required String text,
    String? clientMessageId,
    void Function(ChatStreamUpdate update)? onStreamUpdate,
  }) async {
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/conversations/$conversationId/messages',
        data: {'id': clientMessageId ?? _uuid.v4(), 'text': text},
        options: Options(
          headers: {'Accept': 'text/event-stream'},
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw NetworkException('common.error_generic'.tr());
      }

      final contentType =
          response.headers.value('content-type')?.toLowerCase() ?? '';
      if (!contentType.contains('text/event-stream')) {
        final raw = await _readStreamBytes(body.stream);
        return _parseJsonSendResult(raw);
      }

      return _parseSseSendResult(body.stream, onStreamUpdate: onStreamUpdate);
    } on DioException catch (e) {
      throw await _streamError(e);
    }
  }

  /// Akış isteğinde hata gövdesi de akıştır: zarf okunur ki `code`/`details`
  /// (ör. `QUOTA_EXCEEDED` → paywall) ve yerelleştirilmiş mesaj kaybolmasın.
  Future<NetworkException> _streamError(DioException e) async {
    final data = e.response?.data;
    if (data is! ResponseBody) return NetworkException.fromDio(e);
    try {
      final decoded = jsonDecode(
        utf8.decode(await _readStreamBytes(data.stream)),
      );
      return NetworkException.fromDio(
        e.copyWith(
          response: Response<dynamic>(
            requestOptions: e.requestOptions,
            statusCode: e.response?.statusCode,
            data: decoded,
          ),
        ),
      );
    } on Object {
      return NetworkException.fromDio(e);
    }
  }

  Future<List<int>> _readStreamBytes(Stream<Uint8List> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return chunks;
  }

  ChatSendResult _parseJsonSendResult(List<int> raw) {
    final decoded = jsonDecode(utf8.decode(raw));
    if (decoded is! Map<String, dynamic>) {
      throw NetworkException('common.error_generic'.tr());
    }
    final parsed = BaseResponse<_SendEnvelope>.fromJson(
      decoded,
      _SendEnvelope.fromJson,
    );
    final data = parsed.data;
    if (data == null) {
      throw NetworkException('common.error_generic'.tr());
    }
    return ChatSendResult(
      userMessageId: data.userMessageId,
      assistant: data.assistantMessage,
      remainingToday: data.remainingToday,
    );
  }

  Future<ChatSendResult> _parseSseSendResult(
    Stream<Uint8List> byteStream, {
    void Function(ChatStreamUpdate update)? onStreamUpdate,
  }) async {
    var buffer = '';
    String? userMessageId;
    String? assistantMessageId;
    var assistantText = '';
    int? remainingToday;
    // `urgent`: kullanıcının mesajı kriz işareti taşıyor (sunucu sınıflandırır).
    var safety = 'none';

    // Akış durumlu çözülür: parça sınırında bölünen çok baytlı harfler
    // (ş, ğ, Kiril) bozulmaz. Dio `Stream<Uint8List>` verir → `cast`.
    final chunks = byteStream.cast<List<int>>().transform(
      const Utf8Decoder(allowMalformed: true),
    );
    await for (final chunk in chunks) {
      buffer += chunk;
      while (true) {
        final sep = buffer.indexOf('\n\n');
        if (sep == -1) break;
        final block = buffer.substring(0, sep);
        buffer = buffer.substring(sep + 2);
        final event = _parseSseBlock(block);
        if (event == null) continue;

        switch (event.name) {
          case 'message.created':
            final data = event.data;
            userMessageId = data['userMessageId'] as String?;
            assistantMessageId = data['assistantMessageId'] as String?;
            safety = data['safety'] as String? ?? safety;
            onStreamUpdate?.call(
              ChatStreamUpdate.created(
                userMessageId: userMessageId,
                assistantMessageId: assistantMessageId,
              ),
            );
          case 'delta':
            final piece = event.data['text'] as String? ?? '';
            if (piece.isEmpty) continue;
            assistantText += piece;
            onStreamUpdate?.call(
              ChatStreamUpdate.delta(
                assistantMessageId: assistantMessageId,
                piece: piece,
                fullText: assistantText,
              ),
            );
          case 'message.completed':
            final usage = event.data['usage'];
            if (usage is Map<String, dynamic>) {
              remainingToday = (usage['remainingToday'] as num?)?.toInt();
            }
            assistantMessageId =
                event.data['assistantMessageId'] as String? ??
                assistantMessageId;
            safety = event.data['safety'] as String? ?? safety;
          case 'error':
            final code = event.data['code'] as String? ?? 'UNAVAILABLE';
            throw NetworkException(
              'chat.unavailable'.tr(),
              code: code,
            );
        }
      }
    }

    if (assistantMessageId == null || assistantText.isEmpty) {
      throw NetworkException('common.error_generic'.tr());
    }

    return ChatSendResult(
      userMessageId: userMessageId,
      assistant: ChatApiMessage(
        id: assistantMessageId,
        role: 'assistant',
        text: assistantText,
        status: 'complete',
        safety: safety,
        createdAt: DateTime.now(),
      ),
      remainingToday: remainingToday,
    );
  }

  _SseEvent? _parseSseBlock(String block) {
    if (block.trim().isEmpty) return null;
    final lines = block.split('\n');
    if (lines.every((l) => l.startsWith(':'))) return null;

    String? name;
    final dataLines = <String>[];
    for (final line in lines) {
      if (line.startsWith(':')) continue;
      if (line.startsWith('event:')) {
        name = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }
    if (name == null || dataLines.isEmpty) return null;
    final raw = dataLines.join('\n');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return _SseEvent(name, decoded);
  }
}

final class ChatStreamUpdate {
  const ChatStreamUpdate._({
    this.userMessageId,
    this.assistantMessageId,
    this.piece,
    this.fullText,
  });

  factory ChatStreamUpdate.created({
    String? userMessageId,
    String? assistantMessageId,
  }) => ChatStreamUpdate._(
    userMessageId: userMessageId,
    assistantMessageId: assistantMessageId,
  );

  factory ChatStreamUpdate.delta({
    required String? assistantMessageId,
    required String piece,
    required String fullText,
  }) => ChatStreamUpdate._(
    assistantMessageId: assistantMessageId,
    piece: piece,
    fullText: fullText,
  );

  final String? userMessageId;
  final String? assistantMessageId;
  final String? piece;
  final String? fullText;
}

final class _SseEvent {
  const _SseEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;
}

final class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.isPinned,
    required this.messageCount,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      lastMessageAt: parse(json['lastMessageAt']),
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String title;
  final bool isPinned;
  final int messageCount;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
}

final class ChatApiMessage {
  const ChatApiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.status,
    required this.safety,
    required this.createdAt,
  });

  factory ChatApiMessage.fromJson(Map<String, dynamic> json) => ChatApiMessage(
    id: json['id'] as String,
    role: json['role'] as String? ?? 'assistant',
    text: json['text'] as String? ?? '',
    status: json['status'] as String? ?? 'complete',
    safety: json['safety'] as String? ?? 'none',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  final String id;
  final String role;
  final String text;
  final String status;
  final String safety;
  final DateTime createdAt;

  bool get isUser => role == 'user';
}

final class ChatSendResult {
  const ChatSendResult({
    required this.userMessageId,
    required this.assistant,
    this.remainingToday,
  });

  final String? userMessageId;
  final ChatApiMessage? assistant;
  final int? remainingToday;
}

final class _SuggestionList implements BaseModel<_SuggestionList> {
  const _SuggestionList(this.items);

  factory _SuggestionList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return _SuggestionList([
      if (raw is List)
        for (final item in raw.whereType<Map<String, dynamic>>())
          if ((item['text'] as String? ?? '').isNotEmpty)
            item['text'] as String,
    ]);
  }

  final List<String> items;

  @override
  _SuggestionList fromJson(Map<String, dynamic> json) =>
      _SuggestionList.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _ConversationEnvelope implements BaseModel<_ConversationEnvelope> {
  const _ConversationEnvelope(this.conversation);

  factory _ConversationEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['conversation'];
    return _ConversationEnvelope(
      raw is Map<String, dynamic> ? ChatConversation.fromJson(raw) : null,
    );
  }

  final ChatConversation? conversation;

  @override
  _ConversationEnvelope fromJson(Map<String, dynamic> json) =>
      _ConversationEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'conversation': conversation == null
        ? null
        : {'id': conversation!.id, 'title': conversation!.title},
  };
}

final class _ConversationPage implements BaseModel<_ConversationPage> {
  const _ConversationPage(this.items);

  factory _ConversationPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(ChatConversation.fromJson)
              .toList()
        : const <ChatConversation>[];
    return _ConversationPage(items);
  }

  final List<ChatConversation> items;

  @override
  _ConversationPage fromJson(Map<String, dynamic> json) =>
      _ConversationPage.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'items': items.length};
}

final class _MessagePage implements BaseModel<_MessagePage> {
  const _MessagePage(this.items);

  factory _MessagePage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(ChatApiMessage.fromJson)
              .toList()
        : const <ChatApiMessage>[];
    return _MessagePage(items);
  }

  final List<ChatApiMessage> items;

  @override
  _MessagePage fromJson(Map<String, dynamic> json) =>
      _MessagePage.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'items': items.length};
}

final class _SendEnvelope implements BaseModel<_SendEnvelope> {
  const _SendEnvelope({
    this.userMessageId,
    this.assistantMessage,
    this.remainingToday,
  });

  factory _SendEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['assistantMessage'];
    return _SendEnvelope(
      userMessageId: json['userMessageId'] as String?,
      assistantMessage: raw is Map<String, dynamic>
          ? ChatApiMessage.fromJson(raw)
          : null,
      remainingToday: (json['remainingToday'] as num?)?.toInt(),
    );
  }

  final String? userMessageId;
  final ChatApiMessage? assistantMessage;
  final int? remainingToday;

  @override
  _SendEnvelope fromJson(Map<String, dynamic> json) =>
      _SendEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'userMessageId': userMessageId,
    'remainingToday': remainingToday,
  };
}

final class _ConsentList implements BaseModel<_ConsentList> {
  const _ConsentList(this.items);

  factory _ConsentList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(_ConsentItem.fromJson)
              .toList()
        : const <_ConsentItem>[];
    return _ConsentList(items);
  }

  final List<_ConsentItem> items;

  @override
  _ConsentList fromJson(Map<String, dynamic> json) =>
      _ConsentList.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'items': items.length};
}

final class _ConsentItem {
  const _ConsentItem({required this.type, required this.granted});

  factory _ConsentItem.fromJson(Map<String, dynamic> json) => _ConsentItem(
    type: json['type'] as String? ?? '',
    granted: json['granted'] as bool? ?? false,
  );

  final String type;
  final bool granted;
}

final class _ChatQuota implements BaseModel<_ChatQuota> {
  const _ChatQuota({this.remaining, this.isPremium = false});

  factory _ChatQuota.fromJson(Map<String, dynamic> json) {
    final chat = json['chat'];
    return _ChatQuota(
      remaining: chat is Map<String, dynamic>
          ? (chat['remaining'] as num?)?.toInt()
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  final int? remaining;
  final bool isPremium;

  @override
  _ChatQuota fromJson(Map<String, dynamic> json) => _ChatQuota.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
