import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/config_profile.dart';
import '../../../data/repositories/config_repository.dart';
import '../../../data/services/mihomo_api_service.dart';

class ConfigsScreen extends StatefulWidget {
  const ConfigsScreen({super.key});

  @override
  State<ConfigsScreen> createState() => _ConfigsScreenState();
}

class _ConfigsScreenState extends State<ConfigsScreen> {
  final _repository = ConfigRepository();
  List<ConfigProfile> _profiles = [];
  String? _selectedId;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _profiles = await _repository.getProfiles();
    _selectedId = await _repository.getSelectedId();
    setState(() {});
  }

  Future<void> _select(String id) async {
    await _repository.setSelectedId(id);
    _selectedId = id;
    setState(() {});

    final path = await _repository.getSelectedConfigPath();
    if (path != null) {
      try {
        final api = MihomoApiService(host: '127.0.0.1', port: 9090);
        await api.reloadConfig(path);
      } catch (_) {}
    }
  }

  Future<void> _addFromUrl() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('从 URL 添加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (ok == true && urlCtrl.text.isNotEmpty) {
      try {
        await _repository.addFromUrl(
          nameCtrl.text.isEmpty ? 'config' : nameCtrl.text,
          urlCtrl.text,
        );
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('添加失败: $e')));
        }
      }
    }
  }

  Future<void> _addFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final name = file.name.replaceAll(RegExp(r'\.(yaml|yml)$'), '');

    try {
      await _repository.addFromFile(name, file.path!);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  Future<void> _delete(ConfigProfile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除配置 "${profile.name}"？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repository.delete(profile.id);
      await _load();
    }
  }

  Future<void> _updateSubscription(ConfigProfile profile) async {
    try {
      await _repository.updateSubscription(profile.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('更新成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
  }

  Future<void> _updateAll() async {
    setState(() => _updating = true);
    try {
      await _repository.updateAllSubscriptions();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('全部更新完成')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
    setState(() => _updating = false);
  }

  void _edit(ConfigProfile profile) {
    context.push('/configs/edit', extra: profile.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置'),
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _updateAll,
              tooltip: '更新全部订阅',
            ),
        ],
      ),
      body: _profiles.isEmpty
          ? const Center(child: Text('暂无配置'))
          : ListView.builder(
              itemCount: _profiles.length,
              itemBuilder: (ctx, i) {
                final p = _profiles[i];
                final selected = p.id == _selectedId;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? Colors.green : null,
                  ),
                  title: Text(p.name),
                  subtitle: Text(p.isSubscription ? '订阅' : '本地'),
                  onTap: () => _select(p.id),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      if (p.isSubscription)
                        const PopupMenuItem(value: 'update', child: Text('更新')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') _edit(p);
                      if (v == 'update') _updateSubscription(p);
                      if (v == 'delete') _delete(p);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('从 URL 添加'),
                onTap: () {
                  Navigator.pop(context);
                  _addFromUrl();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('从文件导入'),
                onTap: () {
                  Navigator.pop(context);
                  _addFromFile();
                },
              ),
            ],
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
