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
/// - Açılışta kısa süre çevrimiçi varsayılır: soğuk açılışta `none` blip'i
///   veya ilk CDN probe gecikmesi splash sonrası flash yapmasın.
final class ConnectivityService {
  /// Uygulamada [instance] kullanılır; parametreler testler içindir.
  ConnectivityService({
    this._changes,
    Future<bool> Function()? probe,
    this._retryInterval = const Duration(seconds: 5),
    this._offlineDebounce = const Duration(milliseconds: 750),
    this._startupGrace = const Duration(seconds: 2),
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
  final Duration _startupGrace;

  /// Açılışta "çevrimiçi" varsayılır: kontrol bitmeden sayfa yanıp sönmez.
  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  final ValueNotifier<bool> isChecking = ValueNotifier(false);
  final ValueNotifier<int> reconnects = ValueNotifier(0);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  Timer? _offlineDebounceTimer;
  Timer? _graceTimer;
  Future<bool>? _pending;
  bool _graceElapsed = false;

  void start() {
    if (_subscription != null) return;
    if (_startupGrace <= Duration.zero) {
      _graceElapsed = true;
    } else {
      _graceTimer = Timer(_startupGrace, () {
        _graceElapsed = true;
        // Grace sırasında ertelenen çevrimdışı durum varsa doğrula.
        unawaited(checkNow());
      });
    }
    _subscription = (_changes ?? Connectivity().onConnectivityChanged).listen((
      results,
    ) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        // Anlık none blip'leri debounce ile yutulur; kalıcıysa sayfa açılır.
        // Açılış probe'u sürerken offline uygulanmaz (_set içinde).
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
        _set(online: online, fromProbe: true);
        return online;
      } finally {
        isChecking.value = false;
        _pending = null;
      }
    }();
  }

  void _set({required bool online, bool fromProbe = false}) {
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
    // iOS soğuk açılış: `none` olayı sıkça ilk probe bitmeden gelir. Probe
    // sürerken arayüz durumuna güvenip offline flash'ı gösterme; probe karar
    // versin.
    if (!fromProbe && _pending != null) return;

    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = Timer(_offlineDebounce, () {
      _offlineDebounceTimer = null;
      _apply(online: false);
    });
  }

  void _apply({required bool online}) {
    // Splash / ilk saniyeler: gerçekten offline olsa bile UI'yi ertele.
    if (!online && !_graceElapsed) return;

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
    _graceTimer?.cancel();
    await _subscription?.cancel();
  }
}
