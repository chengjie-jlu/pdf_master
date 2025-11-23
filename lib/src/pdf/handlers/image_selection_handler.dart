import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/pdf/context/context_menu_constants.dart';
import 'package:pdf_master/src/pdf/context/image_context_menu.dart';
import 'package:pdf_master/src/pdf/handlers/gesture_handler.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';
import 'dart:ui' as ui;

import 'package:pdf_master/src/utils/log.dart';

const int kIndexNotSet = -1;

class _ImageSelectionInfo {
  Rect displayBound = Rect.zero;
  ui.Image? image;

  bool get hasSelection => image != null && displayBound != Rect.zero;

  void clear() {
    displayBound = Rect.zero;
    image?.dispose();
    image = null;
  }
}

/// 图片选择处理器
class ImageSelectionHandler extends GestureHandler {
  final BuildContext context;
  final PdfController controller;
  final int pageIndex;
  final Size pageSize;
  final double Function() getRenderWidth;
  final double Function() getRenderHeight;
  final VoidCallback onStateChanged;

  final _imageSelection = _ImageSelectionInfo();

  ImageSelectionHandler({
    required this.context,
    required this.controller,
    required this.pageIndex,
    required this.pageSize,
    required this.getRenderWidth,
    required this.getRenderHeight,
    required this.onStateChanged,
  });

  @override
  bool get hasSelection => _imageSelection.hasSelection;

  @override
  void clearSelection() {
    if (_imageSelection.hasSelection) {
      _imageSelection.clear();
      onStateChanged();
    }
  }

  @override
  Future<GestureHandleResult> handleTap(TapUpDetails details) async {
    if (_imageSelection.hasSelection) {
      clearSelection();
      return GestureHandleResult.handled;
    }

    // 尝试选中图片
    final localPosition = details.localPosition;
    final renderWidth = getRenderWidth();
    final renderHeight = getRenderHeight();

    final pdfX = localPosition.dx / renderWidth * pageSize.width;
    final pdfY = pageSize.height - (localPosition.dy / renderHeight * pageSize.height);

    // 计算容差：在屏幕上约 12 像素的点击范围，转换为 PDF 坐标
    final toleranceInScreen = 12.0;
    final toleranceInPdf = toleranceInScreen / renderWidth * pageSize.width;

    // 检测是否命中图片
    final imageInfo = await controller.getImageObjectAtPosition(pageIndex, pdfX, pdfY, tolerance: toleranceInPdf);
    if (imageInfo != null && imageInfo.image != null) {
      // 将 PDF 坐标转换为显示坐标
      final pdfRect = imageInfo.bounds;
      final left = pdfRect.left / pageSize.width * renderWidth;
      final top = (pageSize.height - pdfRect.bottom) / pageSize.height * renderHeight;
      final width = pdfRect.width / pageSize.width * renderWidth;
      final height = pdfRect.height / pageSize.height * renderHeight;

      _imageSelection.displayBound = Rect.fromLTWH(left, top, width, height);
      _imageSelection.image = imageInfo.image;
      onStateChanged();
      return GestureHandleResult.handled;
    }

    return GestureHandleResult.notHandled;
  }

  @override
  List<Widget> buildWidgets(BuildContext context) {
    if (!_imageSelection.hasSelection) {
      return [];
    }

    final children = <Widget>[];
    final renderWidth = getRenderWidth();
    final boundingBox = _imageSelection.displayBound;

    // 虚线边框
    children.add(
      ValueListenableBuilder(
        valueListenable: controller.scaleNotifier,
        builder: (context, scale, child) {
          final adjustedStrokeWidth = 1.0 / scale;
          final adjustedDashLength = 2.0 / scale;
          final adjustedDashSpace = 2.0 / scale;
          return Positioned.fromRect(
            rect: boundingBox,
            child: DottedBorder(
              options: RectDottedBorderOptions(
                color: Colors.grey,
                strokeWidth: adjustedStrokeWidth,
                dashPattern: [adjustedDashLength, adjustedDashSpace],
                padding: EdgeInsets.zero,
              ),
              child: SizedBox(width: boundingBox.width, height: boundingBox.height),
            ),
          );
        },
      ),
    );

    // 上下文菜单
    children.add(
      ValueListenableBuilder(
        valueListenable: controller.scaleNotifier,
        builder: (context, scale, child) {
          final menuPos = _getContextMenuPosition(scale, boundingBox, renderWidth);
          return Positioned(
            top: menuPos.dy,
            left: menuPos.dx,
            width: kContextMenuWidth,
            child: ImageContextMenu(
              scale: scale,
              showContextMenu: true,
              onAction: (action) => _onImageContextAction(context, action),
            ),
          );
        },
      ),
    );

    return children;
  }

  Offset _getContextMenuPosition(double scale, Rect imageBound, double renderWidth) {
    final renderHeight = getRenderHeight();
    final minTopPadding = 6.0;
    final minBottomPadding = 6.0;
    final scaledMenuWidth = kContextMenuWidth / scale;
    final scaledMenuHeight = kContextMenuHeight / scale;
    final scaledHandleSize = 18.0 / scale;

    // 尝试在图片上方显示菜单
    final topPosition = imageBound.top - scaledMenuHeight - scaledHandleSize - 4;
    // 尝试在图片下方显示菜单
    final bottomPosition = imageBound.bottom + scaledHandleSize + 4;

    // 判断菜单应该显示在上方还是下方
    double finalTop;
    if (topPosition > minTopPadding) {
      // 上方有足够空间
      finalTop = topPosition;
    } else if (bottomPosition + scaledMenuHeight < renderHeight - minBottomPadding) {
      // 下方有足够空间
      finalTop = bottomPosition;
    } else {
      // 上下都没有足够空间，优先显示在图片内部顶部
      finalTop = imageBound.top + minTopPadding;
    }

    final centerLeft = (imageBound.left + imageBound.right - scaledMenuWidth) / 2;
    double finalLeft = centerLeft;
    if (centerLeft < 0) {
      finalLeft = 0;
    } else if (centerLeft + scaledMenuWidth > renderWidth) {
      finalLeft = renderWidth - scaledMenuWidth;
    }
    return Offset(finalLeft, finalTop);
  }

  Future<void> _onImageContextAction(BuildContext context, ImageContextAction action) async {
    switch (action) {
      case ImageContextAction.kView:
        showImagePreview(context, _imageSelection.image?.clone());
        clearSelection();
        break;

      case ImageContextAction.kSave:
        await _saveImageToGallery(_imageSelection.image);
        clearSelection();
        break;
    }
  }

  Future<void> _saveImageToGallery(ui.Image? image) async {
    if (image == null) {
      return;
    }
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      Log.e('ImageSelectionHandler', 'byteData is null');
      return;
    }
    PdfMaster.instance.imageSaveHandler?.handleSavePngBytes(byteData.buffer.asUint8List());
  }
}

void showImagePreview(BuildContext context, ui.Image? image) {
  if (image == null) {
    return;
  }

  Navigator.of(context).push(PDFMasterPageRouter(builder: (ctx) => ImagePreviewPage(image: image)));
}

class ImagePreviewPage extends StatefulWidget {
  final ui.Image image;

  const ImagePreviewPage({super.key, required this.image});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> with SingleTickerProviderStateMixin {
  @override
  void dispose() {
    super.dispose();
    widget.image.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PdfMasterAppBar(
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
            title: context.localizations['imgPreview'],
          ),
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: Center(
                child: RawImage(image: widget.image, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveImageToGallery,
        child: Icon(Icons.file_download_outlined, color: Colors.white),
      ),
    );
  }

  void _saveImageToGallery() async {
    final byteData = await widget.image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) {
      Log.e('ImagePreview', 'byteData is null');
      return;
    }
    PdfMaster.instance.imageSaveHandler?.handleSavePngBytes(byteData.buffer.asUint8List());
  }
}
