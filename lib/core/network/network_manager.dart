import 'package:dio/dio.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/base/model/base_response.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// Generic HTTP katmanı. Dio isteğini atar, [BaseResponse] ile parse eder ve
/// `data` alanını döndürür. (Doküman 10)
final class NetworkManager {
  const NetworkManager(this._dio);

  final Dio _dio;

  Future<T?> send<T extends BaseModel<T>>({
    required String path,
    required RequestType method,
    required T Function(Map<String, dynamic> json) parserModel,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      // Global Content-Type: application/json iken gövdesiz POST/PATCH/PUT/DELETE
      // Fastify'da "İstek gövdesi okunamadı" (empty JSON body) üretir.
      final requestBody =
          data ??
          (method == RequestType.get ? null : const <String, dynamic>{});
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: requestBody,
        queryParameters: queryParameters,
        options: Options(method: method.value, headers: headers),
      );

      final responseBody = response.data;
      if (responseBody == null) return null;

      final parsed = BaseResponse<T>.fromJson(responseBody, parserModel);
      return parsed.data;
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }
}
