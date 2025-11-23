import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/ctx_extension.dart';
import 'package:pdf_master_example/pages/pref/preference.dart';

const openSourceList = [
  "pdfium",
  "flutter",
  "zoom_view",
  "dotted_border",
  "ffi",
  "file_picker",
  "flutter_reorderable_grid_view",
  "gal",
  "receive_sharing_intent",
  "pdf_master",
];

class OpenSourceListPage extends StatelessWidget {
  const OpenSourceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PdfMasterAppBar(
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
            title: context.localizations.openSource,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(top: 16),
              itemBuilder: (ctx, index) => PreferenceText(
                title: openSourceList[index],
                onTap: () => Navigator.push(
                  context,
                  PDFMasterPageRouter(builder: (_) => OpenSourceViewPage(name: openSourceList[index])),
                ),
              ),
              itemCount: openSourceList.length,
              separatorBuilder: (context, index) => SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class OpenSourceViewPage extends StatelessWidget {
  final String name;

  const OpenSourceViewPage({super.key, required this.name});

  Future<String> load() async {
    final result = await rootBundle.loadString("assets/licenses/$name/LICENSE");
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PdfMasterAppBar(
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
            title: name,
          ),
          FutureBuilder(
            future: load(),
            builder: (ctx, snapshot) => Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Text(snapshot.data ?? "", style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
