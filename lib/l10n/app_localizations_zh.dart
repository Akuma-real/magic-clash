// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Magic Clash';

  @override
  String get navHome => '主页';

  @override
  String get navProfiles => '配置';

  @override
  String get navSettings => '设置';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusStopped => '已停止';

  @override
  String get actionStart => '启动';

  @override
  String get actionStop => '停止';

  @override
  String get actionDownloadCore => '下载核心';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '删除';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionUpdate => '更新';

  @override
  String get actionAdd => '添加';

  @override
  String get actionDownload => '下载';

  @override
  String get actionCheckUpdate => '检查更新';

  @override
  String get actionShow => '显示';

  @override
  String get actionHide => '隐藏';

  @override
  String get webUi => 'WebUI';

  @override
  String get logsTitle => '进程日志';

  @override
  String get logsEmpty => '暂无日志';

  @override
  String get logsClear => '清空日志';

  @override
  String logsCount(int count) {
    return '$count 条';
  }

  @override
  String get portConflictTitle => '端口被占用';

  @override
  String portConflictMessage(String port) {
    return '端口 $port 已被占用，无法启动核心。';
  }

  @override
  String get portConflictProcessInfo => '占用进程信息：';

  @override
  String get portConflictUnknown => '未知';

  @override
  String get portConflictChoose => '请选择处理方式：';

  @override
  String get portConflictForceRelease => '强制释放并重试';

  @override
  String errorOperationFailed(String error) {
    return '操作失败: $error';
  }

  @override
  String errorDownloadFailed(String error) {
    return '下载失败: $error';
  }

  @override
  String errorAddFailed(String error) {
    return '添加失败: $error';
  }

  @override
  String errorImportFailed(String error) {
    return '导入失败: $error';
  }

  @override
  String errorUpdateFailed(String error) {
    return '更新失败: $error';
  }

  @override
  String errorLoadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String errorSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String errorCheckUpdateFailed(String error) {
    return '检查更新失败: $error';
  }

  @override
  String get errorCannotOpenBrowser => '无法打开浏览器';

  @override
  String get errorDownloadCoreFirst => '请先下载核心';

  @override
  String get errorAddConfigFirst => '请先添加配置文件';

  @override
  String get errorGenerateConfigFailed => '生成运行时配置失败';

  @override
  String get successUpdateComplete => '更新完成';

  @override
  String get successAllUpdateComplete => '全部更新完成';

  @override
  String get successSaved => '保存成功';

  @override
  String get successSecretSaved => 'Secret 已保存';

  @override
  String get successWebUiDownloaded => 'WebUI 下载完成';

  @override
  String get successUpdated => '更新成功';

  @override
  String get profilesTitle => '配置';

  @override
  String get profilesEmpty => '暂无配置';

  @override
  String get profilesUpdateAll => '更新全部订阅';

  @override
  String get profileTypeSubscription => '订阅';

  @override
  String get profileTypeLocal => '本地';

  @override
  String get profileAddFromUrl => '从 URL 添加';

  @override
  String get profileAddFromFile => '从文件导入';

  @override
  String get profileName => '名称';

  @override
  String get profileUrl => 'URL';

  @override
  String get profileDeleteConfirmTitle => '确认删除';

  @override
  String profileDeleteConfirmMessage(String name) {
    return '删除配置 \"$name\"？';
  }

  @override
  String get profileEditTitle => '编辑配置';

  @override
  String get profileEditSubscriptionTitle => '编辑订阅';

  @override
  String get profileNotFound => '配置未找到';

  @override
  String get profileContentPreview => '配置内容预览';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsCoreVersion => '核心版本';

  @override
  String get settingsNotInstalled => '未安装';

  @override
  String settingsNewVersionFound(String version) {
    return '发现新版本: $version';
  }

  @override
  String get settingsUpdateChannel => '更新通道';

  @override
  String get settingsChannelStable => '正式版';

  @override
  String get settingsChannelAlpha => 'Alpha';

  @override
  String get settingsChannelStableDesc => '正式版 (稳定版本)';

  @override
  String get settingsChannelAlphaDesc => 'Alpha (预发布版，可能不稳定)';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsApiSecret => 'API Secret';

  @override
  String settingsApiSecretDefault(String value) {
    return '默认值: $value';
  }

  @override
  String get settingsApiSecretHint => '输入 API Secret';

  @override
  String get settingsWebUi => 'WebUI (Zashboard)';

  @override
  String get settingsAbout => '关于';

  @override
  String settingsAboutVersion(String version) {
    return 'Magic Clash v$version';
  }

  @override
  String get notificationCoreLatest => 'Mihomo 核心已是最新版本';

  @override
  String notificationCoreLatestBody(String version) {
    return '当前版本: $version';
  }

  @override
  String notificationNewVersion(String channel) {
    return 'Mihomo 核心 ($channel版) 有新版本可用，点击查看详情';
  }

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageZh => '简体中文';

  @override
  String get settingsLanguageEn => 'English';
}
