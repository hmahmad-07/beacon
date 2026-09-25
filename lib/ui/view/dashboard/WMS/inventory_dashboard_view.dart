import 'dart:math' as math;

import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_dashboard_model.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart'
    show InventoryStoreBalance;
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_3d_loader.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stock_report_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Dashboard" page of the reference stock dashboard
/// (104.143.0.113:8000): a store filter, KPI tiles, a 6-month
/// received/issued trend, a value-by-category breakdown (both a donut and
/// the per-category detail bars), balance by store, and negative stock.
class InventoryDashboardView extends StatefulWidget {
  const InventoryDashboardView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryDashboardView> createState() => _InventoryDashboardViewState();
}

class _InventoryDashboardViewState extends State<InventoryDashboardView>
    with SingleTickerProviderStateMixin {
  static const List<Color> _categoryPalette = [
    Color(0xFF7367F0),
    Color(0xFF00A86B),
    Color(0xFFFF9F43),
    Color(0xFF007AFF),
    Color(0xFFE83E8C),
    Color(0xFF28C76F),
    Color(0xFFEA5455),
    Color(0xFF00CFE8),
  ];

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
    final controller = context.read<WMSController>();
    // The store chip shows a name, so the store list must be loaded.
    controller.ensureStoresLoaded(context);
    controller.getDashboard(context);
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
                '${controller.dashboardStoreId ?? 'all'}_'
                '${data.movementLast6Months?.length ?? 0}_'
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: InventoryStoreChip(
                    selectedStoreId: controller.dashboardStoreId,
                    accentColor: widget.accentColor,
                    onChanged: (id) =>
                        controller.setDashboardStore(context, id),
                  ),
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
          child: _categoryDonut(data.valueByCategory ?? []),
        ),
        2.height,
        _sectionCard(
          title: "Category breakdown",
          subtitle: "Value and share, every category",
          child: _categoryBars(data.valueByCategory ?? []),
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
          trailing: TextButton(
            onPressed: () => AppRoutes.push(
              InventoryStockReportView(
                accentColor: widget.accentColor,
                initialLowStockOnly: true,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "View all",
                  style: TextStyle(
                    fontSize: 2.8.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 3.5.w,
                  color: widget.accentColor,
                ),
              ],
            ),
          ),
          child: _negativeStockList(data.negativeStock ?? []),
        ),
        2.height,
        _sectionCard(
          title: "Recent activity",
          subtitle: "Latest posted stock movements",
          child: _recentMovementsList(data.recentMovements ?? []),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ KPIs

  Widget _kpiGrid(InventoryKpis? kpis) {
    // "Below min stock" and "Out of stock" both read off negativeStockItems:
    // the API doc is explicit that this schema has no separate reorder-point
    // column, so low-stock and out-of-stock share one definition
    // (balance <= 0) -- same redundancy the reference dashboard itself shows.
    final zeroOrBelow = _wholeFormat.format(kpis?.negativeStockItems ?? 0);
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
        "Below min stock",
        zeroOrBelow,
        BoxIcons.bxs_bell,
        const Color(0xFFFF9F43),
      ),
      _KpiData(
        "Out of stock",
        zeroOrBelow,
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
                          return Padding(
                            padding: EdgeInsets.only(top: 0.8.h),
                            child: Text(
                              _formatMonth(months[idx].month),
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
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
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
        Text(
          label,
          style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
        ),
      ],
    );
  }

  // API gives months as "yyyy-MM" -- show the month name ("Apr") instead
  // of the raw two-digit number ("04").
  String _formatMonth(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      return DateFormat('MMM').format(DateFormat('yyyy-MM').parse(raw));
    } catch (_) {
      return raw.length >= 7 ? raw.substring(5) : raw;
    }
  }

  // A plain toStringAsFixed(0) rounds any category under ~0.5% of the
  // total straight down to "0%" -- IT EQUIPMENTS and SEMI FINISHED GOODS
  // are real, non-zero categories that just happen to be tiny slices next
  // to RAW MATERIAL, so they need finer precision instead of disappearing
  // to zero.
  String _formatPercent(num value, num total) {
    if (total <= 0) return "0%";
    final pct = (value / total) * 100;
    if (pct <= 0) return "0%";
    if (pct < 0.01) return "<0.01%";
    if (pct < 1) return '${pct.toStringAsFixed(2)}%';
    return '${pct.toStringAsFixed(0)}%';
  }

  // ------------------------------------------------------------ Category donut

  String _compactValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return _wholeFormat.format(value);
  }

  Widget _categoryDonut(List<CategoryValue> categories) {
    final nonZero = categories.where((c) => (c.value ?? 0) != 0).toList();
    if (nonZero.isEmpty) return _inlineEmpty("No category data");

    final total = nonZero.fold<double>(
      0,
      (sum, c) => sum + (c.value ?? 0).toDouble(),
    );
    final top = List<CategoryValue>.from(nonZero)
      ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));
    final shown = top.take(6).toList();

    // Same rotate-in donut treatment as the HR module's pie charts
    // (attendance/salary breakdowns): angle eases from a full spin down to
    // 0 as _safeChartAnim runs, with fl_chart's own duration set to zero so
    // it never fights the AnimatedBuilder driving it.
    return AnimatedBuilder(
      animation: _safeChartAnim,
      builder: (context, child) {
        final anim = _safeChartAnim.value.clamp(0.0, 1.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Transform.rotate(
                angle: (1 - anim) * 4 * math.pi,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 34,
                          startDegreeOffset: -90,
                          sections: [
                            for (int i = 0; i < shown.length; i++)
                              PieChartSectionData(
                                color:
                                    _categoryPalette[i %
                                        _categoryPalette.length],
                                value: ((shown[i].value ?? 0).toDouble() * anim)
                                    .clamp(0, double.infinity),
                                title: '',
                                radius: 20,
                              ),
                          ],
                        ),
                        duration: Duration.zero,
                      ),
                    ),
                    Opacity(
                      opacity: anim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _compactValue(total * anim),
                            style: TextStyle(
                              fontSize: 3.4.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.appDarkColor,
                            ),
                          ),
                          Text(
                            "Total value",
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
            ),
            3.width,
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < shown.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                        children: [
                          Container(
                            width: 2.3.w,
                            height: 2.3.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _categoryPalette[i % _categoryPalette.length],
                            ),
                          ),
                          1.5.width,
                          Expanded(
                            child: Text(
                              shown[i].category ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 2.6.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColor.appDarkColor,
                              ),
                            ),
                          ),
                          Text(
                            _formatPercent(shown[i].value ?? 0, total),
                            style: TextStyle(
                              fontSize: 2.4.sp,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Full per-category list with a progress bar per row (every category,
  // not just the donut's top 6) -- complements the donut with exact
  // values for categories the donut slices are too thin to label.
  Widget _categoryBars(List<CategoryValue> categories) {
    final nonZero = categories.where((c) => (c.value ?? 0) != 0).toList();
    if (nonZero.isEmpty) return _inlineEmpty("No category data");

    final total = nonZero.fold<double>(
      0,
      (sum, c) => sum + (c.value ?? 0).toDouble(),
    );
    final sorted = List<CategoryValue>.from(nonZero)
      ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

    return AnimatedBuilder(
      animation: _safeChartAnim,
      builder: (context, child) {
        final animValue = _safeChartAnim.value.clamp(0.0, 1.0);
        return Column(
          children: sorted.map((c) {
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

  // Diverging horizontal bar chart -- store name on the left, a bar growing
  // right (accent) for a positive balance or left (red) for a negative one
  // from a shared zero line, matching the reference dashboard's layout.
  Widget _storeBalanceList(List<InventoryStoreBalance> balances) {
    final nonZero = balances.where((s) => (s.balance ?? 0) != 0).toList();
    if (nonZero.isEmpty) return _inlineEmpty("No store balances");

    final maxAbs = nonZero.fold<double>(
      0,
      (max, s) => math.max(max, (s.balance ?? 0).abs().toDouble()),
    );

    return AnimatedBuilder(
      animation: _safeChartAnim,
      builder: (context, child) {
        final animValue = _safeChartAnim.value.clamp(0.0, 1.0);
        return Column(
          children: nonZero.map((s) {
            final balance = (s.balance ?? 0).toDouble();
            final negative = balance < 0;
            final fraction = maxAbs <= 0
                ? 0.0
                : (balance.abs() / maxAbs).clamp(0.0, 1.0) * animValue;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 26.w,
                    child: Text(
                      s.storeName ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 2.6.sp, color: AppColor.black),
                    ),
                  ),
                  1.width,
                  Expanded(
                    child: SizedBox(
                      height: 2.h,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: negative ? fraction : 0,
                                child: Container(
                                  height: 2.h,
                                  decoration: BoxDecoration(
                                    color: AppColor.red,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 2.h,
                            color: AppColor.appLightColor,
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: negative ? 0 : fraction,
                                child: Container(
                                  height: 2.h,
                                  decoration: BoxDecoration(
                                    color: widget.accentColor,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  2.width,
                  SizedBox(
                    width: 15.w,
                    child: Text(
                      _decimalFormat.format(balance),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 2.4.sp,
                        fontWeight: FontWeight.bold,
                        color: negative ? AppColor.red : AppColor.appDarkColor,
                      ),
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

  // ------------------------------------------------------------ Recent activity

  String _formatMovementDate(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      return DateFormat('dd MMM').format(DateTime.parse(raw));
    } catch (_) {
      return raw.split(" ").first;
    }
  }

  Widget _recentMovementsList(List<RecentMovement> movements) {
    if (movements.isEmpty) {
      return _inlineEmpty("No recent activity");
    }
    return Column(
      children: movements.map((m) {
        final isIn = m.isIn;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.9.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 1.5.w,
                height: 1.5.w,
                margin: EdgeInsets.only(top: 0.8.h, right: 2.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isIn ? AppColor.green : AppColor.red,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (m.itemName ?? "").trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 3.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "${m.documentType ?? ''} · ${m.storeName ?? ''}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 2.4.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
              2.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isIn ? '+' : '-'}${_decimalFormat.format(m.qty ?? 0)}",
                    style: TextStyle(
                      fontSize: 3.sp,
                      fontWeight: FontWeight.bold,
                      color: isIn ? AppColor.green : AppColor.red,
                    ),
                  ),
                  Text(
                    _formatMovementDate(m.date),
                    style: TextStyle(fontSize: 2.3.sp, color: AppColor.grey),
                  ),
                ],
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
    Widget? trailing,
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
          Row(
            children: [
              Expanded(
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
                  ],
                ),
              ),
              ?trailing,
            ],
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Custom3DLoader(
          color: widget.accentColor,
          label: "Loading dashboard…",
        ),
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
