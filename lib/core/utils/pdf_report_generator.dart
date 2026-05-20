import 'dart:typed_data';
import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/models/employes_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateDailyMasterReport({
    required List<User> users,
    required List<EmployesWorkingDetailModel> reports,
    required DateTime date,
    required String department,
  }) async {
    final pdf = pw.Document();
    final String formattedDate = DateFormat('dd-MMMM-yyyy').format(date);

    final List<Map<String, dynamic>> totalForce = [];
    for (int i = 0; i < users.length; i++) {
      totalForce.add({'user': users[i], 'report': reports[i]});
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(formattedDate, department),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildExecutiveSummary(
            reports
                .where((r) => r.checkin != null || r.visits.isNotEmpty)
                .length,
            users.length,
          ),
          pw.SizedBox(height: 20),
          ...totalForce.map(
            (data) => _buildUserSection(
              data['user'] as User,
              data['report'] as EmployesWorkingDetailModel,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String date, String dept) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "CENTREX",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  "Executive Field Audit System",
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  "REPORT DATE",
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  date,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColors.grey300,
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text(
              "DEPARTMENT: ",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(dept.toUpperCase(), style: pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildExecutiveSummary(int active, int total) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("TOTAL STAFF", total.toString()),
          _summaryItem("ACTIVE FORCE", active.toString()),
          _summaryItem("ABSENT/INACTIVE", (total - active).toString()),
          _summaryItem(
            "UTILIZATION",
            "${((active / total) * 100).toStringAsFixed(1)}%",
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String val) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.blueGrey800,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          val,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildUserSection(
    User user,
    EmployesWorkingDetailModel report,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "${user.userName} (${user.empCode})",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                user.designation ?? "N/A",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            _metaLabelValue("Check-in", report.checkin?.time ?? "Absent"),
            pw.SizedBox(width: 20),
            _metaLabelValue("Check-out", report.checkout?['time'] ?? "N/A"),
            pw.SizedBox(width: 20),
            _metaLabelValue("Total Visits", report.visits.length.toString()),
          ],
        ),
        pw.SizedBox(height: 10),
        if (report.visits.isNotEmpty) _buildVisitTable(report.visits),
        if (report.visits.isEmpty && report.checkin == null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.red50),
            child: pw.Text(
              "STAFF MEMBER ABSENT / NO ACTIVITY RECORDED FOR THIS DATE",
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red900,
              ),
              textAlign: pw.TextAlign.center,
            ),
          )
        else if (report.visits.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              "No visits recorded for this day.",
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        pw.SizedBox(height: 25),
      ],
    );
  }

  static pw.Widget _metaLabelValue(String l, String v) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: "$l: ",
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.TextSpan(
            text: v,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVisitTable(List<Visit> visits) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableHeader("Time"),
            _tableHeader("Shop Name"),
            _tableHeader("Channel"),
            _tableHeader("Status"),
            _tableHeader("Productive"),
            _tableHeader("Revenue"),
          ],
        ),
        ...visits.map((v) {
          double revenue = 0;
          for (var ord in v.orders) {
            for (var item in ord.items) {
              final rate =
                  double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
              final pcs =
                  double.tryParse(item['qty_pcs']?.toString() ?? '0') ?? 0;
              final box =
                  double.tryParse(item['qty_box']?.toString() ?? '0') ?? 0;
              revenue += (pcs + box) * rate;
            }
          }
          return pw.TableRow(
            children: [
              _tableCell(
                v.createdAt.split(' ').length > 1
                    ? v.createdAt.split(' ').sublist(1).join(' ')
                    : v.createdAt,
              ),
              _tableCell(v.placeName),
              _tableCell(v.channel),
              _tableCell(v.orders.isEmpty ? "No Order" : "Visit Done"),
              _tableCell(v.orders.any((o) => o.isProductive) ? "Yes" : "No"),
              _tableCell(
                revenue.toStringAsFixed(0),
                align: pw.Alignment.centerRight,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeader(String t) => pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(
      t,
      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    ),
  );
  static pw.Widget _tableCell(
    String t, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Align(
      alignment: align,
      child: pw.Text(t, style: pw.TextStyle(fontSize: 8)),
    ),
  );

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Generated by CENTREX",
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
            pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }
}
