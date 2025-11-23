import 'package:flutter/material.dart';
import 'package:pdf_master_example/ctx_extension.dart';

void showOrderMenus(BuildContext context, ValueChanged<SortType> onAction) {
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
      child: SortTypeList(onAction: onAction),
    ),
  );
}

enum SortType {
  kName,
  kTime,
  kSize;

  String getTitle(BuildContext context) {
    switch (this) {
      case SortType.kName:
        return context.localizations.sortByName;
      case SortType.kTime:
        return context.localizations.sortByTime;
      case SortType.kSize:
        return context.localizations.sortBySize;
    }
  }

  IconData getIcon() {
    switch (this) {
      case SortType.kName:
        return Icons.sort_by_alpha;
      case SortType.kTime:
        return Icons.access_time;
      case SortType.kSize:
        return Icons.storage;
    }
  }
}

class SortTypeItem extends StatelessWidget {
  final SortType action;
  final ValueChanged<SortType> onAction;

  const SortTypeItem({super.key, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onAction(action);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(children: [Icon(action.getIcon(), size: 21), SizedBox(width: 12), Text(action.getTitle(context))]),
        ),
      ),
    );
  }
}

class SortTypeList extends StatefulWidget {
  final ValueChanged<SortType> onAction;

  const SortTypeList({super.key, required this.onAction});

  @override
  State<SortTypeList> createState() => _SortTypeListState();
}

class _SortTypeListState extends State<SortTypeList> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (ctx, index) => _toElement(SortType.values[index]),
        separatorBuilder: (ctx, index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          height: 0.5,
          color: Theme.of(context).dividerColor.withAlpha(76),
        ),
        itemCount: SortType.values.length,
      ),
    );
  }

  Widget _toElement(SortType action) {
    return SortTypeItem(action: action, onAction: widget.onAction);
  }
}
