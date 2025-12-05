import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/log_entry.dart';
import 'core_controller.dart';
import 'core_runner.dart';
import 'webui_controller.dart';

/// 主页控制器（组合层）
///
/// 组合 CoreController 和 WebUiController，
/// 为 DashboardScreen 提供统一的状态接口
class HomeController extends ChangeNotifier {
  final CoreController coreController;
  final WebUiController webUiController;
  bool _disposed = false;

  /// 核心文件路径
  String? get corePath => coreController.corePath;

  /// 配置文件路径
  String? get configPath => coreController.configPath;

  /// 当前核心版本
  String? get coreVersion => coreController.coreVersion;

  /// 核心运行状态
  CoreStatus get status => coreController.status;

  /// 获取进程日志列表
  List<LogEntry> get logs => coreController.logs;

  /// 是否正在下载核心
  bool get isDownloading => coreController.isDownloading;

  /// 核心下载进度
  double get downloadProgress => coreController.downloadProgress;

  /// 是否正在下载 WebUI
  bool get isDownloadingWebUi => webUiController.isDownloading;

  /// WebUI 下载进度
  double get webUiDownloadProgress => webUiController.downloadProgress;

  /// 清空日志
  void clearLogs() => coreController.clearLogs();

  /// 设置端口冲突回调
  set onPortConflict(void Function(PortConflict conflict)? callback) {
    coreController.onPortConflict = callback;
  }

  /// 构造函数
  HomeController({
    CoreController? coreController,
    WebUiController? webUiController,
  }) : coreController = coreController ?? CoreController(),
       webUiController = webUiController ?? WebUiController() {
    this.coreController.addListener(_onChildChanged);
    this.webUiController.addListener(_onChildChanged);
  }

  /// 初始化
  Future<void> init() async {
    await coreController.init();
    await webUiController.init();

    // 首次启动自动下载 WebUI
    _ensureWebUiInstalled();
  }

  void _onChildChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  /// 确保 WebUI 已安装
  Future<void> _ensureWebUiInstalled() async {
    try {
      await webUiController.ensureInstalled();
    } catch (e) {
      debugPrint('WebUI 自动下载失败: $e');
    }
  }

  /// 查询占用端口的进程信息
  Future<String> getProcessOnPort(String port) =>
      coreController.getProcessOnPort(port);

  /// 强制释放端口并重试启动
  Future<void> killPortAndRetry(String port) =>
      coreController.killPortAndRetry(port);

  /// 下载核心
  Future<void> downloadCore({bool includePrerelease = false}) =>
      coreController.downloadCore(includePrerelease: includePrerelease);

  /// 切换核心运行状态
  Future<void> toggleCore() => coreController.toggleCore();

  /// 刷新配置路径
  Future<void> refreshConfigPath() => coreController.refreshConfigPath();

  @override
  void dispose() {
    _disposed = true;
    coreController.removeListener(_onChildChanged);
    webUiController.removeListener(_onChildChanged);
    coreController.dispose();
    webUiController.dispose();
    super.dispose();
  }
}
