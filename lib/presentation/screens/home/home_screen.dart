import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/config_repository.dart';
import '../../../data/repositories/core_repository.dart';
import '../../../data/services/mihomo_api_service.dart';
import '../../../domain/core_manager.dart';
import '../../../platform/platform_interface.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _coreManager = CoreManager();
  final _coreRepository = CoreRepository();
  MihomoApiService? _apiService;
  StreamSubscription? _trafficSub;

  final List<FlSpot> _uploadData = [];
  final List<FlSpot> _downloadData = [];
  int _dataIndex = 0;
  int _totalUpload = 0;
  int _totalDownload = 0;

  String? _corePath;
  String? _configPath;
  String? _coreVersion;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _init();
    _coreManager.addListener(_onCoreStatusChanged);
  }

  Future<void> _init() async {
    final platform = PlatformInterface.instance;
    _corePath = await platform.getCorePath();

    final configRepo = ConfigRepository();
    _configPath = await configRepo.getSelectedConfigPath();
    if (_configPath == null) {
      final configDir = await platform.getConfigDirectory();
      _configPath = '$configDir/config.yaml';
      await Directory(configDir).create(recursive: true);
    }

    if (await File(_corePath!).exists()) {
      _coreVersion = await _coreRepository.getCoreVersion(_corePath!);
    }
    setState(() {});
  }

  void _onCoreStatusChanged() {
    if (!mounted) return;
    setState(() {});
    if (_coreManager.status == CoreStatus.running) {
      _startTrafficMonitor();
    } else {
      _stopTrafficMonitor();
    }
  }

  void _startTrafficMonitor() {
    _apiService = MihomoApiService(host: '127.0.0.1', port: 9090);
    _trafficSub = _apiService!.trafficStream().listen(
      (traffic) {
        if (!mounted) return;
        setState(() {
          _totalUpload += traffic.up;
          _totalDownload += traffic.down;
          _uploadData.add(FlSpot(_dataIndex.toDouble(), traffic.up / 1024));
          _downloadData.add(FlSpot(_dataIndex.toDouble(), traffic.down / 1024));
          _dataIndex++;
          if (_uploadData.length > 60) {
            _uploadData.removeAt(0);
            _downloadData.removeAt(0);
          }
        });
      },
      onError: (_) {},
    );
  }

  void _stopTrafficMonitor() {
    _trafficSub?.cancel();
    _trafficSub = null;
    _apiService = null;
  }

  Future<void> _downloadCore() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final version = await _coreRepository.getLatestVersion();
      await _coreRepository.downloadCore(
        version,
        _corePath!,
        (received, total) {
          setState(() {
            _downloadProgress = received / total;
          });
        },
      );
      _coreVersion = version.tagName;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _toggleCore() async {
    if (_coreManager.status == CoreStatus.running) {
      await _coreManager.stop();
    } else {
      if (_corePath == null || !await File(_corePath!).exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先下载核心')),
        );
        return;
      }
      if (_configPath == null || !await File(_configPath!).exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先添加配置文件')),
        );
        return;
      }
      await _coreManager.start(_corePath!, _configPath!);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  void dispose() {
    _coreManager.removeListener(_onCoreStatusChanged);
    _trafficSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _coreManager.status == CoreStatus.running;

    return Scaffold(
      appBar: AppBar(title: const Text('Magic Clash')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isRunning ? Icons.check_circle : Icons.cancel,
                        color: isRunning ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRunning ? '运行中' : '已停止',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (_coreVersion != null)
                        Chip(label: Text(_coreVersion!)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleCore,
                          icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                          label: Text(isRunning ? '停止' : '启动'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_coreVersion == null && !_isDownloading)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _downloadCore,
                            icon: const Icon(Icons.download),
                            label: const Text('下载核心'),
                          ),
                        ),
                    ],
                  ),
                  if (_isDownloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _downloadProgress),
                    Text('${(_downloadProgress * 100).toStringAsFixed(1)}%'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('流量统计', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.orange),
                            Text('上传: ${_formatBytes(_totalUpload)}'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_downward, color: Colors.blue),
                            Text('下载: ${_formatBytes(_totalDownload)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _uploadData.isEmpty
                                ? [const FlSpot(0, 0)]
                                : _uploadData,
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.orange.withValues(alpha: 0.2),
                            ),
                          ),
                          LineChartBarData(
                            spots: _downloadData.isEmpty
                                ? [const FlSpot(0, 0)]
                                : _downloadData,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
