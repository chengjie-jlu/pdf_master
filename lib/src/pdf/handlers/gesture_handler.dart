import 'package:flutter/material.dart';

class PdfBackgroundTapNotification extends Notification {}

enum GestureHandleResult {
  /// 已处理，不再传递给其他处理器
  handled,

  /// 未处理，继续传递给下一个处理器
  notHandled,

  /// 已处理，但允许其他处理器也处理
  handledContinue,
}

/// 手势处理器抽象基类
abstract class GestureHandler {
  /// 处理点击事件
  Future<GestureHandleResult> handleTap(TapUpDetails details) async {
    return GestureHandleResult.notHandled;
  }

  /// 处理长按事件
  Future<GestureHandleResult> handleLongPress(LongPressStartDetails details) async {
    return GestureHandleResult.notHandled;
  }

  /// 判断是否应该接受拖动手势
  bool shouldAcceptPan(Offset position) {
    return false;
  }

  /// 处理拖动开始
  void handlePanStart(DragStartDetails details) {}

  /// 处理拖动更新
  void handlePanUpdate(DragUpdateDetails details) {}

  /// 处理拖动结束
  Future<void> handlePanEnd(DragEndDetails details) async {}

  /// 构建该处理器的 UI 层
  List<Widget> buildWidgets(BuildContext context);

  /// 清除选择状态
  void clearSelection();

  /// 是否有选中状态
  bool get hasSelection;
}
