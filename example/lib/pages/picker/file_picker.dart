import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/ctx_extension.dart';
import 'package:pdf_master_example/pages/picker/menus.dart';

class FilePickerPage extends StatefulWidget {
  const FilePickerPage({super.key});

  @override
  State<FilePickerPage> createState() => _FilePickerPageState();
}

class _FilePickerPageState extends State<FilePickerPage> {
  final List<FileItemInfo> fileList = [];

  @override
  void initState() {
    super.initState();
    _initFileList();
  }

  void _initFileList() async {
    final pdfDir = await getApplicationDocumentsDirectory();
    final documentDirPath = p.join(pdfDir.path, "documents");

    final dirs = Directory(documentDirPath).listSync();
    for (var dir in dirs) {
      if (dir is Directory) {
        final files = dir.listSync().where((file) => file.path.toLowerCase().endsWith('.pdf'));
        fileList.addAll(files.map((e) => FileItemInfo.fromPath(e.path)));
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PdfMasterAppBar(
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
            title: context.localizations.pickFile,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 12),
              itemBuilder: (ctx, index) => FileItem(
                info: fileList[index],
                onTap: () => Navigator.pop(ctx, fileList[index].path),
                action: FileItemAction.kNone,
              ),
              itemCount: fileList.length,
              separatorBuilder: (context, index) => SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class FileItemInfo {
  final String name;
  final String path;
  final int size;
  final int modifyTime;
  final String dateStr;
  final String sizeStr;

  bool active = false;

  FileItemInfo(this.name, this.path, this.size, this.modifyTime, this.dateStr, this.sizeStr);

  factory FileItemInfo.fromPath(String path) {
    File file = File(path);
    final modifiedTime = file.lastModifiedSync();
    final year = "${modifiedTime.year}";
    final month = modifiedTime.month.toString().padLeft(2, '0');
    final day = modifiedTime.day.toString().padLeft(2, '0');
    final dateStr = "$year-$month-$day";

    final fileSize = file.lengthSync();
    final String sizeStr;
    if (fileSize < 1024) {
      sizeStr = '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      sizeStr = '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      sizeStr = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}M';
    } else {
      sizeStr = '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
    }

    return FileItemInfo(p.basename(path), path, fileSize, modifiedTime.millisecondsSinceEpoch, dateStr, sizeStr);
  }
}

enum FileItemAction { kNone, kMore, kCheckActive, kCheckInactive }

class FileItem extends StatefulWidget {
  final FileItemInfo info;
  final VoidCallback onTap;
  final FileItemAction action;
  final VoidCallback? onFileDelete;
  final bool highlight;
  final VoidCallback? onLongPress;

  const FileItem({
    super.key,
    required this.info,
    required this.onTap,
    this.onLongPress,
    this.action = FileItemAction.kMore,
    this.onFileDelete,
    this.highlight = false,
  });

  @override
  State<FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<FileItem> {
  final highlightTimes = 3 * 2;
  int highlightCounter = 0;
  late bool highlight = widget.highlight;
  Color highlightColor = Colors.blue.withAlpha(0);

  @override
  void initState() {
    super.initState();
    _startHighLight();
  }

  @override
  void didUpdateWidget(FileItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    highlight = widget.highlight;
    _startHighLight();
  }

  void _startHighLight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.highlight && highlightCounter < highlightTimes) {
        highlightColor = Colors.blue.withAlpha(76);
        setState(() {});
      }
    });
  }

  Widget _buildFileAction() {
    switch (widget.action) {
      case FileItemAction.kNone:
      case FileItemAction.kCheckInactive:
        return SizedBox.shrink();
      case FileItemAction.kMore:
        return IconButton(
          onPressed: () => showMoreMenus(widget.info.path, context, widget.onFileDelete),
          icon: Icon(Icons.more_vert),
        );
      case FileItemAction.kCheckActive:
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(Icons.check, color: Colors.blueAccent),
        );
    }
  }

  void _onAnimEnd() {
    ++highlightCounter;
    if (highlightCounter >= 6) {
      highlight = false;
      highlightCounter = 0;
      highlightColor = Colors.blue.withAlpha(0);
    } else {
      highlightColor = highlightCounter % 2 == 0 ? Colors.blue.withAlpha(76) : Colors.blue.withAlpha(0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          color: highlightColor,
          height: 64,
          padding: EdgeInsets.only(top: 8, bottom: 8, left: 12),
          duration: Duration(seconds: 1),
          onEnd: _onAnimEnd,
          child: Row(
            children: [
              Padding(padding: EdgeInsets.all(4), child: Image.asset('assets/images/pdf.png')),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.basename(widget.info.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "${widget.info.dateStr}  ${widget.info.sizeStr}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              _buildFileAction(),
            ],
          ),
        ),
      ),
    );
  }
}
