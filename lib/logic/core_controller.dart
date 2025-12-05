import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/di/service_locator.dart';
import '../data/models/log_entry.dart';
import '../data/repositories/core_status_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/native/platform_interface.dart';
import 'core_runner.dart';

/// 核心管理控制器
///
/// 负责：
/// - 核心进程的启动/停止
/// - 核心版本管理和下载
/// - 日志管理
class CoreController extends ChangeNotifier {
  final CoreRunner _coreRunner;
  final CoreStatusRepository _coreRepository;
  final ProfileRepository _profileRepository;
  final PlatformInterface _platform;
  bool _disposed = false;

  /// 核心文件路径
  String? corePath;

  /// 配置文件路径
  String? configPath;

  /// 当前核心版本
  String? coreVersion;

  /// 是否正在下载核心
  bool isDownloading = false;

  /// 下载进度 (0.0 - 1.0)
  double downloadProgress = 0;

  /// 核心运行状态
  CoreStatus get status => _coreRunner.status;

  /// 获取进程日志列表
  List<LogEntry> get logs => _coreRunner.logs;

  /// 清空日志
  void clearLogs() => _coreRunner.clearLogs();

  /// 设置端口冲突回调
  set onPortConflict(void Function(PortConflict conflict)? callback) {
    _coreRunner.onPortConflict = callback;
  }

  /// 构造函数注入依赖
  CoreController({
    CoreRunner? coreRunner,
    CoreStatusRepository? coreRepository,
    ProfileRepository? profileRepository,
    PlatformInterface? platform,
  }) : _coreRunner = coreRunner ?? CoreRunner(),
       _coreRepository = coreRepository ?? sl.coreStatusRepository,
       _profileRepository = profileRepository ?? sl.profileRepository,
       _platform = platform ?? sl.platformInterface {
    _coreRunner.addListener(_onCoreStatusChanged);
  }

  /// 初始化
  Future<void> init() async {
    corePath = await _platform.getCorePath();

    configPath = await _profileRepository.getSelectedConfigPath();
    if (configPath == null) {
      final configDir = await _platform.getConfigDirectory();
      configPath = '$configDir/config.yaml';
      await Directory(configDir).create(recursive: true);
    }

    if (corePath != null && await File(corePath!).exists()) {
      coreVersion = await _coreRepository.getCoreVersion(corePath!);
    }

    if (!_disposed) notifyListeners();
  }

  void _onCoreStatusChanged() {
    if (_disposed) return;
    notifyListeners();
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

  /// 下载核心
  ///
  /// [includePrerelease] 是否包含预发布版本
  Future<void> downloadCore({bool includePrerelease = false}) async {
    isDownloading = true;
    downloadProgress = 0;
    notifyListeners();

    try {
      final version = await _coreRepository.getLatestVersion(
        includePrerelease: includePrerelease,
      );
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

  /// 切换核心运行状态
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

  /// 刷新配置路径（当切换配置时调用）
  Future<void> refreshConfigPath() async {
    configPath = await _profileRepository.getSelectedConfigPath();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _coreRunner.removeListener(_onCoreStatusChanged);
    super.dispose();
  }
}
