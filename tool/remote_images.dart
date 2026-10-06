// Geliştirici aracı; çıktıyı konsola yazar.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Uzak görsel paketi üreticisi (uygulama tarafı: lib/core/remote_images/).
///
///   dart run tool/remote_images.dart            dönüştür + manifest + sabitler
///   dart run tool/remote_images.dart --upload   + eksik dosyaları CDN'e yükle
///
/// Kaynak PNG'ler `asset_sources/images/` altındadır ve uygulamaya GÖMÜLMEZ.
/// Kodda kullanılan (AppImages.x ya da 'assets/images/x.png' olarak geçen)
/// her görsel WebP'ye çevrilir, içerik hash'iyle adlandırılır ve manifeste
/// yazılır. `bundled` listesindekiler (internetsiz gereken, ör. açılış ekranı)
/// WebP olarak uygulamaya gömülür. Yükleme için BUNNY_STORAGE_PASSWORD gerekir.
Future<void> main(List<String> args) async {
  final config =
      jsonDecode(File('tool/remote_images.json').readAsStringSync())
          as Map<String, dynamic>;
  final tool = _RemoteImagesTool(config);
  await tool.run(upload: args.contains('--upload'));
}

final class _Source {
  _Source(this.file, this.logicalPath, this.constName);

  final File file;
  final String logicalPath;
  final String constName;
}

final class _Output {
  _Output(this.source, this.bytes);

  final _Source source;
  final List<int> bytes;
  late final String sha = sha256.convert(bytes).toString();
  String get fileName => '${sha.substring(0, 20)}.webp';
}

final class _RemoteImagesTool {
  _RemoteImagesTool(this.config);

  final Map<String, dynamic> config;
  late final String prefix = config['logicalPrefix'] as String;
  late final Set<String> bundledNames = {
    ...(config['bundled'] as List).cast<String>(),
  };
  final Directory cacheDir = Directory('.dart_tool/remote_images');
  final Directory outDir = Directory('build/remote_images');

  Future<void> run({required bool upload}) async {
    final sources = _collectSources();
    _writeConstants(sources);

    final referenced = _referenced(sources);
    final unused = sources.where((s) => !referenced.contains(s)).toList();

    await cacheDir.create(recursive: true);
    await outDir.create(recursive: true);
    final bundledDir = Directory(config['bundledOutputDir'] as String);
    if (bundledDir.existsSync()) bundledDir.deleteSync(recursive: true);
    bundledDir.createSync(recursive: true);

    final images = <String, Map<String, Object>>{};
    var sourceBytes = 0;
    var remoteBytes = 0;
    var bundledBytes = 0;
    final remote = <_Output>[];
    for (final source in referenced) {
      sourceBytes += source.file.lengthSync();
      final out = _Output(source, await _toWebp(source.file));
      final name = source.file.uri.pathSegments.last;
      if (bundledNames.contains(name)) {
        final path = '${bundledDir.path}/${_slug(source.constName)}.webp';
        File(path).writeAsBytesSync(out.bytes);
        images[source.logicalPath] = {'bundled': path};
        bundledBytes += out.bytes.length;
      } else {
        File('${outDir.path}/${out.fileName}').writeAsBytesSync(out.bytes);
        images[source.logicalPath] = {
          'file': out.fileName,
          'bytes': out.bytes.length,
          'sha256': out.sha,
        };
        remote.add(out);
        remoteBytes += out.bytes.length;
      }
    }

    final manifest = File(config['manifest'] as String)
      ..parent.createSync(recursive: true);
    final sortedImages = {
      for (final key in images.keys.toList()..sort()) key: images[key],
    };
    final manifestJson = {
      'version': 1,
      'baseUrl': config['cdnBaseUrl'],
      'images': sortedImages,
    };
    const encoder = JsonEncoder.withIndent('  ');
    manifest.writeAsStringSync('${encoder.convert(manifestJson)}\n');

    print('Kaynak PNG: ${sources.length} · kullanılan: ${referenced.length}');
    print('  PNG toplamı (kullanılan): ${_mb(sourceBytes)}');
    print('  CDN (WebP): ${remote.length} dosya, ${_mb(remoteBytes)}');
    print('  Gömülü (WebP): ${_mb(bundledBytes)}');
    print('  Manifest: ${manifest.path} (${_kb(manifest.lengthSync())})');
    if (unused.isNotEmpty) {
      print('Kodda kullanılmayan ${unused.length} PNG pakete alınmadı:');
      for (final s in unused) {
        print('  - ${s.file.uri.pathSegments.last}');
      }
    }

    if (upload) await _upload(remote);
  }

  List<_Source> _collectSources() {
    final dir = Directory(config['sourceDir'] as String);
    final files =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.png'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final used = <String>{};
    return [
      for (final f in files)
        _Source(
          f,
          '$prefix${f.path.substring(dir.path.length + 1)}',
          _uniqueName(_constName(f.uri.pathSegments.last), used),
        ),
    ];
  }

  /// flutter_gen ile aynı adlandırma: dosya adı → lowerCamelCase.
  String _constName(String fileName) {
    final stem = fileName.replaceAll(
      RegExp(r'\.png$', caseSensitive: false),
      '',
    );
    final spaced = stem.replaceAllMapped(
      RegExp('([a-z0-9])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    final words = spaced
        .split(RegExp('[^A-Za-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'image';
    var name =
        words.first.toLowerCase() +
        words
            .skip(1)
            .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join();
    if (RegExp('^[0-9]').hasMatch(name) ||
        !RegExp('^[A-Za-z]').hasMatch(stem)) {
      name = 'a${name[0].toUpperCase()}${name.substring(1)}';
    }
    if (_reserved.contains(name)) name = '${name}Image';
    return name;
  }

  String _uniqueName(String name, Set<String> used) {
    var candidate = name;
    for (var i = 2; !used.add(candidate); i++) {
      candidate = '$name$i';
    }
    return candidate;
  }

  String _slug(String constName) => constName.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );

  /// Kodda `AppImages.<ad>` ya da mantıksal yol olarak geçenler + gömülüler.
  /// Üretilmiş kod (lib/generated, *.g.dart) kullanım sayılmaz.
  List<_Source> _referenced(List<_Source> sources) {
    final code = StringBuffer();
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is File &&
          f.path.endsWith('.dart') &&
          !f.path.startsWith('lib/generated/') &&
          !f.path.endsWith('.g.dart')) {
        code.write(f.readAsStringSync());
      }
    }
    final text = code.toString();
    return [
      for (final s in sources)
        if (bundledNames.contains(s.file.uri.pathSegments.last) ||
            text.contains("'${s.logicalPath}'") ||
            RegExp('AppImages\\.${s.constName}\\b').hasMatch(text))
          s,
    ];
  }

  /// cwebp ile dönüştürür; sonuç kaynak hash'ine göre önbelleklenir.
  /// Küçük görsellerde kayıpsız deneme de yapılır, küçük olan seçilir.
  Future<List<int>> _toWebp(File png) async {
    final quality = config['quality'] as int;
    final srcHash = sha256.convert(png.readAsBytesSync()).toString();
    final cached = File('${cacheDir.path}/$srcHash-q$quality.webp');
    if (cached.existsSync()) return cached.readAsBytesSync();

    final lossy = File('${cached.path}.lossy');
    await _cwebp([
      '-q', '$quality', '-alpha_q', '90', '-m', '6', '-sharp_yuv', //
      png.path, '-o', lossy.path,
    ]);
    var best = lossy;
    if (png.lengthSync() < 64 * 1024) {
      final lossless = File('${cached.path}.lossless');
      await _cwebp(['-lossless', '-z', '9', png.path, '-o', lossless.path]);
      if (lossless.lengthSync() < lossy.lengthSync()) best = lossless;
    }
    best.renameSync(cached.path);
    for (final f in [
      File('${cached.path}.lossy'),
      File('${cached.path}.lossless'),
    ]) {
      if (f.existsSync()) f.deleteSync();
    }
    return cached.readAsBytesSync();
  }

  Future<void> _cwebp(List<String> args) async {
    final result = await Process.run('cwebp', ['-quiet', '-mt', ...args]);
    if (result.exitCode != 0) {
      throw ProcessException(
        'cwebp',
        args,
        '${result.stderr}',
        result.exitCode,
      );
    }
  }

  void _writeConstants(List<_Source> sources) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// dart run tool/remote_images.dart')
      ..writeln()
      ..writeln('// ignore_for_file: lines_longer_than_80_chars')
      ..writeln()
      ..writeln(
        "import 'package:fastingapp/core/remote_images/app_image.dart';",
      )
      ..writeln()
      ..writeln(
        "/// `assets/images` görselleri: CDN'den indirilir ya da "
        'uygulamaya gömülüdür.',
      )
      ..writeln(
        '/// Kullanım flutter_gen ile aynı: `.path`, `.image()`, '
        '`.provider()`.',
      )
      ..writeln('abstract final class AppImages {');
    for (final s in sources) {
      buffer.writeln(
        '  static const AppImageAsset ${s.constName} = '
        "AppImageAsset('${s.logicalPath}');",
      );
    }
    buffer.writeln('}');
    File(
      config['generatedDart'] as String,
    ).writeAsStringSync(buffer.toString());
  }

  Future<void> _upload(List<_Output> outputs) async {
    final key = Platform.environment['BUNNY_STORAGE_PASSWORD'];
    if (key == null || key.isEmpty) {
      stderr.writeln('BUNNY_STORAGE_PASSWORD tanımlı değil; yükleme atlandı.');
      exitCode = 1;
      return;
    }
    final base =
        'https://${config['storageHost']}/${config['storageZone']}/${config['remoteDir']}/';
    final client = HttpClient();
    try {
      final existing = await _listRemote(client, base, key);
      final pending = outputs
          .where((o) => !existing.contains(o.fileName))
          .toSet();
      print(
        'CDN: ${existing.length} dosya mevcut, ${pending.length} yüklenecek',
      );
      final queue = pending.toList();
      var next = 0;
      var done = 0;
      Future<void> worker() async {
        while (next < queue.length) {
          final out = queue[next++];
          final req = await client.putUrl(Uri.parse('$base${out.fileName}'))
            ..headers.set('AccessKey', key)
            ..headers.contentType = ContentType('image', 'webp')
            ..headers.set('Checksum', out.sha.toUpperCase())
            ..add(out.bytes);
          final res = await req.close();
          await res.drain<void>();
          if (res.statusCode != 201) {
            throw HttpException('${out.fileName}: HTTP ${res.statusCode}');
          }
          done++;
        }
      }

      await Future.wait([for (var i = 0; i < 6; i++) worker()]);
      print('CDN: $done dosya yüklendi');
    } finally {
      client.close();
    }
  }

  Future<Set<String>> _listRemote(
    HttpClient client,
    String base,
    String key,
  ) async {
    final req = await client.getUrl(Uri.parse(base))
      ..headers.set('AccessKey', key)
      ..headers.set('accept', 'application/json');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode == 404) return {};
    if (res.statusCode != 200) {
      throw HttpException('liste: HTTP ${res.statusCode}');
    }
    final list = jsonDecode(body) as List;
    return {
      for (final item in list.cast<Map<String, dynamic>>())
        if (item['IsDirectory'] != true) item['ObjectName'] as String,
    };
  }

  static String _mb(int bytes) => '${(bytes / 1e6).toStringAsFixed(1)} MB';
  static String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(0)} KB';

  static const _reserved = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', //
    'class', 'const', 'continue', 'default', 'do', 'else', 'enum', 'export',
    'extends', 'false', 'final', 'finally', 'for', 'if', 'import', 'in', 'is',
    'new', 'null', 'return', 'super', 'switch', 'this', 'throw', 'true', 'try',
    'var', 'void', 'while', 'with', 'yield',
  };
}
