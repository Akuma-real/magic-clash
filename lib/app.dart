import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'l10n/app_localizations.dart';
import 'presentation/common/app_providers.dart';
import 'presentation/router.dart';
import 'presentation/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  static AppState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppState>();

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = sl.preferencesService;
    final mode = await prefs.getThemeMode();
    final localeCode = await prefs.getLocale();
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
      _locale = localeCode != null ? Locale(localeCode) : null;
    });
  }

  void setLocale(Locale? locale) {
    setState(() => _locale = locale);
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return AppProvidersScope(
      child: MaterialApp.router(
        title: 'Magic Clash',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        locale: _locale,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
