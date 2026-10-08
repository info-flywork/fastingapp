import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM push token'ı (backend doküman 10 §1, 13 §7). Token `PUT /devices/current`
/// ile gönderilir ([AuthRepository.registerDevice]); izin reddedildiyse
/// `pushEnabled: false` gider, inbox yine çalışır.
final class PushService {
  PushService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _refresh;

  /// İzin ister (iOS'ta sistem penceresi; daha önce yanıtlandıysa sormaz).
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return _allowed(settings.authorizationStatus);
  }

  /// İzin varsa güncel token, yoksa null. Simülatör/APNs hazır değilse null.
  Future<({String? token, bool enabled})> currentToken() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      final enabled = _allowed(settings.authorizationStatus);
      if (!enabled) return (token: null, enabled: false);
      // iOS'ta FCM token'ı APNs token'ı gelmeden alınamaz.
      if (Platform.isIOS && await _messaging.getAPNSToken() == null) {
        return (token: null, enabled: true);
      }
      return (token: await _messaging.getToken(), enabled: true);
    } on Object {
      return (token: null, enabled: false);
    }
  }

  /// Token yenilenince [onRefresh] (cihaz kaydını tekrarlar). Bir kez bağlanır.
  void listenTokenRefresh(void Function() onRefresh) {
    _refresh ??= _messaging.onTokenRefresh.listen((_) => onRefresh());
  }

  static bool _allowed(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}
