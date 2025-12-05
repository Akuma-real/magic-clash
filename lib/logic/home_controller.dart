import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/models/log_entry.dart';
import '../data/repositories/core_status_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/webui_repository.dart';
import '../data/services/native/platform_interface.dart';
import 'core_runner.dart';

class HomeController extends ChangeNotifier {
  final _coreRunner = CoreRunner();
  final _coreRepository = CoreStatusRepository();
  final _profileRepository = ProfileRepository();
  final _webUiRepository = WebUiRepository();
  bool _disposed = false;

  String? corePath;
  String? configPath;
  String? coreVersion;
  bool isDownloading = false;
  double downloadProgress = 0;
  bool isDownloadingWebUi = false;
  double webUiDownloadProgress = 0;

  CoreStatus get status => _coreRunner.status;

  /// 获取进程日志列表
  List<LogEntry> get logs => _coreRunner.logs;

  /// 清空日志
  void clearLogs() => _coreRunner.clearLogs();

  /// 设置端口冲突回调
  set onPortConflict(void Function(PortConflict conflict)? callback) {
    _coreRunner.onPortConflict = callback;
  }

  /// 查询占用端口的进程信息
  Future<String> getProcessOnPort(String port) async {
    return _coreRunner.getProcessOnPort(port);
  }

  /// 强制释放端口并重试启动
  Future<void> killPortAndRetry(String port) async {
    await _coreRunner.killProcessOnPort(port);
    await _coreRunner.retryStart();
  }

  HomeController() {
    _coreRunner.addListener(_onCoreStatusChanged);
  }

  Future<void> init() async {
    final platform = PlatformInterface.instance;
    corePath = await platform.getCorePath();

    configPath = await _profileRepository.getSelectedConfigPath();
    if (configPath == null) {
      final configDir = await platform.getConfigDirectory();
      configPath = '$configDir/config.yaml';
      await Directory(configDir).create(recursive: true);
    }

    if (await File(corePath!).exists()) {
      coreVersion = await _coreRepository.getCoreVersion(corePath!);
    }
    if (!_disposed) notifyListeners();

    // 首次启动自动下载 WebUI (Zashboard)
    _ensureWebUiInstalled();
  }

  /// 确保 WebUI 已安装，未安装时自动下载
  Future<void> _ensureWebUiInstalled() async {
    try {
      final installed = await _webUiRepository.isInstalled();
      if (!installed) {
        isDownloadingWebUi = true;
        webUiDownloadProgress = 0;
        if (!_disposed) notifyListeners();

        await _webUiRepository.downloadWithFallback(
          onProgress: (received, total) {
            if (_disposed) return;
            webUiDownloadProgress = received / total;
            notifyListeners();
          },
        );
      }
    } catch (e) {
      // 下载失败不影响正常使用，静默处理
      debugPrint('WebUI 自动下载失败: $e');
    } finally {
      isDownloadingWebUi = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _onCoreStatusChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> downloadCore() async {
    isDownloading = true;
    downloadProgress = 0;
    notifyListeners();

    try {
      final version = await _coreRepository.getLatestVersion();
      await _coreRepository.downloadCore(version, corePath!, (received, total) {
        if (_disposed) return;
        downloadProgress = received / total;
        notifyListeners();
      });
      coreVersion = version.tagName;
    } finally {
      isDownloading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> toggleCore() async {
    if (_coreRunner.status == CoreStatus.running) {
      await _coreRunner.stop();
    } else {
      if (corePath == null || !await File(corePath!).exists()) {
        throw Exception('请先下载核心');
      }
      if (configPath == null || !await File(configPath!).exists()) {
        throw Exception('请先添加配置文件');
      }
      // 生成运行时配置，强制注入必要的配置项
      final runtimeConfigPath = await _profileRepository
          .generateRuntimeConfig();
      if (runtimeConfigPath == null) {
        throw Exception('生成运行时配置失败');
      }
      await _coreRunner.start(corePath!, runtimeConfigPath);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _coreRunner.removeListener(_onCoreStatusChanged);
    super.dispose();
  }
}
