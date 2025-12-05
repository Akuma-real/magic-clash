import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import '../models/core_version.dart';

class CoreStatusRepository {
  /// 获取所有 releases 的 API
  static const _releasesApi =
      'https://api.github.com/repos/MetaCubeX/mihomo/releases';

  /// 获取最新正式版的 API
  static const _latestReleaseApi =
      'https://api.github.com/repos/MetaCubeX/mihomo/releases/latest';

  /// version.txt 下载地址模板
  static const _versionUrlBase =
      'https://github.com/MetaCubeX/mihomo/releases/download';

  final Dio _dio;

  /// 构造函数注入依赖
  CoreStatusRepository({required Dio dio}) : _dio = dio;

  /// 获取最新版本
  /// [includePrerelease] 为 true 时返回最新的 alpha/预发布版本
  Future<CoreVersion> getLatestVersion({bool includePrerelease = false}) async {
    final CoreVersion coreVersion;

    if (!includePrerelease) {
      // 获取最新正式版
      final response = await _dio.get(_latestReleaseApi);
      coreVersion = CoreVersion.fromJson(response.data);
    } else {
      // 获取所有 releases，找到最新的（包括预发布版）
      final response = await _dio.get(
        _releasesApi,
        queryParameters: {'per_page': 10},
      );
      final releases = response.data as List;
      if (releases.isEmpty) {
        throw Exception('No releases found');
      }
      coreVersion = CoreVersion.fromJson(releases.first);
    }

    // 从 version.txt 获取真实版本号
    try {
      final versionUrl = '$_versionUrlBase/${coreVersion.tagName}/version.txt';
      final versionResponse = await _dio.get(versionUrl);
      final realVersion = versionResponse.data.toString().trim();
      // 返回带有真实版本号的 CoreVersion
      return CoreVersion(
        tagName: realVersion,
        name: coreVersion.name,
        assets: coreVersion.assets,
      );
    } catch (_) {
      // 如果获取失败，返回原始版本
      return coreVersion;
    }
  }

  Future<void> downloadCore(
    CoreVersion version,
    String savePath,
    void Function(int received, int total) onProgress,
  ) async {
    final asset = await _selectAsset(version);
    if (asset == null) {
      throw Exception('No compatible asset found for this platform');
    }

    final tempPath = '$savePath.download';
    await _dio.download(
      asset.browserDownloadUrl,
      tempPath,
      onReceiveProgress: onProgress,
    );

    await _extractCore(tempPath, savePath);
    await File(tempPath).delete();

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', savePath]);
    }
  }

  Future<CoreAsset?> _selectAsset(CoreVersion version) async {
    final os = _getOs();
    final arch = await _getArch();
    final pattern = 'mihomo-$os-$arch';

    for (final asset in version.assets) {
      if (asset.name.startsWith(pattern) && asset.name.endsWith('.gz')) {
        return asset;
      }
    }
    return null;
  }

  String _getOs() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    throw UnsupportedError('Unsupported platform');
  }

  Future<String> _getArch() async {
    if (Platform.isAndroid) return 'arm64-v8';
    if (Platform.isLinux) {
      final result = await Process.run('uname', ['-m']);
      final arch = result.stdout.toString().trim();
      return switch (arch) {
        'x86_64' || 'amd64' => 'amd64',
        'aarch64' || 'arm64' => 'arm64',
        'armv7l' => 'armv7',
        _ => 'amd64',
      };
    }
    if (Platform.isWindows) {
      final arch = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '';
      return arch.contains('ARM') ? 'arm64' : 'amd64';
    }
    return 'amd64';
  }

  Future<void> _extractCore(String gzPath, String outputPath) async {
    final bytes = await File(gzPath).readAsBytes();
    final decoded = GZipDecoder().decodeBytes(bytes);
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(decoded);
  }

  String getCoreName() {
    return Platform.isWindows ? 'mihomo.exe' : 'mihomo';
  }

  Future<String?> getCoreVersion(String corePath) async {
    try {
      final result = await Process.run(corePath, ['-v']);
      final output = result.stdout.toString();
      // 匹配版本号：支持 "v1.19.17" 或 "alpha-f44aa22" 格式
      // 示例输出: "Mihomo Meta alpha-f44aa22 linux amd64 ..."
      //          "Mihomo Meta v1.19.17 linux amd64 ..."
      final match = RegExp(r'(v[\d.]+|alpha-[a-f0-9]+)').firstMatch(output);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }
}
