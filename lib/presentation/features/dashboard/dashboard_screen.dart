import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/webui_repository.dart';
import '../../../logic/core_runner.dart';
import '../../../logic/home_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _controller = HomeController();
  final _webUiRepository = WebUiRepository();

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('下载失败: $e')));
      }
    }
  }

  Future<void> _toggleCore() async {
    try {
      await _controller.toggleCore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openWebUI() async {
    final url = await _webUiRepository.getWebUiUrlWithAuth();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开浏览器')));
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
                      if (isRunning)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openWebUI,
                            icon: const Icon(Icons.web),
                            label: const Text('WebUI'),
                          ),
                        ),
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
                    LinearProgressIndicator(
                      value: _controller.downloadProgress,
                    ),
                    Text(
                      '${(_controller.downloadProgress * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
