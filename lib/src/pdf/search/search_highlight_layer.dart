import 'package:flutter/material.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'dart:ui' as ui;

import 'package:pdf_master/src/core/pdf_ffi_api.dart' as ffi_api;

class SearchHighlightLayer extends StatelessWidget {
  final int pageIndex;
  final ui.Size pageSize;
  final double renderWidth;
  final double renderHeight;
  final PdfController controller;

  const SearchHighlightLayer({
    super.key,
    required this.pageIndex,
    required this.pageSize,
    required this.renderWidth,
    required this.renderHeight,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final searchState = controller.searchState;
    return ListenableBuilder(
      listenable: searchState,
      builder: (context, child) {
        if (!searchState.hasResults) {
          return SizedBox.shrink();
        }

        final pageResults = searchState.results.where((result) => result.pageIndex == pageIndex).toList();
        if (pageResults.isEmpty) {
          return SizedBox.shrink();
        }

        return CustomPaint(
          size: Size(renderWidth, renderHeight),
          painter: _SearchHighlightPainter(
            pageResults: pageResults,
            currentResult: searchState.currentResult,
            pageSize: pageSize,
            renderWidth: renderWidth,
            renderHeight: renderHeight,
          ),
        );
      },
    );
  }
}

class _SearchHighlightPainter extends CustomPainter {
  final List<ffi_api.SearchResult> pageResults;
  final ffi_api.SearchResult? currentResult;
  final ui.Size pageSize;
  final double renderWidth;
  final double renderHeight;

  _SearchHighlightPainter({
    required this.pageResults,
    required this.currentResult,
    required this.pageSize,
    required this.renderWidth,
    required this.renderHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final normalPaint = Paint()
      ..color = Colors.yellow.withAlpha(76)
      ..style = PaintingStyle.fill;

    final currentPaint = Paint()
      ..color = Colors.red.withAlpha(76)
      ..style = PaintingStyle.fill;

    for (final result in pageResults) {
      final isCurrent =
          currentResult != null &&
          currentResult?.pageIndex == result.pageIndex &&
          currentResult?.charIndex == result.charIndex;
      final paint = isCurrent ? currentPaint : normalPaint;

      for (final pdfRect in result.rects) {
        final displayRect = _convertPdfRectToDisplayRect(pdfRect);
        canvas.drawRect(displayRect, paint);
      }
    }
  }

  Rect _convertPdfRectToDisplayRect(ui.Rect pdfRect) {
    final scaleX = renderWidth / pageSize.width;
    final scaleY = renderHeight / pageSize.height;

    final left = pdfRect.left * scaleX;
    final right = pdfRect.right * scaleX;

    final top = (pageSize.height - pdfRect.top) * scaleY;
    final bottom = (pageSize.height - pdfRect.bottom) * scaleY;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool shouldRepaint(covariant _SearchHighlightPainter oldDelegate) {
    return oldDelegate.pageResults != pageResults ||
        oldDelegate.currentResult != currentResult ||
        oldDelegate.renderWidth != renderWidth ||
        oldDelegate.renderHeight != renderHeight;
  }
}
