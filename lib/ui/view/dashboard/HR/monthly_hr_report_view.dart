import 'package:beacon/core/controllers/hr_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/HR/hr_summary_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlyHRReportView extends StatefulWidget {
  const MonthlyHRReportView({
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
  State<MonthlyHRReportView> createState() => _MonthlyHRReportViewState();
}

class _MonthlyHRReportViewState extends State<MonthlyHRReportView>
    with SingleTickerProviderStateMixin {
  Color get _accent => context.siteAccent;
  Color get _paidColor => siteShade(context.siteAccent, 0.18);
  Color get _joinersColor => context.siteAccent;
  static const Color _leaversColor = Color(0xFF696D75);

  AnimationController? _chartAnimController;
  Animation<double>? _chartAnim;

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

  void _replayChartAnimation() {
    _chartAnimController?.reset();
    _chartAnimController?.forward();
  }

  // Awaits the fetch and replays the animation off its own completion,
  // instead of a manual HRController.addListener callback. That earlier
  // approach called context.read<HRController>() from inside a listener
  // that fires on EVERY screen's fetch (HRController is a shared
  // singleton) — including after this widget was torn down but before
  // dispose() finished unregistering it, throwing "Looking up a
  // deactivated widget's ancestor is unsafe". Awaiting our own fetch
  // sidesteps that: the callback only ever runs for a request this
  // widget itself made, and `mounted` is checked before touching state.
  Future<void> _fetchReportData() async {
    final hrController = context.read<HRController>();
    await hrController.getHRSummaryReport(
      context,
      month: DateFormat('MM').format(hrController.hrSummarySelectedDate),
      year: DateFormat('yyyy').format(hrController.hrSummarySelectedDate),
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
    );
    if (!mounted) return;
    if (hrController.hrSummaryModel?.data?.kpiCards != null) {
      _replayChartAnimation();
    }
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
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: "Monthly HR Report",
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
          final model = controller.hrSummaryModel;
          final isLoading = controller.isHrSummaryLoading;
          final kpis = model?.data?.kpiCards;

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
                  else if (kpis == null)
                    _buildEmptyState(controller)
                  else ...[
                    _buildKpiGrid(kpis),
                    _buildWorkforceScatter(kpis),
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
    ).format(controller.hrSummarySelectedDate);
    return SiteReportHeader(
      title: widget.siteName,
      subtitle: widget.deptName,
      logoAsset: widget.siteImage,
      icon: BoxIcons.bxs_report,
      periodLabel: "Summary for: $formattedMonth",
      onChangePeriod: () async {
        await CustomMonthPicker.showMonthPickerDialog(
          context: context,
          selectedMonth: controller.hrSummarySelectedDate,
          onMonthSelected: (date) {
            controller.setHrSummarySelectedDate(date);
            _fetchReportData();
          },
        );
      },
    );
  }

  Widget _buildKpiGrid(HRSummaryKpiCards kpis) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Wrap(
        spacing: 2.5.w,
        runSpacing: 1.5.h,
        children: [
          _kpiCard(
            "Headcount",
            (kpis.totalHeadcount ?? 0).toDouble(),
            (v) => v.round().toString(),
            BoxIcons.bxs_group,
            _accent,
          ),
          _kpiCard(
            "Gross Salary",
            (kpis.totalGrossSalary ?? 0).toDouble(),
            _formatCompactCurrency,
            BoxIcons.bxs_wallet,
            const Color(0xFF696D75),
          ),
          _kpiCard(
            "Salary Paid",
            (kpis.totalSalaryPaid ?? 0).toDouble(),
            _formatCompactCurrency,
            BoxIcons.bxs_check_circle,
            _paidColor,
          ),
          _kpiCard(
            "New Joiners",
            (kpis.newJoiners ?? 0).toDouble(),
            (v) => v.round().toString(),
            BoxIcons.bx_user_plus,
            _joinersColor,
          ),
          _kpiCard(
            "Leavers",
            (kpis.totalLeavers ?? 0).toDouble(),
            (v) => v.round().toString(),
            BoxIcons.bx_user_minus,
            _leaversColor,
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    String title,
    num value,
    String Function(num) format,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: (100.w - 15.w) / 3,
      child: Container(
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
              padding: EdgeInsets.all(1.8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 3.8.w),
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
                      fontSize: 3.2.sp,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 2.1.sp,
                color: AppColor.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _niceCeiling(num value) {
    if (value <= 4) return 4;
    if (value <= 10) return 10;
    if (value <= 20) return 20;
    if (value <= 50) return 50;
    return 100;
  }

  // A scatter plot is a chart type not used anywhere else in the app.
  // Each legend entry (New Joiners, Leavers) gets its own point at a
  // fixed x position on a shared count axis, with its value always
  // visible above the dot — so every legend item reads as its own,
  // clearly separate mark instead of being merged into one (x, y) point.
  Widget _buildWorkforceScatter(HRSummaryKpiCards kpis) {
    final joiners = (kpis.newJoiners ?? 0).toDouble();
    final leavers = (kpis.totalLeavers ?? 0).toDouble();
    final axisMax = _niceCeiling(joiners > leavers ? joiners : leavers);
    final axisInterval = axisMax / 4;
    final categories = ["New Joiners", "Leavers"];
    final values = [joiners, leavers];
    final colors = [_joinersColor, _leaversColor];

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
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  BoxIcons.bx_scatter_chart,
                  color: _accent,
                  size: 4.5.w,
                ),
              ),
              2.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Workforce Movement",
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "New joiners vs leavers this month",
                      style: TextStyle(fontSize: 2.2.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          1.5.height,
          SizedBox(
            height: (28.h).clamp(240.0, 300.0),
            child: FadeTransition(
              opacity: _safeChartAnim,
              child: ScatterChart(
                ScatterChartData(
                  minX: -0.6,
                  maxX: 1.6,
                  minY: 0,
                  maxY: axisMax,
                  showingTooltipIndicators: const [0, 1],
                  scatterTouchData: ScatterTouchData(
                    enabled: false,
                    touchTooltipData: ScatterTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) =>
                          AppColor.appDarkColor.withValues(alpha: 0.95),
                      getTooltipItems: (spot) {
                        final idx = spot.x.round().clamp(
                          0,
                          categories.length - 1,
                        );
                        return ScatterTooltipItem(
                          '${categories[idx]}\n${values[idx].round()}',
                          textStyle: TextStyle(
                            color: colors[idx],
                            fontWeight: FontWeight.bold,
                            fontSize: 2.2.sp,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: axisInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColor.appLightColor.withValues(alpha: 0.6),
                      strokeWidth: 0.8,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppColor.appLightColor.withValues(alpha: 0.7),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if (idx < 0 || idx >= categories.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              categories[idx],
                              style: TextStyle(
                                fontSize: 2.2.sp,
                                fontWeight: FontWeight.bold,
                                color: colors[idx],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: axisInterval,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          if (value < 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 1.9.sp,
                              color: AppColor.grey,
                              fontWeight: FontWeight.bold,
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
                  scatterSpots: [
                    ScatterSpot(
                      0,
                      joiners,
                      dotPainter: FlDotCirclePainter(
                        radius: 14,
                        color: _joinersColor,
                        strokeWidth: 2,
                        strokeColor: AppColor.white,
                      ),
                    ),
                    ScatterSpot(
                      1,
                      leavers,
                      dotPainter: FlDotCirclePainter(
                        radius: 14,
                        color: _leaversColor,
                        strokeWidth: 2,
                        strokeColor: AppColor.white,
                      ),
                    ),
                  ],
                ),
                duration: Duration.zero,
                transformationConfig: const FlTransformationConfig(
                  scaleEnabled: false,
                  panEnabled: false,
                ),
              ),
            ),
          ),
          1.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(
                _joinersColor,
                "New Joiners",
                '${kpis.newJoiners ?? 0}',
              ),
              _legendItem(
                _leaversColor,
                "Leavers",
                '${kpis.totalLeavers ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2.5.w,
          height: 2.5.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        2.width,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Widget _buildEmptyState(HRController controller) {
    return Container(
      margin: EdgeInsets.all(5.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: siteCardShadow,
      ),
      child: Column(
        children: [
          Icon(BoxIcons.bxs_report, size: 12.w, color: _accent),
          2.height,
          Text(
            "No HR Summary Available",
            style: TextStyle(
              fontSize: 4.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          Text(
            "No summary found for ${widget.deptName} in ${DateFormat('MMMM yyyy').format(controller.hrSummarySelectedDate)}.",
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
