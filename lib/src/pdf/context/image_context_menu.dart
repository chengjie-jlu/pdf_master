import 'package:flutter/material.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';
import 'context_menu_constants.dart';

enum ImageContextAction { kView, kSave }

class ImageContextItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const ImageContextItem({super.key, required this.text, required this.icon, required this.onTap});

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

class ImageContextMenu extends StatelessWidget {
  final double scale;
  final bool showContextMenu;
  final ValueChanged<ImageContextAction> onAction;

  const ImageContextMenu({super.key, required this.scale, required this.showContextMenu, required this.onAction});

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
            ImageContextItem(
              text: context.localizations['view'],
              icon: Icons.visibility_outlined,
              onTap: () => onAction(ImageContextAction.kView),
            ),
            ImageContextItem(
              text: context.localizations['save'],
              icon: Icons.file_download_outlined,
              onTap: () => onAction(ImageContextAction.kSave),
            ),
          ],
        ),
      ),
    );
  }
}
