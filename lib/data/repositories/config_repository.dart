import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../platform/platform_interface.dart';
import '../models/config_profile.dart';

class ConfigRepository {
  static const _profilesKey = 'config_profiles';
  static const _selectedKey = 'selected_config_id';

  final _dio = Dio();
  final _uuid = const Uuid();

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[/\\:*?"<>|.]'), '_');
  }

  Future<List<ConfigProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_profilesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => ConfigProfile.fromJson(e)).toList();
  }

  Future<void> _saveProfiles(List<ConfigProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey, jsonEncode(profiles));
  }

  Future<String?> getSelectedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedKey);
  }

  Future<void> setSelectedId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, id);
  }

  Future<String?> getSelectedConfigPath() async {
    final id = await getSelectedId();
    if (id == null) return null;
    final profiles = await getProfiles();
    final profile = profiles.where((p) => p.id == id).firstOrNull;
    if (profile == null) return null;
    final configDir = await PlatformInterface.instance.getConfigDirectory();
    return '$configDir/${profile.fileName}';
  }

  Future<ConfigProfile> addFromUrl(String name, String url) async {
    final configDir = await PlatformInterface.instance.getConfigDirectory();
    await Directory(configDir).create(recursive: true);

    // Decode URL if it's URL-encoded
    final decodedUrl = Uri.decodeFull(url);

    final response = await _dio.get<String>(
      decodedUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final content = response.data ?? '';
    var processed = _maybeDecodeBase64(content);
    // If decoded content looks like a list of node links (vmess/trojan/ss/vless),
    // try to convert to a minimal Clash YAML config.
    if (!_looksLikeYaml(processed) && _looksLikeNodeList(processed)) {
      try {
        processed = _convertNodesToClashYaml(processed);
      } catch (_) {
        // ignore and keep processed as-is
      }
    }

    final id = _uuid.v4();
    final safeName = _sanitizeFileName(name);
    final fileName = '${safeName}_$id.yaml';
    await File('$configDir/$fileName').writeAsString(processed);

    final profile = ConfigProfile(
      id: id,
      name: name,
      fileName: fileName,
      sourceUrl: url,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final profiles = await getProfiles();
    profiles.add(profile);
    await _saveProfiles(profiles);

    return profile;
  }

  // If the fetched content is a base64-encoded YAML/config, decode it.
  // Otherwise return original content.
  String _maybeDecodeBase64(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return content;
    // Quick base64 character check (may include newlines)
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=\r\n]+$');

    String tryDecode(String candidate) {
      try {
        final cleaned = candidate.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64.decode(cleaned);
        final decoded = utf8.decode(bytes);
        final yamlIndicators = [
          'proxies:',
          'port:',
          'rules:',
          'proxy:',
          'hosts:',
          'listen:',
          'mixed-port:',
          'redir-port:',
        ];
        final looksLikeYaml =
            decoded.contains('\n') &&
            yamlIndicators.any((k) => decoded.contains(k));
        if (looksLikeYaml) return decoded;
        // Check if it's a node list (vmess/vless/trojan/ss links)
        if (_looksLikeNodeList(decoded)) return decoded;
      } catch (_) {
        // ignore and return empty
      }
      return '';
    }

    // 1) If entire content is pure base64 -> decode
    if (base64Pattern.hasMatch(trimmed)) {
      final decoded = tryDecode(trimmed);
      if (decoded.isNotEmpty) return decoded;
    }

    // 2) Try URL-decoding (some providers send percent-encoded base64)
    try {
      final uriDecoded = Uri.decodeFull(trimmed);
      if (base64Pattern.hasMatch(uriDecoded)) {
        final decoded = tryDecode(uriDecoded);
        if (decoded.isNotEmpty) return decoded;
      }
    } catch (_) {
      // ignore
    }

    // 3) Try to extract long base64-like substrings and decode them
    final longBase64 = RegExp(r'([A-Za-z0-9+/=]{80,})');
    final match = longBase64.firstMatch(trimmed);
    if (match != null) {
      final candidate = match.group(1)!;
      final decoded = tryDecode(candidate);
      if (decoded.isNotEmpty) return decoded;
    }

    return content;
  }

  Future<ConfigProfile> addFromFile(String name, String sourcePath) async {
    final configDir = await PlatformInterface.instance.getConfigDirectory();
    await Directory(configDir).create(recursive: true);

    final content = await File(sourcePath).readAsString();

    final id = _uuid.v4();
    final safeName = _sanitizeFileName(name);
    final fileName = '${safeName}_$id.yaml';
    await File('$configDir/$fileName').writeAsString(content);

    final profile = ConfigProfile(
      id: id,
      name: name,
      fileName: fileName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final profiles = await getProfiles();
    profiles.add(profile);
    await _saveProfiles(profiles);

    return profile;
  }

  Future<void> delete(String id) async {
    final profiles = await getProfiles();
    final profile = profiles.where((p) => p.id == id).firstOrNull;
    if (profile == null) return;

    final configDir = await PlatformInterface.instance.getConfigDirectory();
    final file = File('$configDir/${profile.fileName}');
    if (await file.exists()) await file.delete();

    profiles.removeWhere((p) => p.id == id);
    await _saveProfiles(profiles);

    final selectedId = await getSelectedId();
    if (selectedId == id) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedKey);
    }
  }

  Future<void> updateSubscription(String id) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final profile = profiles[index];
    if (profile.sourceUrl == null) return;

    final configDir = await PlatformInterface.instance.getConfigDirectory();
    final decodedUrl = Uri.decodeFull(profile.sourceUrl!);
    final response = await _dio.get<String>(
      decodedUrl,
      options: Options(responseType: ResponseType.plain),
    );
    var content = response.data ?? '';
    content = _maybeDecodeBase64(content);
    if (!_looksLikeYaml(content) && _looksLikeNodeList(content)) {
      try {
        content = _convertNodesToClashYaml(content);
      } catch (_) {}
    }
    await File('$configDir/${profile.fileName}').writeAsString(content);

    profiles[index] = profile.copyWith(updatedAt: DateTime.now());
    await _saveProfiles(profiles);
  }

  bool _looksLikeYaml(String s) {
    final yamlIndicators = [
      'proxies:',
      'port:',
      'rules:',
      'proxy-groups:',
      'mixed-port:',
    ];
    return s.contains('\n') && yamlIndicators.any((k) => s.contains(k));
  }

  bool _looksLikeNodeList(String s) {
    final lower = s.toLowerCase();
    return lower.contains('vmess://') ||
        lower.contains('trojan://') ||
        lower.contains('ss://') ||
        lower.contains('vless://');
  }

  String _convertNodesToClashYaml(String nodes) {
    final lines = nodes
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final proxies = <String>[];

    String escapeName(String name) => name.replaceAll('"', '\\"');

    for (final line in lines) {
      try {
        if (line.startsWith('vmess://')) {
          final payload = line.substring(8);
          final cleaned = payload.replaceAll(RegExp(r'\s+'), '');
          final decoded = utf8.decode(base64.decode(cleaned));
          final map = jsonDecode(decoded) as Map<String, dynamic>;
          final rawName = (map['ps'] ?? '${map['add']}:${map['port']}').toString();
          final name = Uri.decodeComponent(rawName);
          final server = map['add'].toString();
          final port = map['port'].toString();
          final uuid = map['id']?.toString() ?? map['uuid']?.toString() ?? '';
          final tls = (map['tls'] != null && map['tls'].toString().isNotEmpty)
              ? 'true'
              : 'false';
          final network = (map['net'] ?? 'tcp').toString();
          final buffer = StringBuffer();
          buffer.writeln('- name: "${escapeName(name)}"');
          buffer.writeln('  type: vmess');
          buffer.writeln('  server: $server');
          buffer.writeln('  port: $port');
          buffer.writeln('  uuid: "$uuid"');
          buffer.writeln('  alterId: 0');
          buffer.writeln('  cipher: auto');
          buffer.writeln('  tls: $tls');
          if (network == 'ws') {
            final path = map['path']?.toString() ?? '/';
            final host = map['host']?.toString() ?? '';
            buffer.writeln('  network: ws');
            buffer.writeln('  ws-opts:');
            buffer.writeln('    path: "$path"');
            buffer.writeln('    headers:');
            buffer.writeln('      Host: "$host"');
          }
          proxies.add(buffer.toString());
        } else if (line.startsWith('trojan://')) {
          // Convert trojan://password@host:port?params#name
          final uri = Uri.parse(line.replaceFirst('trojan://', 'http://'));
          final password = uri.userInfo;
          final server = uri.host;
          final port = uri.port == 0 ? 443 : uri.port;
          final name = Uri.decodeComponent(
            uri.fragment.isNotEmpty ? uri.fragment : '$server:$port',
          );
          final sni =
              uri.queryParameters['sni'] ?? uri.queryParameters['peer'] ?? '';
          final tls = (uri.queryParameters['security'] == 'tls' || port == 443)
              ? 'true'
              : 'false';
          final buffer = StringBuffer();
          buffer.writeln('- name: "${escapeName(name)}"');
          buffer.writeln('  type: trojan');
          buffer.writeln('  server: $server');
          buffer.writeln('  port: $port');
          buffer.writeln('  password: "$password"');
          buffer.writeln('  sni: "$sni"');
          buffer.writeln('  alpn: []');
          buffer.writeln('  tls: $tls');
          proxies.add(buffer.toString());
        } else if (line.startsWith('vless://')) {
          final uri = Uri.parse(line.replaceFirst('vless://', 'http://'));
          final uuid = uri.userInfo;
          final server = uri.host.replaceAll(RegExp(r'^\[|\]$'), '');
          final port = uri.port == 0 ? 443 : uri.port;
          final name = Uri.decodeComponent(
            uri.fragment.isNotEmpty ? uri.fragment : '$server:$port',
          );
          final params = uri.queryParameters;
          final security = params['security'] ?? '';
          final buffer = StringBuffer();
          buffer.writeln('- name: "${escapeName(name)}"');
          buffer.writeln('  type: vless');
          buffer.writeln('  server: $server');
          buffer.writeln('  port: $port');
          buffer.writeln('  uuid: "$uuid"');
          buffer.writeln('  tls: ${security == 'reality' || security == 'tls'}');
          if (security == 'reality') {
            buffer.writeln('  reality-opts:');
            buffer.writeln('    public-key: "${params['pbk'] ?? ''}"');
            buffer.writeln('    short-id: "${params['sid'] ?? ''}"');
          }
          if (params['sni']?.isNotEmpty == true) {
            buffer.writeln('  servername: "${params['sni']}"');
          }
          if (params['flow']?.isNotEmpty == true) {
            buffer.writeln('  flow: "${params['flow']}"');
          }
          proxies.add(buffer.toString());
        } else if (line.startsWith('ss://')) {
          // ss://base64#name or ss://method:pass@host:port
          var payload = line.substring(5);
          String name = '';
          if (payload.contains('#')) {
            final parts = payload.split('#');
            payload = parts[0];
            name = Uri.decodeComponent(parts.sublist(1).join('#'));
          }
          if (payload.contains('@')) {
            // method:pass@host:port
            final beforeAt = payload.split('@')[0];
            final afterAt = payload.split('@')[1];
            final method = beforeAt.split(':')[0];
            final password = beforeAt.split(':').sublist(1).join(':');
            final host = afterAt.split(':')[0];
            final port = afterAt.split(':')[1];
            final buffer = StringBuffer();
            buffer.writeln(
              '- name: "${escapeName(name.isNotEmpty ? name : "$host:$port")}"',
            );
            buffer.writeln('  type: ss');
            buffer.writeln('  server: $host');
            buffer.writeln('  port: $port');
            buffer.writeln('  cipher: $method');
            buffer.writeln('  password: "$password"');
            proxies.add(buffer.toString());
          } else {
            // base64 form
            final cleaned = payload.replaceAll(RegExp(r'\s+'), '');
            final decoded = utf8.decode(base64.decode(cleaned));
            // decoded like method:password@host:port
            if (decoded.contains('@')) {
              final method = decoded.split(':')[0];
              final rest = decoded.substring(decoded.indexOf(':') + 1);
              final password = rest.split('@')[0];
              final hostPort = rest.split('@')[1];
              final host = hostPort.split(':')[0];
              final port = hostPort.split(':')[1];
              final buffer = StringBuffer();
              buffer.writeln(
                '- name: "${escapeName(name.isNotEmpty ? name : "$host:$port")}"',
              );
              buffer.writeln('  type: ss');
              buffer.writeln('  server: $host');
              buffer.writeln('  port: $port');
              buffer.writeln('  cipher: $method');
              buffer.writeln('  password: "$password"');
              proxies.add(buffer.toString());
            }
          }
        }
      } catch (_) {
        // skip malformed lines
      }
    }

    final proxySection = proxies.join('\n');
    final yaml = StringBuffer();
    yaml.writeln('port: 7890');
    yaml.writeln('socks-port: 0');
    yaml.writeln('allow-lan: false');
    yaml.writeln('mode: Rule');
    yaml.writeln('log-level: info');
    yaml.writeln('proxies:');
    yaml.writeln(proxySection);
    yaml.writeln('proxy-groups: []');
    yaml.writeln('rules: []');
    return yaml.toString();
  }

  Future<void> updateAllSubscriptions() async {
    final profiles = await getProfiles();
    for (final profile in profiles) {
      if (profile.isSubscription) {
        await updateSubscription(profile.id);
      }
    }
  }

  Future<String> readContent(String id) async {
    final profiles = await getProfiles();
    final profile = profiles.where((p) => p.id == id).firstOrNull;
    if (profile == null) throw Exception('Config not found');

    final configDir = await PlatformInterface.instance.getConfigDirectory();
    return File('$configDir/${profile.fileName}').readAsString();
  }

  Future<void> saveContent(String id, String content) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Config not found');

    final configDir = await PlatformInterface.instance.getConfigDirectory();
    await File('$configDir/${profiles[index].fileName}').writeAsString(content);

    profiles[index] = profiles[index].copyWith(updatedAt: DateTime.now());
    await _saveProfiles(profiles);
  }

  Future<void> updateProfile(String id, {String? name, String? url}) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Config not found');

    profiles[index] = profiles[index].copyWith(
      name: name,
      sourceUrl: url,
      updatedAt: DateTime.now(),
    );
    await _saveProfiles(profiles);
  }
}
