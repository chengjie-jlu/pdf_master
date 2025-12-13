import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/pdf/handlers/annotation_selection_handler.dart';
import 'package:pdf_master/src/pdf/handlers/gesture_handler.dart';
import 'package:pdf_master/src/pdf/handlers/image_selection_handler.dart';
import 'package:pdf_master/src/pdf/handlers/text_selection_handler.dart';

class EditLayer extends StatefulWidget {
  final double renderWidth;
  final double renderHeight;
  final PdfController controller;
  final int index;
  final Size pageSize;
  final VoidCallback onPdfContentChanged;

  const EditLayer({
    super.key,
    required this.renderWidth,
    required this.renderHeight,
    required this.controller,
    required this.index,
    required this.pageSize,
    required this.onPdfContentChanged,
  });

  @override
  State<EditLayer> createState() => _EditLayerState();
}

class _EditLayerState extends State<EditLayer> {
  late final List<GestureHandler> _handlers;
  late final TextSelectionHandler _textSelectionHandler;
  late final AnnotationSelectionHandler _annotationSelectionHandler;
  late final ImageSelectionHandler _imageSelectionHandler;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();

    _annotationSelectionHandler = AnnotationSelectionHandler(
      controller: widget.controller,
      pageIndex: widget.index,
      pageSize: widget.pageSize,
      renderWidth: widget.renderWidth,
      renderHeight: widget.renderHeight,
      onPdfContentChanged: widget.onPdfContentChanged,
      onStateChanged: () => setState(() {}),
    )..refreshAnnotationInfo();

    _textSelectionHandler = TextSelectionHandler(
      controller: widget.controller,
      pageIndex: widget.index,
      pageSize: widget.pageSize,
      renderWidth: widget.renderWidth,
      renderHeight: widget.renderHeight,
      onPdfContentChanged: widget.onPdfContentChanged,
      onStateChanged: () => setState(() {}),
      onHighlightCreated: _annotationSelectionHandler.selectAnnotationAtPosition,
    );

    _imageSelectionHandler = ImageSelectionHandler(
      context: context,
      controller: widget.controller,
      pageIndex: widget.index,
      pageSize: widget.pageSize,
      renderWidth: widget.renderWidth,
      renderHeight: widget.renderHeight,
      onStateChanged: () => setState(() {}),
    );

    _handlers = [_imageSelectionHandler, _textSelectionHandler, _annotationSelectionHandler];

    widget.controller.editStateNotifier.addListener(_clearHandlersSelectionIfNeeded);
    _lastScale = widget.controller.scaleNotifier.value;
    widget.controller.scaleNotifier.addListener(_onScaleChanged);
  }

  @override
  void didUpdateWidget(EditLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _annotationSelectionHandler.refreshAnnotationInfo();
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.editStateNotifier.removeListener(_clearHandlersSelectionIfNeeded);
    widget.controller.scaleNotifier.removeListener(_onScaleChanged);
  }

  void _clearHandlersSelectionIfNeeded() {
    if (widget.controller.editStateNotifier.value != PdfEditState.kEdit) {
      _clearHandlersSelection();
    }
  }

  void _onScaleChanged() {
    final currentScale = widget.controller.scaleNotifier.value;
    if (_lastScale != currentScale) {
      _clearHandlersSelection();
      _lastScale = currentScale;
    }
  }

  void _clearHandlersSelection() {
    for (final handler in _handlers) {
      handler.clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (widget.controller.editStateNotifier.value != PdfEditState.kSearch) {
      final gestureDetector = RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
          _SelectionPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_SelectionPanGestureRecognizer>(
            () => _SelectionPanGestureRecognizer(onShouldAccept: _shouldAcceptPan),
            (instance) => instance
              ..onStart = _onPanStart
              ..onUpdate = _onPanUpdate
              ..onEnd = _onPanEnd,
          ),
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
            (instance) => instance.onTapUp = _onTapUp,
          ),
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(),
            (instance) => instance.onLongPressStart = _onLongPress,
          ),
        },
        behavior: HitTestBehavior.translucent,
        child: Container(color: Colors.transparent, width: widget.renderWidth, height: widget.renderHeight),
      );
      children.add(gestureDetector);
    }

    for (final handler in _handlers) {
      children.addAll(handler.buildWidgets(context));
    }

    return PopScope(
      canPop: _handlers.every((handler) => !handler.hasSelection),
      onPopInvokedWithResult: (didPop, result) {
        _clearHandlersSelection();
      },
      child: Stack(children: children),
    );
  }

  bool _shouldAcceptPan(Offset position) {
    for (final handler in _handlers) {
      if (handler.shouldAcceptPan(position)) {
        return true;
      }
    }
    return false;
  }

  void _onPanStart(DragStartDetails details) {
    for (final handler in _handlers) {
      handler.handlePanStart(details);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    for (final handler in _handlers) {
      handler.handlePanUpdate(details);
    }
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    for (final handler in _handlers) {
      await handler.handlePanEnd(details);
    }
  }

  Future<void> _onTapUp(TapUpDetails details) async {
    bool hadSelection = false;
    for (final handler in _handlers) {
      if (handler.hasSelection) {
        hadSelection = true;
        break;
      }
    }

    if (hadSelection) {
      _clearHandlersSelection();
      return;
    }

    bool handled = false;
    for (final handler in _handlers) {
      final result = await handler.handleTap(details);
      if (result == GestureHandleResult.handled) {
        handled = true;
        break;
      }
    }

    if (!handled && mounted) {
      PdfBackgroundTapNotification().dispatch(context);
    }
  }

  Future<void> _onLongPress(LongPressStartDetails details) async {
    for (final handler in _handlers) {
      final result = await handler.handleLongPress(details);
      if (result == GestureHandleResult.handled) {
        break;
      }
    }
  }
}

class _SelectionPanGestureRecognizer extends PanGestureRecognizer {
  final bool Function(Offset position) onShouldAccept;

  _SelectionPanGestureRecognizer({required this.onShouldAccept});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (onShouldAccept(event.localPosition)) {
      super.addAllowedPointer(event);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerMoveEvent) {
      resolve(GestureDisposition.accepted);
    }
  }
}
