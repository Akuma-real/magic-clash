import 'package:flutter/material.dart';

import '../../../data/models/proxy.dart';
import '../../../logic/proxy_controller.dart';

class ProxyScreen extends StatefulWidget {
  const ProxyScreen({super.key});

  @override
  State<ProxyScreen> createState() => _ProxyScreenState();
}

class _ProxyScreenState extends State<ProxyScreen> {
  final _controller = ProxyController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.loadProxies();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _selectProxy(String group, String name) async {
    try {
      await _controller.selectProxy(group, name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('切换失败: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _controller.groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('代理'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _controller.loadProxies),
        ],
      ),
      body: _controller.loading
          ? const Center(child: CircularProgressIndicator())
          : _controller.error != null
              ? Center(child: Text(_controller.error!))
              : groups.isEmpty
                  ? const Center(child: Text('请先启动核心'))
                  : ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return _ProxyGroupCard(
                          group: group,
                          proxies: _controller.proxies,
                          delays: _controller.delays,
                          testing: _controller.testing,
                          testingAll: _controller.testingAll,
                          onSelect: (name) => _selectProxy(group.name, name),
                          onTest: _controller.testDelay,
                          onTestAll: () =>
                              _controller.testAllDelays(group.all ?? []),
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
        return Text('超时',
            style: TextStyle(color: _getDelayColor(delay), fontSize: 12));
      }
      return Text('${delay}ms',
          style: TextStyle(
              color: _getDelayColor(delay),
              fontSize: 12,
              fontWeight: FontWeight.w500));
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
        children: group.all?.map((name) {
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
                      onPressed:
                          (testing[name] ?? false) ? null : () => onTest(name),
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
