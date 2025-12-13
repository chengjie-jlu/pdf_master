import 'package:flutter/material.dart';
import 'package:pdf_master/src/pdf/context/context_menu_constants.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

enum MenuAction { kCopy, kHighlight, kView, kSave, kDelete, kEdit, kJump, kOpenWebUrl }

class ActionConfig {
  final String text;
  final IconData icon;

  const ActionConfig({required this.text, required this.icon});
}

class ContextItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const ContextItem({super.key, required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              Text(text, style: TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class ContextMenu extends StatelessWidget {
  final double scale;
  final bool showContextMenu;
  final List<MenuAction> actions;
  final ValueChanged<MenuAction> onAction;

  /// 选中元素的边界框（用于计算菜单位置）
  final Rect boundingBox;

  /// 渲染区域的宽度和高度
  final double renderWidth;
  final double? renderHeight;

  const ContextMenu({
    super.key,
    required this.scale,
    required this.showContextMenu,
    required this.actions,
    required this.onAction,
    required this.boundingBox,
    required this.renderWidth,
    this.renderHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (!showContextMenu || actions.isEmpty) {
      return SizedBox.shrink();
    }

    final menuPos = _calculateMenuPosition();
    final menuWidth = actions.length * 50.0;

    return Positioned(
      top: menuPos.dy,
      left: menuPos.dx,
      child: Transform.scale(
        scale: 1 / scale,
        alignment: Alignment.topLeft,
        child: Container(
          width: menuWidth,
          height: kContextMenuHeight,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions.map((action) => _buildActionItem(context, action)).toList(),
          ),
        ),
      ),
    );
  }

  /// 计算菜单位置
  Offset _calculateMenuPosition() {
    final minTopPadding = 6.0;
    final minBottomPadding = 6.0;
    final menuWidth = actions.length * 50.0;
    final scaledMenuWidth = menuWidth / scale;
    final scaledMenuHeight = kContextMenuHeight / scale;
    final scaledHandleSize = 18.0 / scale;
    final height = renderHeight ?? double.infinity;

    // 尝试在选中区域上方显示菜单
    final topPosition = boundingBox.top - scaledMenuHeight - scaledHandleSize - 4;
    // 尝试在选中区域下方显示菜单
    final bottomPosition = boundingBox.bottom + scaledHandleSize + 4;

    // 判断菜单应该显示在上方还是下方
    double finalTop;
    if (topPosition > minTopPadding) {
      // 上方有足够空间
      finalTop = topPosition;
    } else if (bottomPosition + scaledMenuHeight < height - minBottomPadding) {
      // 下方有足够空间
      finalTop = bottomPosition;
    } else {
      // 上下都没有足够空间，优先显示在选中区域内部顶部
      finalTop = boundingBox.top + minTopPadding;
    }

    // 水平居中对齐
    final centerLeft = (boundingBox.left + boundingBox.right - scaledMenuWidth) / 2;
    double finalLeft = centerLeft;
    if (centerLeft < 0) {
      finalLeft = 0;
    } else if (centerLeft + scaledMenuWidth > renderWidth) {
      finalLeft = renderWidth - scaledMenuWidth;
    }
    return Offset(finalLeft, finalTop);
  }

  Widget _buildActionItem(BuildContext context, MenuAction action) {
    final config = _getActionConfig(context, action);

    return ContextItem(text: config.text, icon: config.icon, onTap: () => onAction(action));
  }

  ActionConfig _getActionConfig(BuildContext context, MenuAction action) {
    switch (action) {
      // 文本操作
      case MenuAction.kCopy:
        return ActionConfig(text: context.localizations['copy'], icon: Icons.copy);
      case MenuAction.kHighlight:
        return ActionConfig(text: context.localizations['highlight'], icon: Icons.format_color_fill);

      // 图片操作
      case MenuAction.kView:
        return ActionConfig(text: context.localizations['view'], icon: Icons.visibility_outlined);
      case MenuAction.kSave:
        return ActionConfig(text: context.localizations['save'], icon: Icons.file_download_outlined);

      // 注释操作
      case MenuAction.kDelete:
        return ActionConfig(text: context.localizations['del'], icon: Icons.delete_outline);
      case MenuAction.kEdit:
        return ActionConfig(text: context.localizations['edit'], icon: Icons.edit);
      case MenuAction.kJump:
        return ActionConfig(text: context.localizations['jump'], icon: Icons.arrow_forward);
      case MenuAction.kOpenWebUrl:
        return ActionConfig(text: context.localizations['open'], icon: Icons.open_in_new);
    }
  }
}
