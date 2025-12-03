import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/repositories/core_status_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/api/mihomo_api_service.dart';
import '../data/services/native/platform_interface.dart';
import 'core_runner.dart';

class HomeController extends ChangeNotifier {
  final _coreRunner = CoreRunner();
  final _coreRepository = CoreStatusRepository();
  final _profileRepository = ProfileRepository();
  MihomoApiService? _apiService;
  StreamSubscription? _trafficSub;

  final List<FlSpot> uploadData = [];
  final List<FlSpot> downloadData = [];
  int _dataIndex = 0;
  int totalUpload = 0;
  int totalDownload = 0;

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
    notifyListeners();
  }

  void _onCoreStatusChanged() {
    notifyListeners();
    if (_coreRunner.status == CoreStatus.running) {
      _startTrafficMonitor();
    } else {
      _stopTrafficMonitor();
    }
  }

  void _startTrafficMonitor() {
    _apiService = MihomoApiService();
    _trafficSub = _apiService!.trafficStream().listen(
      (traffic) {
        totalUpload += traffic.up;
        totalDownload += traffic.down;
        uploadData.add(FlSpot(_dataIndex.toDouble(), traffic.up / 1024));
        downloadData.add(FlSpot(_dataIndex.toDouble(), traffic.down / 1024));
        _dataIndex++;
        if (uploadData.length > kTrafficDataPoints) {
          uploadData.removeAt(0);
          downloadData.removeAt(0);
        }
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void _stopTrafficMonitor() {
    _trafficSub?.cancel();
    _trafficSub = null;
    _apiService = null;
  }

  Future<void> downloadCore() async {
    isDownloading = true;
    downloadProgress = 0;
    notifyListeners();

    try {
      final version = await _coreRepository.getLatestVersion();
      await _coreRepository.downloadCore(
        version,
        corePath!,
        (received, total) {
          downloadProgress = received / total;
          notifyListeners();
        },
      );
      coreVersion = version.tagName;
    } finally {
      isDownloading = false;
      notifyListeners();
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
      await _coreRunner.start(corePath!, configPath!);
    }
  }

  @override
  void dispose() {
    _coreRunner.removeListener(_onCoreStatusChanged);
    _trafficSub?.cancel();
    super.dispose();
  }
}
