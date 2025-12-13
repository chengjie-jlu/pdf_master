import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/utils/log.dart';

import 'ffi_define.dart';

const String _tag = 'FFI';

/// PDF链接类型枚举
enum PdfLinkType {
  /// 内部跳转（跳转到指定页面）
  goto,

  /// 外部URL链接
  uri,
}

void initLibrary() {
  final dylib = Platform.isAndroid ? DynamicLibrary.open("libpdfium.so") : DynamicLibrary.process();
  fpdfInitLibraryWithConfig = dylib.lookupFunction<NativeFPDFInitLibraryWithConfig, FPDFInitLibraryWithConfig>(
    'FPDF_InitLibraryWithConfig',
  );
  fpdfLoadDocument = dylib.lookupFunction<NativeFPDFLoadDocument, FPDFLoadDocument>('FPDF_LoadDocument');
  fpdfGetLastError = dylib.lookupFunction<NativeFPDFGetLastError, FPDFGetLastError>('FPDF_GetLastError');
  fpdfGetPageCount = dylib.lookupFunction<NativeFPDFGetPageCount, FPDFGetPageCount>('FPDF_GetPageCount');
  fpdfGetPageSizeByIndexF = dylib.lookupFunction<NativeFPDFGetPageSizeByIndexF, FPDFGetPageSizeByIndexF>(
    'FPDF_GetPageSizeByIndexF',
  );
  fpdfCloseDocument = dylib.lookupFunction<NativeFPDFCloseDocument, FPDFCloseDocument>('FPDF_CloseDocument');
  fpdfLoadPage = dylib.lookupFunction<NativeFPDFLoadPage, FPDFLoadPage>('FPDF_LoadPage');
  fpdfClosePage = dylib.lookupFunction<NativeFPDFClosePage, FPDFClosePage>('FPDF_ClosePage');
  fpdfBitmapCreate = dylib.lookupFunction<NativeFPDFBitmapCreate, FPDFBitmapCreate>('FPDFBitmap_Create');
  fpdfBitmapFillRect = dylib.lookupFunction<NativeFPDFBitmapFillRect, FPDFBitmapFillRect>('FPDFBitmap_FillRect');
  fpdfRenderPageBitmap = dylib.lookupFunction<NativeFPDFRenderPageBitmap, FPDFRenderPageBitmap>(
    'FPDF_RenderPageBitmap',
  );
  fpdfBitmapGetBuffer = dylib.lookupFunction<NativeFPDFBitmapGetBuffer, FPDFBitmapGetBuffer>('FPDFBitmap_GetBuffer');
  fpdfBitmapDestroy = dylib.lookupFunction<NativeFPDFBitmapDestroy, FPDFBitmapDestroy>('FPDFBitmap_Destroy');

  fpdfTextLoadPage = dylib.lookupFunction<NativeFPDFTextLoadPage, FPDFTextLoadPage>('FPDFText_LoadPage');
  fpdfTextClosePage = dylib.lookupFunction<NativeFPDFTextClosePage, FPDFTextClosePage>('FPDFText_ClosePage');
  fpdfTextGetCharIndexAtPos = dylib.lookupFunction<NativeFPDFTextGetCharIndexAtPos, FPDFTextGetCharIndexAtPos>(
    'FPDFText_GetCharIndexAtPos',
  );
  fpdfTextGetText = dylib.lookupFunction<NativeFPDFTextGetText, FPDFTextGetText>('FPDFText_GetText');
  fpdfTextCountChars = dylib.lookupFunction<NativeFPDFTextCountChars, FPDFTextCountChars>('FPDFText_CountChars');
  fpdfTextGetCharBox = dylib.lookupFunction<NativeFPDFTextGetCharBox, FPDFTextGetCharBox>('FPDFText_GetCharBox');
  fpdfTextCountRects = dylib.lookupFunction<NativeFPDFTextCountRects, FPDFTextCountRects>('FPDFText_CountRects');
  fpdfTextGetRect = dylib.lookupFunction<NativeFPDFTextGetRect, FPDFTextGetRect>('FPDFText_GetRect');
  fpdfTextFindStart = dylib.lookupFunction<NativeFPDFTextFindStart, FPDFTextFindStart>('FPDFText_FindStart');
  fpdfTextFindNext = dylib.lookupFunction<NativeFPDFTextFindNext, FPDFTextFindNext>('FPDFText_FindNext');
  fpdfTextFindPrev = dylib.lookupFunction<NativeFPDFTextFindPrev, FPDFTextFindPrev>('FPDFText_FindPrev');
  fpdfTextGetSchResultIndex = dylib.lookupFunction<NativeFPDFTextGetSchResultIndex, FPDFTextGetSchResultIndex>(
    'FPDFText_GetSchResultIndex',
  );
  fpdfTextGetSchCount = dylib.lookupFunction<NativeFPDFTextGetSchCount, FPDFTextGetSchCount>('FPDFText_GetSchCount');
  fpdfTextFindClose = dylib.lookupFunction<NativeFPDFTextFindClose, FPDFTextFindClose>('FPDFText_FindClose');

  fpdfPageCreateAnnot = dylib.lookupFunction<NativeFPDFPageCreateAnnot, FPDFPageCreateAnnot>('FPDFPage_CreateAnnot');
  fpdfPageCloseAnnot = dylib.lookupFunction<NativeFPDFPageCloseAnnot, FPDFPageCloseAnnot>('FPDFPage_CloseAnnot');
  fpdfAnnotSetColor = dylib.lookupFunction<NativeFPDFAnnotSetColor, FPDFAnnotSetColor>('FPDFAnnot_SetColor');
  fpdfAnnotSetAP = dylib.lookupFunction<NativeFPDFAnnotSetAP, FPDFAnnotSetAP>('FPDFAnnot_SetAP');
  fpdfAnnotAppendAttachmentPoints = dylib
      .lookupFunction<NativeFPDFAnnotAppendAttachmentPoints, FPDFAnnotAppendAttachmentPoints>(
        'FPDFAnnot_AppendAttachmentPoints',
      );
  fpdfAnnotSetFlags = dylib.lookupFunction<NativeFPDFAnnotSetFlags, FPDFAnnotSetFlags>('FPDFAnnot_SetFlags');
  fpdfPageRemoveAnnot = dylib.lookupFunction<NativeFPDFPageRemoveAnnot, FPDFPageRemoveAnnot>('FPDFPage_RemoveAnnot');
  fpdfPageGenerateContent = dylib.lookupFunction<NativeFPDFPageGenerateContent, FPDFPageGenerateContent>(
    'FPDFPage_GenerateContent',
  );
  fpdfPageGetAnnotCount = dylib.lookupFunction<NativeFPDFPageGetAnnotCount, FPDFPageGetAnnotCount>(
    'FPDFPage_GetAnnotCount',
  );
  fpdfPageGetAnnot = dylib.lookupFunction<NativeFPDFPageGetAnnot, FPDFPageGetAnnot>('FPDFPage_GetAnnot');
  fpdfAnnotGetSubtype = dylib.lookupFunction<NativeFPDFAnnotGetSubtype, FPDFAnnotGetSubtype>('FPDFAnnot_GetSubtype');
  fpdfAnnotCountAttachmentPoints = dylib
      .lookupFunction<NativeFPDFAnnotCountAttachmentPoints, FPDFAnnotCountAttachmentPoints>(
        'FPDFAnnot_CountAttachmentPoints',
      );
  fpdfAnnotGetAttachmentPoints = dylib.lookupFunction<NativeFPDFAnnotGetAttachmentPoints, FPDFAnnotGetAttachmentPoints>(
    'FPDFAnnot_GetAttachmentPoints',
  );
  fpdfSaveAsCopy = dylib.lookupFunction<NativeFPDFSaveAsCopy, FPDFSaveAsCopy>('FPDF_SaveAsCopy');

  fpdfLinkGetLinkAtPoint = dylib.lookupFunction<NativeFPDFLinkGetLinkAtPoint, FPDFLinkGetLinkAtPoint>(
    'FPDFLink_GetLinkAtPoint',
  );
  fpdfLinkGetDest = dylib.lookupFunction<NativeFPDFLinkGetDest, FPDFLinkGetDest>('FPDFLink_GetDest');
  fpdfLinkGetAction = dylib.lookupFunction<NativeFPDFLinkGetAction, FPDFLinkGetAction>('FPDFLink_GetAction');
  fpdfActionGetType = dylib.lookupFunction<NativeFPDFActionGetType, FPDFActionGetType>('FPDFAction_GetType');
  fpdfActionGetDest = dylib.lookupFunction<NativeFPDFActionGetDest, FPDFActionGetDest>('FPDFAction_GetDest');
  fpdfActionGetURIPath = dylib.lookupFunction<NativeFPDFActionGetURIPath, FPDFActionGetURIPath>(
    'FPDFAction_GetURIPath',
  );
  fpdfDestGetDestPageIndex = dylib.lookupFunction<NativeFPDFDestGetDestPageIndex, FPDFDestGetDestPageIndex>(
    'FPDFDest_GetDestPageIndex',
  );
  fpdfLinkGetAnnotRect = dylib.lookupFunction<NativeFPDFLinkGetAnnotRect, FPDFLinkGetAnnotRect>(
    'FPDFLink_GetAnnotRect',
  );
  fpdfLinkEnumerate = dylib.lookupFunction<NativeFPDFLinkEnumerate, FPDFLinkEnumerate>('FPDFLink_Enumerate');

  fpdfBookmarkGetFirstChild = dylib.lookupFunction<NativeFPDFBookmarkGetFirstChild, FPDFBookmarkGetFirstChild>(
    'FPDFBookmark_GetFirstChild',
  );
  fpdfBookmarkGetNextSibling = dylib.lookupFunction<NativeFPDFBookmarkGetNextSibling, FPDFBookmarkGetNextSibling>(
    'FPDFBookmark_GetNextSibling',
  );
  fpdfBookmarkGetTitle = dylib.lookupFunction<NativeFPDFBookmarkGetTitle, FPDFBookmarkGetTitle>(
    'FPDFBookmark_GetTitle',
  );
  fpdfBookmarkGetDest = dylib.lookupFunction<NativeFPDFBookmarkGetDest, FPDFBookmarkGetDest>('FPDFBookmark_GetDest');

  fpdfPageCountObjects = dylib.lookupFunction<NativeFPDFPageCountObjects, FPDFPageCountObjects>(
    'FPDFPage_CountObjects',
  );
  fpdfPageGetObject = dylib.lookupFunction<NativeFPDFPageGetObject, FPDFPageGetObject>('FPDFPage_GetObject');
  fpdfPageObjGetType = dylib.lookupFunction<NativeFPDFPageObjGetType, FPDFPageObjGetType>('FPDFPageObj_GetType');
  fpdfPageObjGetBounds = dylib.lookupFunction<NativeFPDFPageObjGetBounds, FPDFPageObjGetBounds>(
    'FPDFPageObj_GetBounds',
  );
  fpdfImageObjGetBitmap = dylib.lookupFunction<NativeFPDFImageObjGetBitmap, FPDFImageObjGetBitmap>(
    'FPDFImageObj_GetBitmap',
  );
  fpdfImageObjGetRenderedBitmap = dylib
      .lookupFunction<NativeFPDFImageObjGetRenderedBitmap, FPDFImageObjGetRenderedBitmap>(
        'FPDFImageObj_GetRenderedBitmap',
      );
  fpdfBitmapGetWidth = dylib.lookupFunction<NativeFPDFBitmapGetWidth, FPDFBitmapGetWidth>('FPDFBitmap_GetWidth');
  fpdfBitmapGetHeight = dylib.lookupFunction<NativeFPDFBitmapGetHeight, FPDFBitmapGetHeight>('FPDFBitmap_GetHeight');
  fpdfCreateNewDocument = dylib.lookupFunction<NativeFPDFCreateNewDocument, FPDFCreateNewDocument>(
    'FPDF_CreateNewDocument',
  );
  fpdfImportPagesByIndex = dylib.lookupFunction<NativeFPDFImportPagesByIndex, FPDFImportPagesByIndex>(
    'FPDF_ImportPagesByIndex',
  );
  fpdfPageSetRotation = dylib.lookupFunction<NativeFPDFPageSetRotation, FPDFPageSetRotation>('FPDFPage_SetRotation');
  fpdfPageGetRotation = dylib.lookupFunction<NativeFPDFPageGetRotation, FPDFPageGetRotation>('FPDFPage_GetRotation');
  fpdfPageDelete = dylib.lookupFunction<NativeFPDFPageDelete, FPDFPageDelete>('FPDFPage_Delete');
  fpdfMovePages = dylib.lookupFunction<NativeFPDFMovePages, FPDFMovePages>('FPDF_MovePages');

  final config = calloc<FPDFLibraryConfig>();
  config.ref.version = 2;
  fpdfInitLibraryWithConfig(config);
  calloc.free(config);
}

/// 通过文件路径打开 PDF 文档
PdfDocument openByPath(String path, String? password) {
  final pathPtr = path.toNativeUtf8();
  final passwordPtr = password != null ? password.toNativeUtf8() : nullptr.cast<Utf8>();

  try {
    final document = fpdfLoadDocument(pathPtr, passwordPtr);
    if (document == nullptr) {
      final errorCode = fpdfGetLastError();
      return PdfDocument(document: nullptr, pageCount: 0, errorCode: errorCode, pageSizes: []);
    }

    final pageCount = fpdfGetPageCount(document);
    if (pageCount == 0) {
      return PdfDocument(document: document, pageCount: 0, errorCode: 0, pageSizes: []);
    }

    final pageSizes = <ui.Size>[];
    for (int i = 0; i < pageCount; i++) {
      final sizePtr = calloc<FSSizeF>();
      final result = fpdfGetPageSizeByIndexF(document, i, sizePtr);
      if (result != 0) {
        final size = sizePtr.ref;
        pageSizes.add(ui.Size(size.width, size.height));
      }
      calloc.free(sizePtr);
    }

    return PdfDocument(document: document, pageCount: pageCount, errorCode: 0, pageSizes: pageSizes);
  } finally {
    calloc.free(pathPtr);
    if (passwordPtr != nullptr) {
      calloc.free(passwordPtr);
    }
  }
}

/// 关闭 PDF 文档
void closePdfDocument(PdfDocument? pdfDoc) {
  if (pdfDoc == null || pdfDoc.document == nullptr) {
    return;
  }

  fpdfCloseDocument(pdfDoc.document);
}

/// 渲染 PDF 页面为位图
PageBitmap? renderPageBitmap(
  PdfDocument pdfDoc,
  int index,
  int bWidth,
  int bHeight,
  int pWidth,
  int pHeight,
  int startX,
  int startY,
) {
  if (pdfDoc.document == nullptr) {
    return null;
  }

  final page = fpdfLoadPage(pdfDoc.document, index);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $index");
    return null;
  }

  final bitmap = fpdfBitmapCreate(bWidth, bHeight, 0);
  if (bitmap == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Create Bitmap, Out Of Memory.");
    return null;
  }

  fpdfBitmapFillRect(bitmap, 0, 0, bWidth, bHeight, 0xFFFFFFFF);
  fpdfRenderPageBitmap(bitmap, page, startX, startY, pWidth, pHeight, 0, kPdfRenderFlagAnnot);
  fpdfClosePage(page);
  final buffer = fpdfBitmapGetBuffer(bitmap);
  return PageBitmap(index: index, width: bWidth, height: bHeight, bitmap: bitmap, buffer: buffer);
}

/// 释放页面位图资源
void releasePageBitmap(PageBitmap? pageBitmap) {
  if (pageBitmap == null) {
    return;
  }

  if (pageBitmap.bitmap != nullptr) {
    fpdfBitmapDestroy(pageBitmap.bitmap);
  }
}

/// 释放 FPDFBitmap 对象
void releaseFPDFBitmap(FPDFBitmap? bitmap) {
  if (bitmap != null && bitmap != nullptr) {
    fpdfBitmapDestroy(bitmap);
  }
}

/// 获取指定位置的文本字符
String? getTextAtPosition(PdfDocument pdfDoc, int pageIndex, double x, double y, double xTolerance, double yTolerance) {
  if (pdfDoc.document == nullptr) {
    return null;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return null;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return null;
  }

  final charIndex = fpdfTextGetCharIndexAtPos(textPage, x, y, xTolerance, yTolerance);

  String? result;
  if (charIndex >= 0) {
    final buffer = calloc<Uint16>(2); // 1个字符 + 1个终止符
    final charsRead = fpdfTextGetText(textPage, charIndex, 1, buffer);
    if (charsRead > 0) {
      // 将 UTF-16 转换为 Dart 字符串
      final List<int> units = [];
      for (int i = 0; i < charsRead - 1; i++) {
        // -1 排除终止符
        units.add(buffer[i]);
      }
      result = String.fromCharCodes(units);
    }

    calloc.free(buffer);
  }

  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return result;
}

/// 获取字符的边界框
ui.Rect? getCharBox(PdfDocument pdfDoc, int pageIndex, int charIndex) {
  if (pdfDoc.document == nullptr) {
    return null;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return null;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return null;
  }

  final left = calloc<Double>();
  final right = calloc<Double>();
  final bottom = calloc<Double>();
  final top = calloc<Double>();

  final result = fpdfTextGetCharBox(textPage, charIndex, left, right, bottom, top);

  ui.Rect? rect;
  if (result != 0) {
    // PDF坐标系：原点在左下角，Y轴向上
    rect = ui.Rect.fromLTRB(left.value, bottom.value, right.value, top.value);
  }

  calloc.free(left);
  calloc.free(right);
  calloc.free(bottom);
  calloc.free(top);

  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return rect;
}

/// 获取指定位置的字符索引
int getCharIndexAtPosition(
  PdfDocument pdfDoc,
  int pageIndex,
  double x,
  double y,
  double xTolerance,
  double yTolerance,
) {
  if (pdfDoc.document == nullptr) {
    return -1;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return -1;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return -1;
  }

  final charIndex = fpdfTextGetCharIndexAtPos(textPage, x, y, xTolerance, yTolerance);

  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return charIndex;
}

/// 获取页面字符总数
int getPageCharCount(PdfDocument pdfDoc, int pageIndex) {
  if (pdfDoc.document == nullptr) {
    return 0;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return 0;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return 0;
  }

  final count = fpdfTextCountChars(textPage);

  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return count;
}

/// 获取指定范围的文本
String? getTextRange(PdfDocument pdfDoc, int pageIndex, int startIndex, int count) {
  if (pdfDoc.document == nullptr) {
    return null;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return null;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return null;
  }

  // 分配缓冲区：count 个字符 + 1 个终止符
  final buffer = calloc<Uint16>(count + 1);
  final charsRead = fpdfTextGetText(textPage, startIndex, count, buffer);

  String? result;
  if (charsRead > 0) {
    // 将 UTF-16 转换为 Dart 字符串
    final List<int> units = [];
    for (int i = 0; i < charsRead - 1; i++) {
      // -1 排除终止符
      units.add(buffer[i]);
    }
    result = String.fromCharCodes(units);
  }

  calloc.free(buffer);
  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return result;
}

List<PdfCharInfo> getAllPageTextInfo(PdfDocument pdfDoc, int pageIndex) {
  final List<PdfCharInfo> result = [];

  if (pdfDoc.document == nullptr) {
    return result;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return result;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return result;
  }

  final charCount = fpdfTextCountChars(textPage);

  // 分配用于获取字符的缓冲区
  final buffer = calloc<Uint16>(2); // 1个字符 + 1个终止符
  final left = calloc<Double>();
  final right = calloc<Double>();
  final bottom = calloc<Double>();
  final top = calloc<Double>();

  // 遍历所有字符
  for (int i = 0; i < charCount; i++) {
    // 获取字符内容
    final charsRead = fpdfTextGetText(textPage, i, 1, buffer);
    if (charsRead <= 0) continue;

    // 将 UTF-16 转换为 Dart 字符串
    final char = String.fromCharCode(buffer[0]);

    // 获取字符边界框
    final boxResult = fpdfTextGetCharBox(textPage, i, left, right, bottom, top);
    if (boxResult == 0) continue;

    // PDF坐标系：原点在左下角，Y轴向上
    final bounds = ui.Rect.fromLTRB(left.value, bottom.value, right.value, top.value);

    result.add(PdfCharInfo(char: char, index: i, bounds: bounds));
  }

  // 释放资源
  calloc.free(buffer);
  calloc.free(left);
  calloc.free(right);
  calloc.free(bottom);
  calloc.free(top);
  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return result;
}

/// 获取文本矩形数量
int getTextRectCount(PdfDocument pdfDoc, int pageIndex, int startIndex, int count) {
  if (pdfDoc.document == nullptr) {
    return 0;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return 0;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return 0;
  }

  final rectCount = fpdfTextCountRects(textPage, startIndex, count);

  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return rectCount;
}

/// 获取文本矩形列表
List<ui.Rect> getTextRects(PdfDocument pdfDoc, int pageIndex, int startIndex, int count) {
  final List<ui.Rect> result = [];

  if (pdfDoc.document == nullptr) {
    return result;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return result;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return result;
  }

  final rectCount = fpdfTextCountRects(textPage, startIndex, count);
  if (rectCount <= 0) {
    fpdfTextClosePage(textPage);
    fpdfClosePage(page);
    return result;
  }

  final left = calloc<Double>();
  final top = calloc<Double>();
  final right = calloc<Double>();
  final bottom = calloc<Double>();

  for (int i = 0; i < rectCount; i++) {
    final rectResult = fpdfTextGetRect(textPage, i, left, top, right, bottom);
    if (rectResult != 0) {
      final rect = ui.Rect.fromLTRB(left.value, bottom.value, right.value, top.value);
      result.add(rect);
    }
  }

  calloc.free(left);
  calloc.free(top);
  calloc.free(right);
  calloc.free(bottom);
  fpdfTextClosePage(textPage);
  fpdfClosePage(page);

  return result;
}

bool createHighlightAnnotation(
  PdfDocument pdfDoc,
  int pageIndex,
  List<ui.Rect> rects, {
  int r = 255,
  int g = 255,
  int b = 0,
  int a = 100,
}) {
  if (pdfDoc.document == nullptr || rects.isEmpty) {
    return false;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return false;
  }

  final annot = fpdfPageCreateAnnot(page, kPdfAnnotHighlight);
  if (annot == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Create Highlight Annotation");
    return false;
  }

  fpdfAnnotSetAP(annot, kPdfAnnotAppearanceModeNormal, nullptr);
  final colorResult = fpdfAnnotSetColor(annot, kPdfAnnotColorTypeColor, r, g, b, a);
  if (colorResult == 0) {
    Log.e(_tag, "Failed to set annotation color");
  }

  for (final rect in rects) {
    final quadPoints = calloc<FSQuadPointsF>();
    quadPoints.ref.x1 = rect.left;
    quadPoints.ref.y1 = rect.bottom;
    quadPoints.ref.x2 = rect.right;
    quadPoints.ref.y2 = rect.bottom;
    quadPoints.ref.x3 = rect.left;
    quadPoints.ref.y3 = rect.top;
    quadPoints.ref.x4 = rect.right;
    quadPoints.ref.y4 = rect.top;

    final result = fpdfAnnotAppendAttachmentPoints(annot, quadPoints);
    calloc.free(quadPoints);

    if (result == 0) {
      Log.e(_tag, "Failed to append attachment points");
    }
  }

  fpdfAnnotSetFlags(annot, kPdfAnnotFlagPrint);
  fpdfPageCloseAnnot(annot);
  fpdfPageGenerateContent(page);
  fpdfClosePage(page);
  return true;
}

/// 注解信息类
class AnnotationInfo {
  final int annotIndex;
  final List<ui.Rect> rects;
  final int annotType; // 标注类型
  final PdfLinkType? linkType; // 链接类型，仅当annotType为kPdfAnnotLink时有效
  final dynamic linkTarget; // 链接目标：对于goto是页面索引(int)，对于uri是URL字符串(String)

  AnnotationInfo({
    required this.annotIndex,
    required this.rects,
    required this.annotType,
    this.linkType,
    this.linkTarget,
  });
}

/// 获取页面的所有链接标注
List<AnnotationInfo> getPageLinks(
  PdfDocument pdfDoc,
  int pageIndex,
) {
  if (pdfDoc.document == nullptr) {
    return [];
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return [];
  }

  final results = <AnnotationInfo>[];
  final startPosPtr = calloc<Int32>();
  final linkPtr = calloc<FPDFLink>();
  startPosPtr.value = 0;

  // 枚举页面上的所有链接
  while (fpdfLinkEnumerate(page, startPosPtr, linkPtr) != 0) {
    final link = linkPtr.value;
    if (link == nullptr) continue;

    // 获取链接的矩形区域
    final rectPtr = calloc<FSRectF>();
    final getRectResult = fpdfLinkGetAnnotRect(link, rectPtr);
    final rects = <ui.Rect>[];

    if (getRectResult != 0) {
      final rect = rectPtr.ref;
      rects.add(ui.Rect.fromLTRB(rect.left, rect.bottom, rect.right, rect.top));
    }
    calloc.free(rectPtr);

    if (rects.isEmpty) continue;

    // 获取链接信息
    PdfLinkType? linkType;
    dynamic linkTarget;

    // 先尝试获取目标页面
    final dest = fpdfLinkGetDest(pdfDoc.document, link);
    if (dest != nullptr) {
      linkType = PdfLinkType.goto;
      linkTarget = fpdfDestGetDestPageIndex(pdfDoc.document, dest);
    } else {
      // 如果没有目标页面，尝试获取action
      final action = fpdfLinkGetAction(link);
      if (action != nullptr) {
        final actionType = fpdfActionGetType(action);
        if (actionType == kPdfActionGoto) {
          linkType = PdfLinkType.goto;
          final actionDest = fpdfActionGetDest(pdfDoc.document, action);
          if (actionDest != nullptr) {
            linkTarget = fpdfDestGetDestPageIndex(pdfDoc.document, actionDest);
          }
        } else if (actionType == kPdfActionUri) {
          linkType = PdfLinkType.uri;
          // 获取URI长度
          final uriLength = fpdfActionGetURIPath(pdfDoc.document, action, nullptr, 0);
          if (uriLength > 0) {
            final buffer = calloc<Uint8>(uriLength);
            fpdfActionGetURIPath(pdfDoc.document, action, buffer.cast<Void>(), uriLength);
            linkTarget = buffer.cast<Utf8>().toDartString();
            calloc.free(buffer);
          }
        }
      }
    }

    if (linkType != null) {
      results.add(
        AnnotationInfo(
          annotIndex: -1, // 链接标注没有annotIndex
          rects: rects,
          annotType: kPdfAnnotLink,
          linkType: linkType,
          linkTarget: linkTarget,
        ),
      );
    }
  }

  // 释放分配的内存
  calloc.free(startPosPtr);
  calloc.free(linkPtr);
  fpdfClosePage(page);
  return results;
}

/// 获取页面的所有高亮标注
List<AnnotationInfo> getPageHighlights(
  PdfDocument pdfDoc,
  int pageIndex,
) {
  if (pdfDoc.document == nullptr) {
    return [];
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return [];
  }

  final results = <AnnotationInfo>[];
  final annotCount = fpdfPageGetAnnotCount(page);

  for (int i = 0; i < annotCount; i++) {
    final annot = fpdfPageGetAnnot(page, i);
    if (annot == nullptr) {
      continue;
    }
    final subtype = fpdfAnnotGetSubtype(annot);

    // 处理高亮标注
    if (subtype == kPdfAnnotHighlight) {
      final quadCount = fpdfAnnotCountAttachmentPoints(annot);

      if (quadCount > 0) {
        final rects = <ui.Rect>[];
        for (int j = 0; j < quadCount; j++) {
          final quadPoints = calloc<FSQuadPointsF>();
          final getResult = fpdfAnnotGetAttachmentPoints(annot, j, quadPoints);
          if (getResult != 0) {
            final quad = quadPoints.ref;
            final left = [quad.x1, quad.x2, quad.x3, quad.x4].reduce((a, b) => a < b ? a : b);
            final right = [quad.x1, quad.x2, quad.x3, quad.x4].reduce((a, b) => a > b ? a : b);
            final top = [quad.y1, quad.y2, quad.y3, quad.y4].reduce((a, b) => a > b ? a : b);
            final bottom = [quad.y1, quad.y2, quad.y3, quad.y4].reduce((a, b) => a < b ? a : b);

            final rect = ui.Rect.fromLTRB(left, bottom, right, top);
            rects.add(rect);
          }
          calloc.free(quadPoints);
        }

        if (rects.isNotEmpty) {
          results.add(AnnotationInfo(annotIndex: i, rects: rects, annotType: subtype));
        }
      }
    }

    fpdfPageCloseAnnot(annot);
  }
  fpdfClosePage(page);
  return results;
}

bool removeAnnotation(PdfDocument pdfDoc, int pageIndex, int annotIndex) {
  if (pdfDoc.document == nullptr) {
    return false;
  }
  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return false;
  }

  final result = fpdfPageRemoveAnnot(page, annotIndex);
  if (result != 0) {
    fpdfPageGenerateContent(page);
  }

  fpdfClosePage(page);
  return result != 0;
}

bool updateAnnotationColor(
  PdfDocument pdfDoc,
  int pageIndex,
  int annotIndex, {
  int r = 255,
  int g = 255,
  int b = 0,
  int a = 100,
}) {
  if (pdfDoc.document == nullptr) {
    return false;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return false;
  }

  final annot = fpdfPageGetAnnot(page, annotIndex);
  if (annot == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Get Annotation at index: $annotIndex");
    return false;
  }
  fpdfAnnotSetAP(annot, kPdfAnnotAppearanceModeNormal, nullptr);
  final colorResult = fpdfAnnotSetColor(annot, kPdfAnnotColorTypeColor, r, g, b, a);
  if (colorResult == 0) {
    Log.e(_tag, "Failed to set annotation color");
  }
  fpdfPageCloseAnnot(annot);
  fpdfPageGenerateContent(page);
  fpdfClosePage(page);
  return colorResult != 0;
}

/// 搜索结果信息类
class SearchResult {
  final int pageIndex;
  final int charIndex;
  final int charCount;
  final List<ui.Rect> rects;

  SearchResult({required this.pageIndex, required this.charIndex, required this.charCount, required this.rects});
}

List<SearchResult> searchTextInPage(
  PdfDocument pdfDoc,
  int pageIndex,
  String searchText, {
  bool matchCase = false,
  bool matchWholeWord = false,
}) {
  final List<SearchResult> results = [];

  if (pdfDoc.document == nullptr || searchText.isEmpty) {
    return results;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return results;
  }

  final textPage = fpdfTextLoadPage(page);
  if (textPage == nullptr) {
    fpdfClosePage(page);
    Log.e(_tag, "Can't Load Text Page For Index: $pageIndex");
    return results;
  }

  final searchUnits = searchText.codeUnits;
  final searchBuffer = calloc<Uint16>(searchUnits.length + 1);
  for (int i = 0; i < searchUnits.length; i++) {
    searchBuffer[i] = searchUnits[i];
  }
  searchBuffer[searchUnits.length] = 0;
  int flags = 0;
  if (matchCase) {
    flags |= kPdfSearchMatchCase;
  }
  if (matchWholeWord) {
    flags |= kPdfSearchMatchWholeWord;
  }

  final searchHandle = fpdfTextFindStart(textPage, searchBuffer, flags, 0);
  calloc.free(searchBuffer);

  if (searchHandle == nullptr) {
    fpdfTextClosePage(textPage);
    fpdfClosePage(page);
    Log.e(_tag, "Can't Start Search");
    return results;
  }

  while (fpdfTextFindNext(searchHandle) != 0) {
    final charIndex = fpdfTextGetSchResultIndex(searchHandle);
    final charCount = fpdfTextGetSchCount(searchHandle);

    if (charIndex >= 0 && charCount > 0) {
      final rects = getTextRects(pdfDoc, pageIndex, charIndex, charCount);
      results.add(SearchResult(pageIndex: pageIndex, charIndex: charIndex, charCount: charCount, rects: rects));
    }
  }

  fpdfTextFindClose(searchHandle);
  fpdfTextClosePage(textPage);
  fpdfClosePage(page);
  return results;
}

/// 在整个文档中搜索文本
List<SearchResult> searchTextInDocument(
  PdfDocument pdfDoc,
  String searchText, {
  bool matchCase = false,
  bool matchWholeWord = false,
}) {
  final List<SearchResult> allResults = [];

  for (int i = 0; i < pdfDoc.pageCount; i++) {
    final pageResults = searchTextInPage(pdfDoc, i, searchText, matchCase: matchCase, matchWholeWord: matchWholeWord);
    allResults.addAll(pageResults);
  }

  return allResults;
}

/// 目录项信息类
class TocItem {
  final String title;
  final int pageIndex;
  final int level;
  final List<TocItem> children;

  TocItem({required this.title, required this.pageIndex, required this.level, this.children = const []});
}

/// 获取PDF文档的目录
List<TocItem> getDocumentToc(PdfDocument pdfDoc) {
  if (pdfDoc.document == nullptr) {
    return [];
  }

  final List<TocItem> result = [];
  _traverseBookmarks(pdfDoc, nullptr, 0, result);
  return result;
}

/// 递归遍历书签
void _traverseBookmarks(PdfDocument pdfDoc, FPDFBookmark parentBookmark, int level, List<TocItem> result) {
  FPDFBookmark bookmark = fpdfBookmarkGetFirstChild(pdfDoc.document, parentBookmark);
  while (bookmark != nullptr) {
    final titleLength = fpdfBookmarkGetTitle(bookmark, nullptr, 0);
    String title = '';

    if (titleLength > 0) {
      final titleBuffer = calloc<Uint16>(titleLength);
      fpdfBookmarkGetTitle(bookmark, titleBuffer.cast<Void>(), titleLength);

      final List<int> units = [];
      for (int i = 0; i < titleLength; i++) {
        final charCode = titleBuffer[i];
        if (charCode == 0) break;
        // 只添加可见字符和常用空白字符（空格、制表符、换行符等）
        if (charCode >= 0x20 || charCode == 0x09 || charCode == 0x0A || charCode == 0x0D) {
          units.add(charCode);
        }
      }
      title = String.fromCharCodes(units).trim();
      calloc.free(titleBuffer);
    }

    final dest = fpdfBookmarkGetDest(pdfDoc.document, bookmark);
    int pageIndex = -1;
    if (dest != nullptr) {
      pageIndex = fpdfDestGetDestPageIndex(pdfDoc.document, dest);
    }
    final List<TocItem> children = [];
    final tocItem = TocItem(title: title, pageIndex: pageIndex, level: level, children: children);
    result.add(tocItem);
    _traverseBookmarks(pdfDoc, bookmark, level + 1, children);
    bookmark = fpdfBookmarkGetNextSibling(pdfDoc.document, bookmark);
  }
}

/// 图片对象信息类
class ImageObjectInfo {
  final int objectIndex;
  final ui.Rect bounds;
  final int width;
  final int height;
  final Pointer<Uint8>? buffer;
  final FPDFBitmap? bitmap;

  ImageObjectInfo({
    required this.objectIndex,
    required this.bounds,
    required this.width,
    required this.height,
    this.buffer,
    this.bitmap,
  });
}

/// 获取指定位置的图片对象（返回位图数据，需要在主线程转换为 ui.Image）
ImageObjectInfo? getImageObjectAtPosition(
  PdfDocument pdfDoc,
  int pageIndex,
  double x,
  double y, {
  double tolerance = 8.0,
}) {
  if (pdfDoc.document == nullptr) {
    return null;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return null;
  }

  final objectCount = fpdfPageCountObjects(page);
  if (objectCount <= 0) {
    fpdfClosePage(page);
    return null;
  }

  ImageObjectInfo? result;

  for (int i = 0; i < objectCount; i++) {
    final pageObject = fpdfPageGetObject(page, i);
    if (pageObject == nullptr) {
      continue;
    }

    final objectType = fpdfPageObjGetType(pageObject);
    if (objectType == kPdfPageObjImage) {
      final left = calloc<Float>();
      final bottom = calloc<Float>();
      final right = calloc<Float>();
      final top = calloc<Float>();

      final boundsResult = fpdfPageObjGetBounds(pageObject, left, bottom, right, top);
      if (boundsResult != 0) {
        final bounds = ui.Rect.fromLTRB(left.value, bottom.value, right.value, top.value);
        // 检查点击位置是否在图片范围内（加上容差）
        if (x >= bounds.left - tolerance &&
            x <= bounds.right + tolerance &&
            y <= bounds.bottom + tolerance &&
            y >= bounds.top - tolerance) {
          // 获取图片位图
          final bitmap = fpdfImageObjGetRenderedBitmap(pdfDoc.document, page, pageObject);
          int width = 0;
          int height = 0;
          Pointer<Uint8>? buffer;

          if (bitmap != nullptr) {
            // 获取位图的宽度和高度
            width = fpdfBitmapGetWidth(bitmap);
            height = fpdfBitmapGetHeight(bitmap);

            if (width > 0 && height > 0) {
              // 获取位图缓冲区（不释放 bitmap，需要在主线程使用后释放）
              buffer = fpdfBitmapGetBuffer(bitmap);
            }
          }

          result = ImageObjectInfo(
            objectIndex: i,
            bounds: bounds,
            width: width,
            height: height,
            buffer: buffer,
            bitmap: bitmap,
          );

          calloc.free(left);
          calloc.free(bottom);
          calloc.free(right);
          calloc.free(top);
          break;
        }
      }

      calloc.free(left);
      calloc.free(bottom);
      calloc.free(right);
      calloc.free(top);
    }
  }

  fpdfClosePage(page);
  return result;
}

PdfDocument createNewDocument() {
  final document = fpdfCreateNewDocument();
  if (document == nullptr) {
    return PdfDocument(document: nullptr, pageCount: 0, errorCode: fpdfGetLastError(), pageSizes: []);
  }
  return PdfDocument(document: document, pageCount: 0, errorCode: 0, pageSizes: []);
}

/// 导入页面到目标文档
/// [destDoc] 目标文档
/// [srcDoc] 源文档
/// [pageIndices] 要导入的页面索引列表（从0开始）
/// [insertIndex] 插入位置（从0开始）
/// 返回是否成功
bool importPages(PdfDocument destDoc, PdfDocument srcDoc, List<int> pageIndices, int insertIndex) {
  if (destDoc.document == nullptr || srcDoc.document == nullptr) {
    return false;
  }

  final indicesPtr = calloc<Int32>(pageIndices.length);
  for (int i = 0; i < pageIndices.length; i++) {
    indicesPtr[i] = pageIndices[i];
  }

  final result = fpdfImportPagesByIndex(destDoc.document, srcDoc.document, indicesPtr, pageIndices.length, insertIndex);

  calloc.free(indicesPtr);
  return result != 0;
}

/// 设置页面旋转角度
/// [document] PDF文档
/// [pageIndex] 页面索引
/// [rotation] 旋转角度：0=0度, 1=90度, 2=180度, 3=270度
void setPageRotation(PdfDocument document, int pageIndex, int rotation) {
  if (document.document == nullptr) {
    return;
  }

  final page = fpdfLoadPage(document.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return;
  }

  fpdfPageSetRotation(page, rotation);
  fpdfClosePage(page);
}

/// 获取页面旋转角度
/// [document] PDF文档
/// [pageIndex] 页面索引
/// 返回旋转角度：0=0度, 1=90度, 2=180度, 3=270度
int getPageRotation(PdfDocument document, int pageIndex) {
  if (document.document == nullptr) {
    return 0;
  }

  final page = fpdfLoadPage(document.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return 0;
  }

  final rotation = fpdfPageGetRotation(page);
  fpdfClosePage(page);
  return rotation;
}

/// 删除指定页面
/// [document] PDF文档
/// [pageIndex] 要删除的页面索引
void deletePage(PdfDocument document, int pageIndex) {
  if (document.document == nullptr) {
    return;
  }
  fpdfPageDelete(document.document, pageIndex);
}

/// 移动页面到新位置
/// [document] PDF文档
/// [pageIndices] 要移动的页面索引列表（不能有重复）
/// [destPageIndex] 目标位置索引
/// 返回：true表示成功，false表示失败
bool movePages(PdfDocument document, List<int> pageIndices, int destPageIndex) {
  if (document.document == nullptr || pageIndices.isEmpty) {
    return false;
  }

  final indicesPtr = calloc<Int32>(pageIndices.length);
  try {
    for (int i = 0; i < pageIndices.length; i++) {
      indicesPtr[i] = pageIndices[i];
    }
    final result = fpdfMovePages(document.document, indicesPtr, pageIndices.length, destPageIndex);
    return result != 0;
  } finally {
    calloc.free(indicesPtr);
  }
}

/// 图片对象基本信息类（不包含位图数据）
class ImageObjectBasicInfo {
  final int pageIndex;
  final int objectIndex;
  final ui.Rect bounds;

  ImageObjectBasicInfo({required this.pageIndex, required this.objectIndex, required this.bounds});
}

/// 获取PDF文档中所有图片对象的基本信息
List<ImageObjectBasicInfo> getAllImageObjects(PdfDocument pdfDoc) {
  if (pdfDoc.document == nullptr) {
    return [];
  }

  final List<ImageObjectBasicInfo> result = [];

  for (int pageIndex = 0; pageIndex < pdfDoc.pageCount; pageIndex++) {
    final page = fpdfLoadPage(pdfDoc.document, pageIndex);
    if (page == nullptr) {
      Log.e(_tag, "Can't Load Page For Index: $pageIndex");
      continue;
    }

    final objectCount = fpdfPageCountObjects(page);
    if (objectCount > 0) {
      for (int i = 0; i < objectCount; i++) {
        final pageObject = fpdfPageGetObject(page, i);
        if (pageObject == nullptr) {
          continue;
        }

        final objectType = fpdfPageObjGetType(pageObject);
        if (objectType == kPdfPageObjImage) {
          final left = calloc<Float>();
          final bottom = calloc<Float>();
          final right = calloc<Float>();
          final top = calloc<Float>();

          final boundsResult = fpdfPageObjGetBounds(pageObject, left, bottom, right, top);
          if (boundsResult != 0) {
            final bounds = ui.Rect.fromLTRB(left.value, bottom.value, right.value, top.value);
            result.add(ImageObjectBasicInfo(pageIndex: pageIndex, objectIndex: i, bounds: bounds));
          }

          calloc.free(left);
          calloc.free(bottom);
          calloc.free(right);
          calloc.free(top);
        }
      }
    }

    fpdfClosePage(page);
  }

  return result;
}

/// 根据页面索引和对象索引获取图片对象（返回位图数据，需要在主线程转换为 ui.Image）
ImageObjectInfo? getImageObjectByIndex(PdfDocument pdfDoc, int pageIndex, int objectIndex) {
  if (pdfDoc.document == nullptr) {
    return null;
  }

  final page = fpdfLoadPage(pdfDoc.document, pageIndex);
  if (page == nullptr) {
    Log.e(_tag, "Can't Load Page For Index: $pageIndex");
    return null;
  }

  final objectCount = fpdfPageCountObjects(page);
  if (objectIndex >= objectCount) {
    fpdfClosePage(page);
    return null;
  }

  final pageObject = fpdfPageGetObject(page, objectIndex);
  if (pageObject == nullptr) {
    fpdfClosePage(page);
    return null;
  }

  final objectType = fpdfPageObjGetType(pageObject);
  if (objectType != kPdfPageObjImage) {
    fpdfClosePage(page);
    return null;
  }

  final left = calloc<Float>();
  final bottom = calloc<Float>();
  final right = calloc<Float>();
  final top = calloc<Float>();

  ImageObjectInfo? result;

  final boundsResult = fpdfPageObjGetBounds(pageObject, left, bottom, right, top);
  if (boundsResult != 0) {
    final bounds = ui.Rect.fromLTRB(left.value, bottom.value, right.value, top.value);

    // 获取图片位图
    final bitmap = fpdfImageObjGetRenderedBitmap(pdfDoc.document, page, pageObject);
    int width = 0;
    int height = 0;
    Pointer<Uint8>? buffer;

    if (bitmap != nullptr) {
      // 获取位图的宽度和高度
      width = fpdfBitmapGetWidth(bitmap);
      height = fpdfBitmapGetHeight(bitmap);

      if (width > 0 && height > 0) {
        // 获取位图缓冲区（不释放 bitmap，需要在主线程使用后释放）
        buffer = fpdfBitmapGetBuffer(bitmap);
      }
    }

    result = ImageObjectInfo(
      objectIndex: objectIndex,
      bounds: bounds,
      width: width,
      height: height,
      buffer: buffer,
      bitmap: bitmap,
    );
  }

  calloc.free(left);
  calloc.free(bottom);
  calloc.free(right);
  calloc.free(top);
  fpdfClosePage(page);
  return result;
}
