export 'package:pdf_master/src/pdf/pdf_item_view.dart' show PdfItemView, PdfCoverView;
export 'package:pdf_master/src/pdf/pdf_viewer_page.dart' show PDFViewerPage;

export 'package:pdf_master/src/component/alert_dialog.dart';
export 'package:pdf_master/src/component/page_router.dart';
export 'package:pdf_master/src/component/app_bar.dart';
export 'package:pdf_master/src/pdf/features/features.dart' show AdvancedFeature;

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_master/src/worker/worker.dart';

final _instance = PdfMaster._();

/// called when user need to share the pdf file by path
abstract class ShareHandler {
  Future<void> handleSharePdfFile(String path);
}

/// handle when use save images
abstract class ImageSaveHandler {
  /// [bytes] image file int bytes
  /// [current] current image file index
  /// [total] total image file count
  Future<void> handleSavePngBytes(Uint8List bytes, {int current = 1, int total = 1});
}

abstract class FilePickerHandler {
  /// open a file picker then return a pdf file.
  Future<String?> pickPdfFile(BuildContext context);
}

abstract class WorkSpaceProvider {
  /// workspace to save output file.
  Future<String> getWorkSpaceDirPath();
}

abstract class LocalizationProvider {
  String operator [](String key);
}

class _DefaultLocalizationProvider implements LocalizationProvider {
  Map<String, Map<String, String>> _allLocalizations = {};

  Future<void> _loadLocalizations() async {
    try {
      final jsonString = await rootBundle.loadString('packages/pdf_master/assets/l10n.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      for (var entry in jsonData.entries) {
        final languageCode = entry.key;
        final localeData = entry.value as Map<String, dynamic>;
        _allLocalizations[languageCode] = localeData.map<String, String>(
              (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } catch (e) {
      debugPrint('Failed to load localizations: $e');
      _allLocalizations = {};
    }
  }

  @override
  String operator [](String key) {
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;
    return _allLocalizations[languageCode]?[key] ?? _allLocalizations['en']?[key] ?? key;
  }
}

class PdfMasterThemeConfig {
  final Color appBarBackgroundColor;
  final Color shadowColor;
  final Color iconColor;
  final Color textColor;
  final Brightness brightness;

  const PdfMasterThemeConfig({
    required this.appBarBackgroundColor,
    required this.shadowColor,
    required this.iconColor,
    required this.textColor,
    required this.brightness,
  });

  /// default light theme data
  static const PdfMasterThemeConfig defaultLight = PdfMasterThemeConfig(
    appBarBackgroundColor: Colors.white,
    shadowColor: Color(0x19000000),
    iconColor: Colors.black,
    textColor: Colors.black,
    brightness: Brightness.light,
  );

  /// default dark theme data
  static const PdfMasterThemeConfig defaultDark = PdfMasterThemeConfig(
    appBarBackgroundColor: Colors.black,
    shadowColor: Color(0x19FFFFFF),
    iconColor: Colors.white,
    textColor: Colors.white,
    brightness: Brightness.dark,
  );

  bool get isDark => brightness == Brightness.dark;

  PdfMasterThemeConfig copyWith({
    Color? appBarBackgroundColor,
    Color? shadowColor,
    Color? iconColor,
    Color? textColor,
    Brightness? brightness,
  }) {
    return PdfMasterThemeConfig(
      appBarBackgroundColor: appBarBackgroundColor ?? this.appBarBackgroundColor,
      shadowColor: shadowColor ?? this.shadowColor,
      iconColor: iconColor ?? this.iconColor,
      textColor: textColor ?? this.textColor,
      brightness: brightness ?? this.brightness,
    );
  }
}

class PdfMaster {
  PdfMaster._();

  ShareHandler? shareHandler;
  ImageSaveHandler? imageSaveHandler;
  FilePickerHandler? filePickerHandler;
  WorkSpaceProvider? fileSaveHandler;

  late LocalizationProvider localizationProvider;
  PdfMasterThemeConfig? _themeConfig;

  static PdfMaster get instance => _instance;

  ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

  /// 初始化渲染工作器
  Future<void> initRenderWorker() async {
    await pdfRenderWorker.init();
    final localizationProvider = _DefaultLocalizationProvider();
    localizationProvider._loadLocalizations();
    this.localizationProvider = localizationProvider;
  }

  PdfMasterThemeConfig get themeConfig {
    if (_themeConfig != null) {
      return _themeConfig!;
    }
    return darkModeNotifier.value ? PdfMasterThemeConfig.defaultDark : PdfMasterThemeConfig.defaultLight;
  }

  set themeConfig(PdfMasterThemeConfig? config) {
    _themeConfig = config;
  }
}