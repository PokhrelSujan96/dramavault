import 'package:dramabyte_app/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:dramabyte_app/l10n/generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
