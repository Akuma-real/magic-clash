import 'package:flutter/foundation.dart';

import '../data/models/proxy.dart';
import '../data/services/api/mihomo_api_service.dart';
import 'core_runner.dart';

class ProxyController extends ChangeNotifier {
  final _apiService = MihomoApiService();
  final _coreRunner = CoreRunner();

  Map<String, Proxy> proxies = {};
  final Map<String, int?> delays = {};
  final Map<String, bool> testing = {};
  bool loading = true;
  bool testingAll = false;
  String? error;

  Future<void> loadProxies() async {
    if (_coreRunner.status != CoreStatus.running) {
      loading = false;
      error = '请先启动核心';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      proxies = await _apiService.getProxies();
      for (final entry in proxies.entries) {
        if (entry.value.delay != null) {
          delays[entry.key] = entry.value.delay;
        }
      }
    } catch (e) {
      error = '连接失败，请确认核心已启动';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> selectProxy(String group, String name) async {
    await _apiService.selectProxy(group, name);
    await loadProxies();
  }

  Future<void> testDelay(String name) async {
    testing[name] = true;
    notifyListeners();
    try {
      final delay = await _apiService.delayProxy(name);
      delays[name] = delay;
    } catch (e) {
      delays[name] = -1;
    }
    testing[name] = false;
    notifyListeners();
  }

  Future<void> testAllDelays(List<String> proxyNames) async {
    if (testingAll) return;
    testingAll = true;
    notifyListeners();

    final futures = proxyNames.map((name) async {
      testing[name] = true;
      notifyListeners();
      try {
        final delay = await _apiService.delayProxy(name);
        delays[name] = delay;
      } catch (e) {
        delays[name] = -1;
      }
      testing[name] = false;
      notifyListeners();
    });

    await Future.wait(futures);
    testingAll = false;
    notifyListeners();
  }

  List<Proxy> get groups => proxies.values.where((p) => p.isGroup).toList();
}
