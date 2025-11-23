import 'package:flutter/material.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

class PdfMasterAppBar extends StatelessWidget {
  final Widget? leading;
  final Widget? action;
  final Widget? center;
  final String? title;

  const PdfMasterAppBar({super.key, this.leading, this.action, this.center, this.title});

  @override
  Widget build(BuildContext context) {
    Widget centerWidget =
        center ??
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 64),
          child: Text(
            title ?? "",
            maxLines: 1,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: context.pdfTheme.appBarBackgroundColor,
        boxShadow: [
          BoxShadow(blurRadius: 10, spreadRadius: 0.1, offset: Offset(0, -4), color: context.pdfTheme.shadowColor),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
            centerWidget,
            if (action != null) Align(alignment: Alignment.centerRight, child: action),
          ],
        ),
      ),
    );
  }
}
