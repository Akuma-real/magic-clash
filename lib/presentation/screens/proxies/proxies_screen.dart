import 'package:flutter/material.dart';

import '../../../data/models/proxy.dart';
import '../../../data/services/mihomo_api_service.dart';

class ProxiesScreen extends StatefulWidget {
  const ProxiesScreen({super.key});

  @override
  State<ProxiesScreen> createState() => _ProxiesScreenState();
}

class _ProxiesScreenState extends State<ProxiesScreen> {
  final _apiService = MihomoApiService(host: '127.0.0.1', port: 9090);
  Map<String, Proxy> _proxies = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProxies();
  }

  Future<void> _loadProxies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _proxies = await _apiService.getProxies();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  Future<void> _selectProxy(String group, String name) async {
    try {
      await _apiService.selectProxy(group, name);
      await _loadProxies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败: $e')),
        );
      }
    }
  }

  Future<void> _testDelay(String name) async {
    try {
      final delay = await _apiService.delayProxy(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name: ${delay}ms')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name: 超时')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _proxies.values.where((p) => p.isGroup).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('代理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProxies,
          ),
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
                          onSelect: (name) => _selectProxy(group.name, name),
                          onTest: _testDelay,
                        );
                      },
                    ),
    );
  }
}

class _ProxyGroupCard extends StatelessWidget {
  final Proxy group;
  final Map<String, Proxy> proxies;
  final void Function(String) onSelect;
  final void Function(String) onTest;

  const _ProxyGroupCard({
    required this.group,
    required this.proxies,
    required this.onSelect,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(group.name),
        subtitle: Text(group.now ?? ''),
        children: group.all?.map((name) {
              final proxy = proxies[name];
              final isSelected = name == group.now;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.green : null,
                ),
                title: Text(name),
                subtitle: proxy?.delay != null
                    ? Text('${proxy!.delay}ms')
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.speed),
                  onPressed: () => onTest(name),
                ),
                onTap: () => onSelect(name),
              );
            }).toList() ??
            [],
      ),
    );
  }
}
