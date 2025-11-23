import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

String getMd5(String str) {
  return md5.convert(utf8.encode(str)).toString();
}

/// 计算文件内容的MD5值
Future<String> getFileMd5(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  return md5.convert(bytes).toString();
}