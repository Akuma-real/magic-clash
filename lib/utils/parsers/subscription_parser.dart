import 'dart:convert';

class SubscriptionParser {
  String maybeDecodeBase64(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return content;
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=\r\n]+$');

    String tryDecode(String candidate) {
      try {
        final cleaned = candidate.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64.decode(cleaned);
        final decoded = utf8.decode(bytes);
        if (_looksLikeYaml(decoded) || _looksLikeNodeList(decoded)) {
          return decoded;
        }
      } catch (_) {}
      return '';
    }

    if (base64Pattern.hasMatch(trimmed)) {
      final decoded = tryDecode(trimmed);
      if (decoded.isNotEmpty) return decoded;
    }

    try {
      final uriDecoded = Uri.decodeFull(trimmed);
      if (base64Pattern.hasMatch(uriDecoded)) {
        final decoded = tryDecode(uriDecoded);
        if (decoded.isNotEmpty) return decoded;
      }
    } catch (_) {}

    final longBase64 = RegExp(r'([A-Za-z0-9+/=]{80,})');
    final match = longBase64.firstMatch(trimmed);
    if (match != null) {
      final decoded = tryDecode(match.group(1)!);
      if (decoded.isNotEmpty) return decoded;
    }

    return content;
  }

  bool _looksLikeYaml(String s) {
    final indicators = [
      'proxies:', 'port:', 'rules:', 'proxy-groups:', 'mixed-port:'
    ];
    return s.contains('\n') && indicators.any((k) => s.contains(k));
  }

  bool _looksLikeNodeList(String s) {
    final lower = s.toLowerCase();
    return lower.contains('vmess://') ||
        lower.contains('trojan://') ||
        lower.contains('ss://') ||
        lower.contains('vless://');
  }

  bool looksLikeYaml(String s) => _looksLikeYaml(s);
  bool looksLikeNodeList(String s) => _looksLikeNodeList(s);

  String convertNodesToClashYaml(String nodes) {
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
          proxies.add(_parseVmess(line, escapeName));
        } else if (line.startsWith('trojan://')) {
          proxies.add(_parseTrojan(line, escapeName));
        } else if (line.startsWith('vless://')) {
          proxies.add(_parseVless(line, escapeName));
        } else if (line.startsWith('ss://')) {
          proxies.add(_parseShadowsocks(line, escapeName));
        }
      } catch (_) {}
    }

    final yaml = StringBuffer()
      ..writeln('port: 7890')
      ..writeln('socks-port: 0')
      ..writeln('allow-lan: false')
      ..writeln('mode: Rule')
      ..writeln('log-level: info')
      ..writeln('proxies:')
      ..writeln(proxies.join('\n'))
      ..writeln('proxy-groups: []')
      ..writeln('rules: []');
    return yaml.toString();
  }

  String _parseVmess(String line, String Function(String) escapeName) {
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
        ? 'true' : 'false';
    final network = (map['net'] ?? 'tcp').toString();
    final buffer = StringBuffer()
      ..writeln('- name: "${escapeName(name)}"')
      ..writeln('  type: vmess')
      ..writeln('  server: $server')
      ..writeln('  port: $port')
      ..writeln('  uuid: "$uuid"')
      ..writeln('  alterId: 0')
      ..writeln('  cipher: auto')
      ..writeln('  tls: $tls');
    if (network == 'ws') {
      final path = map['path']?.toString() ?? '/';
      final host = map['host']?.toString() ?? '';
      buffer
        ..writeln('  network: ws')
        ..writeln('  ws-opts:')
        ..writeln('    path: "$path"')
        ..writeln('    headers:')
        ..writeln('      Host: "$host"');
    }
    return buffer.toString();
  }

  String _parseTrojan(String line, String Function(String) escapeName) {
    final uri = Uri.parse(line.replaceFirst('trojan://', 'http://'));
    final password = uri.userInfo;
    final server = uri.host;
    final port = uri.port == 0 ? 443 : uri.port;
    final name = Uri.decodeComponent(
        uri.fragment.isNotEmpty ? uri.fragment : '$server:$port');
    final sni = uri.queryParameters['sni'] ?? uri.queryParameters['peer'] ?? '';
    final tls = (uri.queryParameters['security'] == 'tls' || port == 443)
        ? 'true' : 'false';
    return '''- name: "${escapeName(name)}"
  type: trojan
  server: $server
  port: $port
  password: "$password"
  sni: "$sni"
  alpn: []
  tls: $tls
''';
  }

  String _parseVless(String line, String Function(String) escapeName) {
    final uri = Uri.parse(line.replaceFirst('vless://', 'http://'));
    final uuid = uri.userInfo;
    final server = uri.host.replaceAll(RegExp(r'^\[|\]$'), '');
    final port = uri.port == 0 ? 443 : uri.port;
    final name = Uri.decodeComponent(
        uri.fragment.isNotEmpty ? uri.fragment : '$server:$port');
    final params = uri.queryParameters;
    final security = params['security'] ?? '';
    final buffer = StringBuffer()
      ..writeln('- name: "${escapeName(name)}"')
      ..writeln('  type: vless')
      ..writeln('  server: $server')
      ..writeln('  port: $port')
      ..writeln('  uuid: "$uuid"')
      ..writeln('  tls: ${security == 'reality' || security == 'tls'}');
    if (security == 'reality') {
      buffer
        ..writeln('  reality-opts:')
        ..writeln('    public-key: "${params['pbk'] ?? ''}"')
        ..writeln('    short-id: "${params['sid'] ?? ''}"');
    }
    if (params['sni']?.isNotEmpty == true) {
      buffer.writeln('  servername: "${params['sni']}"');
    }
    if (params['flow']?.isNotEmpty == true) {
      buffer.writeln('  flow: "${params['flow']}"');
    }
    return buffer.toString();
  }

  String _parseShadowsocks(String line, String Function(String) escapeName) {
    var payload = line.substring(5);
    String name = '';
    if (payload.contains('#')) {
      final parts = payload.split('#');
      payload = parts[0];
      name = Uri.decodeComponent(parts.sublist(1).join('#'));
    }
    if (payload.contains('@')) {
      final beforeAt = payload.split('@')[0];
      final afterAt = payload.split('@')[1];
      // Try base64 decode the method:password part (add padding if needed)
      String method, password;
      try {
        var b64 = beforeAt;
        final pad = b64.length % 4;
        if (pad > 0) b64 += '=' * (4 - pad);
        final decoded = utf8.decode(base64.decode(b64));
        method = decoded.split(':')[0];
        password = decoded.split(':').sublist(1).join(':');
      } catch (_) {
        method = beforeAt.split(':')[0];
        password = beforeAt.split(':').sublist(1).join(':');
      }
      final host = afterAt.split(':')[0];
      final port = afterAt.split(':')[1];
      return '''- name: "${escapeName(name.isNotEmpty ? name : "$host:$port")}"
  type: ss
  server: $host
  port: $port
  cipher: $method
  password: "$password"
''';
    } else {
      final cleaned = payload.replaceAll(RegExp(r'\s+'), '');
      final decoded = utf8.decode(base64.decode(cleaned));
      if (decoded.contains('@')) {
        final method = decoded.split(':')[0];
        final rest = decoded.substring(decoded.indexOf(':') + 1);
        final password = rest.split('@')[0];
        final hostPort = rest.split('@')[1];
        final host = hostPort.split(':')[0];
        final port = hostPort.split(':')[1];
        return '''- name: "${escapeName(name.isNotEmpty ? name : "$host:$port")}"
  type: ss
  server: $host
  port: $port
  cipher: $method
  password: "$password"
''';
      }
    }
    return '';
  }
}
