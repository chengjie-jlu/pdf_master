import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/src/core/ffi_define.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/core/pdf_ffi_api.dart';
import 'package:pdf_master/src/pdf/context/context_menu.dart';
import 'package:pdf_master/src/pdf/context/color_picker.dart';
import 'package:pdf_master/src/pdf/handlers/gesture_handler.dart';
import 'package:url_launcher/url_launcher.dart';

const int kIndexNotSet = -1;
const double _sameLineThreshold = 0.6;

class _AnnotationSelectionInfo {
  List<AnnotationInfo> annotations = [];
  List<Rect> displayBounds = [];

  /// 获取整个选中区域的边界框
  Rect get boundingBox {
    if (displayBounds.isEmpty) return Rect.zero;

    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;

    for (final rect in displayBounds) {
      if (rect.left < left) left = rect.left;
      if (rect.top < top) top = rect.top;
      if (rect.right > right) right = rect.right;
      if (rect.bottom > bottom) bottom = rect.bottom;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  bool get hasSelection => annotations.isNotEmpty && displayBounds.isNotEmpty;

  bool get isHyperlink => annotations.length == 1 && annotations[0].annotType == kPdfAnnotLink;

  void clear() {
    annotations.clear();
    displayBounds.clear();
  }
}

/// 标注选择处理器
class AnnotationSelectionHandler extends GestureHandler {
  final PdfController controller;
  final int pageIndex;
  final Size pageSize;
  final double renderWidth;
  final double renderHeight;
  final VoidCallback onPdfContentChanged;
  final VoidCallback onStateChanged;

  final _annotSelection = _AnnotationSelectionInfo();

  // 缓存的页面标注信息
  List<AnnotationInfo> _cachedLinks = [];
  List<AnnotationInfo> _cachedHighlights = [];

  AnnotationSelectionHandler({
    required this.controller,
    required this.pageIndex,
    required this.pageSize,
    required this.renderWidth,
    required this.renderHeight,
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

  void refreshAnnotationInfo() async {
    _cachedLinks = await controller.getPageLinks(pageIndex);
    _cachedHighlights = await controller.getPageHighlights(pageIndex);
  }

  @override
  Future<GestureHandleResult> handleTap(TapUpDetails details) async {
    if (_annotSelection.hasSelection) {
      clearSelection();
      return GestureHandleResult.handled;
    }

    final localPosition = details.localPosition;
    final pdfX = localPosition.dx / renderWidth * pageSize.width;
    final pdfY = pageSize.height - (localPosition.dy / renderHeight * pageSize.height);

    final toleranceInScreen = 12.0;
    final toleranceInPdf = toleranceInScreen / renderWidth * pageSize.width;

    // 从缓存中查找匹配的标注
    final annotInfos = <AnnotationInfo>[];

    // 检查链接标注
    for (final linkInfo in _cachedLinks) {
      bool hit = false;
      for (final pdfRect in linkInfo.rects) {
        if (pdfX >= pdfRect.left - toleranceInPdf &&
            pdfX <= pdfRect.right + toleranceInPdf &&
            pdfY <= pdfRect.bottom + toleranceInPdf &&
            pdfY >= pdfRect.top - toleranceInPdf) {
          hit = true;
          break;
        }
      }
      if (hit) {
        annotInfos.add(linkInfo);
        break;
      }
    }

    // 检查高亮标注
    for (final highlightInfo in _cachedHighlights) {
      // 计算整个高亮标注的边界
      double minLeft = double.infinity;
      double maxRight = double.negativeInfinity;
      double minBottom = double.infinity;
      double maxTop = double.negativeInfinity;

      for (final pdfRect in highlightInfo.rects) {
        if (pdfRect.left < minLeft) minLeft = pdfRect.left;
        if (pdfRect.right > maxRight) maxRight = pdfRect.right;
        if (pdfRect.bottom < minBottom) minBottom = pdfRect.bottom;
        if (pdfRect.top > maxTop) maxTop = pdfRect.top;
      }

      if (pdfX >= minLeft - toleranceInPdf &&
          pdfX <= maxRight + toleranceInPdf &&
          pdfY <= minBottom + toleranceInPdf &&
          pdfY >= maxTop - toleranceInPdf) {
        annotInfos.add(highlightInfo);
      }
    }

    if (annotInfos.isNotEmpty) {
      // 存储所有选中的标注
      _annotSelection.annotations = annotInfos;

      // 计算所有标注的显示边界
      List<Rect> allDisplayBounds = [];
      for (final annotInfo in annotInfos) {
        for (final pdfRect in annotInfo.rects) {
          final left = pdfRect.left / pageSize.width * renderWidth;
          final top = (pageSize.height - pdfRect.bottom) / pageSize.height * renderHeight;
          final width = pdfRect.width / pageSize.width * renderWidth;
          final height = pdfRect.height / pageSize.height * renderHeight;
          allDisplayBounds.add(Rect.fromLTWH(left, top, width, height));
        }
      }

      _annotSelection.displayBounds = _mergeRectsInSameLine(allDisplayBounds);
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
              child: Container(
                color: Colors.blue.withAlpha(_annotSelection.isHyperlink ? 76 : 0),
                width: boundingBox.width,
                height: boundingBox.height,
              ),
            ),
          );
        },
      ),
    );

    // 根据标注类型确定需要显示的操作
    final linkAnnots = _annotSelection.annotations
        .where((a) => a.annotType == kPdfAnnotLink && a.linkType != null)
        .toList();
    final hasHighlightAnnots = _annotSelection.annotations.any((a) => a.annotType == kPdfAnnotHighlight);

    final actions = <MenuAction>[];

    // 如果有高亮标注，添加删除和编辑操作
    if (hasHighlightAnnots) {
      actions.add(MenuAction.kDelete);
      actions.add(MenuAction.kEdit);
    }

    // 如果有链接标注，添加跳转或打开操作
    if (linkAnnots.isNotEmpty) {
      final firstLink = linkAnnots.first;
      if (firstLink.linkType == PdfLinkType.goto) {
        actions.add(MenuAction.kJump);
      } else if (firstLink.linkType == PdfLinkType.uri) {
        actions.add(MenuAction.kOpenWebUrl);
      }
    }

    // 显示上下文菜单
    if (actions.isNotEmpty) {
      children.add(
        ValueListenableBuilder(
          valueListenable: controller.scaleNotifier,
          builder: (context, scale, child) {
            return ContextMenu(
              scale: scale,
              showContextMenu: true,
              actions: actions,
              onAction: (action) => _onContextAction(context, action),
              boundingBox: _annotSelection.boundingBox,
              renderWidth: renderWidth,
              renderHeight: renderHeight,
            );
          },
        ),
      );
    }

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

  Future<void> _onContextAction(BuildContext context, MenuAction action) async {
    switch (action) {
      case MenuAction.kDelete:
        // 删除所有选中的高亮标注（不包括链接标注）
        for (final annot in _annotSelection.annotations) {
          if (annot.annotType == kPdfAnnotHighlight && annot.annotIndex != kIndexNotSet) {
            await controller.removeAnnotation(pageIndex, annot.annotIndex);
          }
        }
        onPdfContentChanged();
        clearSelection();
        break;

      case MenuAction.kEdit:
        // 修改所有选中的高亮标注的颜色
        final highlightAnnots = _annotSelection.annotations
            .where((a) => a.annotType == kPdfAnnotHighlight && a.annotIndex != kIndexNotSet)
            .toList();
        if (highlightAnnots.isNotEmpty) {
          _showColorPicker(context, highlightAnnots);
        }
        break;

      case MenuAction.kJump:
        // 处理跳转操作
        final linkAnnots = _annotSelection.annotations
            .where((a) => a.annotType == kPdfAnnotLink && a.linkType == PdfLinkType.goto)
            .toList();
        if (linkAnnots.isNotEmpty) {
          _handleLinkAction(linkAnnots.first);
          clearSelection();
        }
        break;

      case MenuAction.kOpenWebUrl:
        // 处理打开URL操作
        final linkAnnots = _annotSelection.annotations
            .where((a) => a.annotType == kPdfAnnotLink && a.linkType == PdfLinkType.uri)
            .toList();
        if (linkAnnots.isNotEmpty) {
          _handleLinkAction(linkAnnots.first);
          clearSelection();
        }
        break;
      default:
        break;
    }
  }

  void _showColorPicker(BuildContext context, List<AnnotationInfo> highlightAnnots) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return ColorPickerBottomSheet(
          onColorSelected: (highlightColor) async {
            for (final annot in highlightAnnots) {
              await controller.updateAnnotationColor(
                pageIndex,
                annot.annotIndex,
                r: highlightColor.r,
                g: highlightColor.g,
                b: highlightColor.b,
                a: highlightColor.a,
              );
            }
            onPdfContentChanged();
          },
        );
      },
    );
  }

  /// 处理链接跳转
  void _handleLinkAction(AnnotationInfo linkAnnot) {
    if (linkAnnot.linkType == null) return;

    switch (linkAnnot.linkType!) {
      case PdfLinkType.goto:
        final targetPage = linkAnnot.linkTarget as int?;
        if (targetPage != null && targetPage >= 0 && targetPage < controller.pageCount) {
          controller.tocState.onPageChanged?.call(targetPage);
        }
        break;

      case PdfLinkType.uri:
        final url = linkAnnot.linkTarget as String?;
        if (url != null && url.isNotEmpty) {
          _openUrl(url);
        }
        break;
    }
  }

  /// 打开URL
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
