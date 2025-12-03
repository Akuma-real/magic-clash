import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import '../models/core_version.dart';

class CoreStatusRepository {
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
      final match = RegExp(r'v[\d.]+').firstMatch(output);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }
}
