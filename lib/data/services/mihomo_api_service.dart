import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/connection.dart';
import '../models/log_entry.dart';
import '../models/proxy.dart';
import '../models/traffic.dart';

class MihomoApiService {
  final Dio _dio;
  final String baseUrl;

  MihomoApiService({
    required String host,
    required int port,
    String? secret,
  })  : baseUrl = 'http://$host:$port',
        _dio = Dio() {
    if (secret != null && secret.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $secret';
    }
  }

  Future<Map<String, Proxy>> getProxies() async {
    final response = await _dio.get('$baseUrl/proxies');
    final proxies = <String, Proxy>{};
    final data = response.data['proxies'] as Map<String, dynamic>;
    for (final entry in data.entries) {
      proxies[entry.key] = Proxy.fromJson({
        'name': entry.key,
        ...entry.value as Map<String, dynamic>,
      });
    }
    return proxies;
  }

  Future<void> selectProxy(String group, String name) async {
    await _dio.put('$baseUrl/proxies/$group', data: {'name': name});
  }

  Future<int> delayProxy(String name, {int timeout = 5000}) async {
    final response = await _dio.get(
      '$baseUrl/proxies/$name/delay',
      queryParameters: {
        'timeout': timeout,
        'url': 'http://www.gstatic.com/generate_204',
      },
    );
    return response.data['delay'] as int;
  }

  Future<List<Connection>> getConnections() async {
    final response = await _dio.get('$baseUrl/connections');
    final list = response.data['connections'] as List;
    return list.map((e) => Connection.fromJson(e)).toList();
  }

  Future<void> closeConnection(String id) async {
    await _dio.delete('$baseUrl/connections/$id');
  }

  Future<void> closeAllConnections() async {
    await _dio.delete('$baseUrl/connections');
  }

  Stream<Traffic> trafficStream() async* {
    try {
      final response = await _dio.get<ResponseBody>(
        '$baseUrl/traffic',
        options: Options(responseType: ResponseType.stream),
      );
      await for (final chunk in response.data!.stream) {
        final lines = utf8.decode(chunk).trim().split('\n');
        for (final line in lines) {
          if (line.isNotEmpty) {
            yield Traffic.fromJson(jsonDecode(line));
          }
        }
      }
    } catch (_) {
      // Connection closed, stream ends gracefully
    }
  }

  Stream<LogEntry> logsStream({String level = 'info'}) async* {
    try {
      final response = await _dio.get<ResponseBody>(
        '$baseUrl/logs',
        queryParameters: {'level': level},
        options: Options(responseType: ResponseType.stream),
      );
      await for (final chunk in response.data!.stream) {
        final lines = utf8.decode(chunk).trim().split('\n');
        for (final line in lines) {
          if (line.isNotEmpty) {
            yield LogEntry.fromJson(jsonDecode(line));
          }
        }
      }
    } catch (_) {
      // Connection closed, stream ends gracefully
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
