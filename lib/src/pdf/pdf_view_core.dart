import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/pdf/edit_layer.dart';

import 'search/search_highlight_layer.dart';

class PdfViewCore extends StatefulWidget {
  final PdfController controller;
  final int index;
  final double scale;
  final BoxConstraints constraints;
  final GlobalKey containerKey;
  final bool enableEdit;

  const PdfViewCore({
    super.key,
    required this.controller,
    required this.index,
    required this.constraints,
    required this.scale,
    required this.containerKey,
    required this.enableEdit,
  });

  @override
  State<PdfViewCore> createState() => _PdfViewCoreState();
}

class _PdfViewCoreState extends State<PdfViewCore> {
  ui.Image? image;
  ui.Image? thumbImage;
  Rect thumbRect = Rect.zero;
  late Size pageSize = widget.controller.getPageSizeAt(widget.index);

  double get renderWidth => widget.constraints.maxWidth;

  double get renderHeight => renderWidth / pageSize.aspectRatio;

  Key textSelectionKey = UniqueKey();
  List<PdfCharInfo> pageTextInfo = [];

  bool get darkMode => PdfMaster.instance.darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _refreshPageBitmap();
      _refreshThumbBitmap();
    });
    widget.controller.editStateNotifier.addListener(_refreshContent);
    PdfMaster.instance.darkModeNotifier.addListener(_refreshContent);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.editStateNotifier.removeListener(_refreshContent);
    PdfMaster.instance.darkModeNotifier.removeListener(_refreshContent);

    _releasePageBitmap();
    _releaseThumbBitmap();
  }

  void _refreshContent() {
    _refreshPageBitmap();
    _refreshThumbBitmap();
  }

  void _onPdfContentChanged() {
    _refreshPageBitmap();
    _refreshThumbBitmap();
    widget.controller.editStateNotifier.value = PdfEditState.kEdit;
  }

  @override
  void didUpdateWidget(PdfViewCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.constraints.maxWidth != widget.constraints.maxWidth) {
      _refreshPageBitmap();
      textSelectionKey = UniqueKey();
    }
    _refreshThumbBitmap();
  }

  void _refreshPageBitmap() async {
    if (!mounted) return;
    final width = MediaQuery.devicePixelRatioOf(context) * widget.constraints.maxWidth;
    final newImage = await widget.controller.renderFullPage(index: widget.index, width: width.toInt());
    pageSize = widget.controller.getPageSizeAt(widget.index);
    image?.dispose();
    image = newImage;
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshThumbBitmap() async {
    if (widget.scale <= 1.0) {
      _releaseThumbBitmap();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final parentRenderBox = widget.containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || parentRenderBox == null) {
      _releaseThumbBitmap();
      return;
    }

    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final parentOffset = parentRenderBox.localToGlobal(Offset.zero);
    final position = renderBox.localToGlobal(Offset.zero);
    final parentRect = Rect.fromLTWH(
      parentOffset.dx,
      parentOffset.dy,
      parentRenderBox.size.width,
      parentRenderBox.size.height,
    );

    /// 到这里，计算了父容器在屏幕内的位置与大小[parentRect], 以及当前页面在父容器内的位置与大小[selfRect]
    final selfRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      renderBox.size.width * widget.scale,
      renderBox.size.height * widget.scale,
    );

    Rect intersect = parentRect.intersect(selfRect);

    /// 没有重叠部分，直接返回
    if (intersect.isEmpty) {
      _releaseThumbBitmap();
      return;
    }

    /// 重叠部分小于等于 1
    if (intersect.width <= 1 || intersect.height <= 1) {
      _releaseThumbBitmap();
      return;
    }

    final translateX = selfRect.left > parentRect.left ? 0 : (selfRect.left - parentRect.left);
    final translateY = selfRect.top > parentRect.top ? 0 : (selfRect.top - parentRect.top);

    final bitmap = await widget.controller.renderPageBitmap(
      widget.index,
      (intersect.width * devicePixelRatio).toInt(),
      (intersect.height * devicePixelRatio).toInt(),
      (renderWidth * devicePixelRatio * widget.scale).toInt(),
      (renderWidth / pageSize.aspectRatio * devicePixelRatio * widget.scale).toInt(),
      (translateX * devicePixelRatio).toInt(),
      (translateY * devicePixelRatio).toInt(),
    );

    _releaseThumbBitmap();
    thumbImage = bitmap;
    thumbRect = Rect.fromLTWH(
      -translateX / widget.scale,
      -translateY / widget.scale,
      intersect.width / widget.scale,
      intersect.height / widget.scale,
    );
    setState(() {});
  }

  void _releasePageBitmap() {
    image?.dispose();
    image = null;
  }

  void _releaseThumbBitmap() {
    thumbImage?.dispose();
    thumbImage = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: renderWidth,
      height: renderHeight,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(renderWidth, renderHeight),
            painter: PdfPainter(image: image, thumbImage: thumbImage, thumbRect: thumbRect, darkMode: darkMode),
          ),
          if (widget.enableEdit)
            SearchHighlightLayer(
              pageIndex: widget.index,
              pageSize: pageSize,
              renderWidth: renderWidth,
              renderHeight: renderHeight,
              controller: widget.controller,
            ),
          if (widget.enableEdit)
            EditLayer(
              key: textSelectionKey,
              pageSize: pageSize,
              index: widget.index,
              renderHeight: renderHeight,
              renderWidth: renderWidth,
              controller: widget.controller,
              onPdfContentChanged: _onPdfContentChanged,
            ),
        ],
      ),
    );
  }
}

class PdfPainter extends CustomPainter {
  final ui.Image? image;
  final ui.Image? thumbImage;
  final ui.Rect thumbRect;
  final bool darkMode;

  PdfPainter({required this.image, required this.thumbImage, required this.thumbRect, required this.darkMode});

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    final thumbImage = this.thumbImage;

    final paint = Paint();
    if (darkMode) {
      paint.colorFilter = const ColorFilter.matrix([
        -0.8, 0, 0, 0, 255, //
        0, -0.8, 0, 0, 255, //
        0, 0, -0.8, 0, 255, //
        0, 0, 0, 1, 0,
      ]);
    }

    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        paint,
      );
    }

    if (thumbImage != null) {
      canvas.drawImageRect(
        thumbImage,
        Rect.fromLTWH(0, 0, thumbImage.width.toDouble(), thumbImage.height.toDouble()),
        thumbRect,
        paint,
      );
    }
  }
}
