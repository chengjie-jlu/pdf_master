import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

class HighlightColor {
  final Color color;
  final int r;
  final int g;
  final int b;
  final int a;

  const HighlightColor({required this.color, required this.r, required this.g, required this.b, this.a = 100});
}

const List<HighlightColor> kHighlightColors = [
  HighlightColor(color: Color(0xFFFFFF00), r: 255, g: 255, b: 0),
  HighlightColor(color: Color(0xFF00FF00), r: 0, g: 255, b: 0),
  HighlightColor(color: Color(0xFF00FFFF), r: 0, g: 255, b: 255),
  HighlightColor(color: Color(0xFFFF00FF), r: 255, g: 0, b: 255),
  HighlightColor(color: Color(0xFFFF0000), r: 255, g: 0, b: 0),
  HighlightColor(color: Color(0xFFFF8800), r: 255, g: 136, b: 0),
];

class ColorPickerBottomSheet extends StatefulWidget {
  final ValueChanged<HighlightColor> onColorSelected;

  const ColorPickerBottomSheet({super.key, required this.onColorSelected});

  @override
  State<ColorPickerBottomSheet> createState() => _ColorPickerBottomSheetState();
}

class _ColorPickerBottomSheetState extends State<ColorPickerBottomSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.pdfTheme.appBarBackgroundColor,
        boxShadow: [
          BoxShadow(blurRadius: 10, spreadRadius: 0.1, color: context.pdfTheme.shadowColor),
        ],
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(kHighlightColors.length, (index) {
                final highlightColor = kHighlightColors[index];
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedIndex = index);
                      widget.onColorSelected(highlightColor);
                    },
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      color: Colors.transparent,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: BoxBorder.all(width: 1, color: isSelected ? Colors.blueAccent : Colors.transparent),
                        ),
                        child: Container(
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            color: highlightColor.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
