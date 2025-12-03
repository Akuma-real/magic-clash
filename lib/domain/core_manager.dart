import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/models/log_entry.dart';
import '../data/services/mihomo_api_service.dart';

enum CoreStatus { stopped, starting, running, stopping }

class CoreManager extends ChangeNotifier {
  static final CoreManager _instance = CoreManager._();
  factory CoreManager() => _instance;
  CoreManager._();

  Process? _process;
  CoreStatus _status = CoreStatus.stopped;
  final List<String> _processLogs = [];
  final List<LogEntry> _apiLogs = [];
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;
  StreamSubscription? _apiLogSub;
  bool _disposed = false;

  CoreStatus get status => _status;
  List<String> get processLogs => List.unmodifiable(_processLogs);
  List<LogEntry> get apiLogs => List.unmodifiable(_apiLogs);

  Future<bool> _checkCommand(String cmd) async {
    final result = await Process.run('which', [cmd]);
    return result.exitCode == 0;
  }

  Future<void> start(String corePath, String configPath) async {
    if (_status != CoreStatus.stopped) return;

    _status = CoreStatus.starting;
    _processLogs.clear();
    _apiLogs.clear();
    notifyListeners();

    try {
      if (Platform.isLinux) {
        final hasPkexec = await _checkCommand('pkexec');
        if (hasPkexec) {
          _process = await Process.start(
            'pkexec',
            [corePath, '-f', configPath],
            mode: ProcessStartMode.normal,
          );
        } else {
          dev.log('pkexec not found, trying direct execution',
              name: 'CoreManager');
          _process = await Process.start(
            corePath,
            ['-f', configPath],
            mode: ProcessStartMode.normal,
          );
        }
      } else {
        _process = await Process.start(
          corePath,
          ['-f', configPath],
          mode: ProcessStartMode.normal,
        );
      }

      _stdoutSub = _process!.stdout.listen((data) {
        if (_disposed) return;
        _processLogs.add(String.fromCharCodes(data));
        notifyListeners();
      });

      _stderrSub = _process!.stderr.listen((data) {
        if (_disposed) return;
        _processLogs.add(String.fromCharCodes(data));
        notifyListeners();
      });

      _process!.exitCode.then((code) {
        if (_disposed) return;
        _status = CoreStatus.stopped;
        _process = null;
        notifyListeners();
      });

      // 等待一小段时间确认启动成功
      await Future.delayed(const Duration(milliseconds: 500));
      if (_process != null) {
        _status = CoreStatus.running;
        notifyListeners();
      }
      // 启动 API 日志监听
      _startApiLogListener();
    } catch (e) {
      _status = CoreStatus.stopped;
      _processLogs.add('Failed to start: $e');
      notifyListeners();
      rethrow;
    }
  }

  void _startApiLogListener() {
    final api = MihomoApiService(host: '127.0.0.1', port: 9090);
    _apiLogSub = api.logsStream(level: 'debug').listen(
      (log) {
        if (_disposed) return;
        _apiLogs.add(log);
        if (_apiLogs.length > 5000) _apiLogs.removeAt(0);
        notifyListeners();
      },
    );
  }

  Future<void> stop() async {
    if (_status != CoreStatus.running) return;

    _status = CoreStatus.stopping;
    notifyListeners();

    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _apiLogSub?.cancel();
    _process?.kill();

    _process = null;
    _status = CoreStatus.stopped;
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
    _apiLogSub?.cancel();
    _process?.kill();
    super.dispose();
  }
}
