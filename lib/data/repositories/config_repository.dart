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

    final response = await _dio.get(url);
    final content = response.data.toString();

    final id = _uuid.v4();
    final fileName = '${name}_$id.yaml';
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
    final fileName = '${name}_$id.yaml';
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
    final response = await _dio.get(profile.sourceUrl!);
    await File('$configDir/${profile.fileName}')
        .writeAsString(response.data.toString());

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
}
