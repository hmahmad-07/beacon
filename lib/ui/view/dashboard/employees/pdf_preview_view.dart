// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PdfPreviewView extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const PdfPreviewView({
    super.key,
    required this.pdfBytes,
    required this.fileName,
  });

  Future<void> _sharePdf() async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$fileName').create();
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Audit Report: $fileName');
  }

  Future<void> _printPdf() async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Report Preview"),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColor.scaffold,
              child: SfPdfViewer.memory(
                pdfBytes,
                canShowScrollHead: true,
                canShowScrollStatus: true,
              ),
            ),
          ),
          _buildActionFooter(context.siteAccent),
        ],
      ),
    );
  }

  Widget _buildActionFooter(Color accent) {
    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.share_rounded,
                label: "Share Report",
                color: accent,
                onTap: _sharePdf,
                filled: true,
              ),
            ),
            4.width,
            Expanded(
              child: _actionButton(
                icon: Icons.print_rounded,
                label: "Print / Save",
                color: accent,
                onTap: _printPdf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final fg = filled ? Colors.white : color;
    return SitePressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.6.h),
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(
                  colors: [siteShade(color, 0.08), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: filled ? null : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: filled ? 1 : 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 4.5.w),
            2.width,
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 3.2.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
