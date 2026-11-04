import 'dart:math' as math;

import 'package:beacon/core/controllers/hr_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/HR/attendance_report_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:beacon/ui/view/dashboard/HR/employee_attendance_detail_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AttendanceReportView extends StatefulWidget {
  const AttendanceReportView({
    super.key,
    required this.siteName,
    required this.siteID,
    required this.deptName,
    required this.deptID,
    this.siteImage,
  });

  final String siteName;
  final String siteID;
  final String deptName;
  final int deptID;
  final String? siteImage;

  @override
  State<AttendanceReportView> createState() => _AttendanceReportViewState();
}

class _AttendanceReportViewState extends State<AttendanceReportView>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF1F2A37);

  AnimationController? _chartAnimController;
  Animation<double>? _chartAnim;
  String? _animationKey;

  Animation<double> get _safeChartAnim =>
      _chartAnim ?? const AlwaysStoppedAnimation<double>(1);

  @override
  void initState() {
    super.initState();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController!,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReportData());
  }

  @override
  void dispose() {
    _chartAnimController?.dispose();
    super.dispose();
  }

  void _triggerChartAnimation(String key) {
    if (_animationKey == key) return;
    _animationKey = key;
    _chartAnimController?.reset();
    _chartAnimController?.forward();
  }

  double _chartViewportHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    return (size.height * 0.22).clamp(
      shortest < 600 ? 160.0 : 190.0,
      shortest < 600 ? 210.0 : 240.0,
    );
  }

  void _fetchReportData() {
    _animationKey = null;
    final hrController = context.read<HRController>();
    hrController.getAttendanceReport(
      context,
      month: DateFormat('MM').format(hrController.attendanceSelectedDate),
      year: DateFormat('yyyy').format(hrController.attendanceSelectedDate),
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
    );
  }

  List<AttendanceStatusCount> _statusCounts(AttendanceReportModel model) {
    final table = model.data?.tableData ?? [];
    if (table.isNotEmpty) return table;
    final emp = model.employee?.attendance ?? [];
    if (emp.isNotEmpty) return emp;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: "Attendance Report",
        actions: [
          IconButton(
            icon: Icon(BoxIcons.bx_refresh, color: AppColor.white),
            tooltip: "Refresh Data",
            onPressed: _fetchReportData,
          ),
        ],
      ),
      body: Consumer<HRController>(
        builder: (context, controller, child) {
          final model = controller.attendanceReportModel;
          final isLoading = controller.isAttendanceReportLoading;
          final employees = model?.departmentEmployees ?? [];

          if (!isLoading && employees.isNotEmpty) {
            final animKey =
                '${controller.attendanceSelectedDate.millisecondsSinceEpoch}_'
                '${employees.length}';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _triggerChartAnimation(animKey);
            });
          }

          return RefreshIndicator(
            color: _accent,
            onRefresh: () async => _fetchReportData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(controller),
                  if (isLoading)
                    const AppLoadingView()
                  else if (employees.isEmpty)
                    _buildEmptyState(controller)
                  else ...[
                    _buildMetricsRow(model!, employees),
                    if (_statusCounts(model).isNotEmpty)
                      _buildStatusChart(model),
                    _buildEmployeeList(controller, employees),
                    4.height,
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner(HRController controller) {
    final formattedMonth = DateFormat(
      'MMMM yyyy',
    ).format(controller.attendanceSelectedDate);
    final now = DateTime.now();
    final selected = controller.attendanceSelectedDate;
    final isCurrentMonth =
        selected.year == now.year && selected.month == now.month;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, AppColor.appDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: widget.siteImage != null && widget.siteImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.w),
                        child: Image.asset(
                          widget.siteImage!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(
                        BoxIcons.bxs_calendar_check,
                        color: AppColor.white,
                        size: 6.w,
                      ),
              ),
              3.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.siteName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 4.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    0.4.height,
                    Text(
                      widget.deptName,
                      style: TextStyle(
                        color: AppColor.white.withValues(alpha: 0.85),
                        fontSize: 3.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          2.height,
          InkWell(
            onTap: () async {
              await CustomMonthPicker.showMonthPickerDialog(
                context: context,
                selectedMonth: controller.attendanceSelectedDate,
                onMonthSelected: (date) {
                  controller.setAttendanceSelectedDate(date);
                  _fetchReportData();
                },
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: AppColor.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.white.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        BoxIcons.bx_calendar,
                        color: AppColor.white,
                        size: 4.5.w,
                      ),
                      2.width,
                      Text(
                        isCurrentMonth
                            ? "Month: $formattedMonth"
                            : "Month: $formattedMonth",
                        style: TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 3.5.sp,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "CHANGE",
                      style: TextStyle(
                        color: AppColor.appDarkColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 2.6.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(
    AttendanceReportModel model,
    List<AttendanceEmployee> employees,
  ) {
    final counts = _statusCounts(model);
    int daysFor(String code) {
      final match = counts.where((e) => (e.status ?? '').toUpperCase() == code);
      if (match.isEmpty) return 0;
      return match.first.totalDays ?? 0;
    }

    final present = daysFor('P');
    final unknown = daysFor('UNKNOWN');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: _metricCard(
              "Staff",
              employees.length.toString(),
              BoxIcons.bxs_group,
              _accent,
            ),
          ),
          2.width,
          Expanded(
            child: _metricCard(
              "Present Days",
              present.toString(),
              BoxIcons.bxs_check_circle,
              const Color(0xFFB8922A),
            ),
          ),
          2.width,
          Expanded(
            child: _metricCard(
              "Unknown",
              unknown.toString(),
              BoxIcons.bxs_error_circle,
              const Color(0xFF696D75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 4.5.w),
          1.height,
          Text(
            value,
            style: TextStyle(
              fontSize: 3.8.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 2.4.sp,
              color: AppColor.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart(AttendanceReportModel model) {
    final counts = _statusCounts(
      model,
    ).where((e) => (e.totalDays ?? 0) > 0).toList();
    if (counts.isEmpty) return const SizedBox.shrink();
    final total = counts.fold<int>(0, (s, e) => s + (e.totalDays ?? 0));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.7),
        ),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(BoxIcons.bxs_pie_chart_alt_2, color: _accent, size: 5.w),
              2.width,
              Text(
                "Attendance Breakdown",
                style: TextStyle(
                  fontSize: 3.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.appDarkColor,
                ),
              ),
            ],
          ),
          1.5.height,
          SizedBox(
            height: _chartViewportHeight(context),
            child: AnimatedBuilder(
              animation: _safeChartAnim,
              builder: (context, child) {
                final anim = _safeChartAnim.value.clamp(0.0, 1.0);
                return Row(
                  children: [
                    Expanded(
                      child: Transform.rotate(
                        angle: (1 - anim) * 4 * math.pi,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 32,
                            startDegreeOffset: -90,
                            sections: counts.map((item) {
                              final days = item.totalDays ?? 0;
                              final color = AttendanceStatusStyle.colorOf(
                                item.status,
                              );
                              return PieChartSectionData(
                                color: color,
                                value: (days * anim).clamp(0, double.infinity),
                                title: anim > 0.7 ? '$days' : '',
                                radius: 42,
                                titleStyle: TextStyle(
                                  fontSize: 2.4.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.white,
                                ),
                              );
                            }).toList(),
                          ),
                          duration: Duration.zero,
                        ),
                      ),
                    ),
                    2.width,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: counts.map((item) {
                          final days = item.totalDays ?? 0;
                          final pct = total > 0 ? (days / total) * 100 : 0;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 0.8.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 2.5.w,
                                  height: 2.5.w,
                                  decoration: BoxDecoration(
                                    color: AttendanceStatusStyle.colorOf(
                                      item.status,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                1.5.width,
                                Expanded(
                                  child: Text(
                                    AttendanceStatusStyle.labelOf(item.status),
                                    style: TextStyle(
                                      fontSize: 2.4.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.appDarkColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 2.2.sp,
                                    color: AppColor.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(
    HRController controller,
    List<AttendanceEmployee> employees,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.8.w),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(BoxIcons.bxs_group, color: _accent, size: 4.w),
                  ),
                  2.width,
                  Text(
                    "Department Employees",
                    style: TextStyle(
                      fontSize: 4.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.5.w,
                  vertical: 0.4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColor.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  "${employees.length} staff",
                  style: TextStyle(
                    fontSize: 2.8.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        1.5.height,
        AnimationLimiter(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            itemCount: employees.length,
            separatorBuilder: (_, _) => 1.5.height,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 40,
                  child: FadeInAnimation(child: _employeeCard(emp, controller)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _employeeCard(AttendanceEmployee emp, HRController controller) {
    final isActive = emp.status?.toUpperCase() == "A";
    final statusColor = isActive ? AppColor.green : AppColor.red;

    final hasJoinDate = emp.joinDate != null && emp.joinDate!.trim().isNotEmpty;
    final hasMobile = emp.mobile != null && emp.mobile!.trim().isNotEmpty;

    return Material(
      color: AppColor.white,
      surfaceTintColor: AppColor.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AppRoutes.push(
            EmployeeAttendanceDetailView(
              siteName: widget.siteName,
              siteID: widget.siteID,
              deptName: widget.deptName,
              deptID: widget.deptID,
              siteImage: widget.siteImage,
              employee: emp,
              initialMonth: controller.attendanceSelectedDate,
            ),
          );
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadow.soft,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 1.1.w, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _avatar(emp, haloColor: statusColor),
                            3.width,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp.name ?? "Unknown",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 3.8.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.appDarkColor,
                                    ),
                                  ),
                                  0.3.height,
                                  Text(
                                    emp.designation ?? "Employee",
                                    style: TextStyle(
                                      fontSize: 2.8.sp,
                                      color: AppColor.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 3.5.w,
                              color: AppColor.grey,
                            ),
                          ],
                        ),
                        if (hasJoinDate || hasMobile) ...[
                          1.2.height,
                          Divider(height: 1, color: AppColor.scaffold),
                          1.height,
                          Wrap(
                            spacing: 2.w,
                            runSpacing: 0.8.h,
                            children: [
                              if (hasJoinDate)
                                _infoPill(
                                  icon: BoxIcons.bx_calendar_check,
                                  label: "Joined ${emp.joinDate}",
                                ),
                              if (hasMobile)
                                _infoPill(
                                  icon: BoxIcons.bx_phone,
                                  label: emp.mobile!,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoPill({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: AppColor.scaffold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.3.w, color: _accent),
          1.3.width,
          Text(
            label,
            style: TextStyle(
              fontSize: 2.6.sp,
              color: AppColor.appDarkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(AttendanceEmployee emp, {Color? haloColor}) {
    final color = haloColor ?? _accent;
    return Container(
      width: 13.w,
      height: 13.w,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: emp.profilePic != null && emp.profilePic!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: emp.profilePic!,
                fit: BoxFit.cover,
                placeholder: (_, _) => _avatarFallback(emp),
                errorWidget: (_, _, _) => _avatarFallback(emp),
              )
            : _avatarFallback(emp),
      ),
    );
  }

  Widget _avatarFallback(AttendanceEmployee emp) {
    final initials = emp.name != null && emp.name!.trim().isNotEmpty
        ? emp.name!.trim().split(' ').take(2).map((e) => e[0]).join()
        : '?';
    return Container(
      color: _accent.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: _accent,
          fontWeight: FontWeight.bold,
          fontSize: 3.5.sp,
        ),
      ),
    );
  }

  Widget _buildEmptyState(HRController controller) {
    return Container(
      margin: EdgeInsets.all(5.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        children: [
          Icon(BoxIcons.bx_calendar, size: 12.w, color: _accent),
          2.height,
          Text(
            "No Attendance Data",
            style: TextStyle(
              fontSize: 4.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          Text(
            "No employees found for ${widget.deptName} in ${DateFormat('MMMM yyyy').format(controller.attendanceSelectedDate)}.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 3.2.sp, color: AppColor.grey),
          ),
          3.height,
          ElevatedButton.icon(
            onPressed: _fetchReportData,
            icon: Icon(BoxIcons.bx_refresh, color: AppColor.white),
            label: const Text(
              "Reload Report",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
