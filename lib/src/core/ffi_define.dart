import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';

const int kPdfAnnotUnknown = 0;
const int kPdfAnnotText = 1;
const int kPdfAnnotLink = 2;
const int kPdfAnnotFreeText = 3;
const int kPdfAnnotLine = 4;
const int kPdfAnnotSquare = 5;
const int kPdfAnnotCircle = 6;
const int kPdfAnnotPolygon = 7;
const int kPdfAnnotPolyline = 8;
const int kPdfAnnotHighlight = 9;
const int kPdfAnnotUnderline = 10;
const int kPdfAnnotSquiggly = 11;
const int kPdfAnnotStrikeout = 12;
const int kPdfAnnotStamp = 13;
const int kPdfAnnotCaret = 14;
const int kPdfAnnotInk = 15;
const int kPdfAnnotPopup = 16;
const int kPdfAnnotFileAttachment = 17;
const int kPdfAnnotSound = 18;
const int kPdfAnnotMovie = 19;
const int kPdfAnnotWidget = 20;
const int kPdfAnnotScreen = 21;
const int kPdfAnnotPrinterMark = 22;
const int kPdfAnnotTrapNet = 23;
const int kPdfAnnotWatermark = 24;
const int kPdfAnnot3D = 25;
const int kPdfAnnotRichMedia = 26;
const int kPdfAnnotXfaWidget = 27;
const int kPdfAnnotRedact = 28;

const int kPdfAnnotFlagNone = 0;
const int kPdfAnnotFlagInvisible = 1 << 0; // 1
const int kPdfAnnotFlagHidden = 1 << 1; // 2
const int kPdfAnnotFlagPrint = 1 << 2; // 4
const int kPdfAnnotFlagNoZoom = 1 << 3; // 8
const int kPdfAnnotFlagNoRotate = 1 << 4; // 16
const int kPdfAnnotFlagNoView = 1 << 5; // 32
const int kPdfAnnotFlagReadOnly = 1 << 6; // 64
const int kPdfAnnotFlagLocked = 1 << 7; // 128
const int kPdfAnnotFlagToggleNoView = 1 << 8; // 256

const int kPdfAnnotColorTypeColor = 0;
const int kPdfAnnotColorTypeInteriorColor = 1;

const int kPdfAnnotAppearanceModeNormal = 0;
const int kPdfAnnotAppearanceModeRollover = 1;
const int kPdfAnnotAppearanceModeDown = 2;

// PDF Action Types
const int kPdfActionUnsupported = 0;
const int kPdfActionGoto = 1;
const int kPdfActionRemoteGoto = 2;
const int kPdfActionUri = 3;
const int kPdfActionLaunch = 4;

const int kPdfRenderFlagNone = 0;
const int kPdfRenderFlagAnnot = 0x01; // 渲染注解
const int kPdfRenderFlagLcdText = 0x02; // LCD 优化文本
const int kPdfRenderFlagNoNativeText = 0x04; // 不使用原生文本输出
const int kPdfRenderFlagGrayscale = 0x08; // 灰度渲染
const int kPdfRenderFlagDebugInfo = 0x80; // 调试信息
const int kPdfRenderFlagNoCatch = 0x100; // 不捕获异常
const int kPdfRenderFlagLimitImageCache = 0x200; // 限制图像缓存
const int kPdfRenderFlagForceHalftone = 0x400; // 强制半色调
const int kPdfRenderFlagPrinting = 0x800; // 打印模式
const int kPdfRenderFlagReverseByteOrder = 0x10; // 反转字节序

const int kPdfRenderReady = 0;
const int kPdfRenderToBeContinued = 1;
const int kPdfRenderDone = 2;
const int kPdfRenderFailed = 3;

const int kPdfSearchMatchCase = 0x00000001;
const int kPdfSearchMatchWholeWord = 0x0000002;

const int kPdfPageObjUnknown = 0;
const int kPdfPageObjText = 1;
const int kPdfPageObjPath = 2;
const int kPdfPageObjImage = 3;
const int kPdfPageObjShading = 4;
const int kPdfPageObjForm = 5;

typedef FPDFDocument = Pointer<Void>;
typedef FPDFPage = Pointer<Void>;
typedef FPDFBitmap = Pointer<Void>;
typedef FPDFTextPage = Pointer<Void>;
typedef FPDFAnnotation = Pointer<Void>;
typedef FPDFSchHandle = Pointer<Void>;
typedef FPDFBookmark = Pointer<Void>;
typedef FPDFPageObject = Pointer<Void>;
typedef FPDFLink = Pointer<Void>;
typedef FPDFAction = Pointer<Void>;
typedef FPDFDest = Pointer<Void>;

final class FSSizeF extends Struct {
  @Float()
  external double width;

  @Float()
  external double height;
}

final class FSQuadPointsF extends Struct {
  @Float()
  external double x1;

  @Float()
  external double y1;

  @Float()
  external double x2;

  @Float()
  external double y2;

  @Float()
  external double x3;

  @Float()
  external double y3;

  @Float()
  external double x4;

  @Float()
  external double y4;
}

final class FSRectF extends Struct {
  @Float()
  external double left;

  @Float()
  external double top;

  @Float()
  external double right;

  @Float()
  external double bottom;
}

final class FPDFLibraryConfig extends Struct {
  @Int32()
  external int version;

  external Pointer<Pointer<Int8>> userFontPaths;

  external Pointer<Void> isolate;

  @Uint32()
  external int v8EmbedderSlot;

  external Pointer<Void> platform;

  @Int32()
  external int rendererType;
}

class PdfDocument {
  final FPDFDocument document;
  final int pageCount;
  final int errorCode;
  final List<ui.Size> pageSizes;

  PdfDocument({required this.document, required this.pageCount, required this.errorCode, required this.pageSizes});
}

class PageBitmap {
  final int index;
  final int width;
  final int height;
  final FPDFBitmap bitmap;
  final Pointer<Uint8> buffer;

  PageBitmap({
    required this.index,
    required this.width,
    required this.height,
    required this.bitmap,
    required this.buffer,
  });
}

typedef NativeFPDFInitLibraryWithConfig = Void Function(Pointer<FPDFLibraryConfig>);
typedef NativeFPDFLoadDocument = FPDFDocument Function(Pointer<Utf8>, Pointer<Utf8>);
typedef NativeFPDFGetLastError = Uint32 Function();
typedef NativeFPDFGetPageCount = Int32 Function(FPDFDocument);
typedef NativeFPDFGetPageSizeByIndexF = Int32 Function(FPDFDocument, Int32, Pointer<FSSizeF>);
typedef NativeFPDFCloseDocument = Void Function(FPDFDocument);
typedef NativeFPDFLoadPage = FPDFPage Function(FPDFDocument, Int32);
typedef NativeFPDFClosePage = Void Function(FPDFPage);
typedef NativeFPDFBitmapCreate = FPDFBitmap Function(Int32, Int32, Int32);
typedef NativeFPDFBitmapFillRect = Int32 Function(FPDFBitmap, Int32, Int32, Int32, Int32, Uint32);
typedef NativeFPDFRenderPageBitmap = Void Function(FPDFBitmap, FPDFPage, Int32, Int32, Int32, Int32, Int32, Int32);
typedef NativeFPDFRenderPageClose = Void Function(FPDFPage);
typedef NativeFPDFBitmapGetBuffer = Pointer<Uint8> Function(FPDFBitmap);
typedef NativeFPDFBitmapDestroy = Void Function(FPDFBitmap);
typedef NativeFPDFTextLoadPage = FPDFTextPage Function(FPDFPage);
typedef NativeFPDFTextClosePage = Void Function(FPDFTextPage);
typedef NativeFPDFTextGetCharIndexAtPos = Int32 Function(FPDFTextPage, Double, Double, Double, Double);
typedef NativeFPDFTextGetText = Int32 Function(FPDFTextPage, Int32, Int32, Pointer<Uint16>);
typedef NativeFPDFTextCountChars = Int32 Function(FPDFTextPage);
typedef NativeFPDFTextGetCharBox =
    Int32 Function(FPDFTextPage, Int32, Pointer<Double>, Pointer<Double>, Pointer<Double>, Pointer<Double>);
typedef NativeFPDFTextCountRects = Int32 Function(FPDFTextPage, Int32, Int32);
typedef NativeFPDFTextGetRect =
    Int32 Function(FPDFTextPage, Int32, Pointer<Double>, Pointer<Double>, Pointer<Double>, Pointer<Double>);
typedef NativeFPDFTextFindStart = FPDFSchHandle Function(FPDFTextPage, Pointer<Uint16>, Uint32, Int32);
typedef NativeFPDFTextFindNext = Int32 Function(FPDFSchHandle);
typedef NativeFPDFTextFindPrev = Int32 Function(FPDFSchHandle);
typedef NativeFPDFTextGetSchResultIndex = Int32 Function(FPDFSchHandle);
typedef NativeFPDFTextGetSchCount = Int32 Function(FPDFSchHandle);
typedef NativeFPDFTextFindClose = Void Function(FPDFSchHandle);
typedef NativeFPDFBookmarkGetFirstChild = FPDFBookmark Function(FPDFDocument, FPDFBookmark);
typedef NativeFPDFBookmarkGetNextSibling = FPDFBookmark Function(FPDFDocument, FPDFBookmark);
typedef NativeFPDFBookmarkGetTitle = Size Function(FPDFBookmark, Pointer<Void>, Size);
typedef NativeFPDFBookmarkGetDest = Pointer<Void> Function(FPDFDocument, FPDFBookmark);
typedef NativeFPDFPageCreateAnnot = FPDFAnnotation Function(FPDFPage, Int32);
typedef NativeFPDFPageCloseAnnot = Void Function(FPDFAnnotation);
typedef NativeFPDFAnnotSetColor = Int32 Function(FPDFAnnotation, Int32, Uint32, Uint32, Uint32, Uint32);
typedef NativeFPDFAnnotSetAP = Int32 Function(FPDFAnnotation, Int32, Pointer<Uint16>);
typedef NativeFPDFAnnotAppendAttachmentPoints = Int32 Function(FPDFAnnotation, Pointer<FSQuadPointsF>);
typedef NativeFPDFAnnotSetFlags = Int32 Function(FPDFAnnotation, Int32);
typedef NativeFPDFPageGenerateContent = Int32 Function(FPDFPage);
typedef NativeFPDFPageGetAnnotCount = Int32 Function(FPDFPage);
typedef NativeFPDFPageGetAnnot = FPDFAnnotation Function(FPDFPage, Int32);
typedef NativeFPDFAnnotGetSubtype = Int32 Function(FPDFAnnotation);
typedef NativeFPDFAnnotCountAttachmentPoints = Size Function(FPDFAnnotation);
typedef NativeFPDFAnnotGetAttachmentPoints = Int32 Function(FPDFAnnotation, Size, Pointer<FSQuadPointsF>);
typedef NativeFPDFPageRemoveAnnot = Int32 Function(FPDFPage, Int32);
typedef NativeFPDFLinkGetLinkAtPoint = FPDFLink Function(FPDFPage, Double, Double);
typedef NativeFPDFLinkGetDest = FPDFDest Function(FPDFDocument, FPDFLink);
typedef NativeFPDFLinkGetAction = FPDFAction Function(FPDFLink);
typedef NativeFPDFActionGetType = Uint32 Function(FPDFAction);
typedef NativeFPDFActionGetDest = FPDFDest Function(FPDFDocument, FPDFAction);
typedef NativeFPDFActionGetURIPath = Uint32 Function(FPDFDocument, FPDFAction, Pointer<Void>, Uint32);
typedef NativeFPDFDestGetDestPageIndex = Int32 Function(FPDFDocument, FPDFDest);
typedef NativeFPDFLinkGetAnnotRect = Int32 Function(FPDFLink, Pointer<FSRectF>);
typedef NativeFPDFLinkEnumerate = Int32 Function(FPDFPage, Pointer<Int32>, Pointer<FPDFLink>);
typedef NativeFPDFPageCountObjects = Int32 Function(FPDFPage);
typedef NativeFPDFPageGetObject = FPDFPageObject Function(FPDFPage, Int32);
typedef NativeFPDFPageObjGetType = Int32 Function(FPDFPageObject);
typedef NativeFPDFPageObjGetBounds =
    Int32 Function(FPDFPageObject, Pointer<Float>, Pointer<Float>, Pointer<Float>, Pointer<Float>);
typedef NativeFPDFImageObjGetBitmap = FPDFBitmap Function(FPDFPageObject);
typedef NativeFPDFImageObjGetRenderedBitmap = FPDFBitmap Function(FPDFDocument, FPDFPage, FPDFPageObject);
typedef NativeFPDFBitmapGetWidth = Int32 Function(FPDFBitmap);
typedef NativeFPDFBitmapGetHeight = Int32 Function(FPDFBitmap);
typedef NativeFPDFCreateNewDocument = FPDFDocument Function();
typedef NativeFPDFImportPagesByIndex = Int32 Function(FPDFDocument, FPDFDocument, Pointer<Int32>, Size, Int32);
typedef NativeFPDFPageSetRotation = Void Function(FPDFPage, Int32);
typedef NativeFPDFPageGetRotation = Int32 Function(FPDFPage);
typedef NativeFPDFPageDelete = Void Function(FPDFDocument, Int32);
typedef NativeFPDFMovePages = Int32 Function(FPDFDocument, Pointer<Int32>, Size, Int32);

const int kPdfSaveFlagDefault = 0; // 默认保存（完整保存）
const int kPdfSaveFlagIncremental = 1; // 增量保存（FPDF_INCREMENTAL）
const int kPdfSaveFlagNoIncremental = 2; // 非增量保存（FPDF_NO_INCREMENTAL）
const int kPdfSaveFlagRemoveSecurity = 3; // 移除安全设置（FPDF_REMOVE_SECURITY）

/// WriteBlock 回调函数类型 (Native)
/// 参数：
///   - pThis: FPDF_FILEWRITE 结构体指针
///   - pData: 要写入的数据指针
///   - size: 数据大小（字节）
/// 返回值：1 表示成功，0 表示失败
typedef NativeWriteBlockCallback = Int32 Function(Pointer<FPDFFileWrite> pThis, Pointer<Void> pData, Size size);

/// WriteBlock 回调函数类型 (Dart)
typedef WriteBlockCallback = int Function(Pointer<FPDFFileWrite> pThis, Pointer<Void> pData, int size);

/// FPDF_FILEWRITE 结构体
/// 用于 FPDF_SaveAsCopy 的文件写入回调
final class FPDFFileWrite extends Struct {
  /// 结构体版本号，必须为 1
  @Int32()
  external int version;

  /// WriteBlock 回调函数指针
  external Pointer<NativeFunction<NativeWriteBlockCallback>> writeBlock;
}

/// FPDF_SaveAsCopy 函数类型 (Native)
typedef NativeFPDFSaveAsCopy = Int32 Function(FPDFDocument document, Pointer<FPDFFileWrite> pFileWrite, Uint32 flags);

typedef FPDFInitLibraryWithConfig = void Function(Pointer<FPDFLibraryConfig>);
typedef FPDFLoadDocument = FPDFDocument Function(Pointer<Utf8>, Pointer<Utf8>);
typedef FPDFGetLastError = int Function();
typedef FPDFGetPageCount = int Function(FPDFDocument);
typedef FPDFGetPageSizeByIndexF = int Function(FPDFDocument, int, Pointer<FSSizeF>);
typedef FPDFCloseDocument = void Function(FPDFDocument);
typedef FPDFLoadPage = FPDFPage Function(FPDFDocument, int);
typedef FPDFClosePage = void Function(FPDFPage);
typedef FPDFBitmapCreate = FPDFBitmap Function(int, int, int);
typedef FPDFBitmapFillRect = int Function(FPDFBitmap, int, int, int, int, int);
typedef FPDFRenderPageBitmap = void Function(FPDFBitmap, FPDFPage, int, int, int, int, int, int);
typedef FPDFRenderPageClose = void Function(FPDFPage);
typedef FPDFBitmapGetBuffer = Pointer<Uint8> Function(FPDFBitmap);
typedef FPDFBitmapDestroy = void Function(FPDFBitmap);
typedef FPDFTextLoadPage = FPDFTextPage Function(FPDFPage);
typedef FPDFTextClosePage = void Function(FPDFTextPage);
typedef FPDFTextGetCharIndexAtPos = int Function(FPDFTextPage, double, double, double, double);
typedef FPDFTextGetText = int Function(FPDFTextPage, int, int, Pointer<Uint16>);
typedef FPDFTextCountChars = int Function(FPDFTextPage);
typedef FPDFTextGetCharBox =
    int Function(FPDFTextPage, int, Pointer<Double>, Pointer<Double>, Pointer<Double>, Pointer<Double>);
typedef FPDFTextCountRects = int Function(FPDFTextPage, int, int);
typedef FPDFTextGetRect =
    int Function(FPDFTextPage, int, Pointer<Double>, Pointer<Double>, Pointer<Double>, Pointer<Double>);
typedef FPDFTextFindStart = FPDFSchHandle Function(FPDFTextPage, Pointer<Uint16>, int, int);
typedef FPDFTextFindNext = int Function(FPDFSchHandle);
typedef FPDFTextFindPrev = int Function(FPDFSchHandle);
typedef FPDFTextGetSchResultIndex = int Function(FPDFSchHandle);
typedef FPDFTextGetSchCount = int Function(FPDFSchHandle);
typedef FPDFTextFindClose = void Function(FPDFSchHandle);
typedef FPDFBookmarkGetFirstChild = FPDFBookmark Function(FPDFDocument, FPDFBookmark);
typedef FPDFBookmarkGetNextSibling = FPDFBookmark Function(FPDFDocument, FPDFBookmark);
typedef FPDFBookmarkGetTitle = int Function(FPDFBookmark, Pointer<Void>, int);
typedef FPDFBookmarkGetDest = Pointer<Void> Function(FPDFDocument, FPDFBookmark);
typedef FPDFPageCreateAnnot = FPDFAnnotation Function(FPDFPage, int);
typedef FPDFPageCloseAnnot = void Function(FPDFAnnotation);
typedef FPDFAnnotSetColor = int Function(FPDFAnnotation, int, int, int, int, int);
typedef FPDFAnnotSetAP = int Function(FPDFAnnotation, int, Pointer<Uint16>);
typedef FPDFAnnotAppendAttachmentPoints = int Function(FPDFAnnotation, Pointer<FSQuadPointsF>);
typedef FPDFAnnotGetAttachmentPoints = int Function(FPDFAnnotation, int, Pointer<FSQuadPointsF>);
typedef FPDFAnnotSetFlags = int Function(FPDFAnnotation, int);
typedef FPDFLinkGetLinkAtPoint = FPDFLink Function(FPDFPage, double, double);
typedef FPDFLinkGetDest = FPDFDest Function(FPDFDocument, FPDFLink);
typedef FPDFLinkGetAction = FPDFAction Function(FPDFLink);
typedef FPDFActionGetType = int Function(FPDFAction);
typedef FPDFActionGetDest = FPDFDest Function(FPDFDocument, FPDFAction);
typedef FPDFActionGetURIPath = int Function(FPDFDocument, FPDFAction, Pointer<Void>, int);
typedef FPDFDestGetDestPageIndex = int Function(FPDFDocument, FPDFDest);
typedef FPDFLinkGetAnnotRect = int Function(FPDFLink, Pointer<FSRectF>);
typedef FPDFLinkEnumerate = int Function(FPDFPage, Pointer<Int32>, Pointer<FPDFLink>);
typedef FPDFPageGenerateContent = int Function(FPDFPage);
typedef FPDFPageGetAnnotCount = int Function(FPDFPage);
typedef FPDFPageGetAnnot = FPDFAnnotation Function(FPDFPage, int);
typedef FPDFAnnotGetSubtype = int Function(FPDFAnnotation);
typedef FPDFAnnotCountAttachmentPoints = int Function(FPDFAnnotation);
typedef FPDFPageRemoveAnnot = int Function(FPDFPage, int);
typedef FPDFPageCountObjects = int Function(FPDFPage);
typedef FPDFPageGetObject = FPDFPageObject Function(FPDFPage, int);
typedef FPDFPageObjGetType = int Function(FPDFPageObject);
typedef FPDFPageObjGetBounds =
    int Function(FPDFPageObject, Pointer<Float>, Pointer<Float>, Pointer<Float>, Pointer<Float>);
typedef FPDFImageObjGetBitmap = FPDFBitmap Function(FPDFPageObject);
typedef FPDFImageObjGetRenderedBitmap = FPDFBitmap Function(FPDFDocument, FPDFPage, FPDFPageObject);
typedef FPDFBitmapGetWidth = int Function(FPDFBitmap);
typedef FPDFBitmapGetHeight = int Function(FPDFBitmap);
typedef FPDFCreateNewDocument = FPDFDocument Function();
typedef FPDFImportPagesByIndex = int Function(FPDFDocument, FPDFDocument, Pointer<Int32>, int, int);
typedef FPDFPageSetRotation = void Function(FPDFPage, int);
typedef FPDFPageGetRotation = int Function(FPDFPage);
typedef FPDFPageDelete = void Function(FPDFDocument, int);
typedef FPDFMovePages = int Function(FPDFDocument, Pointer<Int32>, int, int);

/// FPDF_SaveAsCopy 函数类型 (Dart)
typedef FPDFSaveAsCopy = int Function(FPDFDocument document, Pointer<FPDFFileWrite> pFileWrite, int flags);

late FPDFInitLibraryWithConfig fpdfInitLibraryWithConfig;
late FPDFLoadDocument fpdfLoadDocument;
late FPDFGetLastError fpdfGetLastError;
late FPDFGetPageCount fpdfGetPageCount;
late FPDFGetPageSizeByIndexF fpdfGetPageSizeByIndexF;
late FPDFCloseDocument fpdfCloseDocument;
late FPDFLoadPage fpdfLoadPage;
late FPDFClosePage fpdfClosePage;
late FPDFBitmapCreate fpdfBitmapCreate;
late FPDFBitmapFillRect fpdfBitmapFillRect;
late FPDFRenderPageBitmap fpdfRenderPageBitmap;
late FPDFBitmapGetBuffer fpdfBitmapGetBuffer;
late FPDFBitmapDestroy fpdfBitmapDestroy;

late FPDFTextLoadPage fpdfTextLoadPage;
late FPDFTextClosePage fpdfTextClosePage;
late FPDFTextGetCharIndexAtPos fpdfTextGetCharIndexAtPos;
late FPDFTextGetText fpdfTextGetText;
late FPDFTextCountChars fpdfTextCountChars;
late FPDFTextGetCharBox fpdfTextGetCharBox;
late FPDFTextCountRects fpdfTextCountRects;
late FPDFTextGetRect fpdfTextGetRect;

late FPDFTextFindStart fpdfTextFindStart;
late FPDFTextFindNext fpdfTextFindNext;
late FPDFTextFindPrev fpdfTextFindPrev;
late FPDFTextGetSchResultIndex fpdfTextGetSchResultIndex;
late FPDFTextGetSchCount fpdfTextGetSchCount;
late FPDFTextFindClose fpdfTextFindClose;

late FPDFBookmarkGetFirstChild fpdfBookmarkGetFirstChild;
late FPDFBookmarkGetNextSibling fpdfBookmarkGetNextSibling;
late FPDFBookmarkGetTitle fpdfBookmarkGetTitle;
late FPDFBookmarkGetDest fpdfBookmarkGetDest;

late FPDFPageCreateAnnot fpdfPageCreateAnnot;
late FPDFPageCloseAnnot fpdfPageCloseAnnot;
late FPDFAnnotSetColor fpdfAnnotSetColor;
late FPDFAnnotSetAP fpdfAnnotSetAP;
late FPDFAnnotAppendAttachmentPoints fpdfAnnotAppendAttachmentPoints;
late FPDFAnnotSetFlags fpdfAnnotSetFlags;
late FPDFPageGenerateContent fpdfPageGenerateContent;
late FPDFPageGetAnnotCount fpdfPageGetAnnotCount;
late FPDFPageGetAnnot fpdfPageGetAnnot;
late FPDFAnnotGetSubtype fpdfAnnotGetSubtype;
late FPDFAnnotCountAttachmentPoints fpdfAnnotCountAttachmentPoints;
late FPDFAnnotGetAttachmentPoints fpdfAnnotGetAttachmentPoints;
late FPDFPageRemoveAnnot fpdfPageRemoveAnnot;
late FPDFSaveAsCopy fpdfSaveAsCopy;
late FPDFLinkGetLinkAtPoint fpdfLinkGetLinkAtPoint;
late FPDFLinkGetDest fpdfLinkGetDest;
late FPDFLinkGetAction fpdfLinkGetAction;
late FPDFActionGetType fpdfActionGetType;
late FPDFActionGetDest fpdfActionGetDest;
late FPDFActionGetURIPath fpdfActionGetURIPath;
late FPDFDestGetDestPageIndex fpdfDestGetDestPageIndex;
late FPDFLinkGetAnnotRect fpdfLinkGetAnnotRect;
late FPDFLinkEnumerate fpdfLinkEnumerate;

late FPDFPageCountObjects fpdfPageCountObjects;
late FPDFPageGetObject fpdfPageGetObject;
late FPDFPageObjGetType fpdfPageObjGetType;
late FPDFPageObjGetBounds fpdfPageObjGetBounds;
late FPDFImageObjGetBitmap fpdfImageObjGetBitmap;
late FPDFImageObjGetRenderedBitmap fpdfImageObjGetRenderedBitmap;
late FPDFBitmapGetWidth fpdfBitmapGetWidth;
late FPDFBitmapGetHeight fpdfBitmapGetHeight;
late FPDFCreateNewDocument fpdfCreateNewDocument;
late FPDFImportPagesByIndex fpdfImportPagesByIndex;
late FPDFPageSetRotation fpdfPageSetRotation;
late FPDFPageGetRotation fpdfPageGetRotation;
late FPDFPageDelete fpdfPageDelete;
late FPDFMovePages fpdfMovePages;
