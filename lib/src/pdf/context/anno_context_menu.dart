import 'package:flutter/material.dart';
import 'package:pdf_master/src/pdf/context/context_menu_constants.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

enum AnnoContextAction { kRemove, kStyle }

class AnnoContextItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const AnnoContextItem({super.key, required this.text, required this.icon, required this.onTap});

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

class AnnoContextMenu extends StatelessWidget {
  final double scale;
  final bool showContextMenu;
  final ValueChanged<AnnoContextAction> onAction;

  const AnnoContextMenu({super.key, required this.scale, required this.showContextMenu, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (!showContextMenu) {
      return SizedBox.shrink();
    }
    return Transform.scale(
      scale: 1 / scale,
      alignment: Alignment.topLeft,
      child: Container(
        width: kContextMenuWidth,
        height: kContextMenuHeight,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AnnoContextItem(
              text: context.localizations['del'],
              icon: Icons.delete_outline,
              onTap: () => onAction(AnnoContextAction.kRemove),
            ),
            AnnoContextItem(
              text: context.localizations['edit'],
              icon: Icons.edit,
              onTap: () => onAction(AnnoContextAction.kStyle),
            ),
          ],
        ),
      ),
    );
  }
}
