import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/no_content.dart';

/// Bildirim kutusu (`/v1/notifications`, backend doküman 04 §16). Başlık ve
/// gövde sunucuda kullanıcının dilinde hazırlanır.
final class NotificationsRepository {
  const NotificationsRepository(this._networkManager);

  final NetworkManager _networkManager;

  /// Yeniden eskiye ilk sayfa.
  Future<List<InboxNotification>> list({int limit = 50}) async {
    final page = await _networkManager.send<_InboxPage>(
      path: '/notifications',
      method: RequestType.get,
      queryParameters: {'limit': limit},
      parserModel: _InboxPage.fromJson,
    );
    return page?.items ?? const [];
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

  Future<void> markRead(String id) => _networkManager.send<NoContent>(
    path: '/notifications/$id/read',
    method: RequestType.post,
    data: const <String, dynamic>{},
    parserModel: NoContent.fromJson,
  );

  Future<void> markAllRead() => _networkManager.send<NoContent>(
    path: '/notifications/read-all',
    method: RequestType.post,
    data: const <String, dynamic>{},
    parserModel: NoContent.fromJson,
  );

  Future<void> remove(String id) => _networkManager.send<NoContent>(
    path: '/notifications/$id',
    method: RequestType.delete,
    parserModel: NoContent.fromJson,
  );
}

final class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  factory InboxNotification.fromJson(Map<String, dynamic> json) =>
      InboxNotification(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['readAt'] as String? ?? '')?.toLocal(),
      );

  final String id;
  final String type;
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

final class _InboxPage implements BaseModel<_InboxPage> {
  const _InboxPage(this.items);

  factory _InboxPage.fromJson(Map<String, dynamic> json) => _InboxPage([
    for (final item in json['items'] as List<dynamic>? ?? const [])
      InboxNotification.fromJson(item as Map<String, dynamic>),
  ]);

  final List<InboxNotification> items;

  @override
  _InboxPage fromJson(Map<String, dynamic> json) => _InboxPage.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
