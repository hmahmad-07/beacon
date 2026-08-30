import 'dart:math' as math;

import 'package:beacon/core/controllers/hr_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/HR/attendance_report_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class EmployeeAttendanceDetailView extends StatefulWidget {
  const EmployeeAttendanceDetailView({
    super.key,
    required this.siteName,
    required this.siteID,
    required this.deptName,
    required this.deptID,
    required this.employee,
    required this.initialMonth,
    this.siteImage,
  });

  final String siteName;
  final String siteID;
  final String deptName;
  final int deptID;
  final AttendanceEmployee employee;
  final DateTime initialMonth;
  final String? siteImage;

  @override
  State<EmployeeAttendanceDetailView> createState() =>
      _EmployeeAttendanceDetailViewState();
}

class _EmployeeAttendanceDetailViewState
    extends State<EmployeeAttendanceDetailView>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF007AFF);

  late DateTime _selectedMonth;
  AnimationController? _chartAnimController;
  Animation<double>? _chartAnim;
  String? _animationKey;
  int _chartTab = 0;

  Animation<double> get _safeChartAnim =>
      _chartAnim ?? const AlwaysStoppedAnimation<double>(1);

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
    );
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController!,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _chartAnimController?.dispose();
    super.dispose();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  String get _employeeIdParam {
    final code = widget.employee.employeeCode;
    if (code != null && code.trim().isNotEmpty) return code;
    return '${widget.employee.id ?? ''}';
  }

  void _fetchData() {
    _animationKey = null;
    context.read<HRController>().getAttendanceReport(
      context,
      month: DateFormat('MM').format(_selectedMonth),
      year: DateFormat('yyyy').format(_selectedMonth),
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
      employeeId: _employeeIdParam,
      forEmployeeDetail: true,
    );
  }

  void _triggerChartAnimation(String key) {
    if (_animationKey == key) return;
    _animationKey = key;
    _chartAnimController?.reset();
    _chartAnimController?.forward();
  }

  // Unconditionally replays the 0 -> max grow-in animation, bypassing the
  // data-key guard above. Used when the visible chart changes (tab switch)
  // even though the underlying report data hasn't changed.
  void _replayChartAnimation() {
    _chartAnimController?.reset();
    _chartAnimController?.forward();
  }

  double _chartViewportHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    return (size.height * 0.24).clamp(
      shortest < 600 ? 190.0 : 220.0,
      shortest < 600 ? 250.0 : 280.0,
    );
  }

  AttendanceEmployee? _resolvedEmployee(AttendanceReportModel? model) {
    return model?.employee ?? widget.employee;
  }

  // Derives the status breakdown from the same daily-attendance rows the
  // table below renders, instead of trusting the API's separate aggregate
  // fields (data.tableData / employee.attendance) which can drift out of
  // sync with the actual per-day records.
  List<AttendanceStatusCount> _statusCounts(AttendanceReportModel? model) {
    final dailyList = model?.employee?.dailyAttendance ?? [];
    if (dailyList.isNotEmpty) return _deriveStatusCounts(dailyList);

    final fromTable = model?.data?.tableData ?? [];
    if (fromTable.isNotEmpty) return fromTable;
    return model?.employee?.attendance ?? [];
  }

  List<AttendanceStatusCount> _deriveStatusCounts(List<DailyAttendance> days) {
    final tally = <String, int>{};
    for (final day in days) {
      final isHoliday = _isHoliday(day);
      final raw = isHoliday ? 'H' : (_rawStatusCode(day) ?? 'UNKNOWN');
      final code = raw.trim().isEmpty ? 'UNKNOWN' : raw.trim().toUpperCase();
      tally[code] = (tally[code] ?? 0) + 1;
    }
    return tally.entries
        .map((e) => AttendanceStatusCount(status: e.key, totalDays: e.value))
        .toList();
  }

  bool _isHoliday(DailyAttendance day) {
    return _isSundayDate(day.dateIso) ||
        _isSundayDate(day.date) ||
        (day.day?.trim().toLowerCase() == 'sunday');
  }

  String? _rawStatusCode(DailyAttendance day) {
    if (day.statusCode != null && day.statusCode!.trim().isNotEmpty) {
      return day.statusCode;
    }
    return day.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: widget.employee.name ?? "Attendance",
        actions: [
          IconButton(
            icon: Icon(BoxIcons.bx_refresh, color: AppColor.white),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Consumer<HRController>(
        builder: (context, controller, child) {
          final model = controller.employeeAttendanceModel;
          final isLoading = controller.isEmployeeAttendanceLoading;
          final employee = _resolvedEmployee(model);
          final counts = _statusCounts(model);

          if (!isLoading &&
              model != null &&
              (counts.isNotEmpty ||
                  (employee?.dailyAttendance ?? []).isNotEmpty)) {
            final key =
                '${_selectedMonth.millisecondsSinceEpoch}_${employee?.employeeCode}';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _triggerChartAnimation(key);
            });
          }

          return RefreshIndicator(
            color: _accent,
            onRefresh: () async => _fetchData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(employee),
                  if (isLoading)
                    _buildShimmer()
                  else if (model == null ||
                      (counts.isEmpty &&
                          (employee?.dailyAttendance ?? []).isEmpty))
                    _buildEmpty()
                  else ...[
                    _buildStatusMetrics(
                      counts,
                      (employee?.dailyAttendance ?? []).isNotEmpty
                          ? employee!.dailyAttendance!.length
                          : employee?.totalDays,
                    ),
                    _buildCharts(counts, model),
                    _buildDailyList(employee?.dailyAttendance ?? []),
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

  Widget _buildProfileHeader(AttendanceEmployee? employee) {
    final emp = employee ?? widget.employee;
    final formattedMonth = DateFormat('MMMM yyyy').format(_selectedMonth);

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
        children: [
          Row(
            children: [
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: emp.profilePic != null && emp.profilePic!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: emp.profilePic!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _initials(emp),
                        )
                      : _initials(emp),
                ),
              ),
              3.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name ?? "Employee",
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 4.2.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      emp.designation ?? widget.deptName,
                      style: TextStyle(
                        color: AppColor.white.withValues(alpha: 0.85),
                        fontSize: 3.sp,
                      ),
                    ),
                    if (emp.employeeCode != null)
                      Text(
                        "Code: ${emp.employeeCode}  •  ${emp.jobType ?? ''}",
                        style: TextStyle(
                          color: AppColor.white.withValues(alpha: 0.75),
                          fontSize: 2.5.sp,
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
                selectedMonth: _selectedMonth,
                onMonthSelected: (date) {
                  setState(() => _selectedMonth = date);
                  _fetchData();
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
                        _isCurrentMonth ? formattedMonth : formattedMonth,
                        style: TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 3.4.sp,
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

  Widget _initials(AttendanceEmployee emp) {
    final initials = emp.name != null && emp.name!.trim().isNotEmpty
        ? emp.name!.trim().split(' ').take(2).map((e) => e[0]).join()
        : '?';
    return Container(
      color: AppColor.white.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: AppColor.white,
          fontWeight: FontWeight.bold,
          fontSize: 4.sp,
        ),
      ),
    );
  }

  Widget _buildStatusMetrics(
    List<AttendanceStatusCount> counts,
    int? totalDays,
  ) {
    final items = counts.isNotEmpty
        ? counts
        : [AttendanceStatusCount(status: 'P', totalDays: 0)];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalDays != null)
            Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Text(
                "Recorded days: $totalDays",
                style: TextStyle(
                  fontSize: 2.8.sp,
                  color: AppColor.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: items.map((item) {
              final color = AttendanceStatusStyle.colorOf(item.status);
              return Container(
                width: 20.w,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AttendanceStatusStyle.labelOf(item.status),
                      style: TextStyle(
                        fontSize: 2.3.sp,
                        color: AppColor.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item.totalDays ?? 0}',
                      style: TextStyle(
                        fontSize: 4.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(
    List<AttendanceStatusCount> counts,
    AttendanceReportModel model,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
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
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  BoxIcons.bxs_bar_chart_square,
                  color: _accent,
                  size: 4.w,
                ),
              ),
              2.width,
              Text(
                "Attendance Graphs",
                style: TextStyle(
                  fontSize: 3.6.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.appDarkColor,
                ),
              ),
            ],
          ),
          1.height,
          Row(
            children: [
              _chartTabChip(0, "Status", BoxIcons.bxs_pie_chart_alt_2),
              2.width,
              _chartTabChip(1, "Daily", BoxIcons.bx_bar_chart_alt_2),
            ],
          ),
          1.5.height,
          SizedBox(
            height: _chartViewportHeight(context),
            child: _chartTab == 0
                ? _statusPie(counts)
                : _dailyBarChart(model.dailyChartData),
          ),
        ],
      ),
    );
  }

  Widget _chartTabChip(int index, String label, IconData icon) {
    final selected = _chartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _chartTab = index);
          _replayChartAnimation();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.12)
                : AppColor.scaffold,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _accent.withValues(alpha: 0.4)
                  : AppColor.appLightColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 4.w, color: selected ? _accent : AppColor.grey),
              1.5.width,
              Text(
                label,
                style: TextStyle(
                  fontSize: 2.8.sp,
                  fontWeight: FontWeight.bold,
                  color: selected ? _accent : AppColor.appDarkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPie(List<AttendanceStatusCount> counts) {
    final items = counts.where((e) => (e.totalDays ?? 0) > 0).toList();
    if (items.isEmpty) {
      return Center(
        child: Text(
          "No status chart data",
          style: TextStyle(color: AppColor.grey, fontSize: 3.sp),
        ),
      );
    }
    final total = items.fold<int>(0, (s, e) => s + (e.totalDays ?? 0));

    return AnimatedBuilder(
      animation: _safeChartAnim,
      builder: (context, child) {
        final anim = _safeChartAnim.value.clamp(0.0, 1.0);
        return Row(
          children: [
            Expanded(
              flex: 3,
              // Spins the pie into place (two full turns, eased by
              // _safeChartAnim) instead of just filling in flat.
              child: Transform.rotate(
                angle: (1 - anim) * 4 * math.pi,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 34,
                    startDegreeOffset: -90,
                    sections: items.map((item) {
                      final days = item.totalDays ?? 0;
                      return PieChartSectionData(
                        color: AttendanceStatusStyle.colorOf(item.status),
                        value: (days * anim).clamp(0, double.infinity),
                        title: anim > 0.65 ? '$days' : '',
                        radius: 44,
                        titleStyle: TextStyle(
                          fontSize: 2.5.sp,
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
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: items.map((item) {
                  final days = item.totalDays ?? 0;
                  final pct = total > 0 ? (days / total) * 100 : 0.0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      children: [
                        Container(
                          width: 2.4.w,
                          height: 2.4.w,
                          decoration: BoxDecoration(
                            color: AttendanceStatusStyle.colorOf(item.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        1.5.width,
                        Expanded(
                          child: Text(
                            AttendanceStatusStyle.labelOf(item.status),
                            style: TextStyle(
                              fontSize: 2.3.sp,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _dailyBarChart(AttendanceChartData? chart) {
    final labels = chart?.labels ?? [];
    final datasets = chart?.datasets ?? [];
    if (labels.isEmpty || datasets.isEmpty) {
      return Center(
        child: Text(
          "No daily chart data",
          style: TextStyle(color: AppColor.grey, fontSize: 3.sp),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _safeChartAnim,
      builder: (context, child) {
        final anim = _safeChartAnim.value.clamp(0.0, 1.0);
        final groups = <BarChartGroupData>[];
        for (int i = 0; i < labels.length; i++) {
          final rods = <BarChartRodData>[];
          for (final ds in datasets) {
            final values = ds.data ?? [];
            final v = i < values.length ? values[i].toDouble() : 0;
            if (v <= 0) continue;
            rods.add(
              BarChartRodData(
                toY: v * anim,
                width: 6,
                color: AttendanceStatusStyle.colorOf(ds.label),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            );
          }
          if (rods.isEmpty) {
            rods.add(
              BarChartRodData(
                toY: 0.05,
                width: 6,
                color: AppColor.grey.withValues(alpha: 0.2),
              ),
            );
          }
          groups.add(BarChartGroupData(x: i, barRods: rods, barsSpace: 0));
        }

        return BarChart(
          BarChartData(
            maxY: 1.3,
            minY: 0,
            groupsSpace: 2,
            alignment: BarChartAlignment.spaceBetween,
            barGroups: groups,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 4,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    final raw = labels[idx];
                    final day = raw.split('-').first;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 1.8.sp,
                          color: AppColor.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    AppColor.appDarkColor.withValues(alpha: 0.95),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final date = group.x >= 0 && group.x < labels.length
                      ? labels[group.x]
                      : '';
                  return BarTooltipItem(
                    date,
                    TextStyle(
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 2.4.sp,
                    ),
                  );
                },
              ),
            ),
          ),
          duration: Duration.zero,
        );
      },
    );
  }

  Widget _buildDailyList(List<DailyAttendance> days) {
    if (days.isEmpty) return const SizedBox.shrink();

    final tableRows = <TableRow>[];

    tableRows.add(
      TableRow(
        decoration: BoxDecoration(
          color: AppColor.appDarkColor.withValues(alpha: 0.04),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Day',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 2.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Date',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 2.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 2.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Out',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 2.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Hours',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 2.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Status',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 2.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    for (final day in days) {
      final isSunday = _isHoliday(day);
      final code = isSunday ? 'H' : _rawStatusCode(day);
      final label = isSunday
          ? 'Holiday'
          : (day.status?.isNotEmpty == true
                ? day.status!
                : AttendanceStatusStyle.labelOf(code));
      final timeIn = isSunday ? '--:--' : (day.timeIn ?? '--:--');
      final timeOut = isSunday ? '--:--' : (day.timeOut ?? '--:--');
      final totalHours = isSunday
          ? 'Holiday'
          : _totalHoursText(timeIn, timeOut);
      final color = AttendanceStatusStyle.colorOf(code);

      tableRows.add(
        TableRow(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.2.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  day.day ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.black),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.2.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  day.date ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.black),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.2.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeIn,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.black),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.2.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeOut,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.black),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.2.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  totalHours,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.black),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.7.h,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 2.2.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.8.w),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  BoxIcons.bxs_calendar_check,
                  color: _accent,
                  size: 4.w,
                ),
              ),
              2.width,
              Text(
                "Daily Attendance",
                style: TextStyle(
                  fontSize: 4.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.appDarkColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5.w),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColor.appLightColor.withValues(alpha: 0.7),
            ),
            boxShadow: AppShadow.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.0),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.0),
                3: FlexColumnWidth(1.0),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1.3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: AppColor.appLightColor.withValues(alpha: 0.7),
                  width: 1,
                ),
                verticalInside: BorderSide(
                  color: AppColor.appLightColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                top: BorderSide(
                  color: AppColor.appLightColor.withValues(alpha: 0.7),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: AppColor.appLightColor.withValues(alpha: 0.7),
                  width: 1,
                ),
                left: BorderSide(
                  color: AppColor.appLightColor.withValues(alpha: 0.7),
                  width: 1,
                ),
                right: BorderSide(
                  color: AppColor.appLightColor.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              children: tableRows,
            ),
          ),
        ),
      ],
    );
  }

  bool _isSundayDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return false;

    try {
      final cleaned = rawDate.trim();
      DateTime date;

      if (cleaned.contains('-')) {
        final parts = cleaned.split('-');
        if (parts.length >= 3) {
          final first = parts[0];
          final second = parts[1];
          final third = parts[2];

          if (first.length == 4) {
            date = DateTime.parse(cleaned);
          } else {
            final formatted = '$third-$second-$first';
            date = DateTime.parse(formatted);
          }
        } else {
          date = DateTime.parse(cleaned);
        }
      } else {
        date = DateTime.parse(cleaned);
      }

      return date.weekday == DateTime.sunday;
    } catch (_) {
      return false;
    }
  }

  DateTime? _parseTimeValue(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '--:--') {
      return null;
    }

    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final formats = [
      'HH:mm',
      'H:mm',
      'hh:mm a',
      'h:mm a',
      'HH:mm:ss',
      'h:mm:ss a',
    ];

    for (final format in formats) {
      try {
        final parsed = DateFormat(format).parse(cleaned);
        return DateTime(2000, 1, 1, parsed.hour, parsed.minute, parsed.second);
      } catch (_) {}
    }

    return null;
  }

  String _totalHoursText(String? timeIn, String? timeOut) {
    final parsedIn = _parseTimeValue(timeIn);
    final parsedOut = _parseTimeValue(timeOut);

    if (parsedIn == null || parsedOut == null) return '--';

    var minutes = parsedOut.difference(parsedIn).inMinutes;
    if (minutes < 0) {
      minutes += 24 * 60;
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '${remainingMinutes}m';
    }

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: List.generate(
            6,
            (index) => Container(
              height: 8.h,
              margin: EdgeInsets.only(bottom: 1.2.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
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
          Icon(BoxIcons.bx_calendar_x, size: 12.w, color: _accent),
          2.height,
          Text(
            "No Attendance Found",
            style: TextStyle(
              fontSize: 4.2.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          Text(
            "No records for ${widget.employee.name} in ${DateFormat('MMMM yyyy').format(_selectedMonth)}.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 3.2.sp, color: AppColor.grey),
          ),
        ],
      ),
    );
  }
}
