import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用标题
  ///
  /// In zh, this message translates to:
  /// **'Magic Clash'**
  String get appTitle;

  /// 导航-主页
  ///
  /// In zh, this message translates to:
  /// **'主页'**
  String get navHome;

  /// 导航-配置
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get navProfiles;

  /// 导航-设置
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// 核心状态-运行中
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get statusRunning;

  /// 核心状态-已停止
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get statusStopped;

  /// 操作-启动
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get actionStart;

  /// 操作-停止
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get actionStop;

  /// 操作-下载核心
  ///
  /// In zh, this message translates to:
  /// **'下载核心'**
  String get actionDownloadCore;

  /// 操作-取消
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get actionCancel;

  /// 操作-保存
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get actionSave;

  /// 操作-删除
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get actionDelete;

  /// 操作-编辑
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get actionEdit;

  /// 操作-更新
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get actionUpdate;

  /// 操作-添加
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get actionAdd;

  /// 操作-下载
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get actionDownload;

  /// 操作-检查更新
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get actionCheckUpdate;

  /// 操作-显示
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get actionShow;

  /// 操作-隐藏
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get actionHide;

  /// WebUI
  ///
  /// In zh, this message translates to:
  /// **'WebUI'**
  String get webUi;

  /// 日志标题
  ///
  /// In zh, this message translates to:
  /// **'进程日志'**
  String get logsTitle;

  /// 无日志提示
  ///
  /// In zh, this message translates to:
  /// **'暂无日志'**
  String get logsEmpty;

  /// 清空日志
  ///
  /// In zh, this message translates to:
  /// **'清空日志'**
  String get logsClear;

  /// 日志条数
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String logsCount(int count);

  /// 端口冲突对话框标题
  ///
  /// In zh, this message translates to:
  /// **'端口被占用'**
  String get portConflictTitle;

  /// 端口冲突消息
  ///
  /// In zh, this message translates to:
  /// **'端口 {port} 已被占用，无法启动核心。'**
  String portConflictMessage(String port);

  /// 占用进程信息
  ///
  /// In zh, this message translates to:
  /// **'占用进程信息：'**
  String get portConflictProcessInfo;

  /// 未知进程
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get portConflictUnknown;

  /// 选择处理方式
  ///
  /// In zh, this message translates to:
  /// **'请选择处理方式：'**
  String get portConflictChoose;

  /// 强制释放端口并重试
  ///
  /// In zh, this message translates to:
  /// **'强制释放并重试'**
  String get portConflictForceRelease;

  /// 操作失败错误
  ///
  /// In zh, this message translates to:
  /// **'操作失败: {error}'**
  String errorOperationFailed(String error);

  /// 下载失败错误
  ///
  /// In zh, this message translates to:
  /// **'下载失败: {error}'**
  String errorDownloadFailed(String error);

  /// 添加失败错误
  ///
  /// In zh, this message translates to:
  /// **'添加失败: {error}'**
  String errorAddFailed(String error);

  /// 导入失败错误
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String errorImportFailed(String error);

  /// 更新失败错误
  ///
  /// In zh, this message translates to:
  /// **'更新失败: {error}'**
  String errorUpdateFailed(String error);

  /// 加载失败错误
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {error}'**
  String errorLoadFailed(String error);

  /// 保存失败错误
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String errorSaveFailed(String error);

  /// 检查更新失败错误
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败: {error}'**
  String errorCheckUpdateFailed(String error);

  /// 无法打开浏览器
  ///
  /// In zh, this message translates to:
  /// **'无法打开浏览器'**
  String get errorCannotOpenBrowser;

  /// 需要先下载核心
  ///
  /// In zh, this message translates to:
  /// **'请先下载核心'**
  String get errorDownloadCoreFirst;

  /// 需要先添加配置
  ///
  /// In zh, this message translates to:
  /// **'请先添加配置文件'**
  String get errorAddConfigFirst;

  /// 生成配置失败
  ///
  /// In zh, this message translates to:
  /// **'生成运行时配置失败'**
  String get errorGenerateConfigFailed;

  /// 更新完成
  ///
  /// In zh, this message translates to:
  /// **'更新完成'**
  String get successUpdateComplete;

  /// 全部更新完成
  ///
  /// In zh, this message translates to:
  /// **'全部更新完成'**
  String get successAllUpdateComplete;

  /// 保存成功
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get successSaved;

  /// Secret已保存
  ///
  /// In zh, this message translates to:
  /// **'Secret 已保存'**
  String get successSecretSaved;

  /// WebUI下载完成
  ///
  /// In zh, this message translates to:
  /// **'WebUI 下载完成'**
  String get successWebUiDownloaded;

  /// 更新成功
  ///
  /// In zh, this message translates to:
  /// **'更新成功'**
  String get successUpdated;

  /// 配置页面标题
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get profilesTitle;

  /// 无配置提示
  ///
  /// In zh, this message translates to:
  /// **'暂无配置'**
  String get profilesEmpty;

  /// 更新全部订阅
  ///
  /// In zh, this message translates to:
  /// **'更新全部订阅'**
  String get profilesUpdateAll;

  /// 订阅类型
  ///
  /// In zh, this message translates to:
  /// **'订阅'**
  String get profileTypeSubscription;

  /// 本地类型
  ///
  /// In zh, this message translates to:
  /// **'本地'**
  String get profileTypeLocal;

  /// 从URL添加
  ///
  /// In zh, this message translates to:
  /// **'从 URL 添加'**
  String get profileAddFromUrl;

  /// 从文件导入
  ///
  /// In zh, this message translates to:
  /// **'从文件导入'**
  String get profileAddFromFile;

  /// 配置名称
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get profileName;

  /// 配置URL
  ///
  /// In zh, this message translates to:
  /// **'URL'**
  String get profileUrl;

  /// 删除确认标题
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get profileDeleteConfirmTitle;

  /// 删除确认消息
  ///
  /// In zh, this message translates to:
  /// **'删除配置 \"{name}\"？'**
  String profileDeleteConfirmMessage(String name);

  /// 编辑配置标题
  ///
  /// In zh, this message translates to:
  /// **'编辑配置'**
  String get profileEditTitle;

  /// 编辑订阅标题
  ///
  /// In zh, this message translates to:
  /// **'编辑订阅'**
  String get profileEditSubscriptionTitle;

  /// 配置未找到
  ///
  /// In zh, this message translates to:
  /// **'配置未找到'**
  String get profileNotFound;

  /// 配置内容预览
  ///
  /// In zh, this message translates to:
  /// **'配置内容预览'**
  String get profileContentPreview;

  /// 设置页面标题
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// 核心版本
  ///
  /// In zh, this message translates to:
  /// **'核心版本'**
  String get settingsCoreVersion;

  /// 未安装
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get settingsNotInstalled;

  /// 发现新版本
  ///
  /// In zh, this message translates to:
  /// **'发现新版本: {version}'**
  String settingsNewVersionFound(String version);

  /// 更新通道
  ///
  /// In zh, this message translates to:
  /// **'更新通道'**
  String get settingsUpdateChannel;

  /// 正式版通道
  ///
  /// In zh, this message translates to:
  /// **'正式版'**
  String get settingsChannelStable;

  /// Alpha通道
  ///
  /// In zh, this message translates to:
  /// **'Alpha'**
  String get settingsChannelAlpha;

  /// 正式版描述
  ///
  /// In zh, this message translates to:
  /// **'正式版 (稳定版本)'**
  String get settingsChannelStableDesc;

  /// Alpha版描述
  ///
  /// In zh, this message translates to:
  /// **'Alpha (预发布版，可能不稳定)'**
  String get settingsChannelAlphaDesc;

  /// 主题
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get settingsTheme;

  /// 跟随系统
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsThemeSystem;

  /// 浅色主题
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get settingsThemeLight;

  /// 深色主题
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settingsThemeDark;

  /// API Secret
  ///
  /// In zh, this message translates to:
  /// **'API Secret'**
  String get settingsApiSecret;

  /// 默认Secret值
  ///
  /// In zh, this message translates to:
  /// **'默认值: {value}'**
  String settingsApiSecretDefault(String value);

  /// 输入Secret提示
  ///
  /// In zh, this message translates to:
  /// **'输入 API Secret'**
  String get settingsApiSecretHint;

  /// WebUI设置
  ///
  /// In zh, this message translates to:
  /// **'WebUI (Zashboard)'**
  String get settingsWebUi;

  /// 关于
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// 应用版本
  ///
  /// In zh, this message translates to:
  /// **'Magic Clash v{version}'**
  String settingsAboutVersion(String version);

  /// 核心已最新通知
  ///
  /// In zh, this message translates to:
  /// **'Mihomo 核心已是最新版本'**
  String get notificationCoreLatest;

  /// 当前版本通知内容
  ///
  /// In zh, this message translates to:
  /// **'当前版本: {version}'**
  String notificationCoreLatestBody(String version);

  /// 新版本通知
  ///
  /// In zh, this message translates to:
  /// **'Mihomo 核心 ({channel}版) 有新版本可用，点击查看详情'**
  String notificationNewVersion(String channel);

  /// 语言设置
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// 跟随系统语言
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsLanguageSystem;

  /// 简体中文
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get settingsLanguageZh;

  /// 英语
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
