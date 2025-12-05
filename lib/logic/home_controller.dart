import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/repositories/core_status_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/native/platform_interface.dart';
import 'core_runner.dart';

class HomeController extends ChangeNotifier {
  final _coreRunner = CoreRunner();
  final _coreRepository = CoreStatusRepository();
  final _profileRepository = ProfileRepository();
  bool _disposed = false;

  String? corePath;
  String? configPath;
  String? coreVersion;
  bool isDownloading = false;
  double downloadProgress = 0;

  CoreStatus get status => _coreRunner.status;

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
