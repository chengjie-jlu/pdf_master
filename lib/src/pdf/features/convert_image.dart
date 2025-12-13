import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

class PageSelector extends StatefulWidget {
  final PdfController controller;

  const PageSelector({super.key, required this.controller});

  @override
  State<PageSelector> createState() => _PageSelectorState();
}

class _PageSelectorState extends State<PageSelector> {
  late List<bool> indices = List.filled(widget.controller.pageCount, false);
  int totalConvertCount = 0;
  int finishedConvertCount = 0;
  StateSetter? dialogStateSetter;

  void _onCheckAllTapped() {
    if (indices.contains(false)) {
      indices = List.filled(indices.length, true);
    } else {
      indices = List.filled(indices.length, false);
    }
    setState(() {});
  }

  void _onNextStepTapped() async {
    final selectedIndices = <int>[];
    for (int index = 0; index < indices.length; index++) {
      if (indices[index]) {
        selectedIndices.add(index);
      }
    }

    totalConvertCount = selectedIndices.length;
    finishedConvertCount = 0;
    final width = MediaQuery.devicePixelRatioOf(context) * MediaQuery.sizeOf(context).width;

    _showConvertingDialog();
    for (int i = 0; i < selectedIndices.length; i++) {
      final image = await widget.controller.renderFullPage(index: selectedIndices[i], width: width.toInt());
      final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
      finishedConvertCount++;
      if (byteData != null) {
        await PdfMaster.instance.imageSaveHandler?.handleSavePngBytes(
          byteData.buffer.asUint8List(),
          current: finishedConvertCount,
          total: totalConvertCount,
        );
      }
      image?.dispose();
      dialogStateSetter?.call(() {});
    }
    dialogStateSetter = null;
    if (mounted) Navigator.of(context).pop();
  }

  void _showConvertingDialog() {
    Widget builder(ctx, setState) {
      dialogStateSetter = setState;
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).appBarTheme.backgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(radius: 10.0, color: Colors.blueAccent),
                SizedBox(height: 16),
                Text(
                  "${context.localizations['converting']}: ($finishedConvertCount/$totalConvertCount)",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(canPop: false, child: StatefulBuilder(builder: builder)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              PdfMasterAppBar(
                leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
                title: context.localizations['selectPage'],
                action: IconButton(onPressed: _onCheckAllTapped, icon: Icon(Icons.checklist)),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.618,
                  ),
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 80 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => setState(() => indices[i] = !indices[i]),
                    child: IndexedItemView(index: i, controller: widget.controller, active: indices[i]),
                  ),
                  itemCount: widget.controller.pageCount,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.blue[100],
                  ),
                  onPressed: indices.contains(true) ? _onNextStepTapped : null,
                  child: Text(
                    context.localizations['toImage'],
                    style: TextStyle(color: Colors.white, letterSpacing: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IndexedItemView extends StatelessWidget {
  final int index;
  final PdfController controller;
  final bool active;

  const IndexedItemView({super.key, required this.index, required this.controller, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: active ? Colors.blueAccent : Colors.transparent, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: PdfItemView(controller: controller, index: index),
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
          child: Text("${index + 1}", style: TextStyle(fontSize: 10, color: Colors.white)),
        ),
      ],
    );
  }
}
