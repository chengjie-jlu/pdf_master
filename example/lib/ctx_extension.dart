import 'package:flutter/material.dart';
import 'package:pdf_master_example/l10n/app_localizations.dart';

extension ContextExtension on BuildContext {
  AppLocalizations get localizations {
    final appLocalizations = AppLocalizations.of(this);
    if (appLocalizations == null) {
      throw StateError("AppLocalizations Not Initialize Yet.");
    }
    return appLocalizations;
  }
}
