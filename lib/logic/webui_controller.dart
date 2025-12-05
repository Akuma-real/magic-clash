import 'package:flutter/foundation.dart';

import '../core/di/service_locator.dart';
import '../data/repositories/webui_repository.dart';

/// WebUI 管理控制器
///
/// 负责：
/// - WebUI (Zashboard) 的下载和安装
/// - WebUI 版本检查和更新
class WebUiController extends ChangeNotifier {
  final WebUiRepository _webUiRepository;
  bool _disposed = false;

  /// 是否正在下载 WebUI
  bool isDownloading = false;

  /// 下载进度 (0.0 - 1.0)
  double downloadProgress = 0;

  /// 本地已安装的版本
  String? localVersion;

  /// 是否已安装
  bool isInstalled = false;

  /// 构造函数注入依赖
  WebUiController({WebUiRepository? webUiRepository})
    : _webUiRepository = webUiRepository ?? sl.webUiRepository;

  /// 初始化，检查 WebUI 安装状态
  Future<void> init() async {
    isInstalled = await _webUiRepository.isInstalled();
    localVersion = await _webUiRepository.getLocalVersion();
    if (!_disposed) notifyListeners();
  }

  /// 确保 WebUI 已安装，未安装时自动下载
  Future<void> ensureInstalled() async {
    if (isInstalled) return;

    try {
      isDownloading = true;
      downloadProgress = 0;
      if (!_disposed) notifyListeners();

      await _webUiRepository.downloadWithFallback(
        onProgress: (received, total) {
          if (_disposed) return;
          downloadProgress = total > 0 ? received / total : 0;
          notifyListeners();
        },
      );

      isInstalled = true;
      localVersion = await _webUiRepository.getLocalVersion();
    } catch (e) {
      // 下载失败不影响正常使用，静默处理
      debugPrint('WebUI 自动下载失败: $e');
      rethrow;
    } finally {
      isDownloading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// 手动下载/更新 WebUI
  Future<void> download() async {
    isDownloading = true;
    downloadProgress = 0;
    notifyListeners();

    try {
      await _webUiRepository.downloadWithFallback(
        onProgress: (received, total) {
          if (_disposed) return;
          downloadProgress = total > 0 ? received / total : 0;
          notifyListeners();
        },
      );

      isInstalled = true;
      localVersion = await _webUiRepository.getLocalVersion();
    } finally {
      isDownloading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// 检查是否有更新
  Future<bool> checkUpdate() async {
    try {
      return await _webUiRepository.hasUpdate();
    } catch (_) {
      return false;
    }
  }

  /// 获取 WebUI 访问 URL
  String getWebUiUrl() => _webUiRepository.getWebUiUrl();

  /// 获取带认证参数的 WebUI URL
  Future<String> getWebUiUrlWithAuth() =>
      _webUiRepository.getWebUiUrlWithAuth();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
