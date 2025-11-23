// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PDFMaster';

  @override
  String get settings => 'Settings';

  @override
  String get noFilesHint =>
      'Click the plus button to choose a PDF file to open';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get followSystem => 'Follow System';

  @override
  String get fileExists => 'File Exists';

  @override
  String get fileExistsMessage =>
      'This file already exists. Do you want to overwrite it?';

  @override
  String get cancel => 'Cancel';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get pickFile => 'Pick File';

  @override
  String get delete => 'Delete';

  @override
  String get share => 'Share';

  @override
  String get deleteConfirm => 'Confirm Deletion?';

  @override
  String get sortByName => 'Sort By Name';

  @override
  String get sortByTime => 'Sort By Time';

  @override
  String get sortBySize => 'Sort By Size';

  @override
  String get editFiles => 'Edit Files';

  @override
  String get deleteWaring => 'This action cannot be undone';

  @override
  String get openSource => 'Open Code Source License';
}
