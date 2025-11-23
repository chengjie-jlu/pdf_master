import 'package:flutter/material.dart';

class PDFMasterPageRouter<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  PDFMasterPageRouter({required this.builder, super.settings})
    : super(
        pageBuilder: ((context, animation, secondaryAnimation) => builder(context)),
        transitionsBuilder: (ctx, animation, secondAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.ease));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      );
}
