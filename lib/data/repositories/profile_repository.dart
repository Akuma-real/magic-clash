import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../utils/parsers/subscription_parser.dart';
import '../models/config_profile.dart';
import '../services/local_storage/preferences_service.dart';
import '../services/native/platform_interface.dart';

class ProfileRepository {
  final _dio = Dio();
  final _uuid = const Uuid();
  final _prefs = PreferencesService();
  final _parser = SubscriptionParser();

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[/\\:*?"<>|.]'), '_');
  }

  Future<List<ConfigProfile>> getProfiles() async {
    final list = await _prefs.getProfiles();
    return list.map((e) => ConfigProfile.fromJson(e)).toList();
  }

  Future<void> _saveProfiles(List<ConfigProfile> profiles) async {
    await _prefs.saveProfiles(profiles.map((p) => p.toJson()).toList());
  }

  Future<String?> getSelectedId() => _prefs.getSelectedId();

  Future<void> setSelectedId(String id) => _prefs.setSelectedId(id);

  Future<String?> getSelectedConfigPath() async {
    final id = await getSelectedId();
    if (id == null) return null;
    final profiles = await getProfiles();
    final profile = profiles.where((p) => p.id == id).firstOrNull;
    if (profile == null) return null;
    final configDir = await PlatformInterface.instance.getConfigDirectory();
    return '$configDir/${profile.fileName}';
  }

  /// 生成运行时配置文件，强制覆盖 external-controller 等必要配置
  Future<String?> generateRuntimeConfig() async {
    final configPath = await getSelectedConfigPath();
    if (configPath == null) return null;

    final configDir = await PlatformInterface.instance.getConfigDirectory();
    final runtimePath = '$configDir/runtime_config.yaml';

    // 获取用户设置的 secret
    final secret = await _prefs.getSecret();

    final content = await File(configPath).readAsString();
    final modifiedContent = _injectRequiredSettings(content, secret);
    await File(runtimePath).writeAsString(modifiedContent);

    return runtimePath;
  }

  /// 注入必要的配置项，强制覆盖已有设置
  String _injectRequiredSettings(String content, String secret) {
    final lines = content.split('\n');
    final result = <String>[];

    // 需要强制设置的配置项
    // 注意：不设置 external-ui，因为 root 权限运行时路径不允许
    // WebUI 通过浏览器访问外部服务或使用内置 UI
    final overrides = {
      'external-controller': '0.0.0.0:$kApiPort',
      'secret': secret,
      'log-level': 'info',
    };

    // 需要移除的配置项（避免路径问题）
    final removeKeys = {'external-ui', 'external-ui-url'};

    final foundKeys = <String>{};

    for (final line in lines) {
      final trimmed = line.trim();

      // 跳过需要移除的配置项
      bool shouldRemove = false;
      for (final key in removeKeys) {
        if (trimmed.startsWith('$key:')) {
          shouldRemove = true;
          break;
        }
      }
      if (shouldRemove) continue;

      bool replaced = false;
      for (final key in overrides.keys) {
        if (trimmed.startsWith('$key:')) {
          result.add('$key: ${overrides[key]}');
          foundKeys.add(key);
          replaced = true;
          break;
        }
      }

      if (!replaced) {
        result.add(line);
      }
    }

    // 添加未找到的配置项到文件开头（在第一行之后）
    final missingKeys = overrides.keys.where((k) => !foundKeys.contains(k));
    if (missingKeys.isNotEmpty) {
      final insertIndex = result.isNotEmpty ? 1 : 0;
      for (final key in missingKeys) {
        result.insert(insertIndex, '$key: ${overrides[key]}');
      }
    }

    return result.join('\n');
  }

  Future<ConfigProfile> addFromUrl(String name, String url) async {
    final configDir = await PlatformInterface.instance.getConfigDirectory();
    await Directory(configDir).create(recursive: true);

    final decodedUrl = Uri.decodeFull(url);
    final response = await _dio.get<String>(
      decodedUrl,
      options: Options(responseType: ResponseType.plain),
    );
    var content = response.data ?? '';
    content = _parser.maybeDecodeBase64(content);
    if (!_parser.looksLikeYaml(content) && _parser.looksLikeNodeList(content)) {
      try {
        content = _parser.convertNodesToClashYaml(content);
      } catch (_) {}
    }

    final id = _uuid.v4();
    final safeName = _sanitizeFileName(name);
    final fileName = '${safeName}_$id.yaml';
    await File('$configDir/$fileName').writeAsString(content);

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
    if (selectedId == id) await _prefs.clearSelectedId();
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
    content = _parser.maybeDecodeBase64(content);
    if (!_parser.looksLikeYaml(content) && _parser.looksLikeNodeList(content)) {
      try {
        content = _parser.convertNodesToClashYaml(content);
      } catch (_) {}
    }
    await File('$configDir/${profile.fileName}').writeAsString(content);

    profiles[index] = profile.copyWith(updatedAt: DateTime.now());
    await _saveProfiles(profiles);
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
