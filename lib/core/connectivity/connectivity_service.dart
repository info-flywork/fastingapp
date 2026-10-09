import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// İnternet erişimi. Ağ arayüzü (Wi‑Fi/mobil) açık olsa da gerçek erişim
/// CDN'e küçük bir istekle doğrulanır (otel/kafe giriş sayfası, kopuk modem).
///
/// - [isOnline] false → internet yok sayfası gösterilir (OfflineGate).
/// - Çevrimdışıyken birkaç saniyede bir yeniden denenir; ağ değişikliği
///   olayı kaçsa da bağlantı gelince sayfa kendiliğinden kapanır.
/// - [reconnects] her yeniden bağlanmada artar: boş kalmış görseller bunu
///   dinleyip yeniden yüklenir.
/// - Offline'a geçiş kısa gecikmeyle uygulanır: iOS'ta anlık `none` olayı
///   veya tek seferlik probe hatası sayfayı yanıp söndürmesin.
final class ConnectivityService {
  /// Uygulamada [instance] kullanılır; parametreler testler içindir.
  ConnectivityService({
    this._changes,
    Future<bool> Function()? probe,
    this._retryInterval = const Duration(seconds: 5),
    this._offlineDebounce = const Duration(milliseconds: 750),
  }) : _probe = probe ?? _probeCdn;

  static ConnectivityService instance = ConnectivityService();

  /// Ulaşılabilirlik kontrolünün yapıldığı adres (CDN; her HTTP yanıtı yeter).
  static final Uri probeUrl = Uri.parse('https://mochifast.b-cdn.net/');
  static const Duration _probeTimeout = Duration(seconds: 4);

  /// Yalnızca geliştirmede: `--dart-define=MOCHI_FORCE_OFFLINE=true` ile
  /// internet yok sayfası tasarım/test için zorla gösterilir.
  static const bool _forceOffline =
      kDebugMode && bool.fromEnvironment('MOCHI_FORCE_OFFLINE');

  final Stream<List<ConnectivityResult>>? _changes;
  final Future<bool> Function() _probe;
  final Duration _retryInterval;
  final Duration _offlineDebounce;

  /// Açılışta "çevrimiçi" varsayılır: kontrol bitmeden sayfa yanıp sönmez.
  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  final ValueNotifier<bool> isChecking = ValueNotifier(false);
  final ValueNotifier<int> reconnects = ValueNotifier(0);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  Timer? _offlineDebounceTimer;
  Future<bool>? _pending;

  void start() {
    if (_subscription != null) return;
    _subscription = (_changes ?? Connectivity().onConnectivityChanged).listen((
      results,
    ) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        // Anlık none blip'leri debounce ile yutulur; kalıcıysa sayfa açılır.
        _set(online: false);
      } else {
        unawaited(checkNow());
      }
    });
    unawaited(checkNow());
  }

  /// Hemen kontrol eder (ör. "Tekrar dene"). Eşzamanlı çağrılar birleşir.
  Future<bool> checkNow() {
    return _pending ??= () async {
      isChecking.value = true;
      try {
        final online = !_forceOffline && await _probe();
        _set(online: online);
        return online;
      } finally {
        isChecking.value = false;
        _pending = null;
      }
    }();
  }

  void _set({required bool online}) {
    if (online) {
      _offlineDebounceTimer?.cancel();
      _offlineDebounceTimer = null;
      _apply(online: true);
      return;
    }
    // Zaten çevrimdışıysa debounce yok; yeniden deneme zamanlayıcısı sürsün.
    if (!isOnline.value) {
      _retryTimer ??= Timer.periodic(
        _retryInterval,
        (_) => unawaited(checkNow()),
      );
      return;
    }
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = Timer(_offlineDebounce, () {
      _offlineDebounceTimer = null;
      _apply(online: false);
    });
  }

  void _apply({required bool online}) {
    final wasOnline = isOnline.value;
    if (wasOnline == online) return;
    isOnline.value = online;
    if (online) {
      _retryTimer?.cancel();
      _retryTimer = null;
      if (!wasOnline) reconnects.value++;
    } else {
      _retryTimer ??= Timer.periodic(
        _retryInterval,
        (_) => unawaited(checkNow()),
      );
    }
  }

  static Future<bool> _probeCdn() async {
    final client = HttpClient()..connectionTimeout = _probeTimeout;
    try {
      final request = await client.headUrl(probeUrl);
      final response = await request.close().timeout(_probeTimeout);
      await response.drain<void>();
      return true;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  @visibleForTesting
  Future<void> dispose() async {
    _retryTimer?.cancel();
    _offlineDebounceTimer?.cancel();
    await _subscription?.cancel();
  }
}
