import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:shimmer/shimmer.dart';

import 'package:beacon/core/controllers/hr_controller.dart';
import 'package:beacon/core/models/HR/employee_salary_type_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:beacon/ui/components/app_constants.dart';

class JobTypeData {
  final String rawKey;
  final String displayName;
  final num salary;
  final int count;
  final Color color;
  final IconData icon;

  JobTypeData({
    required this.rawKey,
    required this.displayName,
    required this.salary,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class EmpSalaryTypeView extends StatefulWidget {
  final String siteName;
  final String siteID;
  final String deptName;
  final int deptID;
  final String? siteImage;

  const EmpSalaryTypeView({
    super.key,
    required this.siteName,
    required this.siteID,
    required this.deptName,
    required this.deptID,
    this.siteImage,
  });

  @override
  State<EmpSalaryTypeView> createState() => _EmpSalaryTypeViewState();
}

class _EmpSalaryTypeViewState extends State<EmpSalaryTypeView>
    with SingleTickerProviderStateMixin {
  AnimationController? _chartAnimController;
  Animation<double>? _chartAnim;

  Animation<double> get _safeChartAnim =>
      _chartAnim ?? const AlwaysStoppedAnimation<double>(1);

  late final PageController _graphPageController;
  int _graphPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _graphPageController = PageController();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController!,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReportData();
    });
  }

  @override
  void dispose() {
    _graphPageController.dispose();
    _chartAnimController?.dispose();
    super.dispose();
  }

  void _replayChartAnimation() {
    _chartAnimController?.reset();
    _chartAnimController?.forward();
  }

  // Deliberately awaits the fetch and replays the animation off its
  // completion, rather than detecting "data is ready" from a Consumer
  // rebuild. HRController is a shared, app-wide singleton — on a repeat
  // visit to this screen (same site/dept/month), the very first build
  // sees the PREVIOUS visit's leftover data before this fetch even
  // starts, animating that instead. The animKey computed from that stale
  // data (same date + same employee count) then matches the key computed
  // once the fresh data lands, so the real arrival gets silently
  // skipped — the entrance animation only ever seemed to fire once, on
  // truly first-ever load.
  Future<void> _fetchReportData() async {
    final hrController = context.read<HRController>();
    final monthStr = DateFormat('MM').format(hrController.selectedDate);
    final yearStr = DateFormat('yyyy').format(hrController.selectedDate);

    await hrController.getEmpSalaryTypeReport(
      context,
      month: monthStr,
      year: yearStr,
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
    );
    if (!mounted) return;
    final employees = hrController.salaryTypeReportModel?.departmentEmployees;
    if (employees != null && employees.isNotEmpty) {
      _replayChartAnimation();
    }
  }

  String _formatJobTypeName(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == "DAILYWAGES" || upper == "DAILY_WAGES") {
      return "DAILY WAGES";
    } else if (upper == "TEMP" || upper == "TEMPORARY") {
      return "TEMPORARY";
    }
    return upper;
  }

  // Short label used only for the bar chart's x-axis so long names
  // ("PERMANENT", "TEMPORARY") don't crowd/overlap under each bar.
  String _shortJobTypeLabel(String displayName) {
    final upper = displayName.trim().toUpperCase();
    if (upper.contains("PERMANENT")) return "Perm";
    if (upper.contains("CONTRACTUAL") || upper.contains("CONTRACT")) {
      return "Cont";
    }
    if (upper.contains("DAILY")) return "Daily";
    if (upper.contains("TEMP")) return "Temp";
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return trimmed;
    final words = trimmed.split(RegExp(r'\s+'));
    final short = words.length > 1
        ? words.map((w) => w.isNotEmpty ? w[0] : '').take(4).join()
        : (trimmed.length > 5 ? trimmed.substring(0, 5) : trimmed);
    return short.isEmpty
        ? short
        : short[0].toUpperCase() + short.substring(1).toLowerCase();
  }

  // Round, human-friendly y-axis steps (1, 2, 5, 10, 20, 50, 100...) so the
  // bar chart's grid reads as clean numbers instead of odd auto-computed ones.
  double _niceYAxisInterval(num maxValue) {
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 25) return 5;
    if (maxValue <= 60) return 10;
    if (maxValue <= 120) return 20;
    if (maxValue <= 300) return 50;
    return 100;
  }

  Color _getJobTypeColor(String? type) {
    if (type == null) return AppColor.grey;
    final t = type.trim().toUpperCase();
    if (t.contains("PERMANENT")) {
      return const Color(0xFF00A86B);
    } else if (t.contains("CONTRACTUAL") || t.contains("CONTRACT")) {
      return const Color(0xFFFF9F43);
    } else if (t.contains("DAILY") || t.contains("WAGE")) {
      return const Color(0xFF007AFF);
    } else if (t.contains("TEMP")) {
      return const Color(0xFFE83E8C);
    } else {
      return const Color(0xFF7367F0);
    }
  }

  IconData _getJobTypeIcon(String? type) {
    if (type == null) return BoxIcons.bx_id_card;
    final t = type.trim().toUpperCase();
    if (t.contains("PERMANENT")) {
      return BoxIcons.bxs_badge_check;
    } else if (t.contains("CONTRACTUAL")) {
      return BoxIcons.bxs_time_five;
    } else if (t.contains("DAILY")) {
      return BoxIcons.bxs_calendar;
    } else if (t.contains("TEMP")) {
      return BoxIcons.bx_time;
    }
    return BoxIcons.bxs_user_detail;
  }

  List<JobTypeData> _extractJobTypeData(SalaryTypeReportModel model) {
    final tableData = model.data?.tableData ?? [];
    final chartData = model.data?.chartData;
    final employees = model.departmentEmployees ?? [];

    final List<String> defaultTypes = [
      "PERMANENT",
      "CONTRACTUAL",
      "DAILY WAGES",
      "TEMPORARY",
    ];
    final Set<String> allKeys = {};

    for (var d in defaultTypes) {
      allKeys.add(d.replaceAll(' ', '').replaceAll('_', '').toUpperCase());
    }

    for (var t in tableData) {
      if (t.jobType != null && t.jobType!.trim().isNotEmpty) {
        allKeys.add(
          t.jobType!
              .trim()
              .replaceAll(' ', '')
              .replaceAll('_', '')
              .toUpperCase(),
        );
      }
    }

    if (chartData?.labels != null) {
      for (var l in chartData!.labels!) {
        if (l.trim().isNotEmpty) {
          allKeys.add(
            l.trim().replaceAll(' ', '').replaceAll('_', '').toUpperCase(),
          );
        }
      }
    }

    for (var e in employees) {
      if (e.jobType != null && e.jobType!.trim().isNotEmpty) {
        allKeys.add(
          e.jobType!
              .trim()
              .replaceAll(' ', '')
              .replaceAll('_', '')
              .toUpperCase(),
        );
      }
    }

    List<JobTypeData> result = [];

    for (var key in allKeys) {
      num salary = 0;

      for (var t in tableData) {
        final tKey = t.jobType
            ?.trim()
            .replaceAll(' ', '')
            .replaceAll('_', '')
            .toUpperCase();
        if (tKey == key && t.totalSalary != null) {
          salary = t.totalSalary!;
          break;
        }
      }

      if (salary == 0 &&
          chartData?.labels != null &&
          chartData?.datasets != null &&
          chartData!.datasets!.isNotEmpty) {
        final labels = chartData.labels!;
        final datasetValues = chartData.datasets![0].data ?? [];
        for (int i = 0; i < labels.length && i < datasetValues.length; i++) {
          final cKey = labels[i]
              .trim()
              .replaceAll(' ', '')
              .replaceAll('_', '')
              .toUpperCase();
          if (cKey == key && datasetValues[i] > 0) {
            salary = datasetValues[i];
            break;
          }
        }
      }

      int count = 0;
      String rawDisplay = key;
      for (var e in employees) {
        final eKey = e.jobType
            ?.trim()
            .replaceAll(' ', '')
            .replaceAll('_', '')
            .toUpperCase();
        if (eKey == key) {
          count++;
          if (e.jobType != null && e.jobType!.trim().isNotEmpty) {
            rawDisplay = e.jobType!;
          }
        }
      }

      final displayName = _formatJobTypeName(rawDisplay);
      final color = _getJobTypeColor(displayName);
      final icon = _getJobTypeIcon(displayName);

      result.add(
        JobTypeData(
          rawKey: key,
          displayName: displayName,
          salary: salary,
          count: count,
          color: color,
          icon: icon,
        ),
      );
    }

    result.sort((a, b) {
      int getOrder(JobTypeData item) {
        final u = item.displayName.toUpperCase();
        if (u.contains("PERMANENT")) return 1;
        if (u.contains("CONTRACTUAL") || u.contains("CONTRACT")) return 2;
        if (u.contains("DAILY")) return 3;
        if (u.contains("TEMP")) return 4;
        return 5;
      }

      return getOrder(a).compareTo(getOrder(b));
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: "Employment Nature Report",
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
          final model = controller.salaryTypeReportModel;
          final isLoading = controller.isSalaryReportLoading;

          return RefreshIndicator(
            color: AppColor.appColor1,
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
                    _buildShimmerLoading()
                  else if (model == null ||
                      model.departmentEmployees == null ||
                      model.departmentEmployees!.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildMetricsRow(model),
                    _buildGraphSection(controller, model),
                    _buildJobTypeFilterChips(controller, model),
                    _buildEmployeeList(controller, model),
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

  // Header Banner
  Widget _buildHeaderBanner(HRController controller) {
    final formattedMonth = DateFormat(
      'MMMM yyyy',
    ).format(controller.selectedDate);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.appColor1, AppColor.appDarkColor],
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        BoxIcons.bx_buildings,
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.deptName,
                        style: TextStyle(
                          color: AppColor.white,
                          fontSize: 3.sp,
                          fontWeight: FontWeight.w600,
                        ),
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
                selectedMonth: controller.selectedDate,
                onMonthSelected: (date) {
                  controller.setSelectedDate(date);
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
                  width: 1,
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
                        "Report Month: $formattedMonth",
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

  // Summary Metrics Row (Employee Count & Nature Focus)
  Widget _buildMetricsRow(SalaryTypeReportModel model) {
    final totalEmployees =
        model.totalDepartmentEmployees ??
        (model.departmentEmployees?.length ?? 0);

    final jobTypeItems = _extractJobTypeData(model);
    final jobTypeCount = jobTypeItems.length;
    final activeCount = jobTypeItems.fold<int>(0, (sum, e) => sum + e.count);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: _metricCard(
              title: "Total Staff",
              value: totalEmployees,
              suffix: "",
              icon: BoxIcons.bxs_group,
              color: const Color(0xFF007AFF),
            ),
          ),
          2.5.width,
          Expanded(
            child: _metricCard(
              title: "Employment Types",
              value: jobTypeCount,
              suffix: " Types",
              icon: BoxIcons.bxs_badge_check,
              color: const Color(0xFF00A86B),
            ),
          ),
          2.5.width,
          Expanded(
            child: _metricCard(
              title: "Active Nature",
              value: activeCount,
              suffix: "",
              icon: BoxIcons.bxs_pie_chart_alt,
              color: const Color(0xFF7367F0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required int value,
    required String suffix,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 4.5.w),
          ),
          1.2.height,
          AnimatedBuilder(
            animation: _safeChartAnim,
            builder: (context, child) {
              final displayValue = (value * _safeChartAnim.value).round();
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "$displayValue$suffix",
                  style: TextStyle(
                    fontSize: 3.8.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
              );
            },
          ),
          0.3.height,
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 2.5.sp,
              color: AppColor.grey,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNatureDistributionPanel(
    SalaryTypeReportModel model, {
    required double height,
  }) {
    final jobTypeList = _extractJobTypeData(model);
    if (jobTypeList.isEmpty) return SizedBox(height: height);

    final totalCount = jobTypeList.fold<int>(0, (sum, e) => sum + e.count);
    if (totalCount <= 0) return SizedBox(height: height);

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.8.h),
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
              Container(
                padding: EdgeInsets.all(1.8.w),
                decoration: BoxDecoration(
                  color: AppColor.appColor1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  BoxIcons.bxs_pie_chart_alt_2,
                  color: AppColor.appColor1,
                  size: 4.5.w,
                ),
              ),
              2.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nature Distribution",
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "Live share by employment nature",
                      style: TextStyle(
                        fontSize: 2.2.sp,
                        color: AppColor.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          1.5.height,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 2.h,
                children: jobTypeList.map((item) {
                  final pct = totalCount > 0 ? item.count / totalCount : 0.0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.2.h),
                    child: AnimatedBuilder(
                      animation: _safeChartAnim,
                      builder: (context, child) {
                        final animatedPct = pct * _safeChartAnim.value;
                        final animatedCount =
                            (item.count * _safeChartAnim.value).round();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(item.icon, size: 3.8.w, color: item.color),
                                2.width,
                                Expanded(
                                  child: Text(
                                    item.displayName,
                                    style: TextStyle(
                                      fontSize: 2.8.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.appDarkColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  "$animatedCount",
                                  style: TextStyle(
                                    fontSize: 2.8.sp,
                                    fontWeight: FontWeight.bold,
                                    color: item.color,
                                  ),
                                ),
                                2.width,
                                Text(
                                  "${(animatedPct * 100).toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 2.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.grey,
                                  ),
                                ),
                              ],
                            ),
                            0.6.height,
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 0.7.h,
                                    color: AppColor.scaffold,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: animatedPct.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 0.7.h,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            item.color.withValues(alpha: 0.65),
                                            item.color,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveBarChartCard(
    HRController controller,
    SalaryTypeReportModel model, {
    required double height,
  }) {
    final jobTypeList = _extractJobTypeData(model);
    if (jobTypeList.isEmpty) return SizedBox(height: height);

    num grandTotalCount = jobTypeList.fold(0, (sum, v) => sum + v.count);

    num maxYValue = jobTypeList.fold(
      0,
      (max, v) => v.count > max ? v.count : max,
    );
    if (maxYValue <= 0) maxYValue = 10;

    // Round, human-readable axis steps (1, 2, 5, 10, 20...) instead of
    // whatever fraction fl_chart's auto-interval would otherwise pick.
    final double yInterval = _niceYAxisInterval(maxYValue);
    final double chartMaxY =
        (maxYValue / yInterval).ceil() * yInterval + yInterval;

    final isAllSelected = controller.selectedJobType == "ALL";

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(4.w, 2.5.w, 4.w, 1.8.w),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.8.w),
                  decoration: BoxDecoration(
                    color: AppColor.appColor1.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    BoxIcons.bx_bar_chart_alt_2,
                    color: AppColor.appColor1,
                    size: 4.5.w,
                  ),
                ),
                2.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Employment Nature Chart",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 3.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                      0.2.height,
                      Text(
                        "Tap a bar to filter staff",
                        style: TextStyle(
                          fontSize: 2.2.sp,
                          color: AppColor.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(2.5.w, 0.8.h, 3.w, 1.2.w),
              // Bars stay tap-only for tab switching (see PageView physics
              // above); if there are more bars than fit, this scrolls them
              // horizontally instead.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = 22.w;
                  final contentWidth = jobTypeList.length * itemWidth;
                  final chartWidth = contentWidth > constraints.maxWidth
                      ? contentWidth
                      : constraints.maxWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth,
                      child: AnimatedBuilder(
                        animation: _safeChartAnim,
                        builder: (context, child) {
                          final animValue = _safeChartAnim.value.clamp(
                            0.0,
                            1.0,
                          );
                          final animatedBarGroups = <BarChartGroupData>[];

                          for (int i = 0; i < jobTypeList.length; i++) {
                            final item = jobTypeList[i];
                            final isSelectedFilter =
                                controller.selectedJobType.toUpperCase() ==
                                item.displayName.toUpperCase();

                            double targetHeight = 0.0;
                            if (isAllSelected || isSelectedFilter) {
                              targetHeight = item.count.toDouble();
                            }

                            final barHeight = (targetHeight * animValue).clamp(
                              0,
                              double.infinity,
                            );
                            final double rodWidth = isSelectedFilter
                                ? 24.0
                                : 20.0;
                            final rodGradient = LinearGradient(
                              colors: [
                                item.color.withValues(
                                  alpha: isSelectedFilter || isAllSelected
                                      ? 0.7
                                      : 0.25,
                                ),
                                isSelectedFilter || isAllSelected
                                    ? item.color
                                    : item.color.withValues(alpha: 0.35),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            );

                            animatedBarGroups.add(
                              BarChartGroupData(
                                x: i,
                                barsSpace: 5,
                                barRods: [
                                  BarChartRodData(
                                    toY: barHeight.toDouble(),
                                    gradient: rodGradient,
                                    width: rodWidth,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: chartMaxY,
                                      color: isSelectedFilter
                                          ? item.color.withValues(alpha: 0.08)
                                          : AppColor.scaffold.withValues(
                                              alpha: 0.6,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ClipRect(
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: chartMaxY,
                                minY: 0,
                                groupsSpace: 3,
                                barGroups: animatedBarGroups,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: yInterval,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: AppColor.appLightColor.withValues(
                                      alpha: 0.6,
                                    ),
                                    strokeWidth: 0.8,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  show: true,

                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        int idx = value.toInt();
                                        if (idx >= 0 &&
                                            idx < jobTypeList.length) {
                                          final item = jobTypeList[idx];
                                          final isSelected =
                                              controller.selectedJobType
                                                  .toUpperCase() ==
                                              item.displayName.toUpperCase();
                                          final countLabel =
                                              (item.count * animValue).round();

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    _shortJobTypeLabel(
                                                      item.displayName,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: isSelected
                                                          ? 2.4.sp
                                                          : 2.2.sp,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w900
                                                          : FontWeight.bold,
                                                      color: isSelected
                                                          ? item.color
                                                          : AppColor
                                                                .appDarkColor,
                                                    ),
                                                  ),
                                                ),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    '$countLabel',
                                                    style: TextStyle(
                                                      fontSize: 1.7.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: item.color,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),

                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: yInterval,
                                      reservedSize: 26,
                                      getTitlesWidget: (value, meta) {
                                        if (value <= 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                fontSize: 1.9.sp,
                                                color: AppColor.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 14,
                                      getTitlesWidget: (value, meta) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchCallback:
                                      (FlTouchEvent event, barTouchResponse) {
                                        if (event is FlTapUpEvent &&
                                            barTouchResponse != null &&
                                            barTouchResponse.spot != null) {
                                          final groupIndex = barTouchResponse
                                              .spot!
                                              .touchedBarGroupIndex;
                                          if (groupIndex >= 0 &&
                                              groupIndex < jobTypeList.length) {
                                            final selectedType =
                                                jobTypeList[groupIndex]
                                                    .displayName;
                                            if (controller.selectedJobType
                                                    .toUpperCase() ==
                                                selectedType.toUpperCase()) {
                                              controller.setSelectedJobType(
                                                "ALL",
                                              );
                                            } else {
                                              controller.setSelectedJobType(
                                                selectedType,
                                              );
                                            }
                                            _replayChartAnimation();
                                          }
                                        }
                                      },
                                  touchTooltipData: BarTouchTooltipData(
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    getTooltipColor: (_) => AppColor
                                        .appDarkColor
                                        .withValues(alpha: 0.95),
                                    tooltipBorder: BorderSide(
                                      color: AppColor.appLightColor,
                                    ),
                                    tooltipPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    tooltipMargin: 6,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final item = jobTypeList[groupIndex];
                                      final pct = grandTotalCount > 0
                                          ? (item.count / grandTotalCount) * 100
                                          : 0;

                                      return BarTooltipItem(
                                        "${item.displayName}\n",
                                        TextStyle(
                                          color: item.color,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 2.6.sp,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                "${item.count} Staff Members\n",
                                            style: TextStyle(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 2.2.sp,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                "${pct.toStringAsFixed(1)}% of Total Staff",
                                            style: TextStyle(
                                              color: AppColor.appLightColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 1.9.sp,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              duration: Duration.zero,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypeFilterChips(
    HRController controller,
    SalaryTypeReportModel model,
  ) {
    final employees = model.departmentEmployees ?? [];
    final jobTypeList = _extractJobTypeData(model);
    final jobTypes = ["ALL", ...jobTypeList.map((e) => e.displayName)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            children: jobTypes.map((type) {
              final isSelected =
                  controller.selectedJobType.toUpperCase() ==
                  type.toUpperCase();

              int count = 0;
              if (type == "ALL") {
                count = employees.length;
              } else {
                count = employees.where((e) {
                  final fmt = _formatJobTypeName(e.jobType ?? '');
                  return fmt.toUpperCase() == type.toUpperCase();
                }).length;
              }

              final color = _getJobTypeColor(type);

              return Padding(
                padding: EdgeInsets.only(right: 2.5.w),
                child: FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: isSelected
                      ? CircleAvatar(
                          backgroundColor: AppColor.white,
                          child: Icon(
                            Icons.check_rounded,
                            size: 3.w,
                            color: AppColor.appColor1,
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: type == "ALL"
                              ? AppColor.grey
                              : color,
                          child: Icon(
                            _getJobTypeIcon(type),
                            size: 3.w,
                            color: AppColor.white,
                          ),
                        ),
                  label: Text(
                    "$type ($count)",
                    style: TextStyle(
                      fontSize: 3.2.sp,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColor.white
                          : AppColor.appDarkColor,
                    ),
                  ),
                  selectedColor: AppColor.appColor1,
                  backgroundColor: AppColor.white,
                  side: BorderSide(
                    color: isSelected
                        ? AppColor.appColor1
                        : AppColor.appLightColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: isSelected ? 2 : 0,
                  shadowColor: AppColor.appColor1.withValues(alpha: 0.3),
                  onSelected: (selected) {
                    controller.setSelectedJobType(type);
                    _replayChartAnimation();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        2.height,
      ],
    );
  }

  Widget _buildEmployeeList(
    HRController controller,
    SalaryTypeReportModel model,
  ) {
    final allEmployees = model.departmentEmployees ?? [];

    final filteredEmployees = controller.selectedJobType == "ALL"
        ? allEmployees
        : allEmployees.where((e) {
            final fmt = _formatJobTypeName(e.jobType ?? '');
            return fmt.toUpperCase() ==
                controller.selectedJobType.toUpperCase();
          }).toList();

    if (filteredEmployees.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                BoxIcons.bx_user_x,
                size: 10.w,
                color: AppColor.grey.withValues(alpha: 0.5),
              ),
              1.height,
              Text(
                "No employees found for '${controller.selectedJobType}'",
                style: TextStyle(
                  color: AppColor.grey,
                  fontSize: 3.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      color: AppColor.appColor1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      BoxIcons.bxs_group,
                      color: AppColor.appColor1,
                      size: 4.w,
                    ),
                  ),
                  2.width,
                  Text(
                    "Employee Records",
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
                  "${filteredEmployees.length} Shown",
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
            itemCount: filteredEmployees.length,
            separatorBuilder: (context, index) => 1.5.height,
            itemBuilder: (context, index) {
              final emp = filteredEmployees[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  curve: Curves.easeOutCubic,
                  child: FadeInAnimation(child: _employeeCard(emp)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _employeeCard(DepartmentEmployee emp) {
    final fmtJobType = _formatJobTypeName(emp.jobType ?? '');
    final color = _getJobTypeColor(fmtJobType);
    final jobIcon = _getJobTypeIcon(fmtJobType);
    final isActive = emp.status?.toUpperCase() == "A";

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.6),
        ),
        boxShadow: AppShadow.soft,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Job-nature accent strip for quick visual scanning.
            Container(width: 1.1.w, color: color),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 14.w,
                              height: 14.w,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.35),
                                    color.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child:
                                    emp.profilePic != null &&
                                        emp.profilePic!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: emp.profilePic!,
                                        fit: BoxFit.cover,
                                        placeholder: (c, u) =>
                                            Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                color: Colors.white,
                                              ),
                                            ),
                                        errorWidget: (c, u, e) =>
                                            _avatarFallback(emp),
                                      )
                                    : _avatarFallback(emp),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 3.5.w,
                                height: 3.5.w,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColor.green
                                      : AppColor.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColor.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        3.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.name ?? "Unknown Employee",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 4.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.appDarkColor,
                                ),
                              ),
                              0.4.height,
                              Row(
                                children: [
                                  Icon(
                                    BoxIcons.bx_briefcase,
                                    size: 3.3.w,
                                    color: AppColor.grey,
                                  ),
                                  1.width,
                                  Expanded(
                                    child: Text(
                                      emp.designation ?? "Employee",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 2.9.sp,
                                        color: AppColor.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        2.width,
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.6.w,
                            vertical: 0.6.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(jobIcon, size: 3.3.w, color: color),
                              1.2.width,
                              Text(
                                fmtJobType,
                                style: TextStyle(
                                  fontSize: 2.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    1.5.height,
                    Divider(height: 1, color: AppColor.scaffold),
                    1.2.height,
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: [
                        _infoPill(
                          icon: BoxIcons.bx_calendar_check,
                          label:
                              emp.joinDate != null &&
                                  emp.joinDate!.trim().isNotEmpty
                              ? "Joined ${emp.joinDate}"
                              : "Joining: N/A",
                        ),
                        if (emp.mobile != null && emp.mobile!.isNotEmpty)
                          _infoPill(
                            icon: BoxIcons.bx_phone,
                            label: emp.mobile!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          Icon(icon, size: 3.3.w, color: AppColor.appColor1),
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

  Widget _avatarFallback(DepartmentEmployee emp) {
    final initials = emp.name != null && emp.name!.trim().isNotEmpty
        ? emp.name!.trim().split(" ").take(2).map((e) => e[0]).join()
        : "?";

    return Container(
      color: AppColor.appColor1.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: AppColor.appColor1,
          fontWeight: FontWeight.bold,
          fontSize: 4.sp,
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
        child: Column(
          children: [
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 10.h,
                    margin: EdgeInsets.only(right: index < 2 ? 2.w : 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            2.height,
            Container(
              height: 22.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            2.height,
            Column(
              children: List.generate(
                3,
                (index) => Container(
                  height: 12.h,
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hrController = context.read<HRController>();
    return Container(
      margin: EdgeInsets.all(5.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: AppColor.appColor1.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                BoxIcons.bx_folder_open,
                size: 12.w,
                color: AppColor.appColor1,
              ),
            ),
            2.height,
            Text(
              "No Report Data Available",
              style: TextStyle(
                fontSize: 4.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
              ),
            ),
            1.height,
            Text(
              "No employment nature report found for ${widget.siteName} in ${DateFormat('MMMM yyyy').format(hrController.selectedDate)}.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 3.2.sp, color: AppColor.grey),
            ),
            3.height,
            ElevatedButton.icon(
              onPressed: _fetchReportData,
              icon: Icon(BoxIcons.bx_refresh, color: AppColor.white),
              label: Text(
                "Reload Report",
                style: TextStyle(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.appColor1,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphSection(
    HRController controller,
    SalaryTypeReportModel model,
  ) {
    final jobTypeList = _extractJobTypeData(model);
    if (jobTypeList.isEmpty) return const SizedBox.shrink();

    final cardHeight = _graphViewportHeight(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            children: [
              _graphTabChip(0, "Overview", BoxIcons.bxs_pie_chart_alt_2),
              2.width,
              _graphTabChip(1, "Chart", BoxIcons.bx_bar_chart_alt_2),
            ],
          ),
        ),
        1.height,
        SizedBox(
          height: cardHeight,
          child: PageView(
            controller: _graphPageController,
            clipBehavior: Clip.hardEdge,
            allowImplicitScrolling: false,
            // Tab tap only — swipes are reserved for horizontally scrolling
            // a chart's own content (e.g. many bars), not switching tabs.
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _graphPageIndex = index);
              _replayChartAnimation();
            },
            children: [
              _buildNatureDistributionPanel(model, height: cardHeight),
              _buildExecutiveBarChartCard(
                controller,
                model,
                height: cardHeight,
              ),
            ],
          ),
        ),
        1.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = _graphPageIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              width: isActive ? 5.w : 2.w,
              height: 0.7.h,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColor.appColor1
                    : AppColor.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        1.2.height,
      ],
    );
  }

  double _graphViewportHeight(BuildContext context) {
    return (23.h).clamp(220.0, 260.0);
  }

  Widget _graphTabChip(int index, String label, IconData icon) {
    final selected = _graphPageIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _graphPageIndex = index);
          _graphPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.appColor1.withValues(alpha: 0.12)
                : AppColor.scaffold,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColor.appColor1.withValues(alpha: 0.4)
                  : AppColor.appLightColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 4.w,
                color: selected ? AppColor.appColor1 : AppColor.grey,
              ),
              1.5.width,
              Text(
                label,
                style: TextStyle(
                  fontSize: 2.8.sp,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColor.appColor1 : AppColor.appDarkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
