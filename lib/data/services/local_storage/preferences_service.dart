import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';

/// 更新通道枚举
enum UpdateChannel {
  stable, // 正式版
  alpha, // Alpha 预发布版
}

class PreferencesService {
  static const _profilesKey = 'config_profiles';
  static const _selectedKey = 'selected_config_id';
  static const _themeModeKey = 'themeMode';
  static const _updateChannelKey = 'updateChannel';
  static const _secretKey = 'api_secret';
  static const _webUiVersionKey = 'webui_version';
  static const _localeKey = 'locale';

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<List<Map<String, dynamic>>> getProfiles() async {
    final json = await getString(_profilesKey);
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveProfiles(List<Map<String, dynamic>> profiles) async {
    await setString(_profilesKey, jsonEncode(profiles));
  }

  Future<String?> getSelectedId() async => getString(_selectedKey);

  Future<void> setSelectedId(String id) async => setString(_selectedKey, id);

  Future<void> clearSelectedId() async => remove(_selectedKey);

  Future<String> getThemeMode() async =>
      await getString(_themeModeKey) ?? 'system';

  Future<void> setThemeMode(String mode) async =>
      setString(_themeModeKey, mode);

  /// 获取更新通道
  Future<UpdateChannel> getUpdateChannel() async {
    final value = await getString(_updateChannelKey);
    return UpdateChannel.values.firstWhere(
      (c) => c.name == value,
      orElse: () => UpdateChannel.stable,
    );
  }

  /// 设置更新通道
  Future<void> setUpdateChannel(UpdateChannel channel) async =>
      setString(_updateChannelKey, channel.name);

  /// 获取 API Secret
  Future<String> getSecret() async =>
      await getString(_secretKey) ?? kDefaultSecret;

  /// 设置 API Secret
  Future<void> setSecret(String secret) async => setString(_secretKey, secret);

  /// 获取 WebUI 版本
  Future<String?> getWebUiVersion() async => getString(_webUiVersionKey);

  /// 设置 WebUI 版本
  Future<void> setWebUiVersion(String version) async =>
      setString(_webUiVersionKey, version);

  /// 获取语言设置，返回 null 表示跟随系统
  Future<String?> getLocale() async => getString(_localeKey);

  /// 设置语言，传入 null 表示跟随系统
  Future<void> setLocale(String? locale) async {
    if (locale == null) {
      await remove(_localeKey);
    } else {
      await setString(_localeKey, locale);
    }
  }
}
