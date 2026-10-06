import 'dart:ui' as ui;

import 'package:fastingapp/core/connectivity/connectivity_service.dart';
import 'package:fastingapp/core/remote_images/remote_image_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// `assets/images/...` yolundaki görseli, nerede durduğundan bağımsız yükler:
/// cihazdaki indirilmiş dosya → CDN (indirip saklar) → gömülü varlık.
/// Anahtar mantıksal yoldur; ImageCache ve `precacheImage` aynen çalışır.
@immutable
final class AppImageProvider extends ImageProvider<AppImageProvider> {
  const AppImageProvider(this.path, {this.scale = 1.0});

  /// Mantıksal yol, ör. `assets/images/mochi-worlds.png`.
  final String path;
  final double scale;

  @override
  Future<AppImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<AppImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    AppImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: key.scale,
      debugLabel: key.path,
      informationCollector: () => [DiagnosticsProperty('Görsel', key.path)],
    );
  }

  static Future<ui.Codec> _loadCodec(
    AppImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await RemoteImageStore.instance.load(key.path);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is AppImageProvider && other.path == path && other.scale == scale;

  @override
  int get hashCode => Object.hash(path, scale);

  @override
  String toString() => 'AppImageProvider("$path", scale: $scale)';
}

/// `AssetImage(path)` yerine.
ImageProvider appImageProvider(String path) => AppImageProvider(path);

/// `Image.asset(path, ...)` yerine; aynı parametreler.
///
/// İnternet yokken inmemiş görsel boş kalır; bağlantı gelince
/// ([ConnectivityService.reconnects]) yeniden yüklenir.
Widget appImage(
  String path, {
  Key? key,
  double? width,
  double? height,
  BoxFit? fit,
  AlignmentGeometry alignment = Alignment.center,
  Color? color,
  Animation<double>? opacity,
  BlendMode? colorBlendMode,
  ImageRepeat repeat = ImageRepeat.noRepeat,
  bool gaplessPlayback = false,
  bool isAntiAlias = false,
  FilterQuality filterQuality = FilterQuality.medium,
  int? cacheWidth,
  int? cacheHeight,
  ImageFrameBuilder? frameBuilder,
  ImageErrorWidgetBuilder? errorBuilder,
  String? semanticLabel,
  bool excludeFromSemantics = false,
}) {
  return ValueListenableBuilder<int>(
    key: key,
    valueListenable: ConnectivityService.instance.reconnects,
    // Yeni anahtar → Image yeniden çözer: başarılı olanlar önbellekten gelir,
    // hata verenler (ImageCache'te tutulmaz) yeniden indirilir.
    builder: (context, generation, _) => Image(
      key: ValueKey(generation),
      image: ResizeImage.resizeIfNeeded(
        cacheWidth,
        cacheHeight,
        AppImageProvider(path),
      ),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      repeat: repeat,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
      frameBuilder: frameBuilder,
      // İnternet yoksa ve görsel henüz inmediyse boş alan (hata kutusu değil).
      errorBuilder:
          errorBuilder ??
          (context, error, stackTrace) =>
              SizedBox(width: width, height: height),
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    ),
  );
}

/// Üretilen `AppImages` sabitlerinin tipi (`lib/generated/app_images.g.dart`).
/// flutter_gen'deki `AssetGenImage` ile aynı kullanım: `.path`, `.image()`,
/// `.provider()`.
@immutable
final class AppImageAsset {
  const AppImageAsset(this.path);

  final String path;

  String get keyName => path;

  ImageProvider provider() => AppImageProvider(path);

  Widget image({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    // flutter_gen varsayılanıyla aynı.
    bool gaplessPlayback = true,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
  }) {
    return appImage(
      path,
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      repeat: repeat,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}
