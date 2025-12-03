import 'package:flutter/material.dart';

import '../../../data/models/config_profile.dart';
import '../../../data/repositories/config_repository.dart';
import '../../../data/services/mihomo_api_service.dart';

class ConfigEditorScreen extends StatefulWidget {
  final String configId;
  const ConfigEditorScreen({super.key, required this.configId});

  @override
  State<ConfigEditorScreen> createState() => _ConfigEditorScreenState();
}

class _ConfigEditorScreenState extends State<ConfigEditorScreen> {
  final _repository = ConfigRepository();
  final _contentController = TextEditingController();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  ConfigProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profiles = await _repository.getProfiles();
      _profile = profiles.where((p) => p.id == widget.configId).firstOrNull;

      if (_profile != null) {
        _nameController.text = _profile!.name;
        if (_profile!.sourceUrl != null) {
          _urlController.text = _profile!.sourceUrl!;
        }

        final content = await _repository.readContent(widget.configId);
        _contentController.text = content;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_profile == null) return;
    setState(() => _saving = true);
    try {
      if (_profile!.isSubscription) {
        await _repository.updateProfile(
          widget.configId,
          name: _nameController.text,
          url: _urlController.text,
        );
      } else {
        await _repository.saveContent(widget.configId, _contentController.text);
      }

      final selectedId = await _repository.getSelectedId();
      if (selectedId == widget.configId) {
        final path = await _repository.getSelectedConfigPath();
        if (path != null) {
          final api = MihomoApiService(host: '127.0.0.1', port: 9090);
          await api.reloadConfig(path);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑配置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑配置')),
        body: const Center(child: Text('配置未找到')),
      );
    }

    final isSubscription = _profile!.isSubscription;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSubscription ? '编辑订阅' : '编辑配置'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: isSubscription ? _buildSubscriptionEditor() : _buildContentEditor(),
    );
  }

  Widget _buildSubscriptionEditor() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('配置内容预览'),
              TextButton(
                onPressed: () {
                  setState(() => _showPreview = !_showPreview);
                },
                child: Text(_showPreview ? '隐藏' : '显示'),
              ),
            ],
          ),
        ),
        if (_showPreview)
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: TextField(
                controller: _contentController,
                readOnly: true,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentEditor() {
    return TextField(
      controller: _contentController,
      maxLines: null,
      expands: true,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }
}
