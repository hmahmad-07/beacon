import 'package:beacon/core/controllers/hr_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/HR/budget_headcount_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class BudgetHeadcountReportView extends StatefulWidget {
  const BudgetHeadcountReportView({
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
  State<BudgetHeadcountReportView> createState() =>
      _BudgetHeadcountReportViewState();
}

class _BudgetHeadcountReportViewState extends State<BudgetHeadcountReportView>
    with SingleTickerProviderStateMixin {
  static const Color _actualColor = Color(0xFF007AFF);
  static const Color _budgetColor = Color(0xFFFF9F43);
  static const Color _accent = Color(0xFF00A86B);

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

  void _fetchReportData() {
    _animationKey = null;
    final hrController = context.read<HRController>();
    hrController.getBudgetHeadcountReport(
      context,
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
      month: DateFormat('MM').format(hrController.budgetSelectedDate),
      year: DateFormat('yyyy').format(hrController.budgetSelectedDate),
    );
  }

  double _niceYAxisInterval(num maxValue) {
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 25) return 5;
    if (maxValue <= 60) return 10;
    if (maxValue <= 120) return 20;
    return 50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: "Budget vs Actual Headcount",
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
          final model = controller.budgetHeadcountModel;
          final isLoading = controller.isBudgetHeadcountLoading;
          final rows = model?.data?.tableData ?? [];

          if (!isLoading && rows.isNotEmpty) {
            final key =
                'budget_${rows.length}_'
                '${rows.fold<int>(0, (s, r) => s + (r.actualHeadcount ?? 0))}';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _triggerChartAnimation(key);
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
                  _buildHeaderBanner(controller, model),
                  if (isLoading)
                    _buildShimmerLoading()
                  else if (rows.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildMetricsRow(rows),
                    _buildLineChartCard(rows),
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

  Widget _buildHeaderBanner(
    HRController controller,
    BudgetHeadcountModel? model,
  ) {
    final note = model?.filters?.note;
    final formattedMonth = DateFormat(
      'MMMM yyyy',
    ).format(controller.budgetSelectedDate);

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
                        BoxIcons.bxs_bar_chart_alt_2,
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
                selectedMonth: controller.budgetSelectedDate,
                onMonthSelected: (date) {
                  controller.setBudgetSelectedDate(date);
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
                        "Month: $formattedMonth",
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
          if (note != null && note.trim().isNotEmpty) ...[
            1.5.height,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppColor.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    BoxIcons.bx_info_circle,
                    color: AppColor.white,
                    size: 4.w,
                  ),
                  2.width,
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        color: AppColor.white.withValues(alpha: 0.9),
                        fontSize: 2.6.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsRow(List<BudgetHeadcountTableRow> rows) {
    final actual = rows.fold<int>(0, (s, r) => s + (r.actualHeadcount ?? 0));
    final budget = rows.fold<int>(0, (s, r) => s + (r.budgetHeadcount ?? 0));
    final variance = actual - budget;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: _metricCard(
              "Actual",
              actual.toDouble(),
              (v) => v.round().toString(),
              BoxIcons.bxs_group,
              _actualColor,
            ),
          ),
          2.width,
          Expanded(
            child: _metricCard(
              "Budgeted",
              budget.toDouble(),
              (v) => v.round().toString(),
              BoxIcons.bxs_bar_chart_alt_2,
              _budgetColor,
            ),
          ),
          2.width,
          Expanded(
            child: _metricCard(
              "Variance",
              variance.toDouble(),
              (v) {
                final rounded = v.round();
                if (rounded == 0) return "On target";
                return rounded > 0 ? "+$rounded" : "$rounded";
              },
              variance == 0
                  ? BoxIcons.bxs_check_circle
                  : (variance > 0
                        ? BoxIcons.bx_up_arrow_alt
                        : BoxIcons.bx_down_arrow_alt),
              variance == 0
                  ? _accent
                  : (variance > 0 ? const Color(0xFFE83E8C) : _accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String title,
    num value,
    String Function(num) format,
    IconData icon,
    Color color,
  ) {
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
            padding: EdgeInsets.all(1.8.w),
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
                  format(animated),
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
              fontSize: 2.3.sp,
              color: AppColor.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(List<BudgetHeadcountTableRow> rows) {
    num maxY = 0;
    for (final r in rows) {
      final a = r.actualHeadcount ?? 0;
      final b = r.budgetHeadcount ?? 0;
      if (a > maxY) maxY = a;
      if (b > maxY) maxY = b;
    }
    if (maxY <= 0) maxY = 5;
    final yInterval = _niceYAxisInterval(maxY);
    final chartMaxY = (maxY / yInterval).ceil() * yInterval + yInterval;
    final maxX = rows.length > 1 ? (rows.length - 1).toDouble() : 1.0;

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
              Container(
                padding: EdgeInsets.all(1.8.w),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  BoxIcons.bx_line_chart,
                  color: _accent,
                  size: 4.5.w,
                ),
              ),
              2.width,
              Text(
                "Budget vs Actual Trend",
                style: TextStyle(
                  fontSize: 3.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.appDarkColor,
                ),
              ),
            ],
          ),
          0.8.height,
          Wrap(
            spacing: 3.w,
            runSpacing: 0.4.h,
            children: [
              _legendDot(_actualColor, "Actual"),
              _legendDot(_budgetColor, "Budget"),
            ],
          ),
          1.5.height,
          SizedBox(
            height: (26.h).clamp(220.0, 280.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = 24.w;
                final contentWidth = rows.length * itemWidth;
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
                        final anim = _safeChartAnim.value.clamp(0.0, 1.0);
                        final actualSpots = <FlSpot>[];
                        final budgetSpots = <FlSpot>[];
                        if (rows.length == 1) {
                          // A single department (the usual case, since this
                          // report is dept-scoped) gives one point per
                          // series — not enough to draw a line segment.
                          // Duplicate it across the width so the
                          // comparison still renders as an actual line
                          // instead of vanishing.
                          final a =
                              (rows[0].actualHeadcount ?? 0).toDouble() * anim;
                          final b =
                              (rows[0].budgetHeadcount ?? 0).toDouble() * anim;
                          actualSpots.addAll([FlSpot(0, a), FlSpot(1, a)]);
                          budgetSpots.addAll([FlSpot(0, b), FlSpot(1, b)]);
                        } else {
                          for (int i = 0; i < rows.length; i++) {
                            actualSpots.add(
                              FlSpot(
                                i.toDouble(),
                                (rows[i].actualHeadcount ?? 0).toDouble() *
                                    anim,
                              ),
                            );
                            budgetSpots.add(
                              FlSpot(
                                i.toDouble(),
                                (rows[i].budgetHeadcount ?? 0).toDouble() *
                                    anim,
                              ),
                            );
                          }
                        }

                        return LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: maxX,
                            minY: 0,
                            maxY: chartMaxY,
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
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.round();
                                    if (idx < 0 || idx >= rows.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        rows[idx].department ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 2.2.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.appDarkColor,
                                        ),
                                      ),
                                    );
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
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 1.9.sp,
                                        color: AppColor.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 12,
                                  getTitlesWidget: (value, meta) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColor.appDarkColor
                                    .withValues(alpha: 0.95),
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final isActual = spot.barIndex == 0;
                                    final idx = spot.x.round().clamp(
                                      0,
                                      rows.length - 1,
                                    );
                                    final row = rows[idx];
                                    return LineTooltipItem(
                                      '${row.department}\n${isActual ? "Actual" : "Budget"}: ${spot.y.round()}',
                                      TextStyle(
                                        color: isActual
                                            ? _actualColor
                                            : _budgetColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 2.2.sp,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: actualSpots,
                                isCurved: true,
                                curveSmoothness: 0.2,
                                color: _actualColor,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar, index) =>
                                      FlDotCirclePainter(
                                        radius: 4,
                                        color: _actualColor,
                                        strokeWidth: 2,
                                        strokeColor: AppColor.white,
                                      ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: _actualColor.withValues(alpha: 0.1),
                                ),
                              ),
                              LineChartBarData(
                                spots: budgetSpots,
                                isCurved: true,
                                curveSmoothness: 0.2,
                                color: _budgetColor,
                                barWidth: 3,
                                dashArray: [6, 4],
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar, index) =>
                                      FlDotCirclePainter(
                                        radius: 4,
                                        color: _budgetColor,
                                        strokeWidth: 2,
                                        strokeColor: AppColor.white,
                                      ),
                                ),
                              ),
                            ],
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
      ),
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
              height: 24.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          Icon(BoxIcons.bxs_bar_chart_alt_2, size: 12.w, color: _accent),
          2.height,
          Text(
            "No Budget Data",
            style: TextStyle(
              fontSize: 4.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          Text(
            "No budget vs actual headcount found for ${widget.deptName}.",
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
