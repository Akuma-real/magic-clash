import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Extension on [BuildContext] for easy access to [AppLocalizations].
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
