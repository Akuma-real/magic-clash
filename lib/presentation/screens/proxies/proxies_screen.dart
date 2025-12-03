import 'package:flutter/material.dart';

import '../../../data/models/proxy.dart';
import '../../../data/services/mihomo_api_service.dart';
import '../../../domain/core_manager.dart';

class ProxiesScreen extends StatefulWidget {
  const ProxiesScreen({super.key});

  @override
  State<ProxiesScreen> createState() => _ProxiesScreenState();
}

class _ProxiesScreenState extends State<ProxiesScreen> {
  final _apiService = MihomoApiService(host: '127.0.0.1', port: 9090);
  final _coreManager = CoreManager();
  Map<String, Proxy> _proxies = {};
  final Map<String, int?> _delays = {}; // 存储每个代理的延迟
  final Map<String, bool> _testing = {}; // 存储每个代理的测试状态
  bool _loading = true;
  bool _testingAll = false; // 全局测速状态
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProxies();
  }

  Future<void> _loadProxies() async {
    if (_coreManager.status != CoreStatus.running) {
      setState(() {
        _loading = false;
        _error = '请先启动核心';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _proxies = await _apiService.getProxies();
      // 从已加载的代理中提取延迟信息
      for (final entry in _proxies.entries) {
        if (entry.value.delay != null) {
          _delays[entry.key] = entry.value.delay;
        }
      }
    } catch (e) {
      _error = '连接失败，请确认核心已启动';
    }
    setState(() => _loading = false);
  }

  Future<void> _selectProxy(String group, String name) async {
    try {
      await _apiService.selectProxy(group, name);
      await _loadProxies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('切换失败: $e')));
      }
    }
  }

  Future<void> _testDelay(String name) async {
    setState(() => _testing[name] = true);
    try {
      final delay = await _apiService.delayProxy(name);
      if (mounted) {
        setState(() {
          _delays[name] = delay;
          _testing[name] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _delays[name] = -1; // -1 表示超时
          _testing[name] = false;
        });
      }
    }
  }

  Future<void> _testAllDelays(List<String> proxyNames) async {
    if (_testingAll) return;
    setState(() => _testingAll = true);

    // 并发测速所有代理
    final futures = proxyNames.map((name) async {
      setState(() => _testing[name] = true);
      try {
        final delay = await _apiService.delayProxy(name);
        if (mounted) {
          setState(() {
            _delays[name] = delay;
            _testing[name] = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _delays[name] = -1;
            _testing[name] = false;
          });
        }
      }
    });

    await Future.wait(futures);
    if (mounted) {
      setState(() => _testingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _proxies.values.where((p) => p.isGroup).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('代理'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProxies),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : groups.isEmpty
          ? const Center(child: Text('请先启动核心'))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _ProxyGroupCard(
                  group: group,
                  proxies: _proxies,
                  delays: _delays,
                  testing: _testing,
                  testingAll: _testingAll,
                  onSelect: (name) => _selectProxy(group.name, name),
                  onTest: _testDelay,
                  onTestAll: () {
                    final proxyNames = group.all ?? [];
                    _testAllDelays(proxyNames);
                  },
                );
              },
            ),
    );
  }
}

class _ProxyGroupCard extends StatelessWidget {
  final Proxy group;
  final Map<String, Proxy> proxies;
  final Map<String, int?> delays;
  final Map<String, bool> testing;
  final bool testingAll;
  final void Function(String) onSelect;
  final void Function(String) onTest;
  final VoidCallback onTestAll;

  const _ProxyGroupCard({
    required this.group,
    required this.proxies,
    required this.delays,
    required this.testing,
    required this.testingAll,
    required this.onSelect,
    required this.onTest,
    required this.onTestAll,
  });

  Color _getDelayColor(int delay) {
    if (delay < 0) return Colors.red;
    if (delay < 200) return Colors.green;
    if (delay < 500) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDelayWidget(String name) {
    final isTesting = testing[name] ?? false;
    final delay = delays[name];

    if (isTesting) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (delay != null) {
      if (delay < 0) {
        return Text(
          '超时',
          style: TextStyle(color: _getDelayColor(delay), fontSize: 12),
        );
      }
      return Text(
        '${delay}ms',
        style: TextStyle(
          color: _getDelayColor(delay),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return const Text('--', style: TextStyle(color: Colors.grey, fontSize: 12));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(child: Text(group.name)),
            if (testingAll)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.speed, size: 20),
                tooltip: '测速全部',
                onPressed: onTestAll,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        subtitle: Text(group.now ?? ''),
        children:
            group.all?.map((name) {
              final proxy = proxies[name];
              final isSelected = name == group.now;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.green : null,
                ),
                title: Text(name),
                subtitle: proxy != null && !proxy.isGroup
                    ? Text(proxy.type, style: const TextStyle(fontSize: 12))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDelayWidget(name),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.speed, size: 20),
                      onPressed: (testing[name] ?? false)
                          ? null
                          : () => onTest(name),
                      tooltip: '测速',
                    ),
                  ],
                ),
                onTap: () => onSelect(name),
              );
            }).toList() ??
            [],
      ),
    );
  }
}
