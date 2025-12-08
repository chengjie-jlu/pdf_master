// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'PDF大师';

  @override
  String get settings => '设置';

  @override
  String get noFilesHint => '点击加号按钮以选择一个 PDF 文件打开';

  @override
  String get darkMode => '深色模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get fileExists => '文件已存在';

  @override
  String get fileExistsMessage => '该文件已存在，是否要覆盖原文件？';

  @override
  String get cancel => '取消';

  @override
  String get overwrite => '覆盖';

  @override
  String get pickFile => '选择文件';

  @override
  String get delete => '删除';

  @override
  String get share => '分享';

  @override
  String get deleteConfirm => '确认删除?';

  @override
  String get sortByName => '按名称排序';

  @override
  String get sortByTime => '按时间排序';

  @override
  String get sortBySize => '按大小排序';

  @override
  String get editFiles => '编辑文件';

  @override
  String get deleteWaring => '此操作无法撤销';

  @override
  String get openSource => '开放源代码协议';

  @override
  String get immersiveMode => '沉浸模式';
}
