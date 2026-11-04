// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/models/Employees/emp_working_detail_model.dart';
import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/view/dashboard/employees/employee_route_map_view.dart';
import 'package:beacon/ui/view/dashboard/employees/visit_details_list_view.dart';
import 'package:beacon/ui/view/dashboard/employees/full_screen_image_viewer.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/core/utils/pdf_report_generator.dart';
import 'package:beacon/ui/view/dashboard/employees/pdf_preview_view.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';

class EmployeeDetailView extends StatefulWidget {
  final User user;
  const EmployeeDetailView({super.key, required this.user});

  @override
  State<EmployeeDetailView> createState() => _EmployeeDetailViewState();
}

class _EmployeeDetailViewState extends State<EmployeeDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<EmployesController>();
      controller.selectedDate = DateTime.now();
      controller.fetchWorkingDetails(context, widget.user.userId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployesController>(
      builder: (context, controller, child) {
        final detail = controller.workingDetail;

        return Scaffold(
          backgroundColor: AppColor.scaffold,
          appBar: CustomAppBar(
            title: widget.user.userName ?? 'Analytics Dashboard',
            actions: [
              IconButton(
                icon: const Icon(Icons.assessment_rounded, color: Colors.white),
                tooltip: "Monthly Audit Report",
                onPressed: () =>
                    _handleGenerateMonthlyReport(context, controller),
              ),
              2.width,
            ],
          ),
          body: Column(
            children: [
              controller.isWorkingDetailLoading
                  ? SizedBox.shrink()
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, -30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildModernDateSelector(controller),
                    ),
              Expanded(
                child: controller.isWorkingDetailLoading
                    ? const AppLoadingView()
                    : _buildDashboardContent(context, controller, detail),
              ),
            ],
          ),
        );
      },
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
          final isSelected =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(controller.selectedDate);

          return GestureDetector(
            onTap: () => controller.updateSelectedDate(
              context,
              widget.user.userId!,
              date,
            ),
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
                color: isSelected
                    ? null
                    : AppColor.scaffold.withValues(alpha: 0.5),
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
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  0.5.height,
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 4.2.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColor.white
                          : AppColor.appDarkColor,
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
                  Icon(Icons.calendar_month, color: AppColor.appColor1),
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
                    "Generate a full performance and activity audit report for the selected month.",
                    style: TextStyle(color: AppColor.grey, fontSize: 3.2.sp),
                  ),
                  2.height,
                  CustomMonthPicker(
                    hint: "Select Month",
                    fieldTitle: "Audit Month",
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
    bool isFinalizing = false;
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
                const AppLoadingView(label: "Preparing Report..."),
                1.5.height,
                Text(
                  isFinalizing
                      ? "Finalizing report and resolving visit addresses..."
                      : "Analyzing performance for $dateRangeText...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.grey, fontSize: 3.sp),
                ),
                2.height,
                LinearProgressIndicator(
                  value: isFinalizing
                      ? null
                      : (totalDays == 0 ? 0 : currentDay / totalDays),
                  backgroundColor: AppColor.scaffold,
                  color: AppColor.appColor2,
                  borderRadius: BorderRadius.circular(20),
                  minHeight: 7,
                ),
                1.height,
                if (!isFinalizing)
                  Text(
                    "Processing day $currentDay of $totalDays",
                    style: TextStyle(fontSize: 2.2.sp, color: AppColor.grey),
                  ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final reports = await controller.fetchMonthlyData(
        context,
        widget.user.userId!,
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

      if (reports.isEmpty) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        Utils.showSnackBar(
          context,
          "No working records found for this period.",
        );
        return;
      }

      if (updateDialog != null) {
        updateDialog!(() {
          isFinalizing = true;
        });
      }

      final bytes = await PdfReportGenerator.generateMonthlyEmployeeReport(
        user: widget.user,
        reports: reports,
        dateRangeText: dateRangeText,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      final fileName =
          "${widget.user.userName?.replaceAll(' ', '_')}_${dateRangeText.replaceAll(' ', '_')}.pdf";

      AppRoutes.push(PdfPreviewView(pdfBytes: bytes, fileName: fileName));
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      Utils.showSnackBar(context, "Error generating monthly report: $e");
    }
  }

  Future<void> _onRefresh() async {
    final controller = context.read<EmployesController>();
    await controller.fetchWorkingDetails(context, widget.user.userId!);
  }

  Widget _buildDashboardContent(
    BuildContext context,
    EmployesController controller,
    EmployesWorkingDetailModel? detail,
  ) {
    if (detail == null && !controller.isWorkingDetailLoading) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColor.appColor1,
        child: _buildEmptyState(),
      );
    }

    bool hasVisits = detail != null && detail.visits.isNotEmpty;
    bool hasCheckin = detail?.checkin != null;

    int index = 0;
    Widget staggered({
      required Widget child,
      double horizontalOffset = 0,
      double verticalOffset = 0,
    }) {
      final position = index++;
      return AnimationConfiguration.staggeredList(
        position: position,
        duration: const Duration(milliseconds: 500),
        child: SlideAnimation(
          horizontalOffset: horizontalOffset,
          verticalOffset: verticalOffset,
          child: FadeInAnimation(child: child),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColor.appColor1,
      child: AnimationLimiter(
        child: ListView(
          padding: EdgeInsets.all(5.w),
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          children: [
            staggered(
              horizontalOffset: 60, // right se
              child: _buildEnhancedUserCard(isOnline: hasCheckin),
            ),
            3.height,
            if (detail != null && detail.totalVisits > 0) ...[
              _buildSectionTitle("Performance Intelligence"),
              2.height,
              staggered(
                horizontalOffset: -60,
                child: _buildRichAnalyticsCard(detail),
              ),
              3.height,
            ],
            _buildSectionTitle("Daily Journey"),
            2.height,
            Row(
              children: [
                Expanded(
                  child: staggered(
                    horizontalOffset: -60,
                    child: _timelineCardPremium(
                      context,
                      "CHECK IN",
                      detail?.checkin?.time ?? "Pending",
                      Icons.login_rounded,
                      AppColor.green,
                      detail?.checkin != null
                          ? () => _showEventDetails(
                              context,
                              "Check-in",
                              detail!.checkin!,
                            )
                          : null,
                    ),
                  ),
                ),
                4.width,
                Expanded(
                  child: staggered(
                    horizontalOffset: 60, // check-out right se
                    child: _timelineCardPremium(
                      context,
                      "CHECK OUT",
                      detail?.checkout?.time ?? "Pending",
                      Icons.logout_rounded,
                      AppColor.red,
                      detail?.checkout != null
                          ? () =>
                                _showCheckoutDetails(context, detail!.checkout!)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            3.height,
            if (hasVisits || hasCheckin) ...[
              _buildSectionTitle("Operational Modules"),
              2.height,
              if (hasVisits) ...[
                staggered(
                  verticalOffset: 60,
                  child: _buildActionModule(
                    "Field Activity Logs",
                    "${detail.totalVisits} customer touchpoints recorded",
                    Icons.fact_check_rounded,
                    AppColor.appColor1,
                    onTap: () => AppRoutes.push(
                      VisitDetailsListView(
                        visits: detail.visits,
                        dept: widget.user.department ?? 'Other',
                      ),
                    ),
                  ),
                ),
                1.5.height,
              ],
              if (hasCheckin)
                staggered(
                  verticalOffset: 60,
                  child: _buildActionModule(
                    "Visual Coverage Map",
                    "Territory exploration & route intelligence",
                    Icons.map_rounded,
                    AppColor.appDarkColor,
                    onTap: () =>
                        AppRoutes.push(EmployeeRouteMapView(detail: detail!)),
                  ),
                ),
            ],
            5.height,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedUserCard({required bool isOnline}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProfileAvatarPremium(),
          4.width,
          Expanded(
            child: Text(
              widget.user.userName ?? 'Employee',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 4.8.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
          3.width,
          _statusIndicatorPremium(isOnline: isOnline),
        ],
      ),
    );
  }

  Widget _statusIndicatorPremium({required bool isOnline}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: (isOnline ? AppColor.green : AppColor.red).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: (isOnline ? AppColor.green : AppColor.red).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 1.5.w,
            height: 1.5.w,
            decoration: BoxDecoration(
              color: isOnline ? AppColor.green : AppColor.red,
              shape: BoxShape.circle,
            ),
          ),
          2.width,
          Text(
            isOnline ? "ONLINE" : "OFFLINE",
            style: TextStyle(
              color: isOnline ? AppColor.green : AppColor.red,
              fontSize: 3.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatarPremium() {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColor.appColor1.withValues(alpha: 0.1),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50.r),
        child: widget.user.profilePic != null
            ? CachedNetworkImage(
                imageUrl: widget.user.profilePic!,
                fit: BoxFit.fill,
                alignment: Alignment.center,
                errorWidget: (c, u, e) => Icon(
                  Icons.person_rounded,
                  color: AppColor.appColor1,
                  size: 8.w,
                ),
              )
            : Icon(Icons.person_rounded, color: AppColor.appColor1, size: 8.w),
      ),
    );
  }

  Widget _buildRichAnalyticsCard(EmployesWorkingDetailModel? detail) {
    final total = detail?.visits.length ?? 0;
    final isSales =
        widget.user.department?.toLowerCase().contains("sales") == true;

    log(isSales.toString());
    if (!isSales) {
      return _buildSimpleVisitsCard(total);
    }

    final productive =
        detail?.visits
            .where((v) => v.orders.any((o) => o.isProductive))
            .length ??
        0;
    final nonProductive = total - productive;
    final productivePercent = total > 0 ? (productive / total) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        children: [
          SizedBox(
            height: 15.h,
            width: 15.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 12.r,
                    sections: [
                      PieChartSectionData(
                        color: AppColor.green,
                        value: productive > 0 ? productive.toDouble() : 0.01,
                        radius: 10,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: AppColor.red,
                        value: nonProductive > 0
                            ? nonProductive.toDouble()
                            : 0.01,
                        radius: 10,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${productivePercent.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 4.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "Productive",
                      style: TextStyle(
                        fontSize: 2.sp,
                        color: AppColor.grey,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          6.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _analyticRowPremium(
                  "Total Market Visits",
                  total.toString(),
                  AppColor.appDarkColor,
                  Icons.store_rounded,
                ),
                1.height,
                _analyticRowPremium(
                  "Productive Visits",
                  productive.toString(),
                  AppColor.green,
                  Icons.task_alt_rounded,
                ),
                1.height,
                _analyticRowPremium(
                  "Non-Productive",
                  nonProductive.toString(),
                  AppColor.red,
                  Icons.block_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleVisitsCard(int total) {
    final activityPercent = (total * 10).clamp(0, 100) / 100;

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.5.w),
            decoration: BoxDecoration(
              color: AppColor.appDarkColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Icon(
              Iconsax.shop_bold,
              color: AppColor.appDarkColor,
              size: 7.w,
            ),
          ),
          4.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      total.toString(),
                      style: TextStyle(
                        fontSize: 5.5.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColor.appDarkColor,
                        height: 1,
                      ),
                    ),
                    1.width,
                    Padding(
                      padding: EdgeInsets.only(bottom: 0.4.h),
                      child: Text(
                        "visits recorded",
                        style: TextStyle(
                          fontSize: 2.8.sp,
                          color: AppColor.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                1.5.height,
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: activityPercent,
                    minHeight: 1.h,
                    backgroundColor: AppColor.scaffold,
                    color: AppColor.green,
                  ),
                ),
                1.height,
                Text(
                  "${(activityPercent * 100).toStringAsFixed(0)}% activity level",
                  style: TextStyle(
                    fontSize: 2.4.sp,
                    color: AppColor.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticRowPremium(String l, String v, Color c, IconData icon) => Row(
    children: [
      Container(
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 3.5.r, color: c),
      ),
      3.width,
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                l,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 3.5.sp,
                  color: AppColor.appDarkColor,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Text(
              v,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 4.sp,
                color: c,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _timelineCardPremium(
    BuildContext context,
    String title,
    String val,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    bool isPending = val == "Pending";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(5.r),
          boxShadow: AppShadow.soft,
          border: isPending
              ? null
              : Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isPending ? AppColor.grey : color, size: 5.w),
                if (!isPending)
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColor.grey.withValues(alpha: 0.2),
                    size: 5.w,
                  ),
              ],
            ),
            2.height,
            Text(
              title,
              style: TextStyle(
                fontSize: 2.5.sp,
                color: AppColor.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            0.5.height,
            Text(
              val,
              style: TextStyle(
                fontSize: 4.sp,
                fontWeight: FontWeight.bold,
                color: isPending ? AppColor.grey : AppColor.appDarkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionModule(
    String title,
    String sub,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(5.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColor.white, size: 7.w),
            ),
            5.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 4.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  0.5.height,
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 3.sp,
                      color: AppColor.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 3.2.sp,
              color: AppColor.white.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Padding(
    padding: EdgeInsets.only(left: 1.w),
    child: Text(
      t.toUpperCase(),
      style: TextStyle(
        fontSize: 3.2.sp,
        fontWeight: FontWeight.bold,
        color: AppColor.appDarkColor,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 15.w,
                  color: AppColor.grey.withValues(alpha: 0.2),
                ),
                2.height,
                Text(
                  "No Insights Available",
                  style: TextStyle(
                    fontSize: 4.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
                Text(
                  "Pull down to refresh or select a different date.",
                  style: TextStyle(
                    fontSize: 2.8.sp,
                    color: AppColor.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetDetailItem(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            color: AppColor.appColor1.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Icon(icon, size: 6.r, color: AppColor.appColor1),
        ),
        2.5.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 3.5.sp,
                  color: AppColor.grey,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0.3,
                ),
              ),
              0.3.height,
              Text(
                val,
                style: TextStyle(
                  fontSize: 4.sp,
                  color: AppColor.appDarkColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAttendanceDetails(
    BuildContext context,
    String title,
    String subtitle,
    dynamic data,
  ) async {
    final imageUrl = (data as dynamic).imageUrl as String? ?? '';
    final time = (data as dynamic).time as String? ?? 'N/A';
    final lat = (data as dynamic).latitude as String? ?? '';
    final lng = (data as dynamic).longitude as String? ?? '';
    final reason = (data as dynamic).reason as String?;

    String address = await context
        .read<EmployesController>()
        .getAddressFromLatLng(double.parse(lat), double.parse(lng));
    log("Address: $address");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          5.w,
          2.w,
          5.w,
          5.w + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 10.w,
                height: 4,
                margin: EdgeInsets.only(bottom: 3.h),
                decoration: BoxDecoration(
                  color: AppColor.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 4.5.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.appDarkColor,
              ),
            ),
            1.height,
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 2.8.sp,
                color: AppColor.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            2.5.height,
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppColor.scaffold,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: imageUrl.isNotEmpty
                        ? GestureDetector(
                            onTap: () => AppRoutes.push(
                              FullScreenImageViewer(images: [imageUrl]),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: 20.h,
                                fit: BoxFit.fill,
                                placeholder: (c, u) => Center(child: CupertinoActivityIndicator(radius: 8, color: AppColor.grey)),
                                errorWidget: (c, u, e) => Container(
                                  width: double.infinity,
                                  height: 20.h,
                                  color: AppColor.scaffold,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColor.grey,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: AppColor.scaffold,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppColor.grey,
                            ),
                          ),
                  ),
                  4.width,
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetDetailItem(
                          Icons.access_time_filled_rounded,
                          "Time",
                          Utils.formatTime(time),
                        ),
                        1.5.height,
                        _sheetDetailItem(
                          Icons.location_on_rounded,
                          "Location",
                          address,
                        ),
                        if (reason != null && reason.trim().isNotEmpty) ...[
                          1.5.height,
                          _sheetDetailItem(
                            Icons.note_alt_rounded,
                            "Reason",
                            reason,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            4.height,
          ],
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, String event, Checkin data) {
    _showAttendanceDetails(
      context,
      "$event insight",
      "Detailed check-in information",
      data,
    );
  }

  void _showCheckoutDetails(BuildContext context, Checkout data) {
    _showAttendanceDetails(
      context,
      "Shift Conclusion",
      "Final checkout details",
      data,
    );
  }
}
