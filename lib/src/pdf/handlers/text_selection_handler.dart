import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/pdf/context/context_menu_constants.dart';
import 'package:pdf_master/src/pdf/context/text_context_menu.dart';
import 'package:pdf_master/src/pdf/handlers/gesture_handler.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

const int kIndexNotSet = -1;
const double _handleTouchRadius = 48.0;
const double _handleWidth = 36.0;
const double _handleCircleSize = 18.0;
const double _longPressSelectionRange = 12.0;
const double _sameLineThreshold = 0.6;

enum _DragTarget { none, leftHandle, rightHandle }

class _TextSelectionInfo {
  List<Rect> displayBounds = [];
  int startCharIndex = kIndexNotSet;
  int endCharIndex = kIndexNotSet;

  Rect get firstLine => displayBounds.first;

  Rect get lastLine => displayBounds.last;

  bool get hasSelection => displayBounds.isNotEmpty;

  void clear() {
    displayBounds.clear();
    startCharIndex = kIndexNotSet;
    endCharIndex = kIndexNotSet;
  }
}

/// 文字选择处理器
class TextSelectionHandler extends GestureHandler {
  final PdfController controller;
  final int pageIndex;
  final Size pageSize;
  final double Function() getRenderWidth;
  final double Function() getRenderHeight;
  final VoidCallback onPdfContentChanged;
  final VoidCallback onStateChanged;
  final void Function(Offset position) onHighlightCreated;

  final _textSelection = _TextSelectionInfo();
  Offset _leftHandleInitialPos = Offset.zero;
  Offset _rightHandleInitialPos = Offset.zero;
  Offset _panStartPos = Offset.zero;
  _DragTarget _dragTarget = _DragTarget.none;
  bool _hasDragged = false;
  bool _showTextContextMenu = false;

  TextSelectionHandler({
    required this.controller,
    required this.pageIndex,
    required this.pageSize,
    required this.getRenderWidth,
    required this.getRenderHeight,
    required this.onHighlightCreated,
    required this.onPdfContentChanged,
    required this.onStateChanged,
  });

  @override
  bool get hasSelection => _textSelection.hasSelection;

  @override
  void clearSelection() {
    if (_textSelection.hasSelection) {
      _textSelection.clear();
      _showTextContextMenu = false;
      onStateChanged();
    }
  }

  @override
  Future<GestureHandleResult> handleTap(TapUpDetails details) async {
    // 如果有文字选中，清除选中状态
    if (_textSelection.hasSelection) {
      clearSelection();
      return GestureHandleResult.handled;
    }
    return GestureHandleResult.notHandled;
  }

  @override
  Future<GestureHandleResult> handleLongPress(LongPressStartDetails details) async {
    final localPosition = details.localPosition;
    final renderWidth = getRenderWidth();
    final renderHeight = getRenderHeight();

    final leftX = (localPosition.dx - _longPressSelectionRange).clamp(0.0, renderWidth);
    final rightX = (localPosition.dx + _longPressSelectionRange).clamp(0.0, renderWidth);

    final pdfY = pageSize.height - (localPosition.dy / renderHeight * pageSize.height);
    final pdfLeftX = leftX / renderWidth * pageSize.width;
    final pdfRightX = rightX / renderWidth * pageSize.width;

    final toleranceInPdfY = _longPressSelectionRange / renderHeight * pageSize.height;

    final startCharIndex = await controller.getCharIndexAtPosition(
      pageIndex,
      pdfLeftX,
      pdfY,
      xTolerance: double.infinity,
      yTolerance: toleranceInPdfY,
    );

    final endCharIndex = await controller.getCharIndexAtPosition(
      pageIndex,
      pdfRightX,
      pdfY,
      xTolerance: double.infinity,
      yTolerance: toleranceInPdfY,
    );

    if (startCharIndex >= 0 && endCharIndex >= 0) {
      final start = startCharIndex < endCharIndex ? startCharIndex : endCharIndex;
      int end = startCharIndex < endCharIndex ? endCharIndex : startCharIndex;

      // TODO: 主要为了处理表格中跨单元格选中的 case
      if (end - start > 10) {
        end = start;
      }

      await _updateSelectionBounds(start, end);
      _showTextContextMenu = true;
      onStateChanged();
      HapticFeedback.lightImpact();
      return GestureHandleResult.handled;
    }

    return GestureHandleResult.notHandled;
  }

  @override
  bool shouldAcceptPan(Offset position) {
    if (!_textSelection.hasSelection) {
      return false;
    }

    final currentScale = controller.scaleNotifier.value;
    final touchRadius = _handleTouchRadius / currentScale;

    final leftTopCorner = _textSelection.firstLine.topLeft;
    final leftHandleRect = Rect.fromLTRB(
      leftTopCorner.dx - touchRadius,
      leftTopCorner.dy - _handleCircleSize / currentScale,
      leftTopCorner.dx,
      leftTopCorner.dy + touchRadius,
    );

    final rightBottomCorner = _textSelection.lastLine.bottomRight;
    final rightHandleRect = Rect.fromLTRB(
      rightBottomCorner.dx,
      rightBottomCorner.dy,
      rightBottomCorner.dx + touchRadius,
      rightBottomCorner.dy + touchRadius,
    );

    if (leftHandleRect.contains(position)) {
      _dragTarget = _DragTarget.leftHandle;
    } else if (rightHandleRect.contains(position)) {
      _dragTarget = _DragTarget.rightHandle;
    } else {
      _dragTarget = _DragTarget.none;
    }
    return _dragTarget != _DragTarget.none;
  }

  @override
  void handlePanStart(DragStartDetails details) {
    if (!_textSelection.hasSelection) return;

    _hasDragged = false;
    _panStartPos = details.localPosition;
    _leftHandleInitialPos = _textSelection.firstLine.bottomLeft;
    _rightHandleInitialPos = _textSelection.lastLine.topRight;
  }

  @override
  void handlePanUpdate(DragUpdateDetails details) {
    if (!_textSelection.hasSelection) return;

    _hasDragged = true;
    _showTextContextMenu = false;
    if (_dragTarget == _DragTarget.leftHandle) {
      _updateLeftHandle(details);
    } else if (_dragTarget == _DragTarget.rightHandle) {
      _updateRightHandle(details);
    }
  }

  @override
  Future<void> handlePanEnd(DragEndDetails details) async {
    if (!_textSelection.hasSelection) return;

    if (!_hasDragged) {
      clearSelection();
      return;
    }

    _showTextContextMenu = true;
    onStateChanged();
  }

  @override
  List<Widget> buildWidgets(BuildContext context) {
    if (!_textSelection.hasSelection) {
      return [];
    }

    final children = <Widget>[];
    final renderWidth = getRenderWidth();

    // 高亮区域
    children.addAll(
      _textSelection.displayBounds.map(
        (rect) => Positioned.fromRect(
          rect: rect,
          child: Container(color: Colors.blue.withAlpha(76)),
        ),
      ),
    );

    // 左手柄
    children.add(
      Positioned(
        left: _textSelection.firstLine.left - _handleWidth,
        top: _textSelection.firstLine.top - _handleCircleSize,
        width: _handleWidth,
        child: _SelectionHandle(isLeft: true, rect: _textSelection.firstLine, scaleNotifier: controller.scaleNotifier),
      ),
    );

    // 右手柄
    children.add(
      Positioned(
        left: _textSelection.lastLine.right,
        top: _textSelection.lastLine.top,
        width: _handleWidth,
        child: _SelectionHandle(isLeft: false, rect: _textSelection.lastLine, scaleNotifier: controller.scaleNotifier),
      ),
    );

    // 上下文菜单
    children.add(
      ValueListenableBuilder(
        valueListenable: controller.scaleNotifier,
        builder: (context, scale, child) {
          final menuPos = _getContextMenuPosition(
            scale,
            _textSelection.firstLine,
            _textSelection.lastLine,
            renderWidth,
          );
          return Positioned(
            top: menuPos.dy,
            left: menuPos.dx,
            width: kContextMenuWidth,
            child: TextContextMenu(
              scale: scale,
              showContextMenu: _showTextContextMenu,
              onAction: (action) => _onTextContextAction(context, action),
            ),
          );
        },
      ),
    );

    return children;
  }

  Future<void> _updateSelectionBounds(int startIndex, int endIndex) async {
    if (startIndex < 0 || endIndex < 0 || startIndex > endIndex) {
      return;
    }

    final renderWidth = getRenderWidth();
    final renderHeight = getRenderHeight();

    _textSelection.startCharIndex = startIndex;
    _textSelection.endCharIndex = endIndex;
    final count = endIndex - startIndex + 1;
    final pdfRects = await controller.getTextRects(pageIndex, startIndex, count);

    if (pdfRects.isEmpty) {
      return;
    }

    List<Rect> displayBounds = [];
    for (final pdfRect in pdfRects) {
      final left = pdfRect.left / pageSize.width * renderWidth;
      final top = (pageSize.height - pdfRect.bottom) / pageSize.height * renderHeight;
      final width = pdfRect.width / pageSize.width * renderWidth;
      final height = pdfRect.height / pageSize.height * renderHeight;
      displayBounds.add(Rect.fromLTWH(left, top, width, height));
    }

    _textSelection.displayBounds = _mergeRectsInSameLine(displayBounds);
    onStateChanged();
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

  Offset _getContextMenuPosition(double scale, Rect firstLine, Rect lastLine, double renderWidth) {
    final minTopPadding = 6.0;
    final scaledMenuWidth = kContextMenuWidth / scale;
    final scaledMenuHeight = kContextMenuHeight / scale;
    final scaledHandleSize = _handleCircleSize / scale;

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

  Future<int> _getCharIndexAtScreenPosition(Offset screenPos) async {
    final renderWidth = getRenderWidth();
    final renderHeight = getRenderHeight();

    final pdfX = screenPos.dx / renderWidth * pageSize.width;
    final pdfY = pageSize.height - (screenPos.dy / renderHeight * pageSize.height);

    return await controller.getCharIndexAtPosition(
      pageIndex,
      pdfX,
      pdfY,
      xTolerance: double.infinity,
      yTolerance: double.infinity,
    );
  }

  void _updateLeftHandle(DragUpdateDetails details) async {
    final delta = details.localPosition - _panStartPos;
    final newPos = _leftHandleInitialPos + delta;
    final newStartIndex = await _getCharIndexAtScreenPosition(newPos);

    if (newStartIndex >= 0) {
      if (newStartIndex > _textSelection.endCharIndex) {
        _swapHandles(
          newTarget: _DragTarget.rightHandle,
          newLeftPos: _textSelection.lastLine.bottomLeft,
          newRightPos: _leftHandleInitialPos,
        );
        await _updateSelectionBounds(_textSelection.endCharIndex, newStartIndex);
      } else {
        await _updateSelectionBounds(newStartIndex, _textSelection.endCharIndex);
      }
    }
  }

  void _updateRightHandle(DragUpdateDetails details) async {
    final delta = details.localPosition - _panStartPos;
    final newPos = _rightHandleInitialPos + delta;
    final newEndIndex = await _getCharIndexAtScreenPosition(newPos);

    if (newEndIndex >= 0) {
      if (newEndIndex < _textSelection.startCharIndex) {
        _swapHandles(
          newTarget: _DragTarget.leftHandle,
          newLeftPos: _rightHandleInitialPos,
          newRightPos: _textSelection.firstLine.topRight,
        );
        await _updateSelectionBounds(newEndIndex, _textSelection.startCharIndex);
      } else {
        await _updateSelectionBounds(_textSelection.startCharIndex, newEndIndex);
      }
    }
  }

  void _swapHandles({required _DragTarget newTarget, required Offset newLeftPos, required Offset newRightPos}) {
    _dragTarget = newTarget;
    _leftHandleInitialPos = newLeftPos;
    _rightHandleInitialPos = newRightPos;
  }

  Future<void> _onTextContextAction(BuildContext context, TextContextAction action) async {
    switch (action) {
      case TextContextAction.kCopy:
        if (_textSelection.startCharIndex >= 0 && _textSelection.endCharIndex >= 0) {
          final count = _textSelection.endCharIndex - _textSelection.startCharIndex + 1;
          final selectedText = await controller.getTextRange(pageIndex, _textSelection.startCharIndex, count);

          await Clipboard.setData(ClipboardData(text: selectedText ?? ""));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.localizations['textCopied']), duration: Duration(seconds: 2)));
          }
        }
        break;

      case TextContextAction.kHighlight:
        if (_textSelection.displayBounds.isNotEmpty) {
          final renderWidth = getRenderWidth();
          final renderHeight = getRenderHeight();

          final pdfRects = _textSelection.displayBounds.map((displayRect) {
            final left = displayRect.left / renderWidth * pageSize.width;
            final top = pageSize.height - (displayRect.bottom / renderHeight * pageSize.height);
            final width = displayRect.width / renderWidth * pageSize.width;
            final height = displayRect.height / renderHeight * pageSize.height;
            return Rect.fromLTWH(left, top, width, height);
          }).toList();

          // 计算高亮区域的中心位置（屏幕坐标）
          final firstRect = _textSelection.displayBounds.first;
          final lastRect = _textSelection.displayBounds.last;
          final centerX = (firstRect.left + lastRect.right) / 2;
          final centerY = (firstRect.top + lastRect.bottom) / 2;
          final centerPosition = Offset(centerX, centerY);

          final success = controller.createHighlight(pageIndex, pdfRects, r: 255, g: 255, b: 0, a: 100);
          success.then((value) {
            if (value) {
              onPdfContentChanged();
              onHighlightCreated(centerPosition);
            }
          });
        }
        break;
    }

    clearSelection();
  }
}

class _SelectionHandle extends StatelessWidget {
  final bool isLeft;
  final Rect rect;
  final ValueNotifier<double> scaleNotifier;

  const _SelectionHandle({required this.isLeft, required this.rect, required this.scaleNotifier});

  @override
  Widget build(BuildContext context) {
    final children = [
      ValueListenableBuilder(
        valueListenable: scaleNotifier,
        builder: (context, scale, child) {
          return Container(
            width: 1 / scale,
            height: rect.height,
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(1)),
          );
        },
      ),
      ValueListenableBuilder(
        valueListenable: scaleNotifier,
        builder: (context, value, child) => Transform.scale(
          scale: 1 / value,
          alignment: isLeft ? Alignment.bottomRight : Alignment.topLeft,
          child: Container(
            width: _handleCircleSize,
            height: _handleCircleSize,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: isLeft ? Radius.circular(12) : Radius.zero,
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: isLeft ? Radius.zero : Radius.circular(12),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    ];
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: isLeft ? children.reversed.toList() : children,
      ),
    );
  }
}
