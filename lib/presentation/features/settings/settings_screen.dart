import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/repositories/core_status_repository.dart';
import '../../../data/services/local_storage/preferences_service.dart';
import '../../../data/services/native/platform_interface.dart';
import '../../../data/services/notification/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _coreRepository = CoreStatusRepository();
  final _prefs = PreferencesService();
  final _notificationService = NotificationService();
  String? _currentVersion;
  String? _latestVersion;
  bool _checkingUpdate = false;
  bool _downloading = false;
  double _downloadProgress = 0;
  ThemeMode _themeMode = ThemeMode.system;
  UpdateChannel _updateChannel = UpdateChannel.stable;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkCurrentVersion();
  }

  Future<void> _loadSettings() async {
    final mode = await _prefs.getThemeMode();
    final channel = await _prefs.getUpdateChannel();
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
      _updateChannel = channel;
    });
  }

  Future<void> _checkCurrentVersion() async {
    final corePath = await PlatformInterface.instance.getCorePath();
    if (await File(corePath).exists()) {
      _currentVersion = await _coreRepository.getCoreVersion(corePath);
      setState(() {});
    }
  }

  /// 检查核心更新，可选择是否显示系统通知
  Future<void> _checkUpdate({bool showNotification = false}) async {
    setState(() => _checkingUpdate = true);
    try {
      final version = await _coreRepository.getLatestVersion(
        includePrerelease: _updateChannel == UpdateChannel.alpha,
      );
      _latestVersion = version.tagName;

      // 显示系统通知
      if (showNotification) {
        if (_latestVersion != null && _latestVersion != _currentVersion) {
          // 有新版本
          final channelName = _updateChannel == UpdateChannel.alpha
              ? 'Alpha'
              : '正式';
          await _notificationService.showUpdateNotification(
            newVersion: _latestVersion!,
            releaseUrl:
                'https://github.com/MetaCubeX/mihomo/releases/tag/$_latestVersion',
            changelog: 'Mihomo 核心 ($channelName版) 有新版本可用，点击查看详情',
          );
        } else {
          // 已是最新版本
          await _notificationService.showNotification(
            title: 'Mihomo 核心已是最新版本',
            body: '当前版本: ${_currentVersion ?? "未知"}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('检查更新失败: $e')));
      }
    }
    setState(() => _checkingUpdate = false);
  }

  Future<void> _downloadUpdate() async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final version = await _coreRepository.getLatestVersion(
        includePrerelease: _updateChannel == UpdateChannel.alpha,
      );
      final corePath = await PlatformInterface.instance.getCorePath();
      await _coreRepository.downloadCore(version, corePath, (received, total) {
        setState(() => _downloadProgress = received / total);
      });
      _currentVersion = version.tagName;
      _latestVersion = null; // 清除更新提示
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('更新完成')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('下载失败: $e')));
      }
    }
    setState(() => _downloading = false);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(mode.name);
    setState(() => _themeMode = mode);
  }

  Future<void> _setUpdateChannel(UpdateChannel channel) async {
    await _prefs.setUpdateChannel(channel);
    setState(() {
      _updateChannel = channel;
      _latestVersion = null; // 切换通道后清除之前的版本信息
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('核心版本'),
            subtitle: Text(_currentVersion ?? '未安装'),
            trailing: _checkingUpdate
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: () => _checkUpdate(showNotification: true),
                    child: const Text('检查更新'),
                  ),
          ),
          if (_latestVersion != null && _latestVersion != _currentVersion)
            ListTile(
              leading: const Icon(Icons.system_update),
              title: Text('发现新版本: $_latestVersion'),
              trailing: _downloading
                  ? SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(value: _downloadProgress),
                    )
                  : TextButton(
                      onPressed: _downloadUpdate,
                      child: const Text('下载'),
                    ),
            ),
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('更新通道'),
            subtitle: Text(
              _updateChannel == UpdateChannel.alpha
                  ? 'Alpha (预发布版，可能不稳定)'
                  : '正式版 (稳定版本)',
            ),
            trailing: DropdownButton<UpdateChannel>(
              value: _updateChannel,
              items: const [
                DropdownMenuItem(
                  value: UpdateChannel.stable,
                  child: Text('正式版'),
                ),
                DropdownMenuItem(
                  value: UpdateChannel.alpha,
                  child: Text('Alpha'),
                ),
              ],
              onChanged: (channel) {
                if (channel != null) _setUpdateChannel(channel);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题'),
            trailing: DropdownButton<ThemeMode>(
              value: _themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
              ],
              onChanged: (mode) {
                if (mode != null) _setThemeMode(mode);
              },
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('关于'),
            subtitle: Text('Magic Clash v1.0.0'),
          ),
        ],
      ),
    );
  }
}
