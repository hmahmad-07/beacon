import 'dart:typed_data';
import 'package:beacon/core/models/emp_working_detail_model.dart';
import 'package:beacon/core/models/employes_model.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/external_client_model.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateDailyMasterReport({
    required List<User> users,
    required List<EmployesWorkingDetailModel> reports,
    required DateTime date,
    required String department,
    ExternalClientReportModel? externalReport,
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
          ...totalForce.map((data) {
            final u = data['user'] as User;
            final isUserSales = u.department?.toLowerCase().contains('sales') == true ||
                u.department?.toLowerCase().contains('marketing') == true;
            return _buildUserSection(
              u,
              data['report'] as EmployesWorkingDetailModel,
              isSales: isUserSales,
              showRemarks: true,
            );
          }),
          if (externalReport != null && externalReport.orders.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildExternalClientsSection(externalReport),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateMonthlyEmployeeReport({
    required User user,
    required List<EmployesWorkingDetailModel> reports,
    required String dateRangeText,
  }) async {
    final pdf = pw.Document();
    final String formattedMonth = dateRangeText;
    final bool isSales =
        user.department?.toLowerCase().contains('sales') ?? false;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(formattedMonth, "Monthly User Audit"),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildMonthlyUserSummary(user, reports, isSales: isSales),
          pw.SizedBox(height: 20),
          ...reports.map(
            (r) => _buildDailyActivitySection(
              r,
              isSales: isSales,
              showRemarks: true,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildDailyActivitySection(
    EmployesWorkingDetailModel report, {
    bool isSales = true,
    bool showRemarks = false,
  }) {
    final String formattedDate = DateFormat('dd-MMM-yyyy').format(report.date);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "DATE: $formattedDate",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                "Total Visits: ${report.totalVisits}",
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),
        _buildAttendanceSummary(report),
        if (report.visits.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _buildVisitTable(
            report.visits,
            isSales: isSales,
            showRemarks: showRemarks,
          ),
        ],
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildAttendanceSummary(EmployesWorkingDetailModel report) {
    return pw.Row(
      children: [
        _miniSummary("Check-in", report.checkin?.time ?? "N/A"),
        pw.SizedBox(width: 20),
        _miniSummary("Check-out", report.checkout?.time ?? "N/A"),
      ],
    );
  }

  static pw.Widget _miniSummary(String label, String val) {
    return pw.Row(
      children: [
        pw.Text(
          "$label: ",
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(val, style: pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static Future<Uint8List> generateMonthlyExternalReport({
    required List<ExternalClientReportModel> reports,
    required String dateRangeText,
  }) async {
    final pdf = pw.Document();
    final String formattedMonth = dateRangeText;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(formattedMonth, "Monthly External Clients"),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          ...reports.map((r) => _buildExternalClientsSection(r)),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMonthlyUserSummary(
    User user,
    List<EmployesWorkingDetailModel> reports, {
    bool isSales = true,
  }) {
    int totalVisits = 0;
    int productiveVisits = 0;
    double totalRevenue = 0;

    for (var r in reports) {
      totalVisits += r.totalVisits;
      for (var v in r.visits) {
        bool isProductive = v.orders.any((o) => o.isProductive);
        if (isProductive) {
          productiveVisits++;
          for (var o in v.orders) {
            for (var item in o.items) {
              final rate =
                  double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
              final qty =
                  (double.tryParse(item['qty_pcs']?.toString() ?? '0') ?? 0) +
                  (double.tryParse(item['qty_box']?.toString() ?? '0') ?? 0);
              totalRevenue += qty * rate;
            }
          }
        }
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            user.userName?.toUpperCase() ?? "N/A",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem("Total Visits", totalVisits.toString()),
              if (isSales)
                _summaryItem("Productive", productiveVisits.toString()),
              if (isSales)
                _summaryItem(
                  "Revenue",
                  "PKR ${totalRevenue.toStringAsFixed(0)}",
                ),
            ],
          ),
        ],
      ),
    );
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
                  "PAANI.",
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
    EmployesWorkingDetailModel report, {
    bool isSales = true,
    bool showRemarks = false,
  }) {
    int productive = report.visits
        .where((v) => v.orders.any((o) => o.isProductive))
        .length;

    double totalRev = 0;
    for (var v in report.visits) {
      for (var o in v.orders) {
        for (var item in o.items) {
          final rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
          final pcs = double.tryParse(item['qty_pcs']?.toString() ?? '0') ?? 0;
          final box = double.tryParse(item['qty_box']?.toString() ?? '0') ?? 0;
          totalRev += (pcs + box) * rate;
        }
      }
    }

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
            _metaLabelValue("Check-out", report.checkout?.time ?? "N/A"),
            pw.SizedBox(width: 20),
            _metaLabelValue("Total Visits", report.visits.length.toString()),
            if (isSales) ...[
              pw.SizedBox(width: 20),
              _metaLabelValue("Productive Visits", productive.toString()),
              pw.SizedBox(width: 20),
              _metaLabelValue("Total Amount", "PKR ${totalRev.toStringAsFixed(0)}"),
            ],
          ],
        ),
        pw.SizedBox(height: 10),
        if (report.visits.isNotEmpty) ...[
          _buildVisitTable(
            report.visits,
            isSales: isSales,
            showRemarks: showRemarks,
          ),
          pw.SizedBox(height: 10),
          if (isSales) _buildUserTotals(report.visits),
        ],
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

  static pw.Widget _buildUserTotals(List<Visit> visits) {
    int totalVisits = visits.length;
    int productive = visits
        .where((v) => v.orders.any((o) => o.isProductive))
        .length;
    double totalRev = 0;
    for (var v in visits) {
      for (var o in v.orders) {
        for (var item in o.items) {
          final rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
          final pcs = double.tryParse(item['qty_pcs']?.toString() ?? '0') ?? 0;
          final box = double.tryParse(item['qty_box']?.toString() ?? '0') ?? 0;
          totalRev += (pcs + box) * rate;
        }
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(color: PdfColors.blue100),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "User Totals:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.Text(
            "Total Visits: $totalVisits",
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text("Productive: $productive", style: pw.TextStyle(fontSize: 9)),
          pw.Text(
            "Total Revenue: ${totalRev.toStringAsFixed(0)}",
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
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

  static String _extractDuration(String remarks) {
    final match = RegExp(r'\((\d+)m(\d+)s\)').firstMatch(remarks);
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      return '${minutes}m ${seconds}s';
    }
    return 'N/A';
  }

  static String _extractRemarksText(String remarks) {
    if (remarks.isEmpty) return 'N/A';
    final extracted = remarks.replaceAll(RegExp(r'\(\d+m\d+s\)'), '').trim();
    return extracted.isEmpty ? 'N/A' : extracted;
  }

  static pw.Widget _buildVisitTable(
    List<Visit> visits, {
    bool isSales = true,
    bool showRemarks = false,
  }) {
    final sortedVisits = List<Visit>.from(visits)
      ..sort((a, b) {
        final dateA = a.orders.isNotEmpty && a.orders.first.orderDate.isNotEmpty
            ? a.orders.first.orderDate
            : a.createdAt;
        final dateB = b.orders.isNotEmpty && b.orders.first.orderDate.isNotEmpty
            ? b.orders.first.orderDate
            : b.createdAt;
        return Utils.parseDateTime(dateA).compareTo(Utils.parseDateTime(dateB));
      });

    final Map<int, pw.TableColumnWidth> columnWidths = {};
    int colIndex = 0;
    columnWidths[colIndex++] = const pw.IntrinsicColumnWidth(); // Time
    columnWidths[colIndex++] = const pw.FlexColumnWidth();      // Shop Name
    columnWidths[colIndex++] = const pw.IntrinsicColumnWidth(); // Channel
    if (isSales) {
      columnWidths[colIndex++] = const pw.IntrinsicColumnWidth(); // Status
    }
    columnWidths[colIndex++] = const pw.IntrinsicColumnWidth(); // Stay Time
    if (isSales) {
      columnWidths[colIndex++] = const pw.IntrinsicColumnWidth(); // Revenue
    }
    if (showRemarks) {
      columnWidths[colIndex++] = const pw.FixedColumnWidth(160);  // Remarks
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableHeader("Time"),
            _tableHeader("Shop Name"),
            _tableHeader("Channel"),
            if (isSales) _tableHeader("Status"),
            _tableHeader("Stay Time"),
            if (isSales) _tableHeader("Revenue"),
            if (showRemarks) _tableHeader("Remarks"),
          ],
        ),
        ...sortedVisits.map((v) {
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
                (() {
                  final displayDate =
                      v.orders.isNotEmpty && v.orders.first.orderDate.isNotEmpty
                      ? v.orders.first.orderDate
                      : v.createdAt;
                  return displayDate.split(' ').length > 1
                      ? displayDate.split(' ').sublist(1).join(' ')
                      : displayDate;
                })(),
              ),
              _tableCell(v.placeName),
              _tableCell(v.channel),
              if (isSales)
                _tableCell(
                  v.orders.any((o) => o.isProductive)
                      ? "Productive"
                      : "Non-Productive",
                ),
              _tableCell(
                _extractDuration(
                  v.orders.isNotEmpty && v.orders.first.remarks != null
                      ? v.orders.first.remarks!
                      : v.remarks ?? '',
                ),
              ),
              if (isSales)
                _tableCell(
                  revenue.toStringAsFixed(0),
                  align: pw.Alignment.centerRight,
                ),
              if (showRemarks)
                _tableCell(
                  _extractRemarksText(
                    v.orders.isNotEmpty && v.orders.first.remarks != null
                        ? v.orders.first.remarks!
                        : v.remarks ?? '',
                  ),
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

  static pw.Widget _buildExternalClientsSection(
    ExternalClientReportModel report,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "EXTERNAL CLIENTS ORDERS SUMMARY",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                "Total orders: ${report.totalOrders}",
                style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableHeader("Time"),
                _tableHeader("Client Name"),
                _tableHeader("Item"),
                _tableHeader("Qty"),
                _tableHeader("Rate"),
                _tableHeader("Amount"),
              ],
            ),
            ...report.orders.expand((order) {
              return order.items.asMap().entries.map((entry) {
                final itemIndex = entry.key;
                final item = entry.value;
                return pw.TableRow(
                  children: [
                    _tableCell(itemIndex == 0 ? order.orderDate : ""),
                    _tableCell(itemIndex == 0 ? (order.entityName ?? "") : ""),
                    _tableCell(item.itemName),
                    _tableCell((item.qtyPcs + item.qtyBox).toStringAsFixed(0)),
                    _tableCell(item.rate.toStringAsFixed(0)),
                    _tableCell(
                      item.totalAmount.toStringAsFixed(0),
                      align: pw.Alignment.centerRight,
                    ),
                  ],
                );
              });
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Generated by PAANI>",
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
