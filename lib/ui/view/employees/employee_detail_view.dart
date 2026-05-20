import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/models/employes_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:centrex/ui/components/app_constants.dart';
import 'package:centrex/ui/view/employees/employee_route_map_view.dart';
import 'package:centrex/ui/view/employees/visit_details_list_view.dart';
import 'package:flutter/material.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

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
          ),
          body: Column(
            children: [
              _buildModernDateSelector(controller),
              Expanded(
                child: Skeletonizer(
                  enabled: controller.isWorkingDetailLoading,
                  child: _buildDashboardContent(context, controller, detail),
                ),
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
                borderRadius: BorderRadius.circular(2.r),
                boxShadow: isSelected ? AppShadow.soft : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 2.sp,
                      color: isSelected
                          ? AppColor.white.withValues(alpha: 0.8)
                          : AppColor.grey,
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

  Widget _buildDashboardContent(
    BuildContext context,
    EmployesController controller,
    EmployesWorkingDetailModel? detail,
  ) {
    if (detail == null && !controller.isWorkingDetailLoading) {
      return _buildEmptyState();
    }

    bool hasVisits = detail != null && detail.visits.isNotEmpty;
    bool hasCheckin = detail?.checkin != null;

    return ListView(
      padding: EdgeInsets.all(5.w),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildUserSummaryCard(),
        3.height,
        if (detail != null && detail.totalVisits > 0) ...[
          _buildSectionTitle("Performance Overview"),
          2.height,
          _buildAnalyticsCard(detail),
          3.height,
        ],
        _buildSectionTitle("Daily Timeline"),
        2.height,
        _buildCheckinCheckoutModern(context, detail),

        3.height,
        if ((hasVisits || hasCheckin) &&
            (widget.user.department?.toLowerCase().contains("sales") == true ||
                widget.user.department?.toLowerCase().contains("marketing") ==
                    true)) ...[
          _buildSectionTitle("Operational Modules"),
          2.height,

          if (hasVisits) ...[
            _buildActionModule(
              "Field Activity Logs",
              "${detail.totalVisits} customer touchpoints recorded",
              Icons.fact_check_rounded,
              AppColor.appColor1,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VisitDetailsListView(visits: detail.visits),
                ),
              ),
            ),
            1.5.height,
          ],

          if (hasCheckin)
            _buildActionModule(
              "Visual Coverage Map",
              "Territory exploration & route intelligence",
              Icons.map_rounded,
              AppColor.appDarkColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmployeeRouteMapView(detail: detail!),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildUserSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.badge_rounded,
              size: 30.w,
              color: AppColor.appColor1.withValues(alpha: 0.03),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5.w),
            child: Row(
              children: [
                _buildProfileAvatar(),
                5.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.userName ?? 'Employee',
                        style: TextStyle(
                          fontSize: 4.8.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appDarkColor,
                          letterSpacing: -0.8,
                        ),
                      ),
                      1.height,
                      Row(
                        children: [
                          _badge(
                            widget.user.designation ?? 'N/A',
                            AppColor.appColor1,
                          ),
                          2.width,
                          _badge(
                            widget.user.department ?? 'N/A',
                            AppColor.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _statusIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(4.r),
      border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
    ),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 1.8.sp,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _statusIndicator() => Container(
    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
    decoration: BoxDecoration(
      color: AppColor.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4.r),
      border: Border.all(color: AppColor.green.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 1.5.w,
          height: 1.5.w,
          decoration: BoxDecoration(
            color: AppColor.green,
            shape: BoxShape.circle,
          ),
        ),
        2.width,
        Text(
          "ONLINE",
          style: TextStyle(
            color: AppColor.green,
            fontSize: 2.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );

  Widget _buildProfileAvatar() {
    return Container(
      width: 16.w,
      height: 16.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: AppColor.appColor1.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.r),
        child: widget.user.profilePic != null
            ? CachedNetworkImage(
                imageUrl: widget.user.profilePic!,
                fit: BoxFit.cover,
                placeholder: (c, u) => _shimmerWidget(
                  shape: BoxShape.rectangle,
                  borderRadius: 3.r,
                ),
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

  Widget _buildAnalyticsCard(EmployesWorkingDetailModel? detail) {
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
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        children: [
          SizedBox(
            height: 12.h,
            width: 12.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 32,
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
                        fontSize: 4.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "Productive",
                      style: TextStyle(
                        fontSize: 1.8.sp,
                        color: AppColor.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          5.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _analyticRow(
                  "Total Visits",
                  total.toString(),
                  AppColor.appColor1,
                ),
                1.5.height,
                _analyticRow(
                  "Successful Orders",
                  productive.toString(),
                  AppColor.green,
                ),
                1.5.height,
                _analyticRow(
                  "Market Coverage",
                  "${percent.toStringAsFixed(1)}%",
                  AppColor.appDarkColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticRow(String l, String v, Color c) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        l,
        style: TextStyle(
          fontSize: 2.8.sp,
          color: AppColor.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(
        v,
        style: TextStyle(fontSize: 3.sp, color: c, fontWeight: FontWeight.w900),
      ),
    ],
  );

  Widget _buildCheckinCheckoutModern(
    BuildContext context,
    EmployesWorkingDetailModel? detail,
  ) {
    return Row(
      children: [
        _timelineCard(
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
        _timelineCard(
          context,
          "CHECK OUT",
          detail?.checkout?['time'] ?? "Pending",
          Icons.logout_rounded,
          AppColor.red,
          detail?.checkout != null
              ? () => _showCheckoutDetails(context, detail!.checkout!)
              : null,
        ),
      ],
    );
  }

  Widget _timelineCard(
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
              Icon(icon, color: isPending ? AppColor.grey : color, size: 5.w),
              2.height,
              Text(
                title,
                style: TextStyle(
                  fontSize: 2.2.sp,
                  color: AppColor.grey,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              0.5.height,
              Text(
                val,
                style: TextStyle(
                  fontSize: 3.8.sp,
                  fontWeight: FontWeight.w900,
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
    bool isActive = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isActive ? 1.0 : 0.5,
        child: Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColor.white, size: 7.w),
              4.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    0.3.height,
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 2.6.sp,
                        color: AppColor.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 3.5.sp,
                  color: AppColor.white.withValues(alpha: 0.6),
                ),
            ],
          ),
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
        color: AppColor.grey,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildEmptyState() {
    return Center(
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
            "Try selecting a different date from the timeline.",
            style: TextStyle(
              fontSize: 2.8.sp,
              color: AppColor.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Common Shimmer Widget
  Widget _shimmerWidget({
    double? width,
    double? height,
    double borderRadius = 0,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColor.grey.withValues(alpha: 0.1),
      highlightColor: AppColor.white.withValues(alpha: 0.4),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColor.white,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Reuse existing detail item for bottom sheets
  Widget _sheetDetailItem(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColor.appColor1.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 3.5.w, color: AppColor.appColor1),
        ),
        2.5.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 2.3.sp,
                  color: AppColor.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              0.3.height,
              Text(
                val,
                style: TextStyle(
                  fontSize: 3.sp,
                  color: AppColor.appDarkColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEventDetails(BuildContext context, String event, Checkin data) {
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              "$event insight",
              style: TextStyle(
                fontSize: 4.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.appDarkColor,
                letterSpacing: -0.3,
              ),
            ),
            2.5.height,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: data.imageUrl,
                    width: 24.w,
                    height: 24.w,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => _shimmerWidget(
                      width: 24.w,
                      height: 24.w,
                      borderRadius: 16,
                    ),
                    errorWidget: (c, u, e) => Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: AppColor.scaffold,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 8.w,
                        color: AppColor.grey,
                      ),
                    ),
                  ),
                ),
                4.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sheetDetailItem(
                        Icons.access_time_rounded,
                        "Time",
                        data.time,
                      ),
                      2.height,
                      _sheetDetailItem(
                        Icons.location_on_rounded,
                        "Coordinates",
                        "${data.latitude}, ${data.longitude}",
                      ),
                      if (data.reason != null) ...[
                        2.height,
                        _sheetDetailItem(
                          Icons.notes_rounded,
                          "Remarks",
                          data.reason!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            3.height,
          ],
        ),
      ),
    );
  }

  void _showCheckoutDetails(BuildContext context, Map<String, dynamic> data) {
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              "Checkout insight",
              style: TextStyle(
                fontSize: 4.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.appDarkColor,
                letterSpacing: -0.3,
              ),
            ),
            2.5.height,
            _sheetDetailItem(
              Icons.access_time_rounded,
              "Time",
              data['time'] ?? "N/A",
            ),
            2.height,
            _sheetDetailItem(
              Icons.location_on_rounded,
              "Location",
              "${data['latitude']}, ${data['longitude']}",
            ),
            3.height,
          ],
        ),
      ),
    );
  }
}
