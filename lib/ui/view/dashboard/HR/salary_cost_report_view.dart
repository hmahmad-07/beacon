import 'dart:math' as math;

import 'package:beacon/core/controllers/hr_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/HR/department_salary_cost_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:beacon/ui/view/dashboard/HR/employee_salary_detail_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SalaryCostReportView extends StatefulWidget {
  const SalaryCostReportView({
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
  State<SalaryCostReportView> createState() => _SalaryCostReportViewState();
}

class _SalaryCostReportViewState extends State<SalaryCostReportView>
    with SingleTickerProviderStateMixin {
  static const Color _salaryColor = Color(0xFF696D75);
  static const Color _paidColor = Color(0xFFB8922A);
  static const Color _pendingColor = Color(0xFFD9B65E);
  static const Color _accentBlue = Color(0xFF1F2A37);

  AnimationController? _chartAnimController;
  Animation<double>? _chartAnim;
  PageController? _chartPageController;
  String? _animationKey;
  int _chartPageIndex = 0;

  Animation<double> get _safeChartAnim =>
      _chartAnim ?? const AlwaysStoppedAnimation<double>(1);

  double _chartViewportHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    return (size.height * 0.3).clamp(
      shortest < 600 ? 230.0 : 260.0,
      shortest < 600 ? 300.0 : 340.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController!,
      curve: Curves.easeOutCubic,
    );
    _chartPageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReportData());
  }

  @override
  void dispose() {
    _chartPageController?.dispose();
    _chartAnimController?.dispose();
    super.dispose();
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

  void _goToChartPage(int index) {
    setState(() => _chartPageIndex = index);
    final controller = _chartPageController;
    if (controller == null || !controller.hasClients) return;
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _fetchReportData() {
    _animationKey = null;
    final hrController = context.read<HRController>();
    hrController.getSalaryCostReport(
      context,
      month: DateFormat('MM').format(hrController.selectedDate),
      year: DateFormat('yyyy').format(hrController.selectedDate),
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
    );
  }

  String _formatCurrency(num value) {
    return 'PKR ${NumberFormat('#,##0', 'en_US').format(value)}';
  }

  String _formatCompactCurrency(num value) {
    if (value >= 1000000) return 'PKR ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'PKR ${(value / 1000).toStringAsFixed(1)}K';
    return _formatCurrency(value);
  }

  List<SalaryCostEmployee> _sortedEmployees(SalaryCostReportModel model) {
    final list = List<SalaryCostEmployee>.from(model.departmentEmployees ?? []);
    list.sort((a, b) => (b.salary ?? 0).compareTo(a.salary ?? 0));
    return list;
  }

  String _shortName(String? name) {
    if (name == null || name.trim().isEmpty) return 'N/A';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.length > 8
          ? '${parts.first.substring(0, 8)}.'
          : parts.first;
    }
    return '${parts.first} ${parts.last.isNotEmpty ? parts.last[0] : ''}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: "Salary Cost Report",
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
          final model = controller.salaryCostReportModel;
          final isLoading = controller.isSalaryCostReportLoading;

          if (!isLoading &&
              model != null &&
              model.departmentEmployees != null &&
              model.departmentEmployees!.isNotEmpty) {
            final animKey =
                '${controller.selectedDate.millisecondsSinceEpoch}_'
                '${model.departmentEmployees!.length}';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _triggerChartAnimation(animKey);
            });
          }

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
                    const AppLoadingView()
                  else if (model == null ||
                      model.departmentEmployees == null ||
                      model.departmentEmployees!.isEmpty)
                    _buildEmptyState(controller)
                  else ...[
                    _buildMetricsRow(model),
                    _buildChartsSection(model),
                    _buildEmployeeList(model, controller.selectedDate),
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
                        BoxIcons.bxs_wallet,
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
                        "Salary Month: $formattedMonth",
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

  Widget _buildMetricsRow(SalaryCostReportModel model) {
    final employees = model.departmentEmployees ?? [];
    final totalSalary =
        model.departmentTotals?.totalSalary ??
        employees.fold<num>(0, (s, e) => s + (e.salary ?? 0));
    final totalPaid = employees.fold<num>(0, (s, e) => s + (e.paidSalary ?? 0));
    final pending = (totalSalary - totalPaid).clamp(0, totalSalary);
    final avgSalary = employees.isNotEmpty ? totalSalary / employees.length : 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: "Total Salary",
                  value: totalSalary,
                  icon: BoxIcons.bxs_wallet,
                  color: _salaryColor,
                  compact: true,
                ),
              ),
              2.width,
              Expanded(
                child: _metricCard(
                  title: "Total Paid",
                  value: totalPaid,
                  icon: BoxIcons.bxs_check_circle,
                  color: _paidColor,
                  compact: true,
                ),
              ),
            ],
          ),
          1.5.height,
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: "Pending Balance",
                  value: pending,
                  icon: BoxIcons.bxs_time,
                  color: _pendingColor,
                  compact: true,
                ),
              ),
              2.width,
              Expanded(
                child: _metricCard(
                  title: "Avg. Salary",
                  value: avgSalary,
                  icon: BoxIcons.bxs_bar_chart_alt_2,
                  color: _accentBlue,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required num value,
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
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
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 4.w),
          ),
          1.height,
          AnimatedBuilder(
            animation: _safeChartAnim,
            builder: (context, child) {
              final animated = value * _safeChartAnim.value;
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  compact
                      ? _formatCompactCurrency(animated)
                      : _formatCurrency(animated),
                  style: TextStyle(
                    fontSize: 3.5.sp,
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

  Widget _buildChartsSection(SalaryCostReportModel model) {
    const tabs = [
      _ChartTabData(
        label: "Overview",
        icon: BoxIcons.bxs_pie_chart_alt_2,
        color: _salaryColor,
      ),
      _ChartTabData(
        label: "Comparison",
        icon: BoxIcons.bx_bar_chart_alt_2,
        color: _accentBlue,
      ),
      _ChartTabData(
        label: "Payment",
        icon: BoxIcons.bxs_doughnut_chart,
        color: _paidColor,
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
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
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.5.w, 4.w, 0),
            child: Row(
              children: [
                Icon(
                  BoxIcons.bxs_bar_chart_square,
                  color: _salaryColor,
                  size: 4.5.w,
                ),
                2.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Salary Analytics",
                        style: TextStyle(
                          fontSize: 3.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                      Text(
                        "Swipe or tap tabs to explore",
                        style: TextStyle(
                          fontSize: 2.2.sp,
                          color: AppColor.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          1.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isSelected = _chartPageIndex == index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: GestureDetector(
                      onTap: () => _goToChartPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(vertical: 0.7.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tab.color.withValues(alpha: 0.12)
                              : AppColor.scaffold,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? tab.color.withValues(alpha: 0.4)
                                : AppColor.appLightColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 4.w,
                              color: isSelected ? tab.color : AppColor.grey,
                            ),
                            0.4.height,
                            Text(
                              tab.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 2.3.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? tab.color
                                    : AppColor.appDarkColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          0.8.height,
          SizedBox(
            height: _chartViewportHeight(context),
            child: PageView(
              controller: _chartPageController,
              clipBehavior: Clip.hardEdge,
              allowImplicitScrolling: false,
              // Tab tap only — swipes are reserved for horizontally
              // scrolling a chart's own content, not switching tabs.
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _chartPageIndex = index);
                _replayChartAnimation();
              },
              children: [
                _chartPageFrame(child: _buildSalaryOverviewContent(model)),
                _chartPageFrame(
                  child: _buildEmployeeSalaryBarChartContent(model),
                ),
                _chartPageFrame(
                  child: _buildPaymentStatusPieChartContent(model),
                ),
              ],
            ),
          ),
          0.7.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(tabs.length, (index) {
              final isActive = _chartPageIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                width: isActive ? 5.w : 2.w,
                height: 0.7.h,
                decoration: BoxDecoration(
                  color: isActive
                      ? tabs[index].color
                      : AppColor.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          1.height,
        ],
      ),
    );
  }

  Widget _chartPageFrame({required Widget child}) {
    return ClipRect(
      child: Padding(
        padding: EdgeInsets.fromLTRB(4.w, 0.3.h, 4.w, 0.4.h),
        child: child,
      ),
    );
  }

  Widget _buildSalaryOverviewContent(SalaryCostReportModel model) {
    final employees = model.departmentEmployees ?? [];
    final totalSalary =
        model.departmentTotals?.totalSalary ??
        employees.fold<num>(0, (s, e) => s + (e.salary ?? 0));
    final totalPaid = employees.fold<num>(0, (s, e) => s + (e.paidSalary ?? 0));
    final pending = (totalSalary - totalPaid).clamp(0, totalSalary);
    final paidPct = totalSalary > 0 ? totalPaid / totalSalary : 0.0;
    final pendingPct = totalSalary > 0 ? pending / totalSalary : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Overview",
          style: TextStyle(
            fontSize: 3.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.appDarkColor,
          ),
        ),
        1.height,
        Expanded(
          child: AnimatedBuilder(
            animation: _safeChartAnim,
            builder: (context, child) {
              final anim = _safeChartAnim.value;
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _overviewRow(
                            label: "Total Salary Budget",
                            amount: totalSalary * anim,
                            percent: 1.0,
                            color: _salaryColor,
                            showBar: true,
                            barValue: anim,
                          ),
                          _overviewRow(
                            label: "Amount Paid",
                            amount: totalPaid * anim,
                            percent: paidPct,
                            color: _paidColor,
                            showBar: true,
                            barValue: paidPct * anim,
                          ),
                          _overviewRow(
                            label: "Pending Balance",
                            amount: pending * anim,
                            percent: pendingPct,
                            color: _pendingColor,
                            showBar: true,
                            barValue: pendingPct * anim,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _overviewRow({
    required String label,
    required num amount,
    required double percent,
    required Color color,
    required bool showBar,
    required double barValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 2.6.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
            ),
            Text(
              "${(percent * 100).toStringAsFixed(1)}%",
              style: TextStyle(fontSize: 2.3.sp, color: AppColor.grey),
            ),
          ],
        ),
        0.4.height,
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 3.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        if (showBar) ...[
          0.8.height,
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: barValue.clamp(0.0, 1.0),
              minHeight: 0.8.h,
              backgroundColor: AppColor.scaffold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmployeeSalaryBarChartContent(SalaryCostReportModel model) {
    final employees = _sortedEmployees(model);
    if (employees.isEmpty) {
      return Center(
        child: Text(
          'No salary data',
          style: TextStyle(color: AppColor.grey, fontSize: 2.8.sp),
        ),
      );
    }

    // Show every employee from the list below — the chart now scrolls
    // horizontally instead of being capped to a handful of bars.
    final chartEmployees = employees;
    num maxY = 0;
    for (final emp in chartEmployees) {
      final salary = emp.salary ?? 0;
      final paid = emp.paidSalary ?? 0;
      if (salary > maxY) maxY = salary;
      if (paid > maxY) maxY = paid;
    }
    if (maxY <= 0) maxY = 100000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Salary vs Paid",
          style: TextStyle(
            fontSize: 3.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.appDarkColor,
          ),
        ),
        0.4.height,
        Wrap(
          spacing: 3.w,
          runSpacing: 0.4.h,
          children: [
            _legendDot(_salaryColor, "Salary"),
            _legendDot(_paidColor, "Paid"),
          ],
        ),
        0.8.height,
        Expanded(
          // Tab tap only — swipes scroll this chart's own bars
          // horizontally instead of switching tabs (see PageView above).
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = 20.w;
              final contentWidth = chartEmployees.length * itemWidth;
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
                      final animValue = _safeChartAnim.value.clamp(0.0, 1.0);
                      final barGroups = <BarChartGroupData>[];

                      for (int i = 0; i < chartEmployees.length; i++) {
                        final emp = chartEmployees[i];
                        barGroups.add(
                          BarChartGroupData(
                            x: i,
                            barsSpace: 3,
                            barRods: [
                              BarChartRodData(
                                toY: ((emp.salary ?? 0).toDouble() * animValue)
                                    .clamp(0, double.infinity),
                                width: 7,
                                color: _salaryColor.withValues(alpha: 0.85),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                              BarChartRodData(
                                toY:
                                    ((emp.paidSalary ?? 0).toDouble() *
                                            animValue)
                                        .clamp(0, double.infinity),
                                width: 7,
                                color: _paidColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return BarChart(
                        BarChartData(
                          maxY: maxY.toDouble() * 1.25,
                          minY: 0,
                          groupsSpace: 10,
                          alignment: BarChartAlignment.spaceAround,
                          barGroups: barGroups,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: AppColor.appLightColor.withValues(
                                alpha: 0.5,
                              ),
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  if (value <= 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: EdgeInsets.only(right: 1.w),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatCompactCurrency(value),
                                        style: TextStyle(
                                          fontSize: 1.7.sp,
                                          color: AppColor.grey,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= chartEmployees.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: SizedBox(
                                      width: 12.w,
                                      child: Text(
                                        _shortName(chartEmployees[idx].name),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 1.8.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.appDarkColor,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipColor: (_) =>
                                  AppColor.appDarkColor.withValues(alpha: 0.95),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final emp = chartEmployees[group.x];
                                final isSalary = rodIndex == 0;
                                final val = isSalary
                                    ? emp.salary
                                    : emp.paidSalary;
                                return BarTooltipItem(
                                  '${emp.name}\n',
                                  TextStyle(
                                    color: AppColor.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 2.6.sp,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${isSalary ? "Salary" : "Paid"}: ${_formatCurrency(val ?? 0)}',
                                      style: TextStyle(
                                        color: isSalary
                                            ? _salaryColor
                                            : _paidColor,
                                        fontSize: 2.4.sp,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        duration: Duration.zero,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2.5.w,
          height: 2.5.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        1.5.width,
        Text(
          label,
          style: TextStyle(
            fontSize: 2.4.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.appDarkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusPieChartContent(SalaryCostReportModel model) {
    final employees = model.departmentEmployees ?? [];
    final totalSalary =
        model.departmentTotals?.totalSalary ??
        employees.fold<num>(0, (s, e) => s + (e.salary ?? 0));
    final totalPaid = employees.fold<num>(0, (s, e) => s + (e.paidSalary ?? 0));
    final pending = (totalSalary - totalPaid).clamp(0, totalSalary);

    if (totalSalary <= 0) {
      return const Center(child: Text('No payment data'));
    }

    final paidRatio = totalPaid / totalSalary;
    final pendingRatio = pending / totalSalary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Status",
          style: TextStyle(
            fontSize: 3.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.appDarkColor,
          ),
        ),
        0.8.height,
        Expanded(
          child: AnimatedBuilder(
            animation: _safeChartAnim,
            builder: (context, child) {
              final animValue = _safeChartAnim.value.clamp(0.0, 1.0);
              final paidChartValue = paidRatio * animValue;
              final pendingChartValue = pendingRatio * animValue;
              final hasSlice = paidChartValue + pendingChartValue > 0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 280;
                  // Spins the pie into place (two full turns, eased by
                  // _safeChartAnim) instead of just filling in flat.
                  final pie = Transform.rotate(
                    angle: (1 - animValue) * 4 * math.pi,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: hasSlice
                          ? PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: isNarrow ? 24 : 30,
                                startDegreeOffset: -90,
                                sections: [
                                  PieChartSectionData(
                                    color: _paidColor,
                                    value: paidChartValue <= 0
                                        ? 0.0
                                        : paidChartValue,
                                    title: animValue > 0.65
                                        ? '${(paidRatio * 100).toStringAsFixed(0)}%'
                                        : '',
                                    radius: isNarrow ? 38 : 46,
                                    titleStyle: TextStyle(
                                      fontSize: 2.4.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: _pendingColor,
                                    value: pendingChartValue <= 0
                                        ? 0.0
                                        : pendingChartValue,
                                    title: animValue > 0.65
                                        ? '${(pendingRatio * 100).toStringAsFixed(0)}%'
                                        : '',
                                    radius: isNarrow ? 38 : 46,
                                    titleStyle: TextStyle(
                                      fontSize: 2.4.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.white,
                                    ),
                                  ),
                                ],
                              ),
                              duration: Duration.zero,
                            )
                          : const SizedBox.shrink(),
                    ),
                  );

                  final legend = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pieLegendItem(
                        _paidColor,
                        "Paid",
                        _formatCompactCurrency(totalPaid * animValue),
                      ),
                      1.2.height,
                      _pieLegendItem(
                        _pendingColor,
                        "Pending",
                        _formatCompactCurrency(pending * animValue),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        Expanded(flex: 3, child: pie),
                        0.8.height,
                        legend,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 3, child: pie),
                      2.width,
                      Expanded(flex: 2, child: legend),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pieLegendItem(Color color, String label, String amount) {
    return Row(
      children: [
        Container(
          width: 2.5.w,
          height: 2.5.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        2.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 2.4.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 2.2.sp,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeList(
    SalaryCostReportModel model,
    DateTime selectedMonth,
  ) {
    final employees = _sortedEmployees(model);
    if (employees.isEmpty) return const SizedBox.shrink();

    final totalSalary = employees.fold<num>(0, (s, e) => s + (e.salary ?? 0));

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
                      color: _salaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      BoxIcons.bxs_wallet,
                      color: _salaryColor,
                      size: 4.w,
                    ),
                  ),
                  2.width,
                  Text(
                    "Employee Salary Records",
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
                  "${employees.length} employees",
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
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 40,
                  child: FadeInAnimation(
                    child: _employeeSalaryCard(
                      employees[index],
                      totalSalary: totalSalary,
                      rank: index + 1,
                      selectedMonth: selectedMonth,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _employeeSalaryCard(
    SalaryCostEmployee emp, {
    required num totalSalary,
    required int rank,
    required DateTime selectedMonth,
  }) {
    final salary = emp.salary ?? 0;
    final paid = emp.paidSalary ?? 0;
    final balance = (salary - paid).clamp(0, salary);
    final paidPct = salary > 0 ? (paid / salary).clamp(0.0, 1.0) : 0.0;
    final sharePct = totalSalary > 0 ? (salary / totalSalary) * 100 : 0.0;
    final isFullyPaid = paid >= salary && salary > 0;

    final statusColor = isFullyPaid ? _paidColor : _salaryColor;

    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AppRoutes.push(
            EmployeeSalaryDetailView(
              siteName: widget.siteName,
              deptName: widget.deptName,
              employee: emp,
              reportMonth: selectedMonth,
            ),
          );
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(5.r),
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
                            Container(
                              width: 7.w,
                              height: 7.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _accentBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '#$rank',
                                style: TextStyle(
                                  fontSize: 2.4.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _accentBlue,
                                ),
                              ),
                            ),
                            2.5.width,
                            _employeeAvatar(emp, haloColor: statusColor),
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
                                  Text(
                                    emp.designation ?? "Employee",
                                    style: TextStyle(
                                      fontSize: 2.8.sp,
                                      color: AppColor.grey,
                                    ),
                                  ),
                                  if (emp.employeeCode != null &&
                                      emp.employeeCode!.isNotEmpty)
                                    Text(
                                      "Code: ${emp.employeeCode}",
                                      style: TextStyle(
                                        fontSize: 2.4.sp,
                                        color: AppColor.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCompactCurrency(salary),
                                  style: TextStyle(
                                    fontSize: 3.2.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _salaryColor,
                                  ),
                                ),
                                Text(
                                  "${sharePct.toStringAsFixed(1)}% of dept.",
                                  style: TextStyle(
                                    fontSize: 2.2.sp,
                                    color: AppColor.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        1.5.height,
                        Row(
                          children: [
                            Expanded(
                              child: _salaryInfoTile(
                                "Monthly Salary",
                                _formatCurrency(salary),
                                _salaryColor,
                              ),
                            ),
                            2.width,
                            Expanded(
                              child: _salaryInfoTile(
                                "Paid Amount",
                                _formatCurrency(paid),
                                _paidColor,
                              ),
                            ),
                            2.width,
                            Expanded(
                              child: _salaryInfoTile(
                                "Balance",
                                _formatCurrency(balance),
                                _pendingColor,
                              ),
                            ),
                          ],
                        ),
                        1.2.height,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: paidPct,
                            minHeight: 0.65.h,
                            backgroundColor: AppColor.scaffold,
                            color: _paidColor,
                          ),
                        ),
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

  Widget _salaryInfoTile(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 2.1.sp, color: AppColor.grey),
          ),
          0.3.height,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 2.5.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _employeeAvatar(SalaryCostEmployee emp, {Color? haloColor}) {
    final color = haloColor ?? _salaryColor;
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

  Widget _avatarFallback(SalaryCostEmployee emp) {
    final initials = emp.name != null && emp.name!.trim().isNotEmpty
        ? emp.name!.trim().split(' ').take(2).map((e) => e[0]).join()
        : '?';
    return Container(
      color: _salaryColor.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: _salaryColor,
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
          Icon(BoxIcons.bx_wallet, size: 12.w, color: _salaryColor),
          2.height,
          Text(
            "No Salary Data Available",
            style: TextStyle(
              fontSize: 4.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          Text(
            "No salary records found for ${widget.siteName} in ${DateFormat('MMMM yyyy').format(controller.selectedDate)}.",
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
              backgroundColor: _salaryColor,
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

class _ChartTabData {
  final String label;
  final IconData icon;
  final Color color;

  const _ChartTabData({
    required this.label,
    required this.icon,
    required this.color,
  });
}
