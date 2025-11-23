import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/pdf/context/anno_context_menu.dart';
import 'package:pdf_master/src/pdf/context/color_picker.dart';
import 'package:pdf_master/src/pdf/context/context_menu_constants.dart';
import 'package:pdf_master/src/pdf/handlers/gesture_handler.dart';

const int kIndexNotSet = -1;
const double _sameLineThreshold = 0.6;

class _AnnotationSelectionInfo {
  int annotIndex = kIndexNotSet;
  List<Rect> displayBounds = [];

  Rect get firstLine => displayBounds.first;

  Rect get lastLine => displayBounds.last;

  bool get hasSelection => annotIndex > kIndexNotSet && displayBounds.isNotEmpty;

  void clear() {
    annotIndex = kIndexNotSet;
    displayBounds.clear();
  }
}

/// 标注选择处理器
class AnnotationSelectionHandler extends GestureHandler {
  final PdfController controller;
  final int pageIndex;
  final Size pageSize;
  final double Function() getRenderWidth;
  final double Function() getRenderHeight;
  final VoidCallback onPdfContentChanged;
  final VoidCallback onStateChanged;

  final _annotSelection = _AnnotationSelectionInfo();

  AnnotationSelectionHandler({
    required this.controller,
    required this.pageIndex,
    required this.pageSize,
    required this.getRenderWidth,
    required this.getRenderHeight,
    required this.onPdfContentChanged,
    required this.onStateChanged,
  });

  @override
  bool get hasSelection => _annotSelection.hasSelection;

  @override
  void clearSelection() {
    if (_annotSelection.hasSelection) {
      _annotSelection.clear();
      onStateChanged();
    }
  }

  void selectAnnotationAtPosition(Offset screenPosition) async {
    handleTap(TapUpDetails(kind: PointerDeviceKind.touch, localPosition: screenPosition));
  }

  @override
  Future<GestureHandleResult> handleTap(TapUpDetails details) async {
    if (_annotSelection.hasSelection) {
      clearSelection();
      return GestureHandleResult.handled;
    }

    // 尝试选中标注
    final localPosition = details.localPosition;
    final renderWidth = getRenderWidth();
    final renderHeight = getRenderHeight();

    final pdfX = localPosition.dx / renderWidth * pageSize.width;
    final pdfY = pageSize.height - (localPosition.dy / renderHeight * pageSize.height);

    // 计算容差：在屏幕上约 12 像素的点击范围，转换为 PDF 坐标
    // 这样即使标注很小，也能有一个合理的点击区域
    final toleranceInScreen = 12.0;
    final toleranceInPdf = toleranceInScreen / renderWidth * pageSize.width;

    final annotInfo = await controller.getAnnotationAtPosition(pageIndex, pdfX, pdfY, tolerance: toleranceInPdf);

    if (annotInfo != null && annotInfo.rects.isNotEmpty) {
      List<Rect> displayBounds = [];
      for (final pdfRect in annotInfo.rects) {
        final left = pdfRect.left / pageSize.width * renderWidth;
        final top = (pageSize.height - pdfRect.bottom) / pageSize.height * renderHeight;
        final width = pdfRect.width / pageSize.width * renderWidth;
        final height = pdfRect.height / pageSize.height * renderHeight;
        displayBounds.add(Rect.fromLTWH(left, top, width, height));
      }

      _annotSelection.displayBounds = _mergeRectsInSameLine(displayBounds);
      _annotSelection.annotIndex = annotInfo.annotIndex;
      onStateChanged();
      return GestureHandleResult.handled;
    }

    return GestureHandleResult.notHandled;
  }

  @override
  List<Widget> buildWidgets(BuildContext context) {
    if (!_annotSelection.hasSelection) {
      return [];
    }

    final children = <Widget>[];
    final renderWidth = getRenderWidth();
    final boundingBox = _getBoundingBox(_annotSelection.displayBounds);

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
          final menuPos = _getContextMenuPosition(
            scale,
            _annotSelection.firstLine,
            _annotSelection.lastLine,
            renderWidth,
          );
          return Positioned(
            top: menuPos.dy,
            left: menuPos.dx,
            width: kContextMenuWidth,
            child: AnnoContextMenu(
              scale: scale,
              showContextMenu: true,
              onAction: (action) => _onAnnoContextAction(context, action),
            ),
          );
        },
      ),
    );

    return children;
  }

  List<Rect> _mergeRectsInSameLine(List<Rect> rects) {
    if (rects.isEmpty) return [];

    List<Rect> mergedRects = [];
    Rect? currentLine;

    for (final rect in rects) {
      if (currentLine == null) {
        currentLine = rect;
      } else {
        final currentCenter = currentLine.top + currentLine.height / 2;
        final rectCenter = rect.top + rect.height / 2;
        final maxHeight = currentLine.height > rect.height ? currentLine.height : rect.height;

        final isSameLine = (currentCenter - rectCenter).abs() < maxHeight * _sameLineThreshold;

        if (isSameLine) {
          final left = currentLine.left < rect.left ? currentLine.left : rect.left;
          final right = currentLine.right > rect.right ? currentLine.right : rect.right;
          final top = currentLine.top < rect.top ? currentLine.top : rect.top;
          final bottom = currentLine.bottom > rect.bottom ? currentLine.bottom : rect.bottom;
          currentLine = Rect.fromLTRB(left, top, right, bottom);
        } else {
          mergedRects.add(currentLine);
          currentLine = rect;
        }
      }
    }

    if (currentLine != null) {
      mergedRects.add(currentLine);
    }

    return mergedRects;
  }

  Rect _getBoundingBox(List<Rect> rects) {
    if (rects.isEmpty) return Rect.zero;

    double left = rects.first.left;
    double top = rects.first.top;
    double right = rects.first.right;
    double bottom = rects.first.bottom;

    for (final rect in rects) {
      if (rect.left < left) left = rect.left;
      if (rect.top < top) top = rect.top;
      if (rect.right > right) right = rect.right;
      if (rect.bottom > bottom) bottom = rect.bottom;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Offset _getContextMenuPosition(double scale, Rect firstLine, Rect lastLine, double renderWidth) {
    final minTopPadding = 6.0;
    final scaledMenuWidth = kContextMenuWidth / scale;
    final scaledMenuHeight = kContextMenuHeight / scale;
    final scaledHandleSize = 18.0 / scale;

    final top = firstLine.top - scaledMenuHeight - scaledHandleSize - 4;
    final finalTop = top > minTopPadding ? top : firstLine.bottom + scaledHandleSize + 4;

    final centerLeft = (firstLine.left + lastLine.right - scaledMenuWidth) / 2;
    double finalLeft = centerLeft;
    if (centerLeft < 0) {
      finalLeft = 0;
    } else if (centerLeft + scaledMenuWidth > renderWidth) {
      finalLeft = renderWidth - scaledMenuWidth;
    }
    return Offset(finalLeft, finalTop);
  }

  Future<void> _onAnnoContextAction(BuildContext context, AnnoContextAction action) async {
    switch (action) {
      case AnnoContextAction.kRemove:
        if (_annotSelection.annotIndex != kIndexNotSet) {
          final success = await controller.removeAnnotation(pageIndex, _annotSelection.annotIndex);
          if (success) {
            onPdfContentChanged();
          }
        }
        clearSelection();
        break;

      case AnnoContextAction.kStyle:
        if (_annotSelection.annotIndex != kIndexNotSet) {
          _showColorPicker(context);
        }
        break;
    }
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return ColorPickerBottomSheet(
          onColorSelected: (highlightColor) async {
            if (_annotSelection.annotIndex != kIndexNotSet) {
              await controller.updateAnnotationColor(
                pageIndex,
                _annotSelection.annotIndex,
                r: highlightColor.r,
                g: highlightColor.g,
                b: highlightColor.b,
                a: highlightColor.a,
              );
              onPdfContentChanged();
            }
          },
        );
      },
    );
  }
}
