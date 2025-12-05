// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Magic Clash';

  @override
  String get navHome => 'Home';

  @override
  String get navProfiles => 'Profiles';

  @override
  String get navSettings => 'Settings';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get actionStart => 'Start';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionDownloadCore => 'Download Core';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionUpdate => 'Update';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionCheckUpdate => 'Check Update';

  @override
  String get actionShow => 'Show';

  @override
  String get actionHide => 'Hide';

  @override
  String get webUi => 'WebUI';

  @override
  String get logsTitle => 'Process Logs';

  @override
  String get logsEmpty => 'No logs';

  @override
  String get logsClear => 'Clear logs';

  @override
  String logsCount(int count) {
    return '$count entries';
  }

  @override
  String get portConflictTitle => 'Port Occupied';

  @override
  String portConflictMessage(String port) {
    return 'Port $port is occupied, cannot start core.';
  }

  @override
  String get portConflictProcessInfo => 'Process info:';

  @override
  String get portConflictUnknown => 'Unknown';

  @override
  String get portConflictChoose => 'Please choose an action:';

  @override
  String get portConflictForceRelease => 'Force release and retry';

  @override
  String errorOperationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String errorDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String errorAddFailed(String error) {
    return 'Add failed: $error';
  }

  @override
  String errorImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String errorUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String errorLoadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String errorSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String errorCheckUpdateFailed(String error) {
    return 'Check update failed: $error';
  }

  @override
  String get errorCannotOpenBrowser => 'Cannot open browser';

  @override
  String get errorDownloadCoreFirst => 'Please download core first';

  @override
  String get errorAddConfigFirst => 'Please add a config file first';

  @override
  String get errorGenerateConfigFailed => 'Failed to generate runtime config';

  @override
  String get successUpdateComplete => 'Update complete';

  @override
  String get successAllUpdateComplete => 'All updates complete';

  @override
  String get successSaved => 'Saved';

  @override
  String get successSecretSaved => 'Secret saved';

  @override
  String get successWebUiDownloaded => 'WebUI downloaded';

  @override
  String get successUpdated => 'Updated';

  @override
  String get profilesTitle => 'Profiles';

  @override
  String get profilesEmpty => 'No profiles';

  @override
  String get profilesUpdateAll => 'Update all subscriptions';

  @override
  String get profileTypeSubscription => 'Subscription';

  @override
  String get profileTypeLocal => 'Local';

  @override
  String get profileAddFromUrl => 'Add from URL';

  @override
  String get profileAddFromFile => 'Import from file';

  @override
  String get profileName => 'Name';

  @override
  String get profileUrl => 'URL';

  @override
  String get profileDeleteConfirmTitle => 'Confirm Delete';

  @override
  String profileDeleteConfirmMessage(String name) {
    return 'Delete profile \"$name\"?';
  }

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditSubscriptionTitle => 'Edit Subscription';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get profileContentPreview => 'Config content preview';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsCoreVersion => 'Core Version';

  @override
  String get settingsNotInstalled => 'Not installed';

  @override
  String settingsNewVersionFound(String version) {
    return 'New version: $version';
  }

  @override
  String get settingsUpdateChannel => 'Update Channel';

  @override
  String get settingsChannelStable => 'Stable';

  @override
  String get settingsChannelAlpha => 'Alpha';

  @override
  String get settingsChannelStableDesc => 'Stable (Recommended)';

  @override
  String get settingsChannelAlphaDesc => 'Alpha (Pre-release, may be unstable)';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsApiSecret => 'API Secret';

  @override
  String settingsApiSecretDefault(String value) {
    return 'Default: $value';
  }

  @override
  String get settingsApiSecretHint => 'Enter API Secret';

  @override
  String get settingsWebUi => 'WebUI (Zashboard)';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsAboutVersion(String version) {
    return 'Magic Clash v$version';
  }

  @override
  String get notificationCoreLatest => 'Mihomo core is up to date';

  @override
  String notificationCoreLatestBody(String version) {
    return 'Current version: $version';
  }

  @override
  String notificationNewVersion(String channel) {
    return 'Mihomo core ($channel) has a new version available, click for details';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Follow System';

  @override
  String get settingsLanguageZh => '简体中文';

  @override
  String get settingsLanguageEn => 'English';
}
