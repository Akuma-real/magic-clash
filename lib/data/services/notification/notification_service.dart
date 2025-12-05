import 'dart:io';

import 'package:local_notifier/local_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

/// 系统通知服务
/// 封装 local_notifier，提供跨平台的系统级通知功能
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  /// 初始化通知服务
  Future<void> init() async {
    if (_initialized) return;

    // 仅在桌面平台初始化
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await localNotifier.setup(
        appName: 'Magic Clash',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _initialized = true;
    }
  }

  /// 显示简单通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? actionUrl,
  }) async {
    if (!_initialized) {
      await init();
    }

    final notification = LocalNotification(title: title, body: body);

    // 设置点击回调
    if (actionUrl != null) {
      notification.onShow = () {
        // 通知显示时的回调
      };
      notification.onClick = () {
        // 点击通知时打开链接
        _openUrl(actionUrl);
      };
    }

    notification.show();
  }

  /// 显示更新可用通知
  Future<void> showUpdateNotification({
    required String newVersion,
    required String releaseUrl,
    String? changelog,
  }) async {
    final body = changelog != null && changelog.isNotEmpty
        ? '新版本 $newVersion 已发布\n$changelog'
        : '新版本 $newVersion 已发布，点击查看详情';

    await showNotification(
      title: 'Magic Clash 有新版本可用',
      body: body,
      actionUrl: releaseUrl,
    );
  }

  /// 打开 URL
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 关闭所有通知
  Future<void> closeAll() async {
    // local_notifier 不需要显式关闭
  }
}
