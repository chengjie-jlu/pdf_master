import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/ctx_extension.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_master_example/pages/home/order_menus.dart';
import 'package:pdf_master_example/pages/picker/file_picker.dart';
import 'package:pdf_master_example/pages/pref/preference.dart';
import 'package:pdf_master_example/utils/md5.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FileItemInfo> fileList = [];
  late StreamSubscription _intentDataStreamSubscription;
  String? _highlightedFilePath;
  SortType sortType = SortType.kTime;
  bool editMode = false;

  @override
  void initState() {
    super.initState();
    _initFileList();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _initFileList() async {
    await _refreshFileList();
    _sortFileList();
    setState(() {});
  }

  Future<String> getDocumentDirPath() async {
    final pdfDir = await getApplicationDocumentsDirectory();
    final documentDirPath = p.join(pdfDir.path, "documents");
    if (!await Directory(documentDirPath).exists()) {
      await Directory(documentDirPath).create(recursive: true);
    }
    return documentDirPath;
  }

  Future<void> _refreshFileList() async {
    final documentDirPath = await getDocumentDirPath();
    fileList = [];
    final dirs = Directory(documentDirPath).listSync();
    for (final dir in dirs) {
      if (dir is Directory) {
        final files = dir.listSync().where((file) => file.path.toLowerCase().endsWith('.pdf'));
        fileList.addAll(files.map((e) => FileItemInfo.fromPath(e.path)));
      }
    }
    _sortFileList();
  }

  void _openFileChooser() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ["pdf"]);
    final filePath = result?.files.single.path;
    if (!mounted || filePath == null || filePath.isEmpty) {
      return;
    }
    final savedPdfPath = await _copyAndSaveFile(filePath);
    await _refreshAndHighlightPdf(savedPdfPath);
  }

  Future<bool> _showFileConflictDialog() async {
    final result = await showPdfMasterAlertDialog(
      context,
      context.localizations.fileExists,
      content: context.localizations.fileExistsMessage,
      context.localizations.overwrite,
      negativeButtonText: context.localizations.cancel,
    );
    return result ?? false;
  }

  /// 初始化分享文件监听
  void _initSharingIntent() {
    ReceiveSharingIntent.instance.getInitialMedia().then(_handleSharedFiles);
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(_handleSharedFiles);
  }

  /// 处理分享的文件
  void _handleSharedFiles(List<SharedMediaFile> files) async {
    final pdfFiles = files.where((file) {
      final path = file.path.toLowerCase();
      return path.endsWith('.pdf');
    }).toList();
    if (pdfFiles.isEmpty) {
      return;
    }

    final filePath = pdfFiles.first.path;
    final savedPdfPath = await _copyAndSaveFile(filePath);
    await _refreshAndHighlightPdf(savedPdfPath);
  }

  Future<String> _copyAndSaveFile(String sourcePath) async {
    final fileMd5 = await getFileMd5(sourcePath);
    final documentDir = await getDocumentDirPath();
    // 使用MD5作为文件夹名
    final md5Dir = p.join(documentDir, fileMd5);
    final originalFileName = p.basename(sourcePath);
    final targetPath = p.join(md5Dir, originalFileName);

    if (await File(targetPath).exists()) {
      if (await _showFileConflictDialog()) {
        await File(sourcePath).copy(targetPath);
      }
    } else {
      await Directory(md5Dir).create(recursive: true);
      await File(sourcePath).copy(targetPath);
    }
    return targetPath;
  }

  _refreshAndHighlightPdf(String filePath) async {
    await _refreshFileList();
    if (mounted) {
      _highlightedFilePath = filePath;
      setState(() {});
    }
  }

  void _onSettingTapped() {
    Navigator.of(context).push(PDFMasterPageRouter(builder: (ctx) => PreferencePage()));
  }

  void _enterEditMode(int index) {
    editMode = true;
    for (int i = 0; i < fileList.length; i++) {
      fileList[i].active = i == index;
    }
    setState(() {});
  }

  void _onDeleteAllTapped() async {
    final confirmed = await showPdfMasterAlertDialog(
      context,
      context.localizations.deleteConfirm,
      context.localizations.delete,
      content: context.localizations.deleteWaring,
      negativeButtonText: context.localizations.cancel,
    );

    if (confirmed == true) {
      for (final item in fileList) {
        if (item.active) {
          await File(item.path).delete();
        }
      }
      await _refreshFileList();
      editMode = false;
      setState(() {});
    }
  }

  void _onSortTapped() {
    showOrderMenus(context, (selectedSortType) {
      sortType = selectedSortType;
      _sortFileList();
      setState(() {});
    });
  }

  void _sortFileList() {
    switch (sortType) {
      case SortType.kName:
        fileList.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
        break;
      case SortType.kTime:
        fileList.sort((a, b) => b.modifyTime.compareTo(a.modifyTime));
        break;
      case SortType.kSize:
        fileList.sort((a, b) => b.size.compareTo(a.size));
        break;
    }
  }

  void _openPdfViewerPage(String filePath) async {
    final result = await Navigator.of(
      context,
    ).push(PDFMasterPageRouter(builder: (ctx) => PDFViewerPage(filePath: filePath, doubleTapDragZoom: true,)));
    if (result != null && result is String) {
      _highlightedFilePath = await _copyAndSaveFile(result);
      await _refreshFileList();
      setState(() {});
    }
  }

  void _handleFileDelete(String filePath) async {
    final confirmed = await showPdfMasterAlertDialog(
      context,
      context.localizations.deleteConfirm,
      context.localizations.delete,
      content: context.localizations.deleteWaring,
      negativeButtonText: context.localizations.cancel,
    );
    if (confirmed == true) {
      await File(filePath).delete();
      await _refreshFileList();
      setState(() {});
    }
  }

  FileItemAction _getActionByIndex(int index) {
    if (!editMode) {
      return FileItemAction.kMore;
    }
    return fileList[index].active ? FileItemAction.kCheckActive : FileItemAction.kCheckInactive;
  }

  void _onFileItemTap(FileItemInfo info) {
    if (editMode) {
      info.active = !info.active;
      setState(() {});
    } else {
      _openPdfViewerPage(info.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget home = Scaffold(
      body: Column(
        children: [
          Visibility(
            visible: editMode,
            replacement: PdfMasterAppBar(
              title: context.localizations.appName,
              action: IconButton(icon: Icon(Icons.settings_outlined), onPressed: _onSettingTapped),
              leading: IconButton(icon: Icon(Icons.sort_outlined), onPressed: _onSortTapped),
            ),
            child: PdfMasterAppBar(
              title: context.localizations.editFiles,
              leading: IconButton(icon: Icon(Icons.close), onPressed: () => setState(() => editMode = false)),
              action: IconButton(
                icon: Icon(Icons.delete),
                onPressed: fileList.any((f) => f.active) ? _onDeleteAllTapped : null,
              ),
            ),
          ),
          Expanded(
            child: Visibility(
              visible: fileList.isNotEmpty,
              replacement: Center(child: Text(context.localizations.noFilesHint)),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (ctx, index) => FileItem(
                  info: fileList[index],
                  onTap: () => _onFileItemTap(fileList[index]),
                  onLongPress: () => _enterEditMode(index),
                  onFileDelete: () => _handleFileDelete(fileList[index].path),
                  highlight: fileList[index].path == _highlightedFilePath,
                  action: _getActionByIndex(index),
                ),
                itemCount: fileList.length,
                separatorBuilder: (context, index) => SizedBox(height: 1),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFileChooser,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );

    return PopScope(
      canPop: !editMode,
      onPopInvokedWithResult: (didPop, result) {
        setState(() => editMode = false);
      },
      child: home,
    );
  }
}
