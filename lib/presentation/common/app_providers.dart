import 'package:flutter/material.dart';

import '../../logic/core_controller.dart';
import '../../logic/home_controller.dart';
import '../../logic/profile_controller.dart';
import '../../logic/webui_controller.dart';

/// 应用级 Controller 提供者
///
/// 在 Widget 树顶层（MainShell）提供 Controller 实例，
/// 子组件通过 AppProviders.of(context) 获取
class AppProviders extends InheritedWidget {
  final HomeController homeController;
  final ProfileController profileController;

  // 暴露子 Controller 以便直接访问
  CoreController get coreController => homeController.coreController;
  WebUiController get webUiController => homeController.webUiController;

  const AppProviders({
    super.key,
    required this.homeController,
    required this.profileController,
    required super.child,
  });

  /// 获取最近的 AppProviders 实例
  static AppProviders of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppProviders>();
    assert(result != null, 'No AppProviders found in context');
    return result!;
  }

  /// 尝试获取 AppProviders，不存在时返回 null
  static AppProviders? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppProviders>();
  }

  @override
  bool updateShouldNotify(AppProviders oldWidget) {
    return homeController != oldWidget.homeController ||
        profileController != oldWidget.profileController;
  }
}

/// AppProviders 的 StatefulWidget 包装器
///
/// 负责创建和销毁 Controller 实例
class AppProvidersScope extends StatefulWidget {
  final Widget child;

  const AppProvidersScope({super.key, required this.child});

  @override
  State<AppProvidersScope> createState() => _AppProvidersScopeState();
}

class _AppProvidersScopeState extends State<AppProvidersScope> {
  late final HomeController _homeController;
  late final ProfileController _profileController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    _profileController = ProfileController();
    _initialize();
  }

  Future<void> _initialize() async {
    await _homeController.init();
    await _profileController.load();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _homeController.dispose();
    // ProfileController 没有需要特别清理的资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AppProviders(
      homeController: _homeController,
      profileController: _profileController,
      child: widget.child,
    );
  }
}
