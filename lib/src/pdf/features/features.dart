import 'package:flutter/material.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

void showFeatureMenus(
  BuildContext context,
  PdfController controller,
  List<AdvancedFeature> features,
  ValueChanged<AdvancedFeature> onAction,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(76),
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: context.pdfTheme.appBarBackgroundColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: FeaturesList(controller: controller, features: features, onAction: onAction),
    ),
  );
}

enum AdvancedFeature {
  kPageManage,
  kConvertImage,
  kImageExtract;

  String getTitle(BuildContext context) {
    switch (this) {
      case kPageManage:
        return context.localizations['pageManage'];
      case kConvertImage:
        return context.localizations['toImage'];
      case kImageExtract:
        return context.localizations['imageExtract'];
    }
  }

  IconData getIcon() {
    switch (this) {
      case AdvancedFeature.kPageManage:
        return Icons.filter_1;
      case AdvancedFeature.kConvertImage:
        return Icons.filter;
      case AdvancedFeature.kImageExtract:
        return Icons.image_search;
    }
  }
}

class FeatureMenuItem extends StatelessWidget {
  final AdvancedFeature action;
  final VoidCallback onTap;

  const FeatureMenuItem({super.key, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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

class FeaturesList extends StatefulWidget {
  final PdfController controller;
  final List<AdvancedFeature> features;
  final ValueChanged<AdvancedFeature> onAction;

  const FeaturesList({super.key, required this.controller, required this.features, required this.onAction});

  @override
  State<FeaturesList> createState() => _FeaturesListState();
}

class _FeaturesListState extends State<FeaturesList> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.features.map((action) => _toElement(action)).toList(),
      ),
    );
  }

  Widget _toElement(AdvancedFeature action) {
    return FeatureMenuItem(
      action: action,
      onTap: () {
        Navigator.pop(context);
        widget.onAction(action);
      },
    );
  }
}
