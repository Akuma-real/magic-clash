import 'package:dio/dio.dart';

import '../../data/repositories/core_status_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/webui_repository.dart';
import '../../data/services/api/mihomo_api_service.dart';
import '../../data/services/local_storage/preferences_service.dart';
import '../../data/services/native/platform_interface.dart';

/// 服务定位器 - 简单的依赖注入容器
///
/// 使用方式：
/// 1. 在 main.dart 中调用 ServiceLocator.init()
/// 2. 通过 ServiceLocator.instance.xxx 获取依赖
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  /// 是否已初始化
  bool _initialized = false;

  // ===== 基础服务 =====
  late final Dio dio;
  late final PreferencesService preferencesService;
  late final PlatformInterface platformInterface;

  // ===== API 服务 =====
  late final MihomoApiService mihomoApiService;

  // ===== 数据仓库 =====
  late final CoreStatusRepository coreStatusRepository;
  late final ProfileRepository profileRepository;
  late final WebUiRepository webUiRepository;

  /// 初始化所有依赖
  ///
  /// 必须在 runApp() 之前调用
  Future<void> init() async {
    if (_initialized) return;

    // 基础服务
    dio = Dio();
    preferencesService = PreferencesService();
    platformInterface = PlatformInterface.instance;

    // API 服务
    final secret = await preferencesService.getSecret();
    mihomoApiService = MihomoApiService(secret: secret);

    // 数据仓库（注入依赖）
    coreStatusRepository = CoreStatusRepository(dio: dio);
    profileRepository = ProfileRepository(
      dio: dio,
      preferencesService: preferencesService,
      platformInterface: platformInterface,
    );
    webUiRepository = WebUiRepository(
      dio: dio,
      preferencesService: preferencesService,
      platformInterface: platformInterface,
    );

    _initialized = true;
  }

  /// 重置（仅用于测试）
  void reset() {
    _initialized = false;
  }
}

/// 便捷访问器
ServiceLocator get sl => ServiceLocator.instance;
