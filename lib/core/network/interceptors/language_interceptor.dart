import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';

/// Her isteğe uygulamada seçili dile göre `Accept-Language` header'ı ekler
/// (cihaz dili değil; kullanıcı uygulama içinden değiştirebilir).
final class LanguageInterceptor extends Interceptor {
  LanguageInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] =
        LocalizationManager.current.languageCode;
    handler.next(options);
  }
}
