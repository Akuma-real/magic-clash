import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/byte_formatter.dart';
import '../../../logic/core_runner.dart';
import '../../../logic/home_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.init();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _downloadCore() async {
    try {
      await _controller.downloadCore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  Future<void> _toggleCore() async {
    try {
      await _controller.toggleCore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _controller.status == CoreStatus.running;

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
                      if (_controller.coreVersion != null)
                        Chip(label: Text(_controller.coreVersion!)),
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
                      if (_controller.coreVersion == null &&
                          !_controller.isDownloading)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _downloadCore,
                            icon: const Icon(Icons.download),
                            label: const Text('下载核心'),
                          ),
                        ),
                    ],
                  ),
                  if (_controller.isDownloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _controller.downloadProgress),
                    Text(
                        '${(_controller.downloadProgress * 100).toStringAsFixed(1)}%'),
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
                  Text('流量统计',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.orange),
                            Text('上传: ${formatBytes(_controller.totalUpload)}'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_downward, color: Colors.blue),
                            Text(
                                '下载: ${formatBytes(_controller.totalDownload)}'),
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
                            spots: _controller.uploadData.isEmpty
                                ? [const FlSpot(0, 0)]
                                : _controller.uploadData,
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
                            spots: _controller.downloadData.isEmpty
                                ? [const FlSpot(0, 0)]
                                : _controller.downloadData,
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
