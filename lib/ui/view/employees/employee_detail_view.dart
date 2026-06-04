// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/extensions/routes.dart';
import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/models/employes_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/core/utils/utils.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:centrex/ui/components/app_constants.dart';
import 'package:centrex/ui/view/employees/employee_route_map_view.dart';
import 'package:centrex/ui/view/employees/visit_details_list_view.dart';
import 'package:centrex/ui/view/employees/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:intl/intl.dart';
import 'package:centrex/ui/components/custom_month_picker.dart';
import 'package:centrex/core/utils/pdf_report_generator.dart';
import 'package:centrex/ui/view/employees/pdf_preview_view.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
              if (widget.user.department?.toLowerCase().contains("sales") ==
                      true ||
                  widget.user.department?.toLowerCase().contains("marketing") ==
                      true)
                IconButton(
                  icon: const Icon(
                    Icons.assessment_rounded,
                    color: Colors.white,
                  ),
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
                  : _buildModernDateSelector(controller),
              Expanded(
                child: controller.isWorkingDetailLoading
                    ? Skeletonizer(
                        enabled: true,
                        child: _buildSkeletonLoading(),
                      )
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
                  "Preparing Report...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                1.5.height,
                Text(
                  "Analyzing performance for ${DateFormat('MMMM').format(selectedMonth)}...",
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
        Utils.showSnackBar(context, "No working records found for this month.");
        return;
      }

      final bytes = await PdfReportGenerator.generateMonthlyEmployeeReport(
        user: widget.user,
        reports: reports,
        month: selectedMonth,
      );

      final fileName =
          "${widget.user.userName?.replaceAll(' ', '_')}_${DateFormat('MMM_yyyy').format(selectedMonth)}.pdf";

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

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColor.appColor1,
      child: ListView(
        padding: EdgeInsets.all(5.w),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        children: [
          _buildEnhancedUserCard(isOnline: hasCheckin),
          3.height,
          if (detail != null && detail.totalVisits > 0) ...[
            _buildSectionTitle("Performance Intelligence"),
            2.height,
            _buildRichAnalyticsCard(detail),
            3.height,
          ],
          _buildSectionTitle("Daily Journey"),
          2.height,
          _buildCheckinCheckoutPremium(context, detail),

          3.height,
          if (hasVisits || hasCheckin) ...[
            _buildSectionTitle("Operational Modules"),
            2.height,

            if (hasVisits) ...[
              _buildActionModule(
                "Field Activity Logs",
                "${detail.totalVisits} customer touchpoints recorded",
                Icons.fact_check_rounded,
                AppColor.appColor1,
                onTap: () =>
                    AppRoutes.push(VisitDetailsListView(visits: detail.visits)),
              ),
              1.5.height,
            ],

            if (hasCheckin)
              _buildActionModule(
                "Visual Coverage Map",
                "Territory exploration & route intelligence",
                Icons.map_rounded,
                AppColor.appDarkColor,
                onTap: () =>
                    AppRoutes.push(EmployeeRouteMapView(detail: detail!)),
              ),
          ],
          5.height,
        ],
      ),
    );
  }

  Widget _buildEnhancedUserCard({required bool isOnline}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: AppShadow.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColor.appColor1.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5.w),
            child: Row(
              children: [
                _buildProfileAvatarPremium(),
                5.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text(
                            widget.user.userName ?? 'Employee',
                            style: TextStyle(
                              fontSize: 5.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.appDarkColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          _statusIndicatorPremium(isOnline: isOnline),
                        ],
                      ),
                      0.8.height,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _smallBadge(
                            widget.user.designation?.toUpperCase() ?? 'N/A',
                            AppColor.appColor1,
                          ),
                          2.width,
                          _smallBadge(
                            widget.user.department?.toUpperCase() ?? 'N/A',
                            AppColor.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 2.4.sp,
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

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
    final productive =
        detail?.visits
            .where((v) => v.orders.any((o) => o.isProductive))
            .length ??
        0;
    final total = detail?.totalVisits ?? 0;
    final percent = total > 0 ? (productive / total) * 100 : 0.0;

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
                        value: percent > 0 ? percent : 0.1,
                        radius: 10,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: AppColor.scaffold,
                        value: 100 - percent,
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
                      "${percent.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 4.5.sp,
                        fontWeight: FontWeight.w900,
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
                  "Successful Orders",
                  productive.toString(),
                  AppColor.green,
                  Icons.task_alt_rounded,
                ),
                1.height,
                _analyticRowPremium(
                  "Coverage Score",
                  "${percent.toStringAsFixed(1)}%",
                  AppColor.appColor1,
                  Icons.auto_graph_rounded,
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
          mainAxisAlignment: .spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l,
              style: TextStyle(
                fontSize: 3.5.sp,
                color: AppColor.appDarkColor,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              v,
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

  Widget _buildCheckinCheckoutPremium(
    BuildContext context,
    EmployesWorkingDetailModel? detail,
  ) {
    return Row(
      children: [
        _timelineCardPremium(
          context,
          "CHECK IN",
          detail?.checkin?.time ?? "Pending",
          Icons.login_rounded,
          AppColor.green,
          detail?.checkin != null
              ? () => _showEventDetails(context, "Check-in", detail!.checkin!)
              : null,
        ),
        4.width,
        _timelineCardPremium(
          context,
          "CHECK OUT",
          detail?.checkout?.time ?? "Pending",
          Icons.logout_rounded,
          AppColor.red,
          detail?.checkout != null
              ? () => _showCheckoutDetails(context, detail!.checkout!)
              : null,
        ),
      ],
    );
  }

  Widget _timelineCardPremium(
    BuildContext context,
    String title,
    String val,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    bool isPending = val == "Pending";
    return Expanded(
      child: GestureDetector(
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
                  Icon(
                    icon,
                    color: isPending ? AppColor.grey : color,
                    size: 5.w,
                  ),
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

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: EdgeInsets.all(5.w),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          spacing: 2.w,
          children: List.generate(7, (index) {
            return Expanded(
              child: _skeletonBox(height: 10.h, width: 5.w),
            );
          }),
        ),
        2.height,
        _skeletonBox(height: 12.h, width: double.infinity),
        3.height,
        _skeletonBox(height: 2.h, width: 45.w),
        2.height,
        _skeletonBox(height: 18.h, width: double.infinity),
        3.height,
        _skeletonBox(height: 2.h, width: 35.w),
        2.height,
        Row(
          children: [
            Expanded(child: _skeletonBox(height: 12.h)),
            4.width,
            Expanded(child: _skeletonBox(height: 12.h)),
          ],
        ),
        3.height,
        _skeletonBox(height: 2.h, width: 50.w),
        2.height,
        _skeletonBox(height: 10.h, width: double.infinity),
        1.5.height,
        _skeletonBox(height: 10.h, width: double.infinity),
        1.height,
        _skeletonBox(height: 3.h, width: double.infinity),
        1.height,
        _skeletonBox(height: 3.h, width: double.infinity),
      ],
    );
  }

  Widget _skeletonBox({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: AppColor.grey.withValues(alpha: 0.1),
      highlightColor: AppColor.white.withValues(alpha: 0.5),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

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
                                placeholder: (c, u) => Shimmer.fromColors(
                                  baseColor: AppColor.grey.withValues(
                                    alpha: 0.1,
                                  ),
                                  highlightColor: AppColor.white,
                                  child: Container(
                                    width: double.infinity,
                                    height: 20.h,
                                    color: AppColor.white,
                                  ),
                                ),
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
