import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../services/local_storage/preferences_service.dart';
import '../services/native/platform_interface.dart';

class WebUiRepository {
  /// GitHub API 获取最新 release
  static const _releaseApi =
      'https://api.github.com/repos/$kZashboardRepo/releases/latest';

  /// 直接下载地址模板
  static const _downloadUrlBase =
      'https://github.com/$kZashboardRepo/releases/download';

  final Dio _dio;
  final PreferencesService _prefs;
  final PlatformInterface _platform;

  /// 构造函数注入依赖
  WebUiRepository({
    required Dio dio,
    required PreferencesService preferencesService,
    required PlatformInterface platformInterface,
  }) : _dio = dio,
       _prefs = preferencesService,
       _platform = platformInterface;

  /// 检查 WebUI 是否已安装（必须是 Zashboard）
  Future<bool> isInstalled() async {
    final uiDir = await _getUiDirectory();
    final indexFile = File('$uiDir/index.html');
    final manifestFile = File('$uiDir/manifest.webmanifest');

    if (!indexFile.existsSync()) return false;

    // 检查是否是 Zashboard（避免 mihomo 自动下载的 MetaCubeXD）
    if (manifestFile.existsSync()) {
      try {
        final content = await manifestFile.readAsString();
        // 如果是 MetaCubeXD，返回 false 强制重新下载 Zashboard
        if (content.contains('MetaCubeXD') || content.contains('metacubexd')) {
          return false;
        }
      } catch (_) {}
    }

    return true;
  }

  /// 获取本地已安装的版本
  Future<String?> getLocalVersion() async {
    return _prefs.getWebUiVersion();
  }

  /// 获取最新版本信息
  Future<String> getLatestVersion() async {
    final response = await _dio.get(_releaseApi);
    return response.data['tag_name'] as String;
  }

  /// 检查是否有更新
  Future<bool> hasUpdate() async {
    try {
      final localVersion = await getLocalVersion();
      if (localVersion == null) return true;

      final latestVersion = await getLatestVersion();
      return localVersion != latestVersion;
    } catch (_) {
      return false;
    }
  }

  /// 下载并安装 WebUI
  /// [onProgress] 下载进度回调
  /// [useProxy] 是否使用反代加速
  Future<void> downloadAndInstall({
    void Function(int received, int total)? onProgress,
    bool useProxy = false,
  }) async {
    // 获取最新版本
    final version = await getLatestVersion();

    // 构建下载 URL
    var downloadUrl = '$_downloadUrlBase/$version/dist.zip';
    if (useProxy) {
      downloadUrl = '$kGhProxy$downloadUrl';
    }

    // 下载到临时文件
    final uiDir = await _getUiDirectory();
    final tempFile = File('$uiDir/../webui_temp.zip');

    try {
      await _dio.download(
        downloadUrl,
        tempFile.path,
        onReceiveProgress: onProgress,
      );

      // 解压到 ui 目录
      await _extractZip(tempFile.path, uiDir);

      // 保存版本号
      await _prefs.setWebUiVersion(version);
    } finally {
      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// 尝试下载，如果直连失败则使用反代
  Future<void> downloadWithFallback({
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // 先尝试直连
      await downloadAndInstall(onProgress: onProgress, useProxy: false);
    } catch (e) {
      // 直连失败，尝试反代
      await downloadAndInstall(onProgress: onProgress, useProxy: true);
    }
  }

  /// 获取 WebUI 目录路径
  Future<String> _getUiDirectory() async {
    final configDir = await _platform.getConfigDirectory();
    return '$configDir/$kWebUiPath';
  }

  /// 解压 ZIP 文件到目标目录
  /// Zashboard 的 dist.zip 内有 dist/ 子目录，需要去掉这一层
  Future<void> _extractZip(String zipPath, String outputDir) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 确保目标目录存在，先清空旧文件
    final dir = Directory(outputDir);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (e) {
        // 可能是 root 权限的文件（mihomo 自动下载的），尝试用 pkexec 删除
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('pkexec', ['rm', '-rf', outputDir]);
        }
      }
    }
    await dir.create(recursive: true);

    // 检测是否有公共前缀目录（如 dist/）
    String? commonPrefix;
    for (final file in archive) {
      final parts = file.name.split('/');
      if (parts.length > 1) {
        final prefix = '${parts[0]}/';
        if (commonPrefix == null) {
          commonPrefix = prefix;
        } else if (commonPrefix != prefix) {
          commonPrefix = null;
          break;
        }
      } else {
        commonPrefix = null;
        break;
      }
    }

    // 解压文件，去掉公共前缀
    for (final file in archive) {
      var filename = file.name;

      // 去掉公共前缀
      if (commonPrefix != null && filename.startsWith(commonPrefix)) {
        filename = filename.substring(commonPrefix.length);
      }

      // 跳过空路径
      if (filename.isEmpty) continue;

      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File('$outputDir/$filename');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
      } else {
        await Directory('$outputDir/$filename').create(recursive: true);
      }
    }
  }

  /// 获取 WebUI 访问 URL
  String getWebUiUrl() {
    return 'http://$kApiHost:$kApiPort/$kWebUiPath/';
  }

  /// 获取带认证参数的 WebUI URL
  Future<String> getWebUiUrlWithAuth() async {
    final secret = await _prefs.getSecret();
    return 'http://$kApiHost:$kApiPort/$kWebUiPath/?hostname=$kApiHost&port=$kApiPort&secret=$secret';
  }
}
