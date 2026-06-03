import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/models/external_client_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/app_constants.dart';
import 'package:centrex/core/utils/pdf_report_generator.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:centrex/ui/components/custom_month_picker.dart';
import 'package:centrex/ui/view/employees/pdf_preview_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:centrex/core/extensions/routes.dart';
import 'package:centrex/core/utils/utils.dart';

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
            icon: const Icon(Icons.analytics_rounded, color: Colors.white),
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
                child: Skeletonizer(
                  enabled: controller.isExternalReportLoading,
                  child: controller.isExternalReportLoading
                      ? _buildSkeletonLoading()
                      : _buildReportContent(controller),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      children: [
        _shimmerBox(height: 12.h, width: double.infinity, borderRadius: 20),
        2.height,
        ...List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: _shimmerBox(height: 25.h, width: double.infinity, borderRadius: 16),
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({required double height, double? width, double borderRadius = 4}) {
    return Shimmer.fromColors(
      baseColor: AppColor.grey.withValues(alpha: 0.1),
      highlightColor: AppColor.white.withValues(alpha: 0.5),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
      ),
    );
  }

  Widget _buildReportContent(EmployesController controller) {
    final report = controller.externalReport;
    if (report == null || report.orders.isEmpty) {
      return _buildEmptyState();
    }

    double totalRevenue = 0;
    for (var order in report.orders) {
      for (var item in order.items) {
        totalRevenue += item.totalAmount;
      }
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchExternalReport(context),
      color: AppColor.appColor1,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildSummaryCard(report.totalOrders, totalRevenue),
          ...report.orders.map((order) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: _buildOrderCard(order),
              )),
          5.height,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 15.w, color: AppColor.grey),
          2.height,
          Text("No orders for this date",
              style: TextStyle(fontSize: 4.sp, color: AppColor.grey)),
        ],
      ),
    );
  }

  Widget _buildModernDateSelector(EmployesController controller) {
    return Container(
      height: 12.h,
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: AppShadow.soft,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        itemCount: controller.dateRange.length,
        itemBuilder: (context, index) {
          final date = controller.dateRange[index];
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(controller.externalReportDate);

          return GestureDetector(
            onTap: () => controller.updateExternalReportDate(context, date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 13.w,
              margin: EdgeInsets.only(right: 3.w),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColor.appColor1, AppColor.appDarkColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color:
                    isSelected ? null : AppColor.scaffold.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4.r),
                boxShadow: isSelected ? AppShadow.soft : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 2.sp,
                      color: isSelected ? AppColor.white : AppColor.grey,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  0.5.height,
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 4.2.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColor.white : AppColor.appDarkColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleGenerateMonthlyReport(
    BuildContext context,
    EmployesController controller,
  ) async {
    DateTime selectedMonth = DateTime.now();

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
                  Icon(Icons.analytics_rounded, color: AppColor.appColor1),
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
                      setDialogState(() => tempMonth = date);
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
                    backgroundColor: AppColor.appColor1,
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

    int currentDay = 0;
    int totalDays = 0;
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
                CupertinoActivityIndicator(
                  radius: 7.r,
                  color: AppColor.appColor1,
                ),
                3.height,
                Text(
                  "Preparing Summary...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                1.5.height,
                Text(
                  "Analyzing external sales for ${DateFormat('MMMM').format(selectedMonth)}...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.grey, fontSize: 3.sp),
                ),
                2.height,
                LinearProgressIndicator(
                  value: totalDays == 0 ? 0 : currentDay / totalDays,
                  backgroundColor: AppColor.scaffold,
                  color: AppColor.appColor2,
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
        selectedMonth,
        (day, total) {
          if (updateDialog != null) {
            updateDialog!(() {
              currentDay = day;
              totalDays = total;
            });
          }
        },
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (reports.isEmpty) {
        Utils.showSnackBar(context, "No external orders found for this month.");
        return;
      }

      final bytes = await PdfReportGenerator.generateMonthlyExternalReport(
        reports: reports,
        month: selectedMonth,
      );

      final fileName =
          "External_Monthly_${DateFormat('MMM_yyyy').format(selectedMonth)}.pdf";

      AppRoutes.push(PdfPreviewView(pdfBytes: bytes, fileName: fileName));
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      Utils.showSnackBar(context, "Error: $e");
    }
  }

  Widget _buildSummaryCard(int totalOrders, double revenue) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.appDarkColor, AppColor.appColor1],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn("TOTAL ORDERS", totalOrders.toString()),
          Container(width: 1, height: 4.h, color: Colors.white24),
          _summaryColumn("TOTAL VALUE", "PKR ${revenue.toStringAsFixed(0)}"),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white70,
                fontSize: 2.2.sp,
                fontWeight: FontWeight.bold)),
        1.height,
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 4.sp,
                fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildOrderCard(ExternalOrder order) {
    double orderTotal = 0;
    for (var item in order.items) {
      orderTotal += item.totalAmount;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.entityName?.toUpperCase() ?? "UNKNOWN CLIENT",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 3.8.sp,
                            color: AppColor.appDarkColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusBadge(order.isProductive),
                  ],
                ),
                1.height,
                Row(
                  children: [
                    Icon(Icons.numbers_rounded, size: 3.w, color: AppColor.grey),
                    1.width,
                    Text("Entity No: ${order.entityNo ?? 'N/A'}",
                        style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey)),
                    const Spacer(),
                    Icon(Icons.access_time_filled_rounded,
                        size: 3.w, color: AppColor.grey),
                    1.width,
                    Text(order.orderDate,
                        style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey)),
                  ],
                ),
                const Divider(),
                ...order.items.map((item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.5.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${item.itemName} (x${(item.qtyPcs + item.qtyBox).toInt()})",
                              style: TextStyle(
                                  fontSize: 2.8.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            "PKR ${item.totalAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                                fontSize: 2.8.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: AppColor.scaffold.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ORDER TOTAL",
                    style: TextStyle(
                        fontSize: 2.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.grey)),
                Text("PKR ${orderTotal.toStringAsFixed(0)}",
                    style: TextStyle(
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColor.appColor1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool productive) {
    Color color = productive ? AppColor.green : AppColor.red;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        productive ? "PRODUCTIVE" : "NON-PRODUCTIVE",
        style: TextStyle(
            color: color, fontSize: 2.2.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
