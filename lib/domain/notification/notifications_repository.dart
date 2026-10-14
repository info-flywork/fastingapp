import 'dart:async';

import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/no_content.dart';
import 'package:flutter/foundation.dart';

/// Bildirim kutusu (`/v1/notifications`, backend doküman 04 §16). Başlık ve
/// gövde sunucuda kullanıcının dilinde hazırlanır.
final class NotificationsRepository {
  NotificationsRepository(this._networkManager);

  final NetworkManager _networkManager;

  /// Profil rozeti vb.; [refreshUnread] ile güncellenir.
  final ValueNotifier<int> unread = ValueNotifier(0);

  /// Son ilk sayfa (kutu yeniden açılınca boş flaş olmasın).
  InboxPage? _firstPage;

  /// Bellekteki ilk sayfa; yoksa null.
  InboxPage? get cachedInbox => _firstPage;

  void clearCache() {
    _firstPage = null;
    unread.value = 0;
  }

  /// Yeniden eskiye sayfa (`cursor` önceki [InboxPage.nextCursor]).
  Future<InboxPage> list({String? cursor, int limit = 20}) async {
    final page = await _networkManager.send<_InboxPagePayload>(
      path: '/notifications',
      method: RequestType.get,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      parserModel: _InboxPagePayload.fromJson,
    );
    // Null/başarısız parse eski önbelleği ezmesin (boş flaş olmasın).
    if (page == null) {
      if (cursor == null || cursor.isEmpty) {
        return _firstPage ?? const InboxPage();
      }
      return const InboxPage();
    }
    final result = page.toPage();
    if (cursor == null || cursor.isEmpty) _firstPage = result;
    return result;
  }

  /// Okunmamış bildirim sayısı (profil rozeti).
  Future<int> unreadCount() async {
    final result = await _networkManager.send<_UnreadCount>(
      path: '/notifications/unread-count',
      method: RequestType.get,
      parserModel: _UnreadCount.fromJson,
    );
    return result?.count ?? 0;
  }

  /// Sunucudan okuyup [unread] notifier'ını günceller.
  Future<int> refreshUnread() async {
    try {
      final count = await unreadCount();
      unread.value = count;
      return count;
    } on Object {
      return unread.value;
    }
  }

  void clearUnread() {
    unread.value = 0;
    _firstPage = null;
  }

  Future<void> markRead(String id) async {
    await _networkManager.send<NoContent>(
      path: '/notifications/$id/read',
      method: RequestType.post,
      data: const <String, dynamic>{},
      parserModel: NoContent.fromJson,
    );
    unawaited(refreshUnread());
  }

  Future<void> markAllRead() async {
    await _networkManager.send<NoContent>(
      path: '/notifications/read-all',
      method: RequestType.post,
      data: const <String, dynamic>{},
      parserModel: NoContent.fromJson,
    );
    unread.value = 0;
  }

  Future<void> remove(String id) async {
    await _networkManager.send<NoContent>(
      path: '/notifications/$id',
      method: RequestType.delete,
      parserModel: NoContent.fromJson,
    );
    final cached = _firstPage;
    if (cached != null) {
      _firstPage = InboxPage(
        items: [
          for (final n in cached.items)
            if (n.id != id) n,
        ],
        nextCursor: cached.nextCursor,
        hasMore: cached.hasMore,
      );
    }
    unawaited(refreshUnread());
  }
}

/// Bir bildirim listesi sayfası.
final class InboxPage {
  const InboxPage({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
  });

  final List<InboxNotification> items;
  final String? nextCursor;
  final bool hasMore;
}

final class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.category = '',
    this.deepLink,
    this.readAt,
  });

  factory InboxNotification.fromJson(Map<String, dynamic> json) =>
      InboxNotification(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        category: json['category'] as String? ?? '',
        deepLink: json['deepLink'] as String?,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['readAt'] as String? ?? '')?.toLocal(),
      );

  final String id;
  final String type;

  /// `fasting` | `weight` | `water` | `streak` | `challenge` | `world` | …
  final String category;

  /// `fastingapp://water` gibi; dokununca ilgili ekran açılır.
  final String? deepLink;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
}

final class _UnreadCount implements BaseModel<_UnreadCount> {
  const _UnreadCount(this.count);

  factory _UnreadCount.fromJson(Map<String, dynamic> json) =>
      _UnreadCount((json['count'] as num?)?.toInt() ?? 0);

  final int count;

  @override
  _UnreadCount fromJson(Map<String, dynamic> json) =>
      _UnreadCount.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'count': count};
}

final class _InboxPagePayload implements BaseModel<_InboxPagePayload> {
  const _InboxPagePayload({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
  });

  factory _InboxPagePayload.fromJson(Map<String, dynamic> json) {
    final page = json['pageInfo'] as Map<String, dynamic>? ?? const {};
    return _InboxPagePayload(
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          if (item is Map<String, dynamic>) InboxNotification.fromJson(item),
      ],
      nextCursor: page['nextCursor'] as String?,
      hasMore: page['hasMore'] as bool? ?? false,
    );
  }

  final List<InboxNotification> items;
  final String? nextCursor;
  final bool hasMore;

  InboxPage toPage() =>
      InboxPage(items: items, nextCursor: nextCursor, hasMore: hasMore);

  @override
  _InboxPagePayload fromJson(Map<String, dynamic> json) =>
      _InboxPagePayload.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
