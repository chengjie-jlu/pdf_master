import 'dart:async';
import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:pdf_master/src/core/ffi_define.dart' as ffi;
import 'package:pdf_master/src/core/pdf_ffi_api.dart' as ffi_api;
import 'package:pdf_master/src/pdf/search/widgets.dart';
import 'package:pdf_master/src/pdf/toc/toc.dart';
import 'package:pdf_master/src/worker/worker.dart';
import 'pdf_save.dart' as pdf_save;

class PdfCharInfo {
  final String char;

  final int index;

  final ui.Rect bounds;

  PdfCharInfo({required this.char, required this.index, required this.bounds});

  @override
  String toString() {
    return 'PdfCharInfo(char: "$char", index: $index, bounds: $bounds)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PdfCharInfo && runtimeType == other.runtimeType && index == other.index;

  @override
  int get hashCode => index.hashCode;
}

class ImagePreviewInfo {
  final int objectIndex;
  final ui.Rect bounds;
  final ui.Image? image;

  ImagePreviewInfo({required this.objectIndex, required this.bounds, this.image});
}

class _OpenParams {
  final String path;
  final String password;

  _OpenParams(this.path, this.password);
}

class _RenderPageBitmapParams {
  final ffi.PdfDocument document;
  final int index;
  final int bitmapWidth;
  final int bitmapHeight;
  final int pdfWidth;
  final int pdfHeight;
  final int transX;
  final int transY;

  _RenderPageBitmapParams(
    this.document,
    this.index,
    this.bitmapWidth,
    this.bitmapHeight,
    this.pdfWidth,
    this.pdfHeight,
    this.transX,
    this.transY,
  );
}

class _GetCharIndexAtPosParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final double x;
  final double y;
  final double xTolerance;
  final double yTolerance;

  _GetCharIndexAtPosParams(this.document, this.pageIndex, this.x, this.y, this.xTolerance, this.yTolerance);
}

class _GetPageCharCountParams {
  final ffi.PdfDocument document;
  final int pageIndex;

  _GetPageCharCountParams(this.document, this.pageIndex);
}

class _GetTextRangeParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final int startIndex;
  final int count;

  _GetTextRangeParams(this.document, this.pageIndex, this.startIndex, this.count);
}

class _GetAllPageTextInfoParams {
  final ffi.PdfDocument document;
  final int pageIndex;

  _GetAllPageTextInfoParams(this.document, this.pageIndex);
}

class _GetTextRectsParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final int startIndex;
  final int count;

  _GetTextRectsParams(this.document, this.pageIndex, this.startIndex, this.count);
}

class _CreateHighlightParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final List<ui.Rect> rects;
  final int r;
  final int g;
  final int b;
  final int a;

  _CreateHighlightParams(this.document, this.pageIndex, this.rects, this.r, this.g, this.b, this.a);
}

class _GetAnnotationAtPosParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final double x;
  final double y;
  final double tolerance;

  _GetAnnotationAtPosParams(this.document, this.pageIndex, this.x, this.y, this.tolerance);
}

class _RemoveAnnotationParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final int annotIndex;

  _RemoveAnnotationParams(this.document, this.pageIndex, this.annotIndex);
}

class _UpdateAnnotationColorParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final int annotIndex;
  final int r;
  final int g;
  final int b;
  final int a;

  _UpdateAnnotationColorParams(this.document, this.pageIndex, this.annotIndex, this.r, this.g, this.b, this.a);
}

class _SaveParams {
  final ffi.PdfDocument document;
  final String filePath;
  final int flags;

  _SaveParams(this.document, this.filePath, this.flags);
}

class _SearchTextInDocumentParams {
  final ffi.PdfDocument document;
  final String searchText;
  final bool matchCase;
  final bool matchWholeWord;

  _SearchTextInDocumentParams(this.document, this.searchText, this.matchCase, this.matchWholeWord);
}

class _GetImageObjectAtPosParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final double x;
  final double y;
  final double tolerance;

  _GetImageObjectAtPosParams(this.document, this.pageIndex, this.x, this.y, this.tolerance);
}

class _GetImageObjectByIndexParams {
  final ffi.PdfDocument document;
  final int pageIndex;
  final int objectIndex;

  _GetImageObjectByIndexParams(this.document, this.pageIndex, this.objectIndex);
}

class PageInfo {
  final ffi.PdfDocument document;
  final int pageIndex;
  final int queryTurns;

  PageInfo(this.document, this.pageIndex, this.queryTurns);
}

class CreateMergedPdfParams {
  final List<PageInfo> pageInfos;
  final String savePath;

  CreateMergedPdfParams(this.pageInfos, this.savePath);
}

enum PdfEditState { kNone, kEdit, kSearch }

enum PdfOpenState { kNone, kOpened, kRequiredPassword, kPasswordNotMatch, kFmtError, kUnknownError }

class PdfController {
  final tag = "PdfController";

  final String path;
  final String password;

  late ffi.PdfDocument _document;
  final List<ui.Size> _pageSizes = [];

  final ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);
  final ValueNotifier<PdfEditState> editStateNotifier = ValueNotifier(PdfEditState.kNone);

  late final SearchState searchState = SearchState();
  late final TocState tocState = TocState();

  PdfOpenState openState = PdfOpenState.kNone;

  PdfController(this.path, {this.password = ""});

  int get pageCount => _document.pageCount;

  bool get opened => openState == PdfOpenState.kOpened;

  bool get needPassword => openState == PdfOpenState.kRequiredPassword || openState == PdfOpenState.kPasswordNotMatch;

  ffi.PdfDocument get document => _document;

  ui.Size getPageSizeAt(int index) {
    return _pageSizes[index];
  }

  void _updateOpenStateByErrorCode() {
    if (_document.errorCode == 0) {
      openState = PdfOpenState.kOpened;
    } else if (_document.errorCode == 4) {
      openState = password.isEmpty ? PdfOpenState.kRequiredPassword : PdfOpenState.kPasswordNotMatch;
    } else if (_document.errorCode == 3) {
      openState = PdfOpenState.kFmtError;
    } else {
      openState = PdfOpenState.kUnknownError;
    }
  }

  Future<void> open() async {
    final document = await pdfRenderWorker.executeInIsolate(_innerOpen, _OpenParams(path, password));
    _document = document;

    _updateOpenStateByErrorCode();

    // 只有成功打开时才加载页面尺寸
    if (openState == PdfOpenState.kOpened) {
      for (int i = 0; i < pageCount; i++) {
        final size = _document.pageSizes[i];
        _pageSizes.add(ui.Size(size.width, size.height));
      }
    }
  }

  Future<ui.Image?> renderFullPage({required int index, required int width}) {
    final size = _document.pageSizes[index];
    final height = (size.height * width / size.width).round();
    return renderPageBitmap(index, width, height, width, height, 0, 0);
  }

  /// index 页码
  /// bitmapWidth 输出的位图宽度
  /// bitmapHeight 输出的位图高度
  /// pdfWidth 要渲染的 pdf 宽度
  /// pdfHeight 要渲染的 pdf 高度
  /// transX 位图在 pdf 中的 x 偏移
  /// transY 位图在 pdf 中的 y 偏移
  Future<ui.Image?> renderPageBitmap(
    int index,
    int bitmapWidth,
    int bitmapHeight,
    int pdfWidth,
    int pdfHeight,
    int transX,
    int transY,
  ) async {
    final nativeBitmap = await pdfRenderWorker.executeInIsolate(
      _innerRenderPageBitmap,
      _RenderPageBitmapParams(_document, index, bitmapWidth, bitmapHeight, pdfWidth, pdfHeight, transX, transY),
    );
    if (nativeBitmap == null) {
      return null;
    }

    final width = nativeBitmap.width;
    final height = nativeBitmap.height;
    final completer = Completer<ui.Image>();
    void callback(image) => completer.complete(image);
    final typedList = nativeBitmap.buffer.asTypedList(width * height * 4);
    ui.decodeImageFromPixels(typedList, width, height, ui.PixelFormat.bgra8888, callback);
    final image = await completer.future;
    pdfRenderWorker.executeInIsolate(_releasePageBitmapInner, nativeBitmap);
    return image;
  }

  Future<void> dispose() async {
    scaleNotifier.dispose();
    editStateNotifier.dispose();
    searchState.dispose();
    tocState.dispose();
    await pdfRenderWorker.executeInIsolate(_innerClose, _document);
  }

  /// 获取指定位置的字符索引
  Future<int> getCharIndexAtPosition(
    int pageIndex,
    double x,
    double y, {
    double xTolerance = 5.0,
    double yTolerance = 5.0,
  }) {
    return pdfRenderWorker.executeInIsolate(
      _innerGetCharIndexAtPos,
      _GetCharIndexAtPosParams(_document, pageIndex, x, y, xTolerance, yTolerance),
    );
  }

  /// 获取页面字符总数
  Future<int> getPageCharCount(int pageIndex) {
    return pdfRenderWorker.executeInIsolate(_innerGetPageCharCount, _GetPageCharCountParams(_document, pageIndex));
  }

  /// 获取指定范围的文本
  Future<String?> getTextRange(int pageIndex, int startIndex, int count) {
    return pdfRenderWorker.executeInIsolate(
      _innerGetTextRange,
      _GetTextRangeParams(_document, pageIndex, startIndex, count),
    );
  }

  /// 获取页面所有文字信息（内容、索引、位置与大小）
  Future<List<PdfCharInfo>> getAllPageTextInfo(int pageIndex) {
    return pdfRenderWorker.executeInIsolate(_innerGetAllPageTextInfo, _GetAllPageTextInfoParams(_document, pageIndex));
  }

  /// 获取文本选择的矩形区域列表
  Future<List<ui.Rect>> getTextRects(int pageIndex, int startIndex, int count) {
    return pdfRenderWorker.executeInIsolate(
      _innerGetTextRects,
      _GetTextRectsParams(_document, pageIndex, startIndex, count),
    );
  }

  /// 创建高亮注解
  Future<bool> createHighlight(int pageIndex, List<ui.Rect> rects, {int r = 255, int g = 255, int b = 0, int a = 100}) {
    return pdfRenderWorker.executeInIsolate(
      _innerCreateHighlight,
      _CreateHighlightParams(_document, pageIndex, rects, r, g, b, a),
    );
  }

  /// 获取指定位置的标注信息（返回标注的QuadPoints和索引）
  /// [tolerance] 检测容差，单位为 PDF 坐标，默认 8.0，增加容差可以让小标注更容易点击
  Future<ffi_api.AnnotationInfo?> getAnnotationAtPosition(int pageIndex, double x, double y, {double tolerance = 8.0}) {
    return pdfRenderWorker.executeInIsolate(
      _innerGetAnnotationAtPos,
      _GetAnnotationAtPosParams(_document, pageIndex, x, y, tolerance),
    );
  }

  /// 删除指定页面的指定注解
  Future<bool> removeAnnotation(int pageIndex, int annotIndex) {
    return pdfRenderWorker.executeInIsolate(
      _innerRemoveAnnotation,
      _RemoveAnnotationParams(_document, pageIndex, annotIndex),
    );
  }

  /// 修改标注颜色
  Future<bool> updateAnnotationColor(
    int pageIndex,
    int annotIndex, {
    int r = 255,
    int g = 255,
    int b = 0,
    int a = 100,
  }) {
    return pdfRenderWorker.executeInIsolate(
      _innerUpdateAnnotationColor,
      _UpdateAnnotationColorParams(_document, pageIndex, annotIndex, r, g, b, a),
    );
  }

  /// 获取指定位置的图片对象信息
  /// [tolerance] 检测容差，单位为 PDF 坐标，默认 8.0
  Future<ImagePreviewInfo?> getImageObjectAtPosition(
    int pageIndex,
    double x,
    double y, {
    double tolerance = 8.0,
  }) async {
    final imageInfo = await pdfRenderWorker.executeInIsolate(
      _innerGetImageObjectAtPos,
      _GetImageObjectAtPosParams(_document, pageIndex, x, y, tolerance),
    );

    if (imageInfo == null) {
      return null;
    }

    ui.Image? image;

    if (imageInfo.buffer != null && imageInfo.width > 0 && imageInfo.height > 0) {
      final completer = Completer<ui.Image>();
      void callback(ui.Image img) => completer.complete(img);
      final typedList = imageInfo.buffer!.asTypedList(imageInfo.width * imageInfo.height * 4);
      ui.decodeImageFromPixels(typedList, imageInfo.width, imageInfo.height, ui.PixelFormat.bgra8888, callback);
      image = await completer.future;
      if (imageInfo.bitmap != null) {
        await pdfRenderWorker.executeInIsolate(_releaseBitmap, imageInfo.bitmap);
      }
    }
    return ImagePreviewInfo(objectIndex: imageInfo.objectIndex, bounds: imageInfo.bounds, image: image);
  }

  /// 获取PDF文档中所有图片对象的基本信息
  Future<List<ffi_api.ImageObjectBasicInfo>> getAllImageObjects() async {
    return await pdfRenderWorker.executeInIsolate(_innerGetAllImageObjects, _document);
  }

  /// 根据页面索引和对象索引获取图片对象信息
  Future<ImagePreviewInfo?> getImageObjectByIndex(int pageIndex, int objectIndex) async {
    final imageInfo = await pdfRenderWorker.executeInIsolate(
      _innerGetImageObjectByIndex,
      _GetImageObjectByIndexParams(_document, pageIndex, objectIndex),
    );

    if (imageInfo == null) {
      return null;
    }

    ui.Image? image;

    if (imageInfo.buffer != null && imageInfo.width > 0 && imageInfo.height > 0) {
      final completer = Completer<ui.Image>();
      void callback(ui.Image img) => completer.complete(img);
      final typedList = imageInfo.buffer!.asTypedList(imageInfo.width * imageInfo.height * 4);
      ui.decodeImageFromPixels(typedList, imageInfo.width, imageInfo.height, ui.PixelFormat.bgra8888, callback);
      image = await completer.future;
      if (imageInfo.bitmap != null) {
        await pdfRenderWorker.executeInIsolate(_releaseBitmap, imageInfo.bitmap);
      }
    }
    return ImagePreviewInfo(objectIndex: imageInfo.objectIndex, bounds: imageInfo.bounds, image: image);
  }

  Future<List<ffi_api.SearchResult>> searchTextInDocument(
    String searchText, {
    bool matchCase = false,
    bool matchWholeWord = false,
  }) {
    return pdfRenderWorker.executeInIsolate(
      _innerSearchTextInDocument,
      _SearchTextInDocumentParams(_document, searchText, matchCase, matchWholeWord),
    );
  }

  Future<List<ffi_api.TocItem>> getDocumentToc() {
    return pdfRenderWorker.executeInIsolate(_innerGetDocumentToc, _document);
  }

  Future<bool> save() {
    return pdfRenderWorker.executeInIsolate(_innerSave, _SaveParams(_document, path, 0));
  }

  Future<bool> saveAs(String filePath) {
    return pdfRenderWorker.executeInIsolate(_innerSave, _SaveParams(_document, filePath, 0));
  }

  Future<void> reload() async {
    await pdfRenderWorker.executeInIsolate(_innerClose, _document);
    final document = await pdfRenderWorker.executeInIsolate(_innerOpen, _OpenParams(path, password));
    _document = document;
    _pageSizes.clear();

    _updateOpenStateByErrorCode();

    // 只有成功打开时才加载页面尺寸
    if (openState == PdfOpenState.kOpened) {
      for (int i = 0; i < pageCount; i++) {
        final size = _document.pageSizes[i];
        _pageSizes.add(ui.Size(size.width, size.height));
      }
    }
  }
}

// 注意， 所有在 isolate 执行的函数，都是顶级函数，成员函数可能因为类成员变量无法发送到 isolate 导致通信失败
void _innerClose(ffi.PdfDocument document) {
  ffi_api.closePdfDocument(document);
}

void _releasePageBitmapInner(ffi.PageBitmap? bitmap) {
  ffi_api.releasePageBitmap(bitmap);
}

ffi.PageBitmap? _innerRenderPageBitmap(_RenderPageBitmapParams params) {
  return ffi_api.renderPageBitmap(
    params.document,
    params.index,
    params.bitmapWidth,
    params.bitmapHeight,
    params.pdfWidth,
    params.pdfHeight,
    params.transX,
    params.transY,
  );
}

ffi.PdfDocument _innerOpen(_OpenParams params) {
  return ffi_api.openByPath(params.path, params.password);
}

int _innerGetCharIndexAtPos(_GetCharIndexAtPosParams params) {
  return ffi_api.getCharIndexAtPosition(
    params.document,
    params.pageIndex,
    params.x,
    params.y,
    params.xTolerance,
    params.yTolerance,
  );
}

int _innerGetPageCharCount(_GetPageCharCountParams params) {
  return ffi_api.getPageCharCount(params.document, params.pageIndex);
}

String? _innerGetTextRange(_GetTextRangeParams params) {
  return ffi_api.getTextRange(params.document, params.pageIndex, params.startIndex, params.count);
}

List<PdfCharInfo> _innerGetAllPageTextInfo(_GetAllPageTextInfoParams params) {
  return ffi_api.getAllPageTextInfo(params.document, params.pageIndex);
}

List<ui.Rect> _innerGetTextRects(_GetTextRectsParams params) {
  return ffi_api.getTextRects(params.document, params.pageIndex, params.startIndex, params.count);
}

bool _innerCreateHighlight(_CreateHighlightParams params) {
  return ffi_api.createHighlightAnnotation(
    params.document,
    params.pageIndex,
    params.rects,
    r: params.r,
    g: params.g,
    b: params.b,
    a: params.a,
  );
}

ffi_api.AnnotationInfo? _innerGetAnnotationAtPos(_GetAnnotationAtPosParams params) {
  return ffi_api.getAnnotationAtPosition(
    params.document,
    params.pageIndex,
    params.x,
    params.y,
    tolerance: params.tolerance,
  );
}

bool _innerRemoveAnnotation(_RemoveAnnotationParams params) {
  return ffi_api.removeAnnotation(params.document, params.pageIndex, params.annotIndex);
}

bool _innerUpdateAnnotationColor(_UpdateAnnotationColorParams params) {
  return ffi_api.updateAnnotationColor(
    params.document,
    params.pageIndex,
    params.annotIndex,
    r: params.r,
    g: params.g,
    b: params.b,
    a: params.a,
  );
}

bool _innerSave(_SaveParams params) {
  return pdf_save.savePdfDocument(params.document, params.filePath, flags: params.flags);
}

List<ffi_api.SearchResult> _innerSearchTextInDocument(_SearchTextInDocumentParams params) {
  return ffi_api.searchTextInDocument(
    params.document,
    params.searchText,
    matchCase: params.matchCase,
    matchWholeWord: params.matchWholeWord,
  );
}

List<ffi_api.TocItem> _innerGetDocumentToc(ffi.PdfDocument document) {
  return ffi_api.getDocumentToc(document);
}

ffi_api.ImageObjectInfo? _innerGetImageObjectAtPos(_GetImageObjectAtPosParams params) {
  return ffi_api.getImageObjectAtPosition(
    params.document,
    params.pageIndex,
    params.x,
    params.y,
    tolerance: params.tolerance,
  );
}

List<ffi_api.ImageObjectBasicInfo> _innerGetAllImageObjects(ffi.PdfDocument document) {
  return ffi_api.getAllImageObjects(document);
}

ffi_api.ImageObjectInfo? _innerGetImageObjectByIndex(_GetImageObjectByIndexParams params) {
  return ffi_api.getImageObjectByIndex(params.document, params.pageIndex, params.objectIndex);
}

void _releaseBitmap(ffi.FPDFBitmap? bitmap) {
  ffi_api.releaseFPDFBitmap(bitmap);
}

/// 在isolate中处理单个PDF文档的页面调整（删除、移动、旋转）
/// 这样可以保留书签和元数据
String? adjustSinglePdfDocument(CreateMergedPdfParams params) {
  try {
    final sourceDoc = params.pageInfos.first.document;
    final totalPages = sourceDoc.pageCount;

    final Set<int> pagesToKeep = {};
    for (final pageInfo in params.pageInfos) {
      pagesToKeep.add(pageInfo.pageIndex);
    }

    // 从后往前删除不需要的页面（避免索引变化）
    for (int i = totalPages - 1; i >= 0; i--) {
      if (!pagesToKeep.contains(i)) {
        ffi_api.deletePage(sourceDoc, i);
      }
    }

    // 调整页面顺序
    // 需要计算每个页面当前的实际索引和目标索引
    final currentIndices = params.pageInfos.map((p) => p.pageIndex).toList();
    final sortedIndices = List<int>.from(currentIndices)..sort();

    // 构建索引映射：原始索引 -> 删除后的新索引
    final Map<int, int> indexMapping = {};
    for (int i = 0; i < sortedIndices.length; i++) {
      indexMapping[sortedIndices[i]] = i;
    }

    // 按照用户指定的顺序移动页面
    for (int targetPos = 0; targetPos < params.pageInfos.length; targetPos++) {
      final originalIndex = params.pageInfos[targetPos].pageIndex;
      final currentPos = indexMapping[originalIndex]!;

      if (currentPos != targetPos) {
        // 移动页面
        final success = ffi_api.movePages(sourceDoc, [currentPos], targetPos);
        if (!success) {
          return null;
        }

        // 更新索引映射
        for (final key in indexMapping.keys) {
          final pos = indexMapping[key]!;
          if (pos == currentPos) {
            indexMapping[key] = targetPos;
          } else if (pos >= targetPos && pos < currentPos) {
            indexMapping[key] = pos + 1;
          }
        }
      }
    }

    // 设置旋转角度
    for (int i = 0; i < params.pageInfos.length; i++) {
      final page = params.pageInfos[i];
      if (page.queryTurns != 0) {
        ffi_api.setPageRotation(sourceDoc, i, page.queryTurns);
      }
    }

    // 保存文档
    final saveSuccess = pdf_save.savePdfDocument(sourceDoc, params.savePath, flags: ffi.kPdfSaveFlagRemoveSecurity);
    return saveSuccess ? params.savePath : null;
  } catch (e) {
    return null;
  }
}

/// 在isolate中创建合并的PDF文档
String? createMergedPdf(CreateMergedPdfParams params) {
  try {
    // 按源文档分组页面信息
    final Map<int, List<PageInfo>> groupedByDocument = {};
    for (final pageInfo in params.pageInfos) {
      final docKey = pageInfo.document.hashCode;
      groupedByDocument.putIfAbsent(docKey, () => []).add(pageInfo);
    }

    // 如果只有一个源文档，直接在原文档上操作（保留书签和元数据）
    if (groupedByDocument.length == 1) {
      return adjustSinglePdfDocument(params);
    }

    // 多个源文档的情况，创建新文档并批量导入
    final newDoc = ffi_api.createNewDocument();
    if (newDoc.errorCode != 0) {
      return null;
    }

    int currentInsertIndex = 0;

    // 直接遍历Map，顺序就是各文档首次出现的顺序
    for (final entry in groupedByDocument.entries) {
      final pagesFromThisDoc = entry.value;
      final firstPage = pagesFromThisDoc.first;

      final pageIndices = pagesFromThisDoc.map((p) => p.pageIndex).toList();
      final success = ffi_api.importPages(newDoc, firstPage.document, pageIndices, currentInsertIndex);

      if (!success) {
        ffi_api.closePdfDocument(newDoc);
        return null;
      }

      for (int i = 0; i < pagesFromThisDoc.length; i++) {
        final page = pagesFromThisDoc[i];
        if (page.queryTurns != 0) {
          ffi_api.setPageRotation(newDoc, currentInsertIndex + i, page.queryTurns);
        }
      }

      currentInsertIndex += pagesFromThisDoc.length;
    }

    final saveSuccess = pdf_save.savePdfDocument(newDoc, params.savePath, flags: ffi.kPdfSaveFlagRemoveSecurity);
    ffi_api.closePdfDocument(newDoc);
    if (saveSuccess) {
      return params.savePath;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}
