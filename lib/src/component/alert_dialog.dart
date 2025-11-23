import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/src/utils/ctx_extension.dart';

Future<bool?> showPdfMasterAlertDialog(
  BuildContext context,
  String title,
  String positiveButtonText, {
  String? content,
  String? negativeButtonText,
  bool barrierDismissible = false,
}) async {
  return await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: content != null ? Text(content) : null,
        actions: <Widget>[
          if (negativeButtonText != null)
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(negativeButtonText, style: TextStyle(color: Colors.blueAccent)),
            ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(positiveButtonText, style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      );
    },
  );
}

class CupertinoInputDialog extends StatefulWidget {
  final String title;
  final String hint;

  const CupertinoInputDialog({super.key, required this.title, required this.hint});

  @override
  State<CupertinoInputDialog> createState() => _CupertinoInputDialogState();
}

class _CupertinoInputDialogState extends State<CupertinoInputDialog> {
  final textEditController = TextEditingController();

  void cancel() {
    Navigator.of(context).pop(null);
  }

  void submit() {
    if (textEditController.text.isNotEmpty) {
      Navigator.of(context).pop(textEditController.text);
    }
  }

  @override
  void dispose() {
    super.dispose();
    textEditController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.only(top: 12),
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          height: 48,
          child: TextSelectionTheme(
            data: TextSelectionThemeData(selectionHandleColor: Colors.blueAccent, selectionColor: Colors.blueAccent),
            child: TextField(
              autofocus: true,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              controller: textEditController,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: context.localizations["inputPassword"],
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              cursorColor: Colors.blueAccent,
              onSubmitted: (s) => submit(),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: cancel,
          child: Text(context.localizations["cancel"], style: TextStyle(color: Colors.blueAccent)),
        ),
        CupertinoDialogAction(
          onPressed: submit,
          child: Text(context.localizations["ok"], style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    );
  }
}

Future<String?> showPdfMasterInputDialog(BuildContext context, String title, String hint) async {
  return await showCupertinoDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return CupertinoInputDialog(title: title, hint: hint);
    },
  );
}
