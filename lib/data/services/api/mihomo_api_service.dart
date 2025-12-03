import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants.dart';
import '../../models/connection.dart';
import '../../models/log_entry.dart';
import '../../models/proxy.dart';
import '../../models/traffic.dart';

class MihomoApiService {
  final Dio _dio;
  final String baseUrl;

  MihomoApiService({
    String host = kApiHost,
    int port = kApiPort,
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

  Future<int> delayProxy(String name, {int timeout = kDelayTimeout}) async {
    final response = await _dio.get(
      '$baseUrl/proxies/$name/delay',
      queryParameters: {'timeout': timeout, 'url': kDelayTestUrl},
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
    final buffer = StringBuffer();
    try {
      final response = await _dio.get<ResponseBody>(
        '$baseUrl/traffic',
        options: Options(responseType: ResponseType.stream),
      );
      await for (final chunk in response.data!.stream) {
        buffer.write(utf8.decode(chunk));
        final content = buffer.toString();
        final lines = content.split('\n');
        buffer.clear();
        if (!content.endsWith('\n') && lines.isNotEmpty) {
          buffer.write(lines.removeLast());
        }
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            try {
              yield Traffic.fromJson(jsonDecode(line));
            } catch (e) {
              log('Traffic parse error: $e', name: 'MihomoApi');
            }
          }
        }
      }
    } catch (e) {
      log('Traffic stream error: $e', name: 'MihomoApi');
    }
  }

  Stream<LogEntry> logsStream({String level = 'info'}) async* {
    final buffer = StringBuffer();
    try {
      final response = await _dio.get<ResponseBody>(
        '$baseUrl/logs',
        queryParameters: {'level': level},
        options: Options(responseType: ResponseType.stream),
      );
      await for (final chunk in response.data!.stream) {
        buffer.write(utf8.decode(chunk));
        final content = buffer.toString();
        final lines = content.split('\n');
        buffer.clear();
        if (!content.endsWith('\n') && lines.isNotEmpty) {
          buffer.write(lines.removeLast());
        }
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            try {
              yield LogEntry.fromJson(jsonDecode(line));
            } catch (e) {
              log('Log parse error: $e', name: 'MihomoApi');
            }
          }
        }
      }
    } catch (e) {
      log('Logs stream error: $e', name: 'MihomoApi');
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
