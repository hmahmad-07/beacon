// ignore_for_file: use_build_context_synchronously

import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/models/Employees/external_client_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/pdf_report_generator.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/ui/view/dashboard/employees/pdf_preview_view.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:beacon/core/utils/utils.dart';

class ExternalOrdersView extends StatefulWidget {
  const ExternalOrdersView({super.key});

  @override
  State<ExternalOrdersView> createState() => _ExternalOrdersViewState();
}

class _ExternalOrdersViewState extends State<ExternalOrdersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployesController>().fetchExternalReport(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: "External Clients Orders",
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_rounded, color: context.siteAccent),
            tooltip: "Monthly Summary Report",
            onPressed: () {
              final controller = context.read<EmployesController>();
              _handleGenerateMonthlyReport(context, controller);
            },
          ),
          2.width,
        ],
      ),
      body: Consumer<EmployesController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              _buildModernDateSelector(controller),
              Expanded(
                child: controller.isExternalReportLoading
                    ? const SiteLoading(label: "Loading orders…")
                    : _buildReportContent(controller),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportContent(EmployesController controller) {
    final report = controller.externalReport;
    if (report == null || report.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.fetchExternalReport(context),
        color: context.siteAccent,
        child: _buildEmptyState(),
      );
    }

    double totalRevenue = 0;
    for (var order in report.orders) {
      for (var item in order.items) {
        totalRevenue += item.totalAmount;
      }
    }
    final productive = report.orders.where((o) => o.isProductive).length;

    var i = 0;
    return RefreshIndicator(
      onRefresh: () => controller.fetchExternalReport(context),
      color: context.siteAccent,
      child: AnimationLimiter(
        child: ListView(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            siteStagger(
              i++,
              _buildSummaryCard(report.totalOrders, totalRevenue, productive),
            ),
            3.height,
            siteStagger(
              i++,
              SiteSectionTitle("Client orders", count: report.orders.length),
            ),
            ...report.orders.map(
              (order) => siteStagger(i++, _buildOrderCard(order)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const SiteEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: "No orders for this date",
            message: "Pick another day above or pull down to refresh.",
          ),
        ),
      ),
    );
  }

  Widget _buildModernDateSelector(EmployesController controller) {
    return SiteDateStrip(
      dates: controller.dateRange,
      selected: controller.externalReportDate,
      onSelected: (date) => controller.updateExternalReportDate(context, date),
    );
  }

  Future<void> _handleGenerateMonthlyReport(
    BuildContext context,
    EmployesController controller,
  ) async {
    final brandColor = PdfReportGenerator.brandColorFrom(
      context.siteAccent.toARGB32(),
    );
    DateTime selectedMonth = DateTime.now();
    DateTimeRange? customRange;

    bool? shouldGenerate = await showDialog<bool>(
      context: context,
      builder: (context) {
        DateTime tempMonth = selectedMonth;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.analytics_rounded, color: context.siteAccent),
                  2.width,
                  Text(
                    "Monthly Audit",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 4.5.sp,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Generate a monthly summary for all external clients bookings and sales.",
                    style: TextStyle(color: AppColor.grey, fontSize: 3.2.sp),
                  ),
                  2.height,
                  CustomMonthPicker(
                    hint: "Select Month",
                    fieldTitle: "Sales Month",
                    selectedMonth: tempMonth,
                    onMonthSelected: (date) {
                      setDialogState(() {
                        tempMonth = date;
                        customRange = null; // Clear range if month is picked
                      });
                    },
                  ),
                  2.height,
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColor.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color: AppColor.grey,
                            fontSize: 3.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColor.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  2.height,
                  CustomDateRangePicker(
                    hint: "Select Range",
                    fieldTitle: "Custom Range",
                    selectedRange: customRange,
                    onClear: () {
                      setDialogState(() {
                        customRange = null;
                      });
                    },
                    onRangeSelected: (range) {
                      setDialogState(() {
                        customRange = range;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      color: AppColor.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    selectedMonth = tempMonth;
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.siteAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "GENERATE REPORT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldGenerate != true) return;

    DateTime startDate;
    DateTime endDate;
    String dateRangeText;

    if (customRange != null) {
      startDate = customRange!.start;
      endDate = customRange!.end;
      dateRangeText =
          "${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}";
    } else {
      final now = DateTime.now();
      startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final isCurrentMonth =
          selectedMonth.year == now.year && selectedMonth.month == now.month;
      endDate = isCurrentMonth
          ? now
          : DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
      dateRangeText = DateFormat('MMMM yyyy').format(selectedMonth);
    }

    int currentDay = 0;
    int totalDays = endDate.difference(startDate).inDays + 1;
    StateSetter? updateDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          updateDialog = setDialogState;
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SiteLoading(label: "Preparing Summary..."),
                1.5.height,
                Text(
                  "Analyzing external sales for $dateRangeText...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.grey, fontSize: 3.sp),
                ),
                2.height,
                LinearProgressIndicator(
                  value: totalDays == 0 ? 0 : currentDay / totalDays,
                  backgroundColor: AppColor.scaffold,
                  color: context.siteAccent,
                  borderRadius: BorderRadius.circular(20),
                  minHeight: 7,
                ),
                1.height,
                Text(
                  "Day $currentDay / $totalDays",
                  style: TextStyle(fontSize: 2.2.sp, color: AppColor.grey),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final reports = await controller.fetchExternalMonthlyData(
        context,
        startDate,
        endDate,
        (day, total) {
          if (updateDialog != null) {
            updateDialog!(() {
              currentDay = day;
            });
          }
        },
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (reports.isEmpty) {
        Utils.showSnackBar(
          context,
          "No external orders found for this period.",
        );
        return;
      }

      final bytes = await PdfReportGenerator.generateMonthlyExternalReport(
        reports: reports,
        dateRangeText: dateRangeText,
        periodStart: startDate,
        periodEnd: endDate,
        brandColor: brandColor,
      );

      final fileName =
          "External_Monthly_${dateRangeText.replaceAll(' ', '_')}.pdf";

      context.pushSite(PdfPreviewView(pdfBytes: bytes, fileName: fileName));
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      Utils.showSnackBar(context, "Error: $e");
    }
  }

  Widget _buildSummaryCard(int totalOrders, double revenue, int productive) {
    return SiteBanner(
      eyebrow: DateFormat(
        'EEEE, dd MMM yyyy',
      ).format(context.read<EmployesController>().externalReportDate),
      title: "External client orders",
      titleSize: 4.6.sp,
      pills: [
        SiteBannerPill(
          "$productive productive",
          icon: Icons.check_circle_rounded,
        ),
        SiteBannerPill(
          "${totalOrders - productive < 0 ? 0 : totalOrders - productive} non-productive",
          icon: Icons.block_rounded,
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: _summaryColumn("Total orders", totalOrders.toString()),
          ),
          Container(
            width: 1,
            height: 5.h,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          4.width,
          Expanded(
            child: _summaryColumn(
              "Total value",
              "PKR ${revenue.toStringAsFixed(0)}",
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, String value) {
    return SiteBannerStat(label: label, value: value);
  }

  Widget _buildOrderCard(ExternalOrder order) {
    final accent = context.siteAccent;
    double orderTotal = 0;
    for (var item in order.items) {
      orderTotal += item.totalAmount;
    }

    return SiteCard(
      margin: EdgeInsets.only(bottom: 1.6.h),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SiteIconBadge(Icons.storefront_rounded, size: 10.w),
                    3.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.entityName ?? "Unknown client",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 3.9.sp,
                              color: AppColor.appDarkColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          0.3.height,
                          Text(
                            "${order.entityNo ?? 'N/A'} · ${Utils.formatDate(order.orderDate)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 2.8.sp,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    2.width,
                    _statusBadge(order.isProductive),
                  ],
                ),
                if (order.items.isNotEmpty) ...[
                  1.6.height,
                  ...order.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.5.h),
                      child: Row(
                        children: [
                          Container(
                            width: 1.6.w,
                            height: 1.6.w,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          2.5.width,
                          Expanded(
                            child: Text(
                              "${item.itemName} × ${(item.qtyPcs + item.qtyBox).toInt()}",
                              style: TextStyle(
                                fontSize: 3.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColor.darkGrey,
                              ),
                            ),
                          ),
                          Text(
                            "PKR ${item.totalAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 3.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.appDarkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if ((order.remarks ?? '').isNotEmpty) ...[
                  1.2.height,
                  Text(
                    "Remarks: ${order.remarks}",
                    style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.05),
              border: Border(
                top: BorderSide(color: accent.withValues(alpha: 0.08)),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ORDER TOTAL",
                  style: TextStyle(
                    fontSize: 2.6.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  "PKR ${orderTotal.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 4.sp,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool productive) {
    return SitePill.tint(
      productive ? "Productive" : "Non-productive",
      productive ? AppColor.green : AppColor.red,
    );
  }
}
