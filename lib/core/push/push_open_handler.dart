import 'dart:async';
import 'dart:io';

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/app_router.dart';
import 'package:fastingapp/core/router/deep_link_gate.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/domain/notification/notifications_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Push bildirimine dokununca: bildirim okundu işaretlenir, `deepLink`
/// (`fastingapp://water` → `/water`) ekranı açılır (backend push verisi:
/// `{type, deepLink, notificationId}`).
final class PushOpenHandler {
  const PushOpenHandler._();

  /// Sekme ekranları değiştirilir (go); diğerleri üstüne açılır (push).
  static final _tabs = {
    RoutePaths.home.path,
    RoutePaths.fasting.path,
    RoutePaths.profile.path,
    RoutePaths.mochiWorld.path,
    RoutePaths.plans.path,
  };

  static final _known = {for (final r in RoutePaths.values) r.path};

  static void start() {
    // Ön planda gelen bildirim: iOS sistem afişini gösterir; Android göstermez,
    // uygulama içi şerit gösterilir.
    unawaited(
      FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          )
          .catchError((Object _) {}),
    );
    if (Platform.isAndroid) FirebaseMessaging.onMessage.listen(_showInApp);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(_open(message)),
    );
    unawaited(
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((message) async {
            if (message != null) await _open(message);
          })
          .catchError((Object _) {}),
    );
  }

  static Future<void> _open(RemoteMessage message) async {
    final data = message.data;
    final id = data['notificationId'];
    if (id is String && id.isNotEmpty) {
      unawaited(
        getIt<NotificationsRepository>().markRead(id).catchError((Object _) {}),
      );
    }
    final path = _pathOf(data['deepLink']);
    if (path == null) return;
    // Soğuk açılışta splash bitsin; onboarding'i bitmemiş / oturumsuz
    // kullanıcıda açılmaz.
    if (!await DeepLinkGate.ready()) return;
    _navigate(path);
  }

  static void _navigate(String path) {
    if (_tabs.contains(path)) {
      appRouter.go(path);
    } else {
      unawaited(appRouter.push(path));
    }
  }

  /// Bildirim kutusundan: kaydın derin bağlantısını aç; bilinmiyorsa false.
  static bool openDeepLink(String? deepLink) {
    final path = _pathOf(deepLink);
    if (path == null) return false;
    _navigate(path);
    return true;
  }

  static void _showInApp(RemoteMessage message) {
    unawaited(getIt<NotificationsRepository>().refreshUnread());
    final context = rootNavigatorKey.currentContext;
    final notification = message.notification;
    if (context == null || notification == null) return;
    final text = [
      notification.title,
      notification.body,
    ].whereType<String>().where((t) => t.isNotEmpty).join('\n');
    if (text.isEmpty) return;
    AppSnackbar.show(context: context, text: text, type: SnackBarType.info);
  }

  /// `fastingapp://body-history` → `/body-history` (bilinen rotalar dışında null).
  static String? _pathOf(Object? deepLink) {
    if (deepLink is! String) return null;
    final uri = Uri.tryParse(deepLink);
    if (uri == null || uri.host.isEmpty) return null;
    final path = '/${uri.host}${uri.path}';
    return _known.contains(path) ? path : null;
  }
}
