import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:pdf_master/src/core/pdf_controller.dart';

class PdfCoverView extends StatefulWidget {
  final String filePath;
  final int index;
  final int width;

  const PdfCoverView({super.key, required this.filePath, this.index = 0, this.width = 360});

  @override
  State<PdfCoverView> createState() => _PdfCoverViewState();
}

class _PdfCoverViewState extends State<PdfCoverView> {
  Size pageSize = Size.zero;
  ui.Image? image;

  @override
  void initState() {
    super.initState();
    _refreshPageBitmap();
  }

  @override
  void dispose() {
    super.dispose();
    image?.dispose();
  }

  @override
  void didUpdateWidget(PdfCoverView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index || widget.filePath != oldWidget.filePath || widget.width != oldWidget.width) {
      _refreshPageBitmap();
    }
  }

  _refreshPageBitmap() async {
    final pdfController = PdfController(widget.filePath);
    await pdfController.open();
    pageSize = pdfController.getPageSizeAt(widget.index);
    final newImage = await pdfController.renderFullPage(index: widget.index, width: widget.width);
    pdfController.dispose();
    image?.dispose();
    image = newImage;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (pageSize.isEmpty) {
      return SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        height: (pageSize.height / pageSize.width) * constraints.maxWidth,
        child: RawImage(
          image: image,
          width: constraints.maxWidth,
          height: (pageSize.height / pageSize.width) * constraints.maxWidth,
        ),
      ),
    );
  }
}

class PdfItemView extends StatelessWidget {
  final PdfController controller;
  final int index;
  final BoxFit fit;

  const PdfItemView({super.key, required this.controller, required this.index, this.fit = BoxFit.fill});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PageBitmapViewer(controller: controller, index: index, constraints: constraints, fit: fit);
      },
    );
  }
}

class PageBitmapViewer extends StatefulWidget {
  final PdfController controller;
  final int index;
  final BoxConstraints constraints;
  final BoxFit fit;

  const PageBitmapViewer({
    super.key,
    required this.controller,
    required this.index,
    required this.constraints,
    this.fit = BoxFit.fill,
  });

  @override
  State<PageBitmapViewer> createState() => _PageBitmapViewerState();
}

class _PageBitmapViewerState extends State<PageBitmapViewer> {
  ui.Image? image;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _refreshPageBitmap);
  }

  @override
  void dispose() {
    super.dispose();
    image?.dispose();
    image = null;
  }

  @override
  void didUpdateWidget(PageBitmapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _refreshPageBitmap();
    }
  }

  void _refreshPageBitmap() async {
    final width = MediaQuery.of(context).devicePixelRatio * widget.constraints.maxWidth;
    final newImage = await widget.controller.renderFullPage(index: widget.index, width: width.toInt());
    image?.dispose();
    image = newImage;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.constraints.maxWidth,
      height: widget.constraints.maxHeight,
      child: RawImage(image: image),
    );
  }
}
