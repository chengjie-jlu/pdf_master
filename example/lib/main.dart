import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/config_impl.dart';
import 'package:pdf_master_example/ctx_extension.dart';
import 'package:pdf_master_example/pages/pref/preference.dart';

import 'l10n/app_localizations.dart';
import 'pages/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initDarkMode = initDarkModePref();
  final pdfMasterInitFuture = initPdfMaster();
  Future.wait([pdfMasterInitFuture, initDarkMode]).then((_) => runApp(const PDFMasterApp()));
}

Future<void> initPdfMaster() async {
  final configImpl = PdfMasterConfigImpl();
  await PdfMaster.instance.initRenderWorker();
  PdfMaster.instance.darkModeNotifier = darkModeNotifier;
  PdfMaster.instance.shareHandler = configImpl;
  PdfMaster.instance.filePickerHandler = configImpl;
  PdfMaster.instance.imageSaveHandler = configImpl;
  PdfMaster.instance.fileSaveHandler = configImpl;
}

class PDFMasterApp extends StatefulWidget {
  const PDFMasterApp({super.key});

  @override
  State<PDFMasterApp> createState() => _PDFMasterAppState();
}

class _PDFMasterAppState extends State<PDFMasterApp> with WidgetsBindingObserver {
  ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(backgroundColor: Colors.white, centerTitle: true),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.blueAccent),
    shadowColor: Colors.black.withAlpha(25),
  );

  ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(backgroundColor: Colors.black, centerTitle: true),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.blueAccent),
    shadowColor: Colors.white.withAlpha(25),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    onSystemThemeChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkModeNotifier,
      builder: (context, value, child) {
        return MaterialApp(
          onGenerateTitle: (context) => context.localizations.appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: value ? dark : light,
          home: HomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
