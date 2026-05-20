import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'custom_appbar.dart';

class DocsViewer extends StatelessWidget {
  final String path;
  const DocsViewer({super.key, required this.path});

  bool get isNetwork => path.startsWith('http');
  bool get isPdf => path.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "View File"),

      body: SafeArea(
        child: isPdf
            ? (isNetwork
                  ? SfPdfViewer.network(path)
                  : SfPdfViewer.file(File(path)))
            : (isNetwork
                  ? Image.network(path, fit: BoxFit.contain)
                  : Image.file(File(path), fit: BoxFit.contain)),
      ),
    );
  }
}
