import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/models/log_entry.dart';
import '../data/services/native/platform_interface.dart';

enum CoreStatus { stopped, starting, running, stopping }

/// 端口冲突信息
class PortConflict {
  final String message;
  final String port;

  PortConflict({required this.message, required this.port});
}

class CoreRunner extends ChangeNotifier {
  static final CoreRunner _instance = CoreRunner._();
  factory CoreRunner() => _instance;
  CoreRunner._();

  Process? _process;
  CoreStatus _status = CoreStatus.stopped;
  final List<LogEntry> _logs = [];
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;
  bool _disposed = false;

  /// 端口冲突回调
  void Function(PortConflict conflict)? onPortConflict;

  /// 当前启动的配置路径，用于重试
  String? _currentCorePath;
  String? _currentConfigPath;

  /// 日志条数上限
  static const int _maxLogEntries = 1000;

  /// 端口占用错误正则 - 匹配 listen tcp 127.0.0.1:9090: bind: address already in use
  static final _portInUseRegex = RegExp(
    r'listen tcp [^:]+:(\d+).*?bind: address already in use',
  );

  CoreStatus get status => _status;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// 添加日志条目
  void _addLog(String message, LogType type) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    _logs.add(
      LogEntry(timestamp: DateTime.now(), type: type, message: trimmed),
    );

    // 超出上限时移除旧日志
    while (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }

    // 检测端口冲突（mihomo 的错误日志可能输出到 stdout，所以同时检测）
    if (trimmed.contains('address already in use')) {
      final match = _portInUseRegex.firstMatch(trimmed);
      final port = match?.group(1) ?? '未知';
      onPortConflict?.call(PortConflict(message: trimmed, port: port));
    }

    notifyListeners();
  }

  /// 清空日志
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  /// 清理残留的 mihomo 进程
  Future<void> killExistingMihomoProcesses() async {
    if (!Platform.isLinux && !Platform.isMacOS) return;

    try {
      // 查找所有 mihomo 核心进程
      final result = await Process.run('pgrep', ['-x', 'mihomo']);
      if (result.exitCode == 0) {
        final pids = (result.stdout as String)
            .trim()
            .split('\n')
            .where((s) => s.isNotEmpty)
            .toList();
        if (pids.isNotEmpty) {
          _addLog(
            '发现 ${pids.length} 个残留的 mihomo 进程 (PID: ${pids.join(", ")})，正在清理...',
            LogType.system,
          );
          // 使用 pkexec 一次性终止所有进程（只需输入一次密码）
          final hasPkexec = await _checkCommand('pkexec');
          if (hasPkexec) {
            // pkexec kill -9 pid1 pid2 pid3 ...
            await Process.run('pkexec', ['kill', '-9', ...pids]);
          } else {
            for (final p in pids) {
              await Process.run('kill', ['-9', p]);
            }
          }
          // 等待进程完全结束
          await Future.delayed(const Duration(milliseconds: 500));
          _addLog('残留进程已清理', LogType.system);
        }
      }
    } catch (e) {
      dev.log('Failed to kill existing processes: $e', name: 'CoreRunner');
    }
  }

  /// 强制释放指定端口（终止占用该端口的进程）
  Future<bool> killProcessOnPort(String port) async {
    if (!Platform.isLinux && !Platform.isMacOS) return false;

    try {
      _addLog('正在释放端口 $port...', LogType.system);

      final hasPkexec = await _checkCommand('pkexec');

      if (Platform.isLinux) {
        // Linux: 使用 pkexec fuser 来终止 root 进程
        if (hasPkexec) {
          await Process.run('pkexec', ['fuser', '-k', '$port/tcp']);
        } else {
          await Process.run('fuser', ['-k', '$port/tcp']);
        }
      } else {
        // macOS: 使用 lsof + kill
        final lsofResult = await Process.run('lsof', ['-ti', 'tcp:$port']);
        if (lsofResult.exitCode == 0) {
          final pids = (lsofResult.stdout as String).trim().split('\n');
          for (final pid in pids.where((p) => p.isNotEmpty)) {
            await Process.run('kill', ['-9', pid]);
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      _addLog('端口 $port 已释放', LogType.system);
      return true;
    } catch (e) {
      _addLog('释放端口失败: $e', LogType.system);
      return false;
    }
  }

  /// 查询占用指定端口的进程信息（只查找 LISTEN 状态）
  Future<String> getProcessOnPort(String port) async {
    if (!Platform.isLinux && !Platform.isMacOS) return '不支持的平台';

    try {
      final results = <String>[];

      if (Platform.isLinux) {
        // 方法1: 使用 ss 命令查找 LISTEN 状态的进程（最可靠）
        final ssResult = await Process.run('ss', [
          '-tlnp',
          'sport',
          '=',
          ':$port',
        ]);
        if (ssResult.exitCode == 0 &&
            (ssResult.stdout as String).trim().isNotEmpty) {
          results.add('【ss 命令结果】\n${(ssResult.stdout as String).trim()}');
        }

        // 方法2: 使用 lsof 查找 LISTEN 状态
        final lsofResult = await Process.run('lsof', [
          '-i',
          'tcp:$port',
          '-sTCP:LISTEN',
          '-P',
          '-n',
        ]);
        if (lsofResult.exitCode == 0 &&
            (lsofResult.stdout as String).trim().isNotEmpty) {
          results.add('【lsof 命令结果】\n${(lsofResult.stdout as String).trim()}');
        }

        // 方法3: 使用 fuser 查找占用进程
        final fuserResult = await Process.run('fuser', ['$port/tcp']);
        if (fuserResult.exitCode == 0 ||
            (fuserResult.stderr as String).isNotEmpty) {
          final pids =
              (fuserResult.stdout as String).trim() +
              (fuserResult.stderr as String).trim();
          if (pids.isNotEmpty) {
            // 获取进程详细信息
            final pidList = pids
                .split(RegExp(r'\s+'))
                .where((p) => p.isNotEmpty)
                .toList();
            for (final pid in pidList) {
              final psResult = await Process.run('ps', [
                '-p',
                pid,
                '-o',
                'pid,comm,user,args',
              ]);
              if (psResult.exitCode == 0) {
                results.add(
                  '【进程 $pid 详情】\n${(psResult.stdout as String).trim()}',
                );
              }
            }
          }
        }
      } else {
        // macOS
        final result = await Process.run('lsof', [
          '-i',
          'tcp:$port',
          '-sTCP:LISTEN',
          '-P',
          '-n',
        ]);
        if (result.exitCode == 0) {
          results.add((result.stdout as String).trim());
        }
      }

      if (results.isEmpty) {
        return '未找到占用端口 $port 的 LISTEN 进程\n\n可能是进程已退出但端口尚未释放（TIME_WAIT 状态）';
      }
      return results.join('\n\n');
    } catch (e) {
      return '查询失败: $e';
    }
  }

  /// 重试启动（在处理端口冲突后调用）
  Future<void> retryStart() async {
    if (_currentCorePath == null || _currentConfigPath == null) return;
    await start(_currentCorePath!, _currentConfigPath!);
  }

  Future<bool> _checkCommand(String cmd) async {
    final result = await Process.run('which', [cmd]);
    return result.exitCode == 0;
  }

  Future<void> start(String corePath, String configPath) async {
    if (_status != CoreStatus.stopped) return;

    // 保存配置路径，用于重试
    _currentCorePath = corePath;
    _currentConfigPath = configPath;

    _status = CoreStatus.starting;
    _addLog('正在启动核心...', LogType.system);
    notifyListeners();

    // 启动前自动清理残留进程
    await killExistingMihomoProcesses();

    // 获取 WebUI 路径
    final configDir = await PlatformInterface.instance.getConfigDirectory();
    final extUiPath = '$configDir/$kWebUiPath';

    try {
      // 构建启动参数
      final args = ['-f', configPath, '-ext-ui', extUiPath];

      if (Platform.isLinux) {
        final hasPkexec = await _checkCommand('pkexec');
        if (hasPkexec) {
          _process = await Process.start('pkexec', [
            corePath,
            ...args,
          ], mode: ProcessStartMode.normal);
        } else {
          dev.log(
            'pkexec not found, trying direct execution',
            name: 'CoreRunner',
          );
          _process = await Process.start(
            corePath,
            args,
            mode: ProcessStartMode.normal,
          );
        }
      } else {
        _process = await Process.start(
          corePath,
          args,
          mode: ProcessStartMode.normal,
        );
      }

      _stdoutSub = _process!.stdout.listen((data) {
        if (_disposed) return;
        _addLog(String.fromCharCodes(data), LogType.stdout);
      });

      _stderrSub = _process!.stderr.listen((data) {
        if (_disposed) return;
        _addLog(String.fromCharCodes(data), LogType.stderr);
      });

      _process!.exitCode.then((code) {
        if (_disposed) return;
        _addLog('核心进程已退出，退出码: $code', LogType.system);
        _status = CoreStatus.stopped;
        _process = null;
        notifyListeners();
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (_process != null) {
        _status = CoreStatus.running;
        _addLog('核心已成功启动', LogType.system);
        notifyListeners();
      }
    } catch (e) {
      _status = CoreStatus.stopped;
      _addLog('启动失败: $e', LogType.system);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_status != CoreStatus.running) return;

    _status = CoreStatus.stopping;
    _addLog('正在停止核心...', LogType.system);
    notifyListeners();

    _stdoutSub?.cancel();
    _stderrSub?.cancel();

    if (_process != null) {
      final processPid = _process!.pid.toString();

      // 先尝试普通 kill
      _process!.kill(ProcessSignal.sigterm);

      // 等待进程退出，最多等待 2 秒
      bool exited = false;
      try {
        await _process!.exitCode
            .timeout(const Duration(seconds: 2), onTimeout: () => -999)
            .then((code) {
              if (code != -999) exited = true;
            });
      } catch (_) {}

      // 如果没有退出，使用 pkexec 强制终止（因为进程可能是 root 权限）
      if (!exited) {
        _addLog('进程未响应，使用 root 权限强制终止...', LogType.system);
        final hasPkexec = await _checkCommand('pkexec');
        if (hasPkexec) {
          await Process.run('pkexec', ['kill', '-9', processPid]);
        } else {
          _process?.kill(ProcessSignal.sigkill);
        }
      }

      // 等待端口释放
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _process = null;
    _status = CoreStatus.stopped;
    _addLog('核心已停止', LogType.system);
    notifyListeners();
  }

  Future<void> restart(String corePath, String configPath) async {
    await stop();
    await start(corePath, configPath);
  }

  @override
  void dispose() {
    _disposed = true;
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _process?.kill();
    super.dispose();
  }
}
