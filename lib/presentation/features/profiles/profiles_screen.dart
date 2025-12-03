import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/config_profile.dart';
import '../../../logic/profile_controller.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final _controller = ProfileController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.load();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
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
        await _controller.addFromUrl(nameCtrl.text, urlCtrl.text);
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
      await _controller.addFromFile(name, file.path!);
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
    if (ok == true) await _controller.delete(profile.id);
  }

  Future<void> _updateSubscription(ConfigProfile profile) async {
    try {
      await _controller.updateSubscription(profile.id);
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
    try {
      await _controller.updateAll();
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
  }

  void _edit(ConfigProfile profile) {
    context.push('/profiles/edit', extra: profile.id);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置'),
        actions: [
          if (_controller.updating)
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
      body: _controller.profiles.isEmpty
          ? const Center(child: Text('暂无配置'))
          : ListView.builder(
              itemCount: _controller.profiles.length,
              itemBuilder: (ctx, i) {
                final p = _controller.profiles[i];
                final selected = p.id == _controller.selectedId;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? Colors.green : null,
                  ),
                  title: Text(p.name),
                  subtitle: Text(p.isSubscription ? '订阅' : '本地'),
                  onTap: () => _controller.select(p.id),
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
