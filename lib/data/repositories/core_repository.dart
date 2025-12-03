import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import '../models/core_version.dart';

class CoreRepository {
  static const _releaseApi =
      'https://api.github.com/repos/MetaCubeX/mihomo/releases/latest';

  final Dio _dio = Dio();

  Future<CoreVersion> getLatestVersion() async {
    final response = await _dio.get(_releaseApi);
    return CoreVersion.fromJson(response.data);
  }

  Future<void> downloadCore(
    CoreVersion version,
    String savePath,
    void Function(int received, int total) onProgress,
  ) async {
    final asset = _selectAsset(version);
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

  CoreAsset? _selectAsset(CoreVersion version) {
    final os = _getOs();
    final arch = _getArch();
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

  String _getArch() {
    // 简化处理，实际应检测系统架构
    if (Platform.isAndroid) return 'arm64-v8';
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
      final match = RegExp(r'v[\d.]+').firstMatch(output);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }
}
