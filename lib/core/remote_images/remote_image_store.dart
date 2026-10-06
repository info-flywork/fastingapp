import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Uzak görsel paketi: `assets/images` PNG'leri uygulamaya gömülmez; WebP olarak
/// CDN'de durur ve cihaza **bir kez** indirilip saklanır.
///
/// - Hangi görselin nerede olduğu, uygulamaya gömülü küçük bir manifestte
///   yazılıdır (`tool/remote_images.dart` üretir). Dosyalar içerik hash'iyle
///   adlandırılır: aynı görsel bir daha indirilmez, değişen görsel yeni dosya
///   olur (CDN önbelleği temizlemeye gerek yok).
/// - Açılışta arka planda eksik dosyalar indirilir ([syncInBackground]).
///   İndirme bitmeden ekrana gelen görsel o an indirilir ve aynı yere yazılır
///   ([load]); hiçbir dosya iki kez indirilmez.
/// - İndirilen her dosyanın uzunluğu ve SHA-256'sı manifestle doğrulanır;
///   yazma `.part` dosyasına yapılıp atomik olarak yeniden adlandırılır.
final class RemoteImageStore {
  /// Uygulamada [instance] kullanılır; parametreler testler içindir.
  RemoteImageStore({
    AssetBundle? bundle,
    Future<Directory> Function()? cacheDirectory,
  }) : _bundle = bundle ?? rootBundle,
       _cacheDirectory = cacheDirectory ?? getApplicationCacheDirectory;

  /// Uygulama genelindeki örnek. Testler kendi örneğini atayabilir.
  static RemoteImageStore instance = RemoteImageStore();

  static const String manifestAsset = 'assets/remote_images/manifest.json';
  static const String _dirName = 'remote_images';
  static const int _parallelDownloads = 4;
  static const int _maxAttempts = 3;
  static const Duration _timeout = Duration(seconds: 30);

  final AssetBundle _bundle;
  final Future<Directory> Function() _cacheDirectory;
  Future<void>? _initializing;
  late Uri _baseUrl;
  late Directory _dir;
  final Map<String, RemoteImageEntry> _entries = {};
  final Set<String> _present = {};
  final Map<String, Future<Uint8List>> _inflight = {};
  final HttpClient _http = HttpClient()..connectionTimeout = _timeout;
  bool _syncStarted = false;

  /// Manifesti yükler ve cihazdaki dosyaları tarar. Tekrar çağrılması
  /// güvenlidir (ör. ana ekran widget'ı ayrı yoldan çağırabilir).
  Future<void> ensureInitialized() => _initializing ??= _init();

  Future<void> _init() async {
    final raw = await _bundle.loadString(manifestAsset, cache: false);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _baseUrl = Uri.parse(json['baseUrl'] as String);
    final images = json['images'] as Map<String, dynamic>;
    for (final MapEntry(:key, :value) in images.entries) {
      _entries[key] = RemoteImageEntry.fromJson(value as Map<String, dynamic>);
    }

    // iOS: Library/Caches, Android: cacheDir. Yeniden indirilebilir içerik
    // yedeklenmez (Apple Data Storage Guidelines); sistem çok nadiren bu
    // klasörü temizlerse dosyalar yeniden indirilir.
    final base = await _cacheDirectory();
    _dir = Directory('${base.path}/$_dirName');
    await _dir.create(recursive: true);
    await for (final entity in _dir.list()) {
      if (entity is File && entity.path.endsWith('.webp')) {
        _present.add(entity.uri.pathSegments.last);
      }
    }
  }

  /// Manifestteki görselin kaydı; yoksa null (görsel uygulamaya gömülüdür).
  RemoteImageEntry? entryFor(String logicalPath) => _entries[logicalPath];

  /// Görselin baytları: önce cihazdaki dosya, yoksa CDN (ve cihaza yazılır).
  Future<Uint8List> load(String logicalPath) async {
    await ensureInitialized();
    final entry = _entries[logicalPath];
    if (entry == null) {
      final data = await _bundle.load(logicalPath);
      return data.buffer.asUint8List();
    }
    if (entry.bundled != null) {
      final data = await _bundle.load(entry.bundled!);
      return data.buffer.asUint8List();
    }
    final file = _fileFor(entry);
    if (_present.contains(entry.file)) {
      try {
        return await file.readAsBytes();
      } on FileSystemException {
        _present.remove(entry.file);
      }
    }
    return _download(entry);
  }

  /// Eksik görselleri arka planda indirir; eski sürümlerden kalanları siler.
  /// Hata uygulamayı etkilemez: kalanlar bir sonraki açılışta ya da görsel
  /// ekrana geldiğinde indirilir.
  Future<void> syncInBackground() async {
    if (_syncStarted) return;
    _syncStarted = true;
    try {
      await ensureInitialized();
      await _removeStale();
      final missing = {
        for (final e in _entries.values)
          if (e.file != null && !_present.contains(e.file)) e.file!: e,
      }.values.toList();
      if (missing.isEmpty) return;

      var next = 0;
      Future<void> worker() async {
        while (next < missing.length) {
          final entry = missing[next++];
          try {
            await _download(entry);
          } on Object catch (error) {
            debugPrint('RemoteImageStore: ${entry.file} indirilemedi: $error');
          }
        }
      }

      await Future.wait([
        for (var i = 0; i < _parallelDownloads; i++) worker(),
      ]);
    } on Object catch (error) {
      debugPrint('RemoteImageStore: senkron başarısız: $error');
    } finally {
      _syncStarted = false;
    }
  }

  /// Aynı dosya için eşzamanlı istekler tek indirmeye bağlanır.
  Future<Uint8List> _download(RemoteImageEntry entry) {
    final name = entry.file!;
    return _inflight.putIfAbsent(
      name,
      // Gövdeli kapanış: `=> _inflight.remove(name)` bu Future'ın kendisini
      // döndürür ve whenComplete onu bekleyip kilitlenirdi.
      () => _fetchWithRetry(entry).whenComplete(() {
        _inflight.remove(name);
      }),
    );
  }

  Future<Uint8List> _fetchWithRetry(RemoteImageEntry entry) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _fetch(entry);
      } on Object catch (error) {
        lastError = error;
        if (attempt < _maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    throw RemoteImageException('${entry.file}: $lastError');
  }

  Future<Uint8List> _fetch(RemoteImageEntry entry) async {
    final request = await _http.getUrl(_baseUrl.resolve(entry.file!));
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw RemoteImageException('HTTP ${response.statusCode}');
    }
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add).timeout(_timeout);
    final bytes = builder.takeBytes();
    if (bytes.length != entry.bytes ||
        sha256.convert(bytes).toString() != entry.sha256) {
      throw const RemoteImageException('bütünlük kontrolü başarısız');
    }

    final file = _fileFor(entry);
    final part = File('${file.path}.part');
    await part.writeAsBytes(bytes, flush: true);
    await part.rename(file.path);
    _present.add(entry.file!);
    return bytes;
  }

  Future<void> _removeStale() async {
    final wanted = {for (final e in _entries.values) ?e.file};
    await for (final entity in _dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!wanted.contains(name)) {
        _present.remove(name);
        await entity.delete().catchError((Object _) => entity);
      }
    }
  }

  File _fileFor(RemoteImageEntry entry) => File('${_dir.path}/${entry.file}');

  /// Kaynakları bırakır (testler).
  @visibleForTesting
  void close() => _http.close(force: true);
}

/// Manifestteki tek görsel: ya CDN'deki dosya ya da gömülü varlık yolu.
@immutable
final class RemoteImageEntry {
  const RemoteImageEntry({
    this.file,
    this.bytes = 0,
    this.sha256 = '',
    this.bundled,
  });

  factory RemoteImageEntry.fromJson(Map<String, dynamic> json) =>
      RemoteImageEntry(
        file: json['file'] as String?,
        bytes: (json['bytes'] as num?)?.toInt() ?? 0,
        sha256: json['sha256'] as String? ?? '',
        bundled: json['bundled'] as String?,
      );

  /// CDN'deki dosya adı (`<hash>.webp`).
  final String? file;
  final int bytes;
  final String sha256;

  /// İnternetsiz de gereken görseller (ör. açılış ekranı) uygulamaya gömülür.
  final String? bundled;
}

final class RemoteImageException implements Exception {
  const RemoteImageException(this.message);

  final String message;

  @override
  String toString() => 'RemoteImageException: $message';
}
