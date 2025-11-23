import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';

extension ContextExtension on BuildContext {
  LocalizationProvider get localizations => PdfMaster.instance.localizationProvider;

  PdfMasterThemeConfig get pdfTheme => PdfMaster.instance.themeConfig;
}
