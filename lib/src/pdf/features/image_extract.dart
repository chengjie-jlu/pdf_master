import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master/src/core/pdf_ffi_api.dart' as ffi_api;
import 'package:pdf_master/src/pdf/handlers/image_selection_handler.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

class ImageExtractPage extends StatefulWidget {
  final PdfController controller;

  const ImageExtractPage({super.key, required this.controller});

  @override
  State<ImageExtractPage> createState() => _ImageExtractPageState();
}

class _ImageExtractPageState extends State<ImageExtractPage> {
  List<ffi_api.ImageObjectBasicInfo> imageObjects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllImages();
  }

  void _loadAllImages() async {
    final images = await widget.controller.getAllImageObjects();
    imageObjects = images;
    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PdfMasterAppBar(
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
            title: context.localizations['imageExtract'],
          ),
          Expanded(
            child: imageObjects.isEmpty
                ? Center(
                    child: Visibility(
                      visible: loading,
                      replacement: Text(context.localizations['noImagesHint'], style: TextStyle(fontSize: 16)),
                      child: CupertinoActivityIndicator(radius: 12.0),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 0.71,
                    ),
                    itemBuilder: (context, index) =>
                        _ImageGridItem(controller: widget.controller, imageInfo: imageObjects[index], index: index),
                    itemCount: imageObjects.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ImageGridItem extends StatefulWidget {
  final PdfController controller;
  final ffi_api.ImageObjectBasicInfo imageInfo;
  final int index;

  const _ImageGridItem({required this.controller, required this.imageInfo, required this.index});

  @override
  State<_ImageGridItem> createState() => _ImageGridItemState();
}

class _ImageGridItemState extends State<_ImageGridItem> {
  ui.Image? image;

  @override
  void initState() {
    super.initState();
    _refreshImage();
  }

  @override
  void dispose() {
    super.dispose();
    image?.dispose();
  }

  @override
  void didUpdateWidget(_ImageGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshImage();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              if (image != null)
                Positioned.fill(
                  child: RawImage(image: image, fit: BoxFit.cover),
                ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshImage() async {
    final imagePreview = await widget.controller.getImageObjectByIndex(
      widget.imageInfo.pageIndex,
      widget.imageInfo.objectIndex,
    );

    final newImage = imagePreview?.image;
    if (newImage == null) {
      return;
    }

    image?.dispose();
    image = newImage;
    setState(() {});
  }

  Future<void> _onTap() async {
    showImagePreview(context, image?.clone());
  }
}
