import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import 'pexels_models.dart';

class PexelsClient {
  PexelsClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.pexels.com',
      headers: {
        'Authorization': AppConfig.pexelsApiKey,
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  late final Dio _dio;

  bool get hasApiKey => AppConfig.pexelsApiKey.isNotEmpty;

  Future<PexelsSearchResponse> search({
    required String query,
    String orientation = 'portrait',
    int perPage = 30,
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    if (!hasApiKey) {
      throw PexelsException('PEXELS_API_KEY não configurada.');
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/search',
        queryParameters: {
          'query': query.isEmpty ? 'abstract' : query,
          'orientation': orientation,
          'per_page': perPage.clamp(1, 80),
          'page': page,
        },
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      if (data == null) return const PexelsSearchResponse();
      return PexelsSearchResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) throw PexelsCancelException();
      final status = e.response?.statusCode;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString()
          : null;
      throw PexelsException(
          msg ?? 'Erro Pexels: ${e.message} (${status ?? "?"})');
    }
  }
}

class PexelsException implements Exception {
  PexelsException(this.message);
  final String message;
  @override
  String toString() => 'PexelsException: $message';
}

class PexelsCancelException implements Exception {}
