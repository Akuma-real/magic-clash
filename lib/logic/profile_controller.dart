import 'package:flutter/foundation.dart';

import '../data/models/config_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/api/mihomo_api_service.dart';

class ProfileController extends ChangeNotifier {
  final _repository = ProfileRepository();
  final _apiService = MihomoApiService();

  List<ConfigProfile> profiles = [];
  String? selectedId;
  bool updating = false;

  Future<void> load() async {
    profiles = await _repository.getProfiles();
    selectedId = await _repository.getSelectedId();
    notifyListeners();
  }

  Future<void> select(String id) async {
    await _repository.setSelectedId(id);
    selectedId = id;
    notifyListeners();

    final path = await _repository.getSelectedConfigPath();
    if (path != null) {
      try {
        await _apiService.reloadConfig(path);
      } catch (_) {}
    }
  }

  Future<void> addFromUrl(String name, String url) async {
    await _repository.addFromUrl(
      name.isEmpty ? 'config' : name,
      url,
    );
    await load();
  }

  Future<void> addFromFile(String name, String path) async {
    await _repository.addFromFile(name, path);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> updateSubscription(String id) async {
    await _repository.updateSubscription(id);
    await load();
  }

  Future<void> updateAll() async {
    updating = true;
    notifyListeners();
    try {
      await _repository.updateAllSubscriptions();
      await load();
    } finally {
      updating = false;
      notifyListeners();
    }
  }

  Future<String> readContent(String id) => _repository.readContent(id);

  Future<void> saveContent(String id, String content) async {
    await _repository.saveContent(id, content);
    await load();
  }
}
