import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/log_entry.dart';
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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.onPortConflict = _handlePortConflict;
    _controller.init();
  }

  void _onUpdate() {
    if (mounted) {
      setState(() {});
      // 自动滚动到日志底部
      _scrollToBottom();
    }
  }

  void _handlePortConflict(PortConflict conflict) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('端口被占用'),
        content: _PortConflictContent(
          port: conflict.port,
          controller: _controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _killPortAndRetry(conflict.port);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('强制释放并重试'),
          ),
        ],
      ),
    );
  }

  Future<void> _killPortAndRetry(String port) async {
    try {
      await _controller.killPortAndRetry(port);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
    _controller.onPortConflict = null;
    _scrollController.dispose();
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
          const SizedBox(height: 16),
          // 日志卡片
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '进程日志',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${_controller.logs.length} 条',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: '清空日志',
                        onPressed: _controller.logs.isEmpty
                            ? null
                            : () => _controller.clearLogs(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: 250,
                  child: _controller.logs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无日志',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _controller.logs.length,
                          itemBuilder: (context, index) {
                            final log = _controller.logs[index];
                            return _buildLogEntry(log);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    Color typeColor;
    IconData typeIcon;

    switch (log.type) {
      case LogType.stdout:
        typeColor = Colors.green;
        typeIcon = Icons.arrow_forward;
        break;
      case LogType.stderr:
        typeColor = Colors.red;
        typeIcon = Icons.error_outline;
        break;
      case LogType.system:
        typeColor = Colors.blue;
        typeIcon = Icons.info_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.formattedTime,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Icon(typeIcon, size: 14, color: typeColor),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              log.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: log.type == LogType.stderr ? Colors.red[700] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 端口冲突对话框内容组件
class _PortConflictContent extends StatefulWidget {
  final String port;
  final HomeController controller;

  const _PortConflictContent({required this.port, required this.controller});

  @override
  State<_PortConflictContent> createState() => _PortConflictContentState();
}

class _PortConflictContentState extends State<_PortConflictContent> {
  String? _processInfo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProcessInfo();
  }

  Future<void> _loadProcessInfo() async {
    final info = await widget.controller.getProcessOnPort(widget.port);
    if (mounted) {
      setState(() {
        _processInfo = info;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('端口 ${widget.port} 已被占用，无法启动核心。'),
        const SizedBox(height: 16),
        const Text('占用进程信息：', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          constraints: const BoxConstraints(maxHeight: 150),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: SelectableText(
                    _processInfo ?? '未知',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        const Text('请选择处理方式：'),
      ],
    );
  }
}
