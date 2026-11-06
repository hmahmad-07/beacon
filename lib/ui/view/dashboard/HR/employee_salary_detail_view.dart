import 'dart:math' as math;

import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/HR/department_salary_cost_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';

class EmployeeSalaryDetailView extends StatefulWidget {
  const EmployeeSalaryDetailView({
    super.key,
    required this.siteName,
    required this.deptName,
    required this.employee,
    required this.reportMonth,
  });

  final String siteName;
  final String deptName;
  final SalaryCostEmployee employee;
  final DateTime reportMonth;

  @override
  State<EmployeeSalaryDetailView> createState() =>
      _EmployeeSalaryDetailViewState();
}

class _EmployeeSalaryDetailViewState extends State<EmployeeSalaryDetailView>
    with SingleTickerProviderStateMixin {
  static const Color _salaryColor = Color(0xFF696D75);
  Color get _paidColor => context.siteAccent;
  Color get _pendingColor => siteShade(context.siteAccent, 0.25);

  AnimationController? _animController;
  Animation<double>? _anim;

  Animation<double> get _safeAnim =>
      _anim ?? const AlwaysStoppedAnimation<double>(1);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController?.forward();
    });
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  String _formatCurrency(num value) {
    return 'PKR ${NumberFormat('#,##0', 'en_US').format(value)}';
  }

  String _formatCompactCurrency(num value) {
    if (value >= 1000000) {
      return 'PKR ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) return 'PKR ${(value / 1000).toStringAsFixed(1)}K';
    return _formatCurrency(value);
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final salary = emp.salary ?? 0;
    final paid = emp.paidSalary ?? 0;
    final balance = (salary - paid).clamp(0, salary);
    final isFullyPaid = paid >= salary && salary > 0;
    final paidRatio = salary > 0 ? (paid / salary).clamp(0.0, 1.0) : 0.0;
    final pendingRatio = salary > 0 ? (balance / salary).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: emp.name ?? "Salary Detail"),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(emp),
            _buildMetricsRow(salary, paid, balance),
            _buildPaymentBreakdown(
              salary: salary,
              paid: paid,
              balance: balance,
              paidRatio: paidRatio,
              pendingRatio: pendingRatio,
              isFullyPaid: isFullyPaid,
            ),
            4.height,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(SalaryCostEmployee emp) {
    final formattedMonth = DateFormat('MMMM yyyy').format(widget.reportMonth);
    final code = emp.employeeCode?.trim() ?? '';

    return SiteReportHeader(
      leading: Container(
        padding: EdgeInsets.all(0.8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
        ),
        child: SiteAvatar(
          name: emp.name ?? '',
          imageUrl: emp.profilePic,
          size: 15.w,
          color: siteShade(_paidColor, -0.08),
        ),
      ),
      eyebrow: emp.designation ?? widget.deptName,
      title: emp.name ?? "Employee",
      subtitle: widget.siteName,
      pills: [
        if (code.isNotEmpty) SiteBannerPill(code, icon: Icons.badge_outlined),
      ],
      periodLabel: "Salary month: $formattedMonth",
    );
  }

  Widget _buildMetricsRow(num salary, num paid, num balance) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: _metricTile(
              "Salary",
              salary,
              _salaryColor,
              BoxIcons.bxs_wallet,
            ),
          ),
          2.width,
          Expanded(
            child: _metricTile(
              "Paid",
              paid,
              _paidColor,
              BoxIcons.bxs_check_circle,
            ),
          ),
          2.width,
          Expanded(
            child: _metricTile(
              "Balance",
              balance,
              _pendingColor,
              BoxIcons.bxs_time,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String title, num value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: siteCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 4.w),
          ),
          1.height,
          AnimatedBuilder(
            animation: _safeAnim,
            builder: (context, child) {
              final animated = value * _safeAnim.value;
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCompactCurrency(animated),
                  style: TextStyle(
                    fontSize: 3.4.sp,
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

  // Salary/paid amounts are a single-month snapshot (no historical series
  // is fetched for one employee), so a donut showing paid-vs-pending share
  // is the honest "relative" chart here rather than a misleading line chart.
  Widget _buildPaymentBreakdown({
    required num salary,
    required num paid,
    required num balance,
    required double paidRatio,
    required double pendingRatio,
    required bool isFullyPaid,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.7),
        ),
        boxShadow: siteCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  BoxIcons.bxs_doughnut_chart,
                  color: _salaryColor,
                  size: 4.5.w,
                ),
              ),
              2.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Breakdown",
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "Paid vs pending this month",
                      style: TextStyle(fontSize: 2.2.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          1.5.height,
          SizedBox(
            height: (26.h).clamp(220.0, 280.0),
            child: AnimatedBuilder(
              animation: _safeAnim,
              builder: (context, child) {
                final anim = _safeAnim.value.clamp(0.0, 1.0);
                final paidValue = paidRatio * anim;
                final pendingValue = pendingRatio * anim;
                final hasSlice = paidValue + pendingValue > 0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 280;
                    // Spins the donut into place instead of just filling
                    // in flat, matching the department-level charts.
                    final pie = Transform.rotate(
                      angle: (1 - anim) * 4 * math.pi,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: hasSlice
                            ? PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: isNarrow ? 26 : 34,
                                  startDegreeOffset: -90,
                                  sections: [
                                    PieChartSectionData(
                                      color: _paidColor,
                                      value: paidValue <= 0 ? 0.0 : paidValue,
                                      title: anim > 0.65
                                          ? '${(paidRatio * 100).toStringAsFixed(0)}%'
                                          : '',
                                      radius: isNarrow ? 40 : 48,
                                      titleStyle: TextStyle(
                                        fontSize: 2.6.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      color: _pendingColor,
                                      value: pendingValue <= 0
                                          ? 0.0
                                          : pendingValue,
                                      title: anim > 0.65
                                          ? '${(pendingRatio * 100).toStringAsFixed(0)}%'
                                          : '',
                                      radius: isNarrow ? 40 : 48,
                                      titleStyle: TextStyle(
                                        fontSize: 2.6.sp,
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
                        _legendItem(
                          _paidColor,
                          "Paid",
                          _formatCurrency(paid * anim),
                        ),
                        1.2.height,
                        _legendItem(
                          _pendingColor,
                          "Pending",
                          _formatCurrency(balance * anim),
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
          1.5.height,
          Divider(height: 1, color: AppColor.scaffold),
          1.2.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total: ${_formatCurrency(salary)}",
                style: TextStyle(
                  fontSize: 2.8.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.grey,
                ),
              ),
              if (isFullyPaid)
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 3.5.w, color: _paidColor),
                    1.width,
                    Text(
                      "Fully Paid",
                      style: TextStyle(
                        fontSize: 2.6.sp,
                        fontWeight: FontWeight.bold,
                        color: _paidColor,
                      ),
                    ),
                  ],
                )
              else if (balance > 0)
                Text(
                  "${_formatCompactCurrency(balance)} remaining",
                  style: TextStyle(
                    fontSize: 2.6.sp,
                    fontWeight: FontWeight.w600,
                    color: _pendingColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String amount) {
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
}
