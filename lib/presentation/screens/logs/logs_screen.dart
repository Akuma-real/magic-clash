import 'package:flutter/material.dart';

import '../../../data/models/log_entry.dart';
import '../../../domain/core_manager.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _coreManager = CoreManager();
  final _scrollController = ScrollController();
  bool _autoScroll = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _coreManager.addListener(_onLogsChanged);
  }

  void _onLogsChanged() {
    if (!mounted) return;
    setState(() {});
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  List<LogEntry> get _filteredLogs {
    if (_filter == 'all') return _coreManager.apiLogs;
    return _coreManager.apiLogs.where((l) => l.type == _filter).toList();
  }

  Color _getLogColor(String type) {
    switch (type.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'debug':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _coreManager.removeListener(_onLogsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          DropdownButton<String>(
            value: _filter,
            items: ['all', 'debug', 'info', 'warning', 'error']
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _filter = v);
            },
          ),
          IconButton(
            icon: Icon(_autoScroll ? Icons.lock : Icons.lock_open),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('暂无日志'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '[${log.type}] ',
                          style: TextStyle(
                            color: _getLogColor(log.type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: log.payload),
                      ],
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}
