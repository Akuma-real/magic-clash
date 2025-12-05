import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'data/services/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务定位器
  await ServiceLocator.instance.init();

  if (Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(400, 600));
    await windowManager.setSize(const Size(900, 700));
    await windowManager.setTitle('Magic Clash');
  }

  // 初始化通知服务
  await NotificationService().init();

  runApp(const App());
}
