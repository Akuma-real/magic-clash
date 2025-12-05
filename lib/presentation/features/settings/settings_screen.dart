import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../../data/services/local_storage/preferences_service.dart';
import '../../../data/services/native/platform_interface.dart';
import '../../../data/services/notification/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _coreRepository = sl.coreStatusRepository;
  final _webUiRepository = sl.webUiRepository;
  final _prefs = sl.preferencesService;
  final _notificationService = NotificationService();
  final _secretController = TextEditingController();
  String? _currentVersion;
  String? _latestVersion;
  bool _checkingUpdate = false;
  bool _downloading = false;
  double _downloadProgress = 0;
  ThemeMode _themeMode = ThemeMode.system;
  UpdateChannel _updateChannel = UpdateChannel.stable;
  String? _webUiVersion;
  bool _downloadingWebUi = false;
  double _webUiDownloadProgress = 0;
  String? _locale; // null 表示跟随系统

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkCurrentVersion();
  }

  Future<void> _loadSettings() async {
    final mode = await _prefs.getThemeMode();
    final channel = await _prefs.getUpdateChannel();
    final secret = await _prefs.getSecret();
    final webUiVersion = await _prefs.getWebUiVersion();
    final locale = await _prefs.getLocale();
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
      _updateChannel = channel;
      _secretController.text = secret;
      _webUiVersion = webUiVersion;
      _locale = locale;
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
    // 缓存 l10n 以避免异步上下文问题
    final l10n = context.l10n;
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
              : 'Stable';
          await _notificationService.showUpdateNotification(
            newVersion: _latestVersion!,
            releaseUrl:
                'https://github.com/MetaCubeX/mihomo/releases/tag/$_latestVersion',
            changelog: l10n.notificationNewVersion(channelName),
          );
        } else {
          // 已是最新版本
          await _notificationService.showNotification(
            title: l10n.notificationCoreLatest,
            body: l10n.notificationCoreLatestBody(_currentVersion ?? 'Unknown'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorCheckUpdateFailed(e.toString())),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.successUpdateComplete)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorDownloadFailed(e.toString())),
          ),
        );
      }
    }
    setState(() => _downloading = false);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final appState = App.of(context);
    await _prefs.setThemeMode(mode.name);
    setState(() => _themeMode = mode);
    appState?.setThemeMode(mode);
  }

  Future<void> _setLocale(String? locale) async {
    final appState = App.of(context);
    await _prefs.setLocale(locale);
    setState(() => _locale = locale);
    appState?.setLocale(locale != null ? Locale(locale) : null);
  }

  Future<void> _setUpdateChannel(UpdateChannel channel) async {
    await _prefs.setUpdateChannel(channel);
    setState(() {
      _updateChannel = channel;
      _latestVersion = null; // 切换通道后清除之前的版本信息
    });
  }

  Future<void> _saveSecret() async {
    await _prefs.setSecret(_secretController.text);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.successSecretSaved)));
    }
  }

  Future<void> _downloadWebUi() async {
    setState(() {
      _downloadingWebUi = true;
      _webUiDownloadProgress = 0;
    });
    try {
      await _webUiRepository.downloadWithFallback(
        onProgress: (received, total) {
          setState(() => _webUiDownloadProgress = received / total);
        },
      );
      _webUiVersion = await _prefs.getWebUiVersion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.successWebUiDownloaded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorDownloadFailed(e.toString())),
          ),
        );
      }
    }
    setState(() => _downloadingWebUi = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.memory),
            title: Text(context.l10n.settingsCoreVersion),
            subtitle: Text(
              _currentVersion ?? context.l10n.settingsNotInstalled,
            ),
            trailing: _checkingUpdate
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: () => _checkUpdate(showNotification: true),
                    child: Text(context.l10n.actionCheckUpdate),
                  ),
          ),
          if (_latestVersion != null && _latestVersion != _currentVersion)
            ListTile(
              leading: const Icon(Icons.system_update),
              title: Text(
                context.l10n.settingsNewVersionFound(_latestVersion!),
              ),
              trailing: _downloading
                  ? SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(value: _downloadProgress),
                    )
                  : TextButton(
                      onPressed: _downloadUpdate,
                      child: Text(context.l10n.actionDownload),
                    ),
            ),
          ListTile(
            leading: const Icon(Icons.science),
            title: Text(context.l10n.settingsUpdateChannel),
            subtitle: Text(
              _updateChannel == UpdateChannel.alpha
                  ? context.l10n.settingsChannelAlphaDesc
                  : context.l10n.settingsChannelStableDesc,
            ),
            trailing: DropdownButton<UpdateChannel>(
              value: _updateChannel,
              items: [
                DropdownMenuItem(
                  value: UpdateChannel.stable,
                  child: Text(context.l10n.settingsChannelStable),
                ),
                DropdownMenuItem(
                  value: UpdateChannel.alpha,
                  child: Text(context.l10n.settingsChannelAlpha),
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
            title: Text(context.l10n.settingsTheme),
            trailing: DropdownButton<ThemeMode>(
              value: _themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(context.l10n.settingsThemeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(context.l10n.settingsThemeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(context.l10n.settingsThemeDark),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) _setThemeMode(mode);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.l10n.settingsLanguage),
            trailing: DropdownButton<String?>(
              value: _locale,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(context.l10n.settingsLanguageSystem),
                ),
                DropdownMenuItem(
                  value: 'zh',
                  child: Text(context.l10n.settingsLanguageZh),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(context.l10n.settingsLanguageEn),
                ),
              ],
              onChanged: (locale) => _setLocale(locale),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(context.l10n.settingsApiSecret),
            subtitle: Text(
              context.l10n.settingsApiSecretDefault(kDefaultSecret),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _secretController,
                    decoration: InputDecoration(
                      hintText: context.l10n.settingsApiSecretHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saveSecret,
                  child: Text(context.l10n.actionSave),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.web),
            title: Text(context.l10n.settingsWebUi),
            subtitle: Text(_webUiVersion ?? context.l10n.settingsNotInstalled),
            trailing: _downloadingWebUi
                ? SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: _webUiDownloadProgress,
                    ),
                  )
                : TextButton(
                    onPressed: _downloadWebUi,
                    child: Text(
                      _webUiVersion == null
                          ? context.l10n.actionDownload
                          : context.l10n.actionUpdate,
                    ),
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(context.l10n.settingsAbout),
            subtitle: Text(context.l10n.settingsAboutVersion('1.0.0')),
          ),
        ],
      ),
    );
  }
}
