import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/core_repository.dart';
import '../../../platform/platform_interface.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _coreRepository = CoreRepository();
  String? _currentVersion;
  String? _latestVersion;
  bool _checkingUpdate = false;
  bool _downloading = false;
  double _downloadProgress = 0;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkCurrentVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
    });
  }

  Future<void> _checkCurrentVersion() async {
    final corePath = await PlatformInterface.instance.getCorePath();
    if (await File(corePath).exists()) {
      _currentVersion = await _coreRepository.getCoreVersion(corePath);
      setState(() {});
    }
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final version = await _coreRepository.getLatestVersion();
      _latestVersion = version.tagName;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查更新失败: $e')),
        );
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
      final version = await _coreRepository.getLatestVersion();
      final corePath = await PlatformInterface.instance.getCorePath();
      await _coreRepository.downloadCore(
        version,
        corePath,
        (received, total) {
          setState(() => _downloadProgress = received / total);
        },
      );
      _currentVersion = version.tagName;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
    setState(() => _downloading = false);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    setState(() => _themeMode = mode);
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
                    onPressed: _checkUpdate,
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题'),
            trailing: DropdownButton<ThemeMode>(
              value: _themeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('跟随系统'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('浅色'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('深色'),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) _setThemeMode(mode);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            subtitle: const Text('Mihomo Valdi v1.0.0'),
          ),
        ],
      ),
    );
  }
}
