import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_dashboard_model.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart'
    show InventoryStoreBalance;
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_store_filter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// Mirrors the "Dashboard" page of the reference stock dashboard
/// (104.143.0.113:8000): KPI tiles, a 6-month received/issued trend,
/// value-by-category breakdown, balance by store, and negative stock.
class InventoryDashboardView extends StatefulWidget {
  const InventoryDashboardView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryDashboardView> createState() =>
      _InventoryDashboardViewState();
}

class _InventoryDashboardViewState extends State<InventoryDashboardView>
    with SingleTickerProviderStateMixin {
  String? _storeId;

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
      duration: const Duration(milliseconds: 1600),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController!,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
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

  void _fetch() {
    _animationKey = null;
    context.read<WMSController>().getDashboard(context, storeId: _storeId);
  }

  final _wholeFormat = NumberFormat('#,##0', 'en_US');
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Inventory Dashboard"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final data = controller.dashboardModel?.data;
          final loading = controller.isDashboardLoading;

          if (!loading && data != null) {
            final animKey =
                '${_storeId ?? 'all'}_${data.movementLast6Months?.length ?? 0}_'
                '${data.kpis?.totalItems ?? 0}';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _triggerChartAnimation(animKey);
            });
          }

          return RefreshIndicator(
            onRefresh: () async => _fetch(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
              children: [
                InventoryStoreFilter(
                  selectedStoreId: _storeId,
                  onChanged: (id) {
                    setState(() => _storeId = id);
                    _fetch();
                  },
                ),
                2.height,
                if (loading && data == null)
                  _loadingSkeleton()
                else if (data == null)
                  _emptyState()
                else
                  _buildContent(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(InventoryDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kpiGrid(data.kpis),
        3.height,
        _sectionCard(
          title: "Stock movement",
          subtitle: "Received vs issued, last 6 months",
          child: _movementChart(data.movementLast6Months ?? []),
        ),
        2.height,
        _sectionCard(
          title: "Stock value by category",
          subtitle: "Share of total on-hand value",
          child: _categoryList(data.valueByCategory ?? []),
        ),
        2.height,
        _sectionCard(
          title: "Balance by store",
          subtitle: "Total on-hand quantity per store",
          child: _storeBalanceList(data.balanceByStore ?? []),
        ),
        2.height,
        _sectionCard(
          title: "Negative stock",
          subtitle: "Issued more than received — needs investigation",
          child: _negativeStockList(data.negativeStock ?? []),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ KPIs

  Widget _kpiGrid(InventoryKpis? kpis) {
    final tiles = [
      _KpiData(
        "Total items",
        _wholeFormat.format(kpis?.totalItems ?? 0),
        BoxIcons.bxs_box,
        widget.accentColor,
      ),
      _KpiData(
        "Stock value",
        _wholeFormat.format(kpis?.stockValue ?? 0),
        BoxIcons.bxs_wallet,
        const Color(0xFF00A86B),
      ),
      _KpiData(
        "Negative stock items",
        _wholeFormat.format(kpis?.negativeStockItems ?? 0),
        BoxIcons.bxs_error,
        const Color(0xFFE83E8C),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 3.w,
        crossAxisSpacing: 3.w,
        childAspectRatio: 1.5,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final t = tiles[index];
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(3.5.r),
            boxShadow: AppShadow.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(1.8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.color.withValues(alpha: 0.12),
                ),
                child: Icon(t.icon, color: t.color, size: 5.w),
              ),
              1.height,
              Text(
                t.value,
                style: TextStyle(
                  fontSize: 4.8.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.appDarkColor,
                ),
              ),
              0.3.height,
              Text(
                t.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ Movement chart

  Widget _movementChart(List<MonthlyMovement> months) {
    if (months.isEmpty) return _inlineEmpty("No movement data");

    final maxVal = months.fold<double>(0, (max, m) {
      final r = (m.received ?? 0).toDouble();
      final i = (m.issued ?? 0).toDouble();
      return [max, r, i].reduce((a, b) => a > b ? a : b);
    });
    final interval = maxVal <= 0 ? 1.0 : maxVal / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _legendDot(const Color(0xFF00A86B), "Received"),
            3.width,
            _legendDot(const Color(0xFFFF9F43), "Issued"),
          ],
        ),
        1.5.height,
        SizedBox(
          height: 22.h,
          // Grows the lines in from flat on every fresh fetch, matching the
          // HR module's chart entrance animation (AnimatedBuilder scaling
          // spot values by _safeChartAnim.value instead of just snapping in).
          child: AnimatedBuilder(
            animation: _safeChartAnim,
            builder: (context, child) {
              final animValue = _safeChartAnim.value.clamp(0.0, 1.0);
              return LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal <= 0 ? 10 : maxVal * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 3.5.h,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final month = months[idx].month ?? "";
                          return Padding(
                            padding: EdgeInsets.only(top: 0.8.h),
                            child: Text(
                              month.length >= 7 ? month.substring(5) : month,
                              style: TextStyle(
                                fontSize: 2.6.sp,
                                color: AppColor.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _lineSeries(
                      months,
                      const Color(0xFF00A86B),
                      (m) => m.received,
                      animValue,
                    ),
                    _lineSeries(
                      months,
                      const Color(0xFFFF9F43),
                      (m) => m.issued,
                      animValue,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  LineChartBarData _lineSeries(
    List<MonthlyMovement> months,
    Color color,
    num? Function(MonthlyMovement) selector,
    double animValue,
  ) {
    return LineChartBarData(
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
      spots: [
        for (int i = 0; i < months.length; i++)
          FlSpot(
            i.toDouble(),
            (selector(months[i]) ?? 0).toDouble() * animValue,
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        1.width,
        Text(label, style: TextStyle(fontSize: 3.sp, color: AppColor.grey)),
      ],
    );
  }

  // ------------------------------------------------------------ Category list

  Widget _categoryList(List<CategoryValue> categories) {
    if (categories.isEmpty) return _inlineEmpty("No category data");

    final total = categories.fold<double>(
      0,
      (sum, c) => sum + (c.value ?? 0).toDouble(),
    );
    final top = List<CategoryValue>.from(categories)
      ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

    return AnimatedBuilder(
      animation: _safeChartAnim,
      builder: (context, child) {
        final animValue = _safeChartAnim.value.clamp(0.0, 1.0);
        return Column(
          children: top.take(8).map((c) {
            final value = (c.value ?? 0).toDouble();
            final share = total <= 0 ? 0.0 : value / total;
            return Padding(
              padding: EdgeInsets.only(bottom: 1.2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.category ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 3.2.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColor.appDarkColor,
                          ),
                        ),
                      ),
                      Text(
                        _wholeFormat.format(value),
                        style: TextStyle(
                          fontSize: 3.2.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                  0.6.height,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: LinearProgressIndicator(
                      value: (share * animValue).clamp(0, 1),
                      minHeight: 1.h,
                      backgroundColor: AppColor.appLightColor,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ------------------------------------------------------------ Balance by store

  Widget _storeBalanceList(List<InventoryStoreBalance> balances) {
    if (balances.isEmpty) return _inlineEmpty("No store balances");
    return Column(
      children: balances.map<Widget>((s) {
        final balance = (s.balance ?? 0).toDouble();
        final negative = balance < 0;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.7.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.storeName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 3.2.sp, color: AppColor.black),
                ),
              ),
              Text(
                _decimalFormat.format(balance),
                style: TextStyle(
                  fontSize: 3.2.sp,
                  fontWeight: FontWeight.bold,
                  color: negative ? AppColor.red : AppColor.appDarkColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------ Negative stock

  Widget _negativeStockList(List<NegativeStockItem> items) {
    if (items.isEmpty) {
      return _inlineEmpty("No negative-stock items");
    }
    return Column(
      children: items.map((item) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.7.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (item.name ?? "").trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 3.2.sp, color: AppColor.black),
                ),
              ),
              Text(
                _decimalFormat.format(item.onHand ?? 0),
                style: TextStyle(
                  fontSize: 3.2.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------ Shared UI

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          0.3.height,
          Text(
            subtitle,
            style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
          ),
          1.5.height,
          child,
        ],
      ),
    );
  }

  Widget _inlineEmpty(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Text(
        message,
        style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Text(
          "No dashboard data",
          style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey),
        ),
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(4, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            height: 12.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3.5.r),
            ),
          );
        }),
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _KpiData(this.label, this.value, this.icon, this.color);
}
