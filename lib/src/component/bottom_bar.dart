import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

enum ToolAction {
  kToc,
  kRotate,
  kSearch,
  kPageMode,
  kMore;

  IconData _icon() {
    switch (this) {
      case ToolAction.kToc:
        return Icons.toc;
      case ToolAction.kRotate:
        return Icons.fit_screen;
      case ToolAction.kSearch:
        return Icons.search;
      case ToolAction.kMore:
        return Icons.widgets_outlined;
      case ToolAction.kPageMode:
        return Icons.menu_book_outlined;
    }
  }

  String _title(BuildContext context) {
    switch (this) {
      case ToolAction.kToc:
        return context.localizations['toc'];
      case ToolAction.kRotate:
        return context.localizations['rotate'];
      case ToolAction.kSearch:
        return context.localizations['search'];
      case ToolAction.kMore:
        return context.localizations['more'];
      case ToolAction.kPageMode:
        return context.localizations['horizontal'];
    }
  }
}

class ToolActions {
  final List<AdvancedFeature> features;
  final ValueChanged<ToolAction> onToolAction;
  const ToolActions({required this.features, required this.onToolAction});

  Color? getIconColor(ToolAction action, bool pageMode) {
    if (action == ToolAction.kPageMode && pageMode) {
      return Colors.blue;
    }
    return null;
  }

  List<ToolAction> getToolActions() {
    final actions = [ToolAction.kToc, ToolAction.kRotate, ToolAction.kPageMode, ToolAction.kSearch];
    if (features.isNotEmpty) {
      actions.add(ToolAction.kMore);
    }
    return actions;
  }
}

class BottomToolbar extends StatelessWidget {
  final bool pageMode;
  final ToolActions toolActions;
  const BottomToolbar({super.key, required this.pageMode, required this.toolActions});
  @override
  Widget build(BuildContext context) {
    final actions = toolActions.getToolActions();
    return Container(
      decoration: BoxDecoration(
        color: context.pdfTheme.appBarBackgroundColor,
        boxShadow: [
          BoxShadow(blurRadius: 10, spreadRadius: 0.1, offset: Offset(0, 4), color: context.pdfTheme.shadowColor),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            actions.length,
            (index) => IconButton(
              onPressed: () => toolActions.onToolAction(actions[index]),
              icon: Icon(actions[index]._icon(), color: toolActions.getIconColor(actions[index], pageMode)),
              tooltip: actions[index]._title(context),
            ),
          ),
        ),
      ),
    );
  }
}
