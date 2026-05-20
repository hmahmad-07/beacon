import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/extensions/routes.dart';
import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/models/employes_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:centrex/ui/components/app_constants.dart';
import 'package:centrex/ui/view/employees/employee_route_map_view.dart';
import 'package:centrex/ui/view/employees/visit_details_list_view.dart';
import 'package:centrex/ui/view/employees/full_screen_image_viewer.dart';
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
        _buildEnhancedUserCard(),
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
    );
  }

  Widget _buildEnhancedUserCard() {
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
                      Text(
                        widget.user.userName ?? 'Employee',
                        style: TextStyle(
                          fontSize: 5.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColor.appDarkColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      0.8.height,
                      Row(
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
                _statusIndicatorPremium(),
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
    child: Text(
      text,
      style: TextStyle(
        fontSize: 1.8.sp,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _statusIndicatorPremium() => Container(
    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
    decoration: BoxDecoration(
      color: AppColor.green.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(50),
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
            fontSize: 1.8.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );

  Widget _buildProfileAvatarPremium() {
    return Container(
      width: 18.w,
      height: 18.w,
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
        borderRadius: BorderRadius.circular(100),
        child: widget.user.profilePic != null
            ? CachedNetworkImage(
                imageUrl: widget.user.profilePic!,
                fit: BoxFit.cover,
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
            height: 14.h,
            width: 14.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 36,
                    sections: [
                      PieChartSectionData(
                        color: AppColor.green,
                        value: percent > 0 ? percent : 0.1,
                        radius: 12,
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
                        fontSize: 1.8.sp,
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
        child: Icon(icon, size: 3.w, color: c),
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
                fontSize: 2.5.sp,
                color: AppColor.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              v,
              style: TextStyle(
                fontSize: 3.5.sp,
                color: c,
                fontWeight: FontWeight.w900,
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
                      size: 3.w,
                    ),
                ],
              ),
              2.height,
              Text(
                title,
                style: TextStyle(
                  fontSize: 2.sp,
                  color: AppColor.grey,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
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
                      fontSize: 3.8.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColor.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  0.5.height,
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 2.6.sp,
                      color: AppColor.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
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
        fontSize: 2.8.sp,
        fontWeight: FontWeight.w900,
        color: AppColor.grey,
        letterSpacing: 1.5,
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
                GestureDetector(
                  onTap: () => AppRoutes.push(
                    FullScreenImageViewer(images: [data.imageUrl]),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: data.imageUrl,
                      width: 24.w,
                      height: 24.w,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Shimmer.fromColors(
                        baseColor: AppColor.grey.withValues(alpha: 0.1),
                        highlightColor: AppColor.white,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          color: AppColor.white,
                        ),
                      ),
                      errorWidget: (c, u, e) => Container(
                        width: 24.w,
                        height: 24.w,
                        color: AppColor.scaffold,
                        child: Icon(Icons.broken_image, color: AppColor.grey),
                      ),
                    ),
                  ),
                ),
                5.width,
                Expanded(
                  child: Column(
                    children: [
                      _sheetDetailItem(
                        Icons.access_time_filled_rounded,
                        "Timestamp",
                        data.time,
                      ),
                      1.5.height,
                      _sheetDetailItem(
                        Icons.location_on_rounded,
                        "Coordinates",
                        "${data.latitude}, ${data.longitude}",
                      ),
                    ],
                  ),
                ),
              ],
            ),
            4.height,
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
              "Shift Conclusion",
              style: TextStyle(
                fontSize: 4.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.appDarkColor,
                letterSpacing: -0.3,
              ),
            ),
            2.5.height,
            _sheetDetailItem(
              Icons.access_time_filled_rounded,
              "Sign-out Time",
              data['time'] ?? 'N/A',
            ),
            1.5.height,
            _sheetDetailItem(
              Icons.location_on_rounded,
              "Final Location",
              "${data['latitude']}, ${data['longitude']}",
            ),
            4.height,
          ],
        ),
      ),
    );
  }
}
