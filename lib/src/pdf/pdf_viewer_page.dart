import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master/src/component/bottom_bar.dart';
import 'package:zoom_view/zoom_view.dart';

import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/pdf/edit/edit_tool_bar.dart';
import 'package:pdf_master/src/pdf/features/convert_image.dart';
import 'package:pdf_master/src/pdf/features/features.dart';
import 'package:pdf_master/src/pdf/features/image_extract.dart';
import 'package:pdf_master/src/pdf/features/page_manage.dart';
import 'package:pdf_master/src/pdf/handlers/gesture_handler.dart';
import 'package:pdf_master/src/pdf/pdf_view_core.dart';
import 'package:pdf_master/src/pdf/search/widgets.dart';
import 'package:pdf_master/src/pdf/toc/toc.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

const _kMaxPageJumpCount = 3;

class PDFViewerPage extends StatefulWidget {
  final String filePath;
  final String password;
  final bool pageMode;
  final bool fullScreen;
  final bool enableEdit;
  final bool showTitleBar;
  final bool showToolBar;
  final bool doubleTapDragZoom;
  final List<AdvancedFeature> features;

  const PDFViewerPage({
    super.key,
    required this.filePath,
    this.password = "",
    this.pageMode = false,
    this.fullScreen = false,
    this.enableEdit = true,
    this.showTitleBar = true,
    this.showToolBar = true,
    this.doubleTapDragZoom = false,
    this.features = AdvancedFeature.values,
  });

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class FullScreenExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const FullScreenExitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final right = MediaQuery.viewPaddingOf(context).right;
    return Positioned(
      top: top,
      right: right,
      child: Container(
        margin: EdgeInsets.only(right: right > 24 ? 0 : max(24 - right, 0), top: top > 24 ? 0 : max(24 - top, 0)),
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: Colors.black.withAlpha(128), borderRadius: BorderRadius.circular(24)),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(Icons.close, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late bool pageMode = widget.pageMode;
  late bool fullscreen = widget.fullScreen;
  late PdfController controller;
  final containerKey = GlobalKey();
  final appBarKey = GlobalKey();
  final bottomBarKey = GlobalKey();
  bool _barsVisible = true;

  double get appBarHeight {
    final renderBox = appBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return 0;
    return renderBox.size.height;
  }

  double get bottomBarHeight {
    final renderBox = bottomBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return 0;
    return renderBox.size.height;
  }

  @override
  void initState() {
    super.initState();
    _openDocument(widget.password);
    PdfMaster.instance.darkModeNotifier.addListener(_onDarkModeChanged);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    controller.editStateNotifier.removeListener(_toggleBarVisible);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    PdfMaster.instance.darkModeNotifier.removeListener(_onDarkModeChanged);
    SystemChrome.setPreferredOrientations([]);
  }

  void _openDocument(String password) async {
    controller = PdfController(widget.filePath, password: password);
    await controller.open();
    if (!mounted) return;
    if (controller.opened) {
      controller.editStateNotifier.addListener(_toggleBarVisible);
      setState(() {});
    } else if (controller.needPassword) {
      final input = await showPdfMasterInputDialog(
        context,
        context.localizations[controller.password.isEmpty ? "needPassword" : "passwordErr"],
        context.localizations["inputPassword"],
      );
      if (input == null) {
        if (mounted) Navigator.pop(context);
      } else {
        await controller.dispose();
        _openDocument(input);
      }
    } else {
      await showPdfMasterAlertDialog(context, context.localizations["fmtErr"], context.localizations['ok']);
      if (mounted) Navigator.pop(context);
    }
  }

  void _onDarkModeChanged() {
    setState(() {});
  }

  void _toggleBarVisible({bool? visible}) {
    bool nextValue;
    if (controller.editStateNotifier.value == PdfEditState.kNone) {
      nextValue = visible ?? !_barsVisible;
    } else {
      nextValue = true;
    }

    if (_barsVisible != nextValue) {
      setState(() => _barsVisible = nextValue);
    }
  }

  Widget _buildContent(_, BoxConstraints constraints) {
    switch (controller.openState) {
      case PdfOpenState.kFmtError:
      case PdfOpenState.kUnknownError:
      case PdfOpenState.kNone:
        return SizedBox.shrink();
      case PdfOpenState.kOpened:
      case PdfOpenState.kRequiredPassword:
      case PdfOpenState.kPasswordNotMatch:
        return Visibility(
          key: containerKey,
          visible: pageMode,
          replacement: PdfListViewer(
            key: ValueKey(MediaQuery.orientationOf(context)),
            controller: controller,
            constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight),
            padding: EdgeInsets.only(top: appBarHeight, bottom: bottomBarHeight),
            containerKey: containerKey,
            enableEdit: widget.enableEdit,
            initialPageIndex: 0,
            doubleTapDragZoom: widget.doubleTapDragZoom,
            onPageChanged: (index) => controller.currentPageIndexNotifier.value = index,
          ),
          child: PdfPageViewer(
            key: ValueKey(MediaQuery.orientationOf(context)),
            controller: controller,
            constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight),
            padding: EdgeInsets.only(top: appBarHeight, bottom: bottomBarHeight),
            containerKey: containerKey,
            enableEdit: widget.enableEdit,
            initialPageIndex: 0,
            doubleTapDragZoom: widget.doubleTapDragZoom,
            onPageChanged: (index) => controller.currentPageIndexNotifier.value = index,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Scaffold(
      resizeToAvoidBottomInset: false,
      body: NotificationListener<Notification>(
        onNotification: (notification) {
          if (notification is PdfBackgroundTapNotification) {
            _toggleBarVisible();
          } else if (notification is ScrollUpdateNotification) {
            if (notification.metrics.axis == Axis.horizontal) return false;
            if (appBarHeight != 0 && !pageMode) {
              if (notification.metrics.pixels >= appBarHeight && _barsVisible) {
                _toggleBarVisible(visible: false);
              } else if (notification.metrics.pixels < appBarHeight && !_barsVisible) {
                _toggleBarVisible(visible: true);
              }
            }
          }
          return true;
        },
        child: Stack(
          children: [
            Positioned.fill(
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _toggleBarVisible,
                child: LayoutBuilder(builder: _buildContent),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _barsVisible ? 0 : -(appBarHeight + MediaQuery.of(context).padding.top),
              left: 0,
              right: 0,
              child: _appBar(),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _barsVisible ? 0 : -(bottomBarHeight + MediaQuery.of(context).padding.bottom),
              left: 0,
              right: 0,
              child: _bottomBar(),
            ),

            if (fullscreen) FullScreenExitButton(onTap: () => _changeFullScreenMode(false)),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: !fullscreen,
      onPopInvokedWithResult: (didPop, result) => _changeFullScreenMode(false),
      child: body,
    );
  }

  Widget _appBar() {
    return ValueListenableBuilder(
      key: appBarKey,
      valueListenable: controller.editStateNotifier,
      builder: (context, editMode, child) {
        if (fullscreen || !widget.showTitleBar) return SizedBox.shrink();
        switch (editMode) {
          case PdfEditState.kNone:
            return PdfMasterAppBar(
              title: p.basename(widget.filePath),
              leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
              action: Visibility(
                visible: PdfMaster.instance.shareHandler != null,
                child: IconButton(onPressed: _onShareTapped, icon: Icon(Icons.ios_share)),
              ),
            );
          case PdfEditState.kEdit:
            return EditToolBar(controller: controller);
          case PdfEditState.kSearch:
            return SearchToolBar(controller: controller, searchState: controller.searchState);
        }
      },
    );
  }

  Widget _bottomBar() {
    return ValueListenableBuilder(
      key: bottomBarKey,
      valueListenable: controller.editStateNotifier,
      builder: (context, editMode, child) {
        if (fullscreen || !widget.showToolBar) return SizedBox.shrink();
        switch (editMode) {
          case PdfEditState.kEdit:
          case PdfEditState.kNone:
            return BottomToolbar(pageMode: pageMode, onToolAction: _onToolAction, features: widget.features);
          case PdfEditState.kSearch:
            return SearchBottomBar(controller: controller, searchState: controller.searchState);
        }
      },
    );
  }

  Future<bool> _saveEditBeforeJump() async {
    if (controller.editStateNotifier.value != PdfEditState.kEdit) {
      return true;
    }

    final ret = await showPdfMasterAlertDialog(
      context,
      context.localizations['warning'],
      context.localizations['save'],
      content: context.localizations['editNotSave'],
      negativeButtonText: context.localizations['cancel'],
    );

    if (ret == true) {
      await controller.save();
      controller.editStateNotifier.value = PdfEditState.kNone;
      setState(() {});
      return true;
    }
    return false;
  }

  void _changeFullScreenMode(bool fullscreen) {
    this.fullscreen = fullscreen;
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    setState(() {});
  }

  void _onToolAction(ToolAction action) async {
    switch (action) {
      case ToolAction.kToc:
        showTocBottomSheet(context, controller, controller.tocState);
        break;
      case ToolAction.kSearch:
        if (await _saveEditBeforeJump()) {
          controller.editStateNotifier.value = PdfEditState.kSearch;
        }
        break;
      case ToolAction.kPageMode:
        if (await _saveEditBeforeJump()) {
          setState(() => pageMode = !pageMode);
        }
        break;
      case ToolAction.kMore:
        showFeatureMenus(context, controller, widget.features, _onFeatureAction);
        break;
      case ToolAction.kRotate:
        _changeFullScreenMode(true);
        break;
    }
  }

  void _onFeatureAction(AdvancedFeature action) async {
    if (!await _saveEditBeforeJump()) return;
    if (!mounted) return;
    switch (action) {
      case AdvancedFeature.kPageManage:
        final newFilePath = await Navigator.of(
          context,
        ).push<String>(PDFMasterPageRouter(builder: (ctx) => PageManagePage(controller: controller)));
        if (!mounted || newFilePath == null) return;
        Navigator.pop(context, newFilePath);
        break;
      case AdvancedFeature.kConvertImage:
        Navigator.push(context, PDFMasterPageRouter(builder: (ctx) => PageSelector(controller: controller)));
        break;
      case AdvancedFeature.kImageExtract:
        Navigator.push(context, PDFMasterPageRouter(builder: (ctx) => ImageExtractPage(controller: controller)));
        break;
    }
  }

  void _onShareTapped() async {
    PdfMaster.instance.shareHandler?.handleSharePdfFile(widget.filePath);
  }
}

class PdfPageViewer extends StatefulWidget {
  final PdfController controller;
  final BoxConstraints constraints;
  final EdgeInsets padding;
  final GlobalKey containerKey;
  final bool enableEdit;
  final int initialPageIndex;
  final ValueChanged<int>? onPageChanged;
  final bool doubleTapDragZoom;

  const PdfPageViewer({
    super.key,
    required this.controller,
    required this.constraints,
    required this.padding,
    required this.containerKey,
    required this.enableEdit,
    this.initialPageIndex = 0,
    this.onPageChanged,
    this.doubleTapDragZoom = false,
  });

  @override
  State<PdfPageViewer> createState() => _PdfPageViewerState();
}

class _PdfPageViewerState extends State<PdfPageViewer> {
  final scrollController = ScrollController();
  double zoomViewScale = 1.0;
  Timer? _scrollDebounceTimer;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.searchState.onPageChanged = _jumpToPage;
    widget.controller.tocState.onPageChanged = _jumpToPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToPage(widget.initialPageIndex, withoutAnim: true);
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    _scrollDebounceTimer?.cancel();
  }

  void _calCurrentPageIndex() {
    if (!scrollController.hasClients) return;
    final offset = scrollController.offset;
    final pageWidth = widget.constraints.maxWidth;
    final currentPage = (offset / pageWidth).round().clamp(0, widget.controller.pageCount - 1);

    if (currentPage != _currentPageIndex) {
      _currentPageIndex = currentPage;
      widget.controller.tocState.setCurrentPageIndex(currentPage);
      widget.onPageChanged?.call(currentPage);
    }
  }

  void _jumpToPage(int pageIndex, {bool withoutAnim = false}) {
    if (scrollController.hasClients && pageIndex >= 0 && pageIndex < widget.controller.pageCount) {
      final targetOffset = pageIndex * widget.constraints.maxWidth;
      final delta = scrollController.offset - targetOffset;
      if (withoutAnim || delta.abs() > widget.constraints.maxWidth * _kMaxPageJumpCount) {
        scrollController.jumpTo(targetOffset);
      } else {
        scrollController.animateTo(targetOffset, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  bool _onNotification(Notification notification) {
    if (notification is ScrollEndNotification) {
      _calCurrentPageIndex();
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(Duration(milliseconds: 100), () {
        widget.controller.scaleNotifier.value = zoomViewScale;
        setState(() {});
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: ZoomListView(
        doubleTapDrag: widget.doubleTapDragZoom,
        onScaleChanged: (scale) {
          final newScale = scale;
          if (zoomViewScale == 1.0) {
            zoomViewScale = newScale;
            scrollController.jumpTo(scrollController.offset + widget.constraints.maxWidth * 0.5);
            setState(() {});
          } else {
            zoomViewScale = newScale;
          }
          widget.controller.scaleNotifier.value = zoomViewScale;
        },
        child: ListView.builder(
          padding: widget.padding,
          controller: scrollController,
          physics: zoomViewScale == 1.0 ? PageScrollPhysics() : null,
          scrollDirection: Axis.horizontal,
          itemBuilder: (ctx, index) => Align(
            alignment: Alignment.center,
            child: _PdfViewBox(
              controller: widget.controller,
              index: index,
              constraints: widget.constraints,
              scale: zoomViewScale,
              containerKey: widget.containerKey,
              pageMode: true,
              enableEdit: widget.enableEdit,
            ),
          ),
          itemCount: widget.controller.pageCount,
        ),
      ),
    );
  }
}

class PdfListViewer extends StatefulWidget {
  final PdfController controller;
  final BoxConstraints constraints;
  final EdgeInsets padding;
  final GlobalKey containerKey;
  final bool enableEdit;
  final int initialPageIndex;
  final ValueChanged<int>? onPageChanged;
  final bool doubleTapDragZoom;

  const PdfListViewer({
    super.key,
    required this.controller,
    required this.constraints,
    required this.padding,
    required this.containerKey,
    required this.enableEdit,
    this.initialPageIndex = 0,
    this.onPageChanged,
    this.doubleTapDragZoom = false,
  });

  @override
  State<PdfListViewer> createState() => _PdfListViewerState();
}

final _separatorHeight = 5.0;

class _PdfListViewerState extends State<PdfListViewer> {
  final scrollController = ScrollController();
  double zoomViewScale = 1.0;
  Timer? _scrollDebounceTimer;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.searchState.onPageChanged = _jumpToPage;
    widget.controller.tocState.onPageChanged = _jumpToPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToPage(widget.initialPageIndex, withoutAnim: true);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _calculateCurrentPageIndex() {
    if (!scrollController.hasClients) return;
    final offset = scrollController.offset;
    double accumulatedHeight = 0;
    int currentPage = 0;

    for (int i = 0; i < widget.controller.pageCount; i++) {
      final pageHeight = widget.constraints.maxWidth / widget.controller.getPageSizeAt(i).aspectRatio;
      if (offset < accumulatedHeight + pageHeight / 2) {
        currentPage = i;
        break;
      }
      accumulatedHeight += pageHeight + _separatorHeight;
      currentPage = i;
    }

    if (currentPage != _currentPageIndex) {
      _currentPageIndex = currentPage;
      widget.onPageChanged?.call(currentPage);
      widget.controller.tocState.setCurrentPageIndex(currentPage);
    }
  }

  void _jumpToPage(int pageIndex, {bool withoutAnim = false}) {
    if (scrollController.hasClients && pageIndex >= 0 && pageIndex < widget.controller.pageCount) {
      double targetOffset = 0;
      for (int i = 0; i < pageIndex; i++) {
        targetOffset += widget.constraints.maxWidth / widget.controller.getPageSizeAt(i).aspectRatio;
        targetOffset += _separatorHeight;
      }
      final delta = scrollController.offset - targetOffset;
      if (withoutAnim || delta.abs() > widget.constraints.maxHeight * _kMaxPageJumpCount) {
        scrollController.jumpTo(targetOffset);
      } else {
        scrollController.animateTo(targetOffset, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  double _getListViewPaddingTop() {
    double totalHeight = 0;
    for (int index = 0; index < widget.controller.pageCount; index++) {
      totalHeight += widget.constraints.maxWidth / widget.controller.getPageSizeAt(index).aspectRatio;
    }
    totalHeight += (widget.controller.pageCount - 1) * _separatorHeight;
    return totalHeight > widget.constraints.maxHeight ? 0 : (widget.constraints.maxHeight - totalHeight) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: ZoomListView(
        doubleTapDrag: widget.doubleTapDragZoom,
        onScaleChanged: (scale) {
          zoomViewScale = scale;
          widget.controller.scaleNotifier.value = zoomViewScale;
        },
        child: ListView.separated(
          padding: EdgeInsets.only(top: _getListViewPaddingTop() + widget.padding.top, bottom: widget.padding.bottom),
          cacheExtent: 3 * widget.constraints.maxHeight,
          controller: scrollController,
          itemBuilder: (ctx, index) => _PdfViewBox(
            controller: widget.controller,
            index: index,
            scale: zoomViewScale,
            constraints: widget.constraints,
            containerKey: widget.containerKey,
            pageMode: false,
            enableEdit: widget.enableEdit,
          ),
          separatorBuilder: (ctx, index) => SizedBox(height: _separatorHeight),
          itemCount: widget.controller.pageCount,
        ),
      ),
    );
  }

  bool _onNotification(Notification notification) {
    if (notification is ScrollEndNotification) {
      _scrollDebounceTimer?.cancel();
      _calculateCurrentPageIndex();
      _scrollDebounceTimer = Timer(Duration(milliseconds: 100), () {
        widget.controller.scaleNotifier.value = zoomViewScale;
        setState(() {});
      });
    }
    return false;
  }
}

class _PdfViewBox extends StatelessWidget {
  final PdfController controller;
  final int index;
  final double scale;
  final BoxConstraints constraints;
  final GlobalKey containerKey;
  final bool pageMode;
  final bool enableEdit;

  const _PdfViewBox({
    required this.controller,
    required this.index,
    required this.scale,
    required this.constraints,
    required this.containerKey,
    required this.pageMode,
    required this.enableEdit,
  });

  BoxConstraints getPageRenderCts() {
    final pageSize = controller.getPageSizeAt(index);
    if (constraints.maxWidth / constraints.maxHeight <= pageSize.aspectRatio) {
      return constraints;
    }

    return BoxConstraints(maxWidth: pageSize.aspectRatio * constraints.maxHeight, maxHeight: constraints.maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    if (pageMode) {
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        alignment: Alignment.center,
        child: PdfViewCore(
          controller: controller,
          index: index,
          constraints: getPageRenderCts(),
          scale: scale,
          containerKey: containerKey,
          enableEdit: enableEdit,
        ),
      );
    } else {
      return Container(
        width: constraints.maxWidth,
        alignment: Alignment.center,
        child: PdfViewCore(
          controller: controller,
          index: index,
          constraints: constraints,
          scale: scale,
          containerKey: containerKey,
          enableEdit: enableEdit,
        ),
      );
    }
  }
}
