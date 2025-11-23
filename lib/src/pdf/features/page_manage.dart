import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master/src/core/ffi_define.dart' as ffi;
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';
import 'package:pdf_master/src/worker/worker.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

class PageEditInfo {
  final PdfController controller;
  final ffi.PdfDocument document;
  int uiIndex;
  final int pageIndex;
  int queryTurns;

  late Key key = ValueKey("${controller.path}-$pageIndex");

  GlobalKey pageViewKey = GlobalKey();

  PageEditInfo(this.controller, this.document, this.uiIndex, this.pageIndex, this.queryTurns);
}

class PageManagePage extends StatefulWidget {
  final PdfController controller;

  const PageManagePage({super.key, required this.controller});

  @override
  State<PageManagePage> createState() => _PageManagePageState();
}

class _PageManagePageState extends State<PageManagePage> {
  late List<bool> indices = List.filled(widget.controller.pageCount, false, growable: true);
  List<PageEditInfo> pageEditInfos = [];
  final controllers = <PdfController>[];
  final scrollController = ScrollController();
  final gridListViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    for (int i = 0; i < widget.controller.pageCount; i++) {
      pageEditInfos.add(PageEditInfo(widget.controller, widget.controller.document, i, i, 0));
    }

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        showPdfMasterAlertDialog(
          context,
          context.localizations['tips'],
          content: context.localizations['dragHint'],
          context.localizations['ok'],
          barrierDismissible: true,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([]);
    scrollController.dispose();
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PdfMasterAppBar(
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
            title: context.localizations['pageManage'],
            action: IconButton(onPressed: _onNextStepTapped, icon: Icon(Icons.check)),
          ),
          Expanded(
            child: ReorderableBuilder.builder(
              scrollController: scrollController,
              onReorderPositions: (pos) {
                for (final p in pos) {
                  final movedItem = pageEditInfos.removeAt(p.oldIndex);
                  pageEditInfos.insert(p.newIndex, movedItem);
                }
                for (int i = 0; i < pageEditInfos.length; i++) {
                  pageEditInfos[i].uiIndex = i;
                }
                setState(() {});
              },
              dragChildBoxDecoration: BoxDecoration(color: Colors.transparent),
              onDragStarted: (index) => pageEditInfos[index].pageViewKey = GlobalKey(),
              childBuilder: (itemBuilder) {
                return GridView.builder(
                  key: gridListViewKey,
                  controller: scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.618,
                  ),
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.all(24),
                  itemBuilder: (context, index) => itemBuilder(
                    GestureDetector(
                      key: pageEditInfos[index].key,
                      onTap: () => _onItemTapped(index),
                      child: IndexedItemView(
                        uiIndex: pageEditInfos[index].uiIndex,
                        pageIndex: pageEditInfos[index].pageIndex,
                        controller: pageEditInfos[index].controller,
                        active: indices[index],
                        queryTurns: pageEditInfos[index].queryTurns,
                        pdfViewKey: pageEditInfos[index].pageViewKey,
                      ),
                    ),
                    index,
                  ),
                  itemCount: indices.length,
                );
              },
              itemCount: indices.length,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.pdfTheme.appBarBackgroundColor,
              boxShadow: [
                BoxShadow(blurRadius: 10, spreadRadius: 0.1, offset: Offset(0, 4), color: context.pdfTheme.shadowColor),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(onPressed: indices.contains(true) ? _onDeleteTapped : null, icon: Icon(Icons.delete)),
                  IconButton(
                    onPressed: indices.contains(true) ? _onRotatedTapped : null,
                    icon: Icon(Icons.rotate_right),
                  ),
                  if (PdfMaster.instance.filePickerHandler != null)
                    IconButton(onPressed: _onAddTapped, icon: Icon(Icons.add_box_outlined)),
                  IconButton(onPressed: _onCheckAllTapped, icon: Icon(Icons.checklist)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDeleteTapped() {
    if (!indices.contains(false)) {
      showPdfMasterAlertDialog(context, context.localizations['onePageHint'], context.localizations['ok']);
      return;
    }

    final selectedIndices = <int>[];
    for (int index = 0; index < indices.length; index++) {
      if (!indices[index]) {
        selectedIndices.add(index);
      }
    }
    indices = List.filled(selectedIndices.length, false, growable: true);
    final newEditInfos = <PageEditInfo>[];
    for (int index = 0; index < selectedIndices.length; index++) {
      newEditInfos.add(pageEditInfos[selectedIndices[index]]);
    }
    pageEditInfos = newEditInfos;
    setState(() {});
  }

  void _onRotatedTapped() {
    for (int i = 0; i < indices.length; i++) {
      if (indices[i]) {
        pageEditInfos[i].queryTurns = (pageEditInfos[i].queryTurns + 1) % 4;
      }
    }
    setState(() {});
  }

  void _onItemTapped(int index) {
    indices[index] = !indices[index];
    setState(() {});
  }

  void _onNextStepTapped() async {
    // 显示加载对话框
    showDialog(
      context: context,
      builder: (ctx) => Center(
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
                Text(context.localizations['creatingPdf'], style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    final saveDirPath = await PdfMaster.instance.fileSaveHandler?.getWorkSpaceDirPath();
    if (saveDirPath == null) {
      return;
    }

    final targetPath = p.join(saveDirPath, "pdf_master_${DateTime.now().millisecondsSinceEpoch}.pdf");
    final pageInfos = pageEditInfos.map((p) => PageInfo(p.document, p.pageIndex, p.queryTurns)).toList();

    // 在isolate中执行PDF合并操作
    final result = await pdfRenderWorker.executeInIsolate(
      createMergedPdf,
      CreateMergedPdfParams(pageInfos, targetPath),
    );

    if (mounted) {
      Navigator.pop(context); // 关闭加载对话框
      if (result != null) {
        Navigator.pop(context, result);
      } else {
        showPdfMasterAlertDialog(context, context.localizations['createPdfFailed'], context.localizations['ok']);
      }
    }
  }

  void _onAddTapped() async {
    final path = await PdfMaster.instance.filePickerHandler?.pickPdfFile(context);
    if (path == null) {
      return;
    }

    final controller = await tryOpenByPath(path, "");

    if (controller == null) {
      return;
    }
    controllers.add(controller);
    indices.addAll(List.filled(controller.pageCount, false));
    final length = pageEditInfos.length;
    pageEditInfos.addAll(
      List.generate(controller.pageCount, (i) => PageEditInfo(controller, controller.document, length + i, i, 0)),
    );
    setState(() {});
  }

  Future<PdfController?> tryOpenByPath(String path, String password) async {
    final controller = PdfController(path, password: password);
    await controller.open();
    if (!mounted) return null;

    if (controller.opened) {
      return controller;
    } else if (controller.needPassword) {
      final input = await showPdfMasterInputDialog(
        context,
        context.localizations[controller.password.isEmpty ? "needPassword" : "passwordErr"],
        context.localizations["inputPassword"],
      );
      await controller.dispose();
      if (input == null) {
        return null;
      } else {
        return tryOpenByPath(path, input);
      }
    } else {
      showPdfMasterAlertDialog(context, context.localizations["fmtErr"], context.localizations['ok']);
      await controller.dispose();
      return null;
    }
  }

  void _onCheckAllTapped() {
    if (indices.contains(false)) {
      indices = List.filled(indices.length, true, growable: true);
    } else {
      indices = List.filled(indices.length, false, growable: true);
    }
    setState(() {});
  }
}

class IndexedItemView extends StatelessWidget {
  final int uiIndex;
  final int pageIndex;
  final PdfController controller;
  final bool active;
  final int queryTurns;
  final Key pdfViewKey;

  const IndexedItemView({
    super.key,
    required this.uiIndex,
    required this.pageIndex,
    required this.controller,
    required this.active,
    required this.queryTurns,
    required this.pdfViewKey,
  });

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
              child: RotatedBox(
                quarterTurns: queryTurns,
                child: PdfItemView(key: pdfViewKey, controller: controller, index: pageIndex),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
          child: Text("${uiIndex + 1}", style: TextStyle(fontSize: 10, color: Colors.white)),
        ),
      ],
    );
  }
}
