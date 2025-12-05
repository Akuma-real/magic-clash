import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/models/config_profile.dart';
import '../../../l10n/l10n_extensions.dart';

class ProfileEditorScreen extends StatefulWidget {
  final String configId;
  const ProfileEditorScreen({super.key, required this.configId});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _repository = sl.profileRepository;
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
          await sl.mihomoApiService.reloadConfig(path);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.successSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorSaveFailed(e.toString()))),
        );
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
        appBar: AppBar(title: Text(context.l10n.profileEditTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profileEditTitle)),
        body: Center(child: Text(context.l10n.profileNotFound)),
      );
    }

    final isSubscription = _profile!.isSubscription;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSubscription
              ? context.l10n.profileEditSubscriptionTitle
              : context.l10n.profileEditTitle,
        ),
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
                decoration: InputDecoration(
                  labelText: context.l10n.profileName,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(labelText: context.l10n.profileUrl),
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
              Text(context.l10n.profileContentPreview),
              TextButton(
                onPressed: () => setState(() => _showPreview = !_showPreview),
                child: Text(
                  _showPreview
                      ? context.l10n.actionHide
                      : context.l10n.actionShow,
                ),
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
