import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_master/src/component/app_bar.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';

class EditToolBar extends StatelessWidget {
  final PdfController controller;

  const EditToolBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _cancelEdit(),
      child: PdfMasterAppBar(
        title: p.basename(controller.path),
        leading: IconButton(onPressed: _cancelEdit, icon: Icon(Icons.close)),
        action: IconButton(onPressed: _saveEdit, icon: Icon(Icons.check)),
      ),
    );
  }

  void _saveEdit() async {
    await controller.save();
    controller.editStateNotifier.value = PdfEditState.kNone;
  }

  void _cancelEdit() async {
    await controller.reload();
    controller.editStateNotifier.value = PdfEditState.kNone;
  }
}
