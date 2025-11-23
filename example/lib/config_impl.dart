import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/pages/picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class PdfMasterConfigImpl implements ShareHandler, ImageSaveHandler, FilePickerHandler, WorkSpaceProvider {
  @override
  Future<void> handleSavePngBytes(Uint8List bytes, {int current = 1, int total = 1}) async {
    await Gal.putImageBytes(bytes);
    if (current == total) {
      Gal.open();
    }
  }

  @override
  Future<void> handleSharePdfFile(String path) async {
    final params = ShareParams(text: p.basename(path), files: [XFile(path)]);
    SharePlus.instance.share(params);
  }

  @override
  Future<String?> pickPdfFile(BuildContext context) async {
    return Navigator.push(context, PDFMasterPageRouter(builder: (ctx) => FilePickerPage()));
  }

  @override
  Future<String> getWorkSpaceDirPath() async {
    final dir = await getApplicationCacheDirectory();
    return dir.path;
  }
}
