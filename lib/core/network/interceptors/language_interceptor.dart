import 'dart:ui';

import 'package:dio/dio.dart';

/// Her isteğe aktif dile göre `Accept-Language` header'ı ekler.
final class LanguageInterceptor extends Interceptor {
  LanguageInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['Accept-Language'] =
        PlatformDispatcher.instance.locale.languageCode;
    handler.next(options);
  }
}
