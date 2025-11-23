import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/ctx_extension.dart';

void showMoreMenus(String path, BuildContext context, VoidCallback? onFileDelete) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(76),
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: MenuList(path: path, onFileDelete: onFileDelete),
    ),
  );
}

enum MenuAction {
  kShare,
  kDelete;

  String getTitle(BuildContext context) {
    switch (this) {
      case MenuAction.kDelete:
        return context.localizations.delete;
      case MenuAction.kShare:
        return context.localizations.share;
    }
  }

  IconData getIcon() {
    switch (this) {
      case MenuAction.kDelete:
        return Icons.delete;
      case MenuAction.kShare:
        return Icons.ios_share;
    }
  }
}

class FeatureMenuItem extends StatelessWidget {
  final MenuAction action;
  final ValueChanged<MenuAction> onAction;

  const FeatureMenuItem({super.key, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onAction(action),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(action.getIcon()), SizedBox(height: 12), Text(action.getTitle(context))],
          ),
        ),
      ),
    );
  }
}

class MenuList extends StatefulWidget {
  final String path;
  final VoidCallback? onFileDelete;

  const MenuList({super.key, required this.path, required this.onFileDelete});

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: MenuAction.values.map((action) => _toElement(action)).toList(),
      ),
    );
  }

  Widget _toElement(MenuAction action) {
    return FeatureMenuItem(action: action, onAction: _onAction);
  }

  void _onAction(MenuAction action) {
    Navigator.pop(context);
    switch (action) {
      case MenuAction.kDelete:
        widget.onFileDelete?.call();
        break;
      case MenuAction.kShare:
        PdfMaster.instance.shareHandler?.handleSharePdfFile(widget.path);
        break;
    }
  }
}
