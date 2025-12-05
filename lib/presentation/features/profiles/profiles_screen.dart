import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/config_profile.dart';
import '../../../l10n/l10n_extensions.dart';
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
        title: Text(context.l10n.profileAddFromUrl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: context.l10n.profileName),
            ),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(labelText: context.l10n.profileUrl),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.actionAdd),
          ),
        ],
      ),
    );

    if (ok == true && urlCtrl.text.isNotEmpty) {
      try {
        await _controller.addFromUrl(nameCtrl.text, urlCtrl.text);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorAddFailed(e.toString()))),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorImportFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _delete(ConfigProfile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.profileDeleteConfirmTitle),
        content: Text(context.l10n.profileDeleteConfirmMessage(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.actionDelete),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.successUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorUpdateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateAll() async {
    try {
      await _controller.updateAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.successAllUpdateComplete)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorUpdateFailed(e.toString()))),
        );
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
        title: Text(context.l10n.profilesTitle),
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
              tooltip: context.l10n.profilesUpdateAll,
            ),
        ],
      ),
      body: _controller.profiles.isEmpty
          ? Center(child: Text(context.l10n.profilesEmpty))
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
                  subtitle: Text(
                    p.isSubscription
                        ? context.l10n.profileTypeSubscription
                        : context.l10n.profileTypeLocal,
                  ),
                  onTap: () => _controller.select(p.id),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(context.l10n.actionEdit),
                      ),
                      if (p.isSubscription)
                        PopupMenuItem(
                          value: 'update',
                          child: Text(context.l10n.actionUpdate),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.l10n.actionDelete),
                      ),
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
                title: Text(context.l10n.profileAddFromUrl),
                onTap: () {
                  Navigator.pop(context);
                  _addFromUrl();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: Text(context.l10n.profileAddFromFile),
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
