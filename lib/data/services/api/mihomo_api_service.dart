import 'package:dio/dio.dart';

import '../../../core/constants.dart';

class MihomoApiService {
  final Dio _dio;
  final String baseUrl;

  MihomoApiService({
    String host = kApiHost,
    int port = kApiPort,
    String? secret,
  }) : baseUrl = 'http://$host:$port',
       _dio = Dio() {
    if (secret != null && secret.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $secret';
    }
  }

  Future<void> reloadConfig(String path) async {
    await _dio.put(
      '$baseUrl/configs',
      queryParameters: {'force': 'true'},
      data: {'path': path},
    );
  }

  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get('$baseUrl/configs');
    return response.data;
  }
}
