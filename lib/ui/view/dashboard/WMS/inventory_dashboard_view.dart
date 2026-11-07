import 'dart:math' as math;

import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_dashboard_model.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart'
    show InventoryStoreBalance;
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stock_report_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_ui.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Inventory dashboard: stock value, six months of movement, value by
/// category, balance by store, negative stock and the latest movements.
/// Charts respond to taps: pick a month or a category to see its figures.
class InventoryDashboardView extends StatefulWidget {
  const InventoryDashboardView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryDashboardView> createState() => _InventoryDashboardViewState();
}

class _InventoryDashboardViewState extends State<InventoryDashboardView> {
  /// 0 = received vs issued, 1 = net change.
  int _movementMode = 0;

  /// Selected month (index into the movement list); defaults to the latest.
  int? _month;

  /// Selected category (index into the shown categories), or none.
  int? _category;

  /// True once data for this screen is in. Opened from the inventory home,
  /// the overview loaded there is shown at once (so the overview card can
  /// fly in); otherwise the dashboard loads first.
  late bool _ready;

  @override
  void initState() {
    super.initState();
    final c = context.read<WMSController>();
    _ready = c.dashboardModel?.data != null && !c.isDashboardLoading;
    if (!_ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _month = null;
      _category = null;
    });
    final controller = context.read<WMSController>();
    // The store chip shows a name, so the store list must be loaded.
    controller.ensureStoresLoaded(context);
    await controller.getDashboard(context);
    if (mounted && !_ready) setState(() => _ready = true);
  }

  void _openLowStock() => context.pushSite(
    InventoryStockReportView(
      accentColor: widget.accentColor,
      initialLowStockOnly: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Inventory Dashboard"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final data = controller.dashboardModel?.data;
          final loading = !_ready || controller.isDashboardLoading;

          return RefreshIndicator(
            color: widget.accentColor,
            onRefresh: _fetch,
            child: loading
                ? const InventoryLoadingView(
                    key: ValueKey('dash-loading'),
                    icon: BoxIcons.bxs_dashboard,
                    label: "Loading dashboard…",
                  )
                : AnimationLimiter(
                    key: ValueKey('dash-${controller.dashboardStoreId}'),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
                      children: [
                        invEnter(0, _toolbar(controller)),
                        2.height,
                        if (data == null)
                          SiteEmptyState(
                            icon: BoxIcons.bxs_dashboard,
                            title: "No dashboard data",
                            message: "Pull down to load the dashboard again.",
                            onRetry: _fetch,
                          )
                        else
                          ..._content(controller, data),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _toolbar(WMSController controller) {
    return Row(
      children: [
        Flexible(
          child: InventoryStoreChip(
            selectedStoreId: controller.dashboardStoreId,
            accentColor: widget.accentColor,
            onChanged: (id) {
              setState(() {
                _month = null;
                _category = null;
              });
              controller.setDashboardStore(context, id);
            },
          ),
        ),
        2.width,
        SitePill.tint(
          "Last 6 months",
          widget.accentColor,
          icon: Icons.date_range_rounded,
        ),
      ],
    );
  }

  List<Widget> _content(WMSController c, InventoryDashboardData data) {
    final months = data.movementLast6Months ?? const <MonthlyMovement>[];
    var i = 1;
    return [
      // The overview card is the Hero target, so it does not slide.
      _hero(c, data),
      2.4.height,
      _kpis(data, months),
      2.4.height,
      invEnter(i++ + 4, _movementPanel(months)),
      invEnter(i++ + 4, _categoryPanel(data.valueByCategory ?? [])),
      invEnter(i++ + 4, _storePanel(data.balanceByStore ?? [])),
      invEnter(i++ + 4, _negativePanel(data.negativeStock ?? [])),
      invEnter(i++ + 4, _activityPanel(data.recentMovements ?? [])),
    ];
  }

  // ─────────────────────────── Hero and figures

  Widget _hero(WMSController c, InventoryDashboardData data) {
    final kpis = data.kpis;
    final storeName = c.storeNameById(c.dashboardStoreId) ?? kAllStoresLabel;
    final stores = (data.balanceByStore ?? [])
        .where((s) => (s.balance ?? 0) != 0)
        .length;
    return InventoryHero(
      heroTag: kInventoryHeroTag,
      icon: BoxIcons.bxs_wallet,
      eyebrow: storeName,
      title: "PKR ${invWhole(kpis?.stockValue)}",
      titleSize: 6.4.sp,
      subtitle: "Value of the stock on hand",
      child: InventoryHeroStats(
        stats: [
          ("Items", invWhole(kpis?.totalItems)),
          ("Zero or below", invWhole(kpis?.negativeStockItems)),
          ("Stores with stock", "$stores"),
        ],
      ),
    );
  }

  Widget _kpis(InventoryDashboardData data, List<MonthlyMovement> months) {
    final received = months.fold<num>(0, (s, m) => s + (m.received ?? 0));
    final issued = months.fold<num>(0, (s, m) => s + (m.issued ?? 0));
    final net = received - issued;
    final perMonth = months.isEmpty ? 0 : received / months.length;
    final zero = data.kpis?.negativeStockItems ?? 0;
    final tiles = [
      SiteStatTile(
        icon: Icons.south_west_rounded,
        color: InventoryPalette.received,
        value: invCompact(received),
        label: "Received in 6 months",
        caption: "About ${invCompact(perMonth)} a month",
      ),
      SiteStatTile(
        icon: Icons.north_east_rounded,
        color: InventoryPalette.issued,
        value: invCompact(issued),
        label: "Issued in 6 months",
        caption: invPercent(issued, received == 0 ? 1 : received) == "0%"
            ? null
            : "${invPercent(issued, received == 0 ? 1 : received)} of received",
      ),
      SiteStatTile(
        icon: net >= 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: net >= 0 ? InventoryPalette.stockIn : InventoryPalette.stockOut,
        value:
            "${net > 0
                ? '+'
                : net < 0
                ? '−'
                : ''}${invCompact(net.abs())}",
        label: "Net change",
        caption: "Received minus issued",
      ),
      SiteStatTile(
        icon: BoxIcons.bxs_error,
        color: InventoryPalette.stockOut,
        value: invWhole(zero),
        label: "Zero or below stock",
        caption: zero > 0 ? "Tap to review" : "Nothing to fix",
        onTap: zero > 0 ? _openLowStock : null,
      ),
    ];
    return SiteStatGrid(
      children: [for (final (i, t) in tiles.indexed) invEnter(1 + i, t)],
    );
  }

  // ─────────────────────────── Movement

  String _monthShort(String? raw) => _formatMonth(raw, 'MMM');
  String _monthLong(String? raw) => _formatMonth(raw, 'MMMM yyyy');

  // API months are "yyyy-MM".
  String _formatMonth(String? raw, String pattern) {
    if (raw == null || raw.isEmpty) return "";
    try {
      return DateFormat(pattern).format(DateFormat('yyyy-MM').parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Widget _movementPanel(List<MonthlyMovement> months) {
    return InventoryPanel(
      icon: Icons.stacked_bar_chart_rounded,
      title: "Stock movement",
      subtitle: "Tap a month to see its figures",
      child: months.isEmpty
          ? _inlineEmpty("No movement in the last 6 months")
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SiteSegmented(
                  labels: const ["Received vs issued", "Net change"],
                  selected: _movementMode,
                  onChanged: (v) => setState(() => _movementMode = v),
                ),
                1.8.height,
                _movementReadout(months),
                2.height,
                SizedBox(
                  height: 24.h,
                  child: _movementMode == 0
                      ? _compareChart(months)
                      : _netChart(months),
                ),
                1.4.height,
                Wrap(
                  spacing: 4.w,
                  runSpacing: 0.8.h,
                  children: _movementMode == 0
                      ? const [
                          InventoryLegendDot(
                            color: InventoryPalette.received,
                            label: "Received",
                            square: true,
                          ),
                          InventoryLegendDot(
                            color: InventoryPalette.issued,
                            label: "Issued",
                            square: true,
                          ),
                        ]
                      : [
                          InventoryLegendDot(
                            color: InventoryPalette.received,
                            label: "More received",
                            square: true,
                          ),
                          InventoryLegendDot(
                            color: InventoryPalette.stockOut,
                            label: "More issued",
                            square: true,
                          ),
                        ],
                ),
              ],
            ),
    );
  }

  int _selectedMonth(List<MonthlyMovement> months) =>
      (_month ?? months.length - 1).clamp(0, months.length - 1);

  Widget _movementReadout(List<MonthlyMovement> months) {
    final m = months[_selectedMonth(months)];
    final received = m.received ?? 0;
    final issued = m.issued ?? 0;
    final net = received - issued;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.6.w, vertical: 1.4.h),
      decoration: BoxDecoration(
        color: InventoryPalette.wash,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthLong(m.month),
            style: TextStyle(
              fontSize: 3.1.sp,
              fontWeight: FontWeight.w800,
              color: InventoryPalette.deep,
            ),
          ),
          1.height,
          Row(
            children: [
              Expanded(
                child: InventoryFigure(
                  label: "Received",
                  value: invQty(received),
                  icon: Icons.square_rounded,
                  iconColor: InventoryPalette.received,
                ),
              ),
              Expanded(
                child: InventoryFigure(
                  label: "Issued",
                  value: invQty(issued),
                  icon: Icons.square_rounded,
                  iconColor: InventoryPalette.issued,
                ),
              ),
              Expanded(
                child: InventoryFigure(
                  label: "Net",
                  value:
                      "${net > 0
                          ? '+'
                          : net < 0
                          ? '−'
                          : ''}${invQty(net.abs())}",
                  color: net < 0
                      ? InventoryPalette.stockOut
                      : AppColor.appDarkColor,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarTouchData _barTouch() => BarTouchData(
    enabled: true,
    handleBuiltInTouches: false,
    touchCallback: (event, response) {
      final spot = response?.spot;
      if (!event.isInterestedForInteractions || spot == null) return;
      if (spot.touchedBarGroupIndex != _month) {
        setState(() => _month = spot.touchedBarGroupIndex);
      }
    },
  );

  FlTitlesData _titles(
    List<MonthlyMovement> months,
    double interval,
    int selected,
  ) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 10.w,
          interval: interval,
          getTitlesWidget: (value, meta) {
            if (value == meta.max || value == meta.min && value != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(right: 1.5.w),
              child: Text(
                invCompact(value),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 3.6.h,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx < 0 || idx >= months.length) return const SizedBox();
            final on = idx == selected;
            return Padding(
              padding: EdgeInsets.only(top: 0.9.h),
              child: Text(
                _monthShort(months[idx].month),
                style: TextStyle(
                  fontSize: 2.7.sp,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                  color: on ? InventoryPalette.deep : AppColor.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  FlGridData _grid(double interval) => FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: interval,
    getDrawingHorizontalLine: (value) => FlLine(
      color: InventoryPalette.grid,
      strokeWidth: 1,
      dashArray: value == 0 ? null : [4, 4],
    ),
  );

  double _niceInterval(double max) {
    if (max <= 0) return 1;
    final raw = max / 4;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final norm = raw / mag;
    final step = norm <= 1
        ? 1
        : norm <= 2
        ? 2
        : norm <= 2.5
        ? 2.5
        : norm <= 5
        ? 5
        : 10;
    return step * mag;
  }

  Widget _compareChart(List<MonthlyMovement> months) {
    final selected = _selectedMonth(months);
    final maxVal = months.fold<double>(
      0,
      (m, e) => math.max(
        m,
        math.max((e.received ?? 0).toDouble(), (e.issued ?? 0).toDouble()),
      ),
    );
    final interval = _niceInterval(maxVal);
    final maxY = (maxVal / interval).ceil() * interval;
    final rodWidth = math.min(4.2.w, 60.w / months.length / 2.4);

    return TweenAnimationBuilder<double>(
      key: ValueKey('compare_${months.length}_$maxVal'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 10 : maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: _barTouch(),
          titlesData: _titles(months, interval, selected),
          gridData: _grid(interval),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  _rod(
                    (months[i].received ?? 0) * t,
                    InventoryPalette.received,
                    rodWidth,
                    i == selected,
                  ),
                  _rod(
                    (months[i].issued ?? 0) * t,
                    InventoryPalette.issued,
                    rodWidth,
                    i == selected,
                  ),
                ],
              ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }

  BarChartRodData _rod(num value, Color color, double width, bool selected) {
    return BarChartRodData(
      toY: value.toDouble(),
      width: width,
      color: selected ? color : color.withValues(alpha: 0.38),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(width / 2.6),
        bottom: const Radius.circular(2),
      ),
    );
  }

  Widget _netChart(List<MonthlyMovement> months) {
    final selected = _selectedMonth(months);
    final nets = [
      for (final m in months) ((m.received ?? 0) - (m.issued ?? 0)).toDouble(),
    ];
    final maxAbs = nets.fold<double>(0, (m, v) => math.max(m, v.abs()));
    final interval = _niceInterval(maxAbs == 0 ? 1 : maxAbs);
    final hasNegative = nets.any((v) => v < 0);
    final hasPositive = nets.any((v) => v > 0);
    final top = hasPositive ? (maxAbs / interval).ceil() * interval : interval;
    final bottom = hasNegative ? -(maxAbs / interval).ceil() * interval : 0.0;
    final rodWidth = math.min(6.w, 60.w / months.length / 1.6);

    return TweenAnimationBuilder<double>(
      key: ValueKey('net_${months.length}_$maxAbs'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => BarChart(
        BarChartData(
          maxY: top,
          minY: bottom,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: _barTouch(),
          titlesData: _titles(months, interval, selected),
          gridData: _grid(interval),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: AppColor.appLightColor,
                strokeWidth: 1.2,
              ),
            ],
          ),
          barGroups: [
            for (var i = 0; i < nets.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: nets[i] * t,
                    width: rodWidth,
                    color:
                        (nets[i] < 0
                                ? InventoryPalette.stockOut
                                : InventoryPalette.received)
                            .withValues(alpha: i == selected ? 1 : 0.38),
                    borderRadius: BorderRadius.circular(rodWidth / 3),
                  ),
                ],
              ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }

  // ─────────────────────────── Categories

  /// The five largest categories plus "Other" for the rest. Only positive
  /// values can be drawn as slices; negative ones are listed separately.
  List<(String, double, Color)> _categories(List<CategoryValue> raw) {
    final positive = raw.where((c) => (c.value ?? 0) > 0).toList()
      ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));
    final palette = InventoryPalette.categories;
    final shown = <(String, double, Color)>[
      for (var i = 0; i < positive.length && i < palette.length; i++)
        (
          (positive[i].category ?? "Uncategorised").trim(),
          (positive[i].value ?? 0).toDouble(),
          palette[i],
        ),
    ];
    if (positive.length > palette.length) {
      final rest = positive
          .skip(palette.length)
          .fold<double>(0, (s, c) => s + (c.value ?? 0).toDouble());
      shown.add((
        "Other (${positive.length - palette.length})",
        rest,
        InventoryPalette.other,
      ));
    }
    return shown;
  }

  /// Categories whose value is below zero (more issued than received).
  List<(String, double)> _negativeCategories(List<CategoryValue> raw) {
    final negative = raw.where((c) => (c.value ?? 0) < 0).toList()
      ..sort((a, b) => (a.value ?? 0).compareTo(b.value ?? 0));
    return [
      for (final c in negative)
        ((c.category ?? "Uncategorised").trim(), (c.value ?? 0).toDouble()),
    ];
  }

  Widget _categoryPanel(List<CategoryValue> raw) {
    final cats = _categories(raw);
    final negatives = _negativeCategories(raw);
    // Shares are of the positive value, which is what the ring shows.
    final positiveTotal = cats.fold<double>(0, (s, c) => s + c.$2);
    final negativeTotal = negatives.fold<double>(0, (s, c) => s + c.$2);
    // The total is every category added up, negative ones included.
    final total = positiveTotal + negativeTotal;
    final sel = _category != null && _category! < cats.length
        ? _category
        : null;

    return InventoryPanel(
      icon: Icons.donut_large_rounded,
      title: "Stock value by category",
      subtitle: "Tap a slice or a row to focus on it",
      child: cats.isEmpty && negatives.isEmpty
          ? _inlineEmpty("No category values yet")
          : Column(
              children: [
                if (cats.isNotEmpty)
                  SizedBox(
                    height: 25.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          key: ValueKey('donut_${cats.length}_$positiveTotal'),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, _) => PieChart(
                            PieChartData(
                              sectionsSpace: 2.5,
                              centerSpaceRadius: 15.w,
                              startDegreeOffset: -90 + (1 - t) * -120,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  if (event is! FlTapUpEvent) return;
                                  final idx = response
                                      ?.touchedSection
                                      ?.touchedSectionIndex;
                                  if (idx == null || idx < 0) return;
                                  setState(
                                    () => _category = _category == idx
                                        ? null
                                        : idx,
                                  );
                                },
                              ),
                              sections: [
                                for (var i = 0; i < cats.length; i++)
                                  PieChartSectionData(
                                    value: math.max(cats[i].$2 * t, 0.0001),
                                    color: sel == null || sel == i
                                        ? cats[i].$3
                                        : cats[i].$3.withValues(alpha: 0.28),
                                    radius: sel == i ? 9.w : 7.w,
                                    title: "",
                                  ),
                              ],
                            ),
                            duration: const Duration(milliseconds: 250),
                          ),
                        ),
                        _donutCenter(cats, total, positiveTotal, sel),
                      ],
                    ),
                  ),
                1.6.height,
                for (var i = 0; i < cats.length; i++)
                  _categoryRow(cats[i], positiveTotal, i, sel),
                for (final n in negatives) _negativeCategoryRow(n),
                if (negatives.isNotEmpty) ...[
                  0.6.height,
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.scaffold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Total value ${invWhole(total)} = "
                      "${invWhole(positiveTotal)} in the ring "
                      "minus ${invWhole(negativeTotal.abs())} "
                      "from categories below zero.",
                      style: TextStyle(
                        fontSize: 2.8.sp,
                        height: 1.35,
                        color: AppColor.darkGrey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _donutCenter(
    List<(String, double, Color)> cats,
    double total,
    double positiveTotal,
    int? sel,
  ) {
    final value = sel == null ? total : cats[sel].$2;
    final label = sel == null ? "Total value" : cats[sel].$1;
    return SizedBox(
      width: 26.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${value < 0 ? '−' : ''}${invCompact(value.abs())}",
              style: TextStyle(
                fontSize: 5.6.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 2.6.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.grey,
            ),
          ),
          if (sel != null)
            Text(
              invPercent(value, positiveTotal),
              style: TextStyle(
                fontSize: 2.8.sp,
                fontWeight: FontWeight.w800,
                color: InventoryPalette.deep,
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryRow(
    (String, double, Color) cat,
    double total,
    int index,
    int? sel,
  ) {
    final selected = sel == index;
    final share = total <= 0 ? 0.0 : cat.$2 / total;
    return SitePressable(
      onTap: () => setState(() => _category = selected ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 0.6.h),
        padding: EdgeInsets.symmetric(horizontal: 2.6.w, vertical: 1.1.h),
        decoration: BoxDecoration(
          color: selected ? InventoryPalette.wash : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 2.8.w,
                  height: 2.8.w,
                  decoration: BoxDecoration(
                    color: cat.$3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                2.5.width,
                Expanded(
                  child: Text(
                    cat.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.3.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ),
                Text(
                  invWhole(cat.$2),
                  style: TextStyle(
                    fontSize: 3.3.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.appDarkColor,
                  ),
                ),
                SizedBox(
                  width: 13.w,
                  child: Text(
                    invPercent(cat.$2, total),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 2.9.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.grey,
                    ),
                  ),
                ),
              ],
            ),
            0.8.height,
            InventoryMeter(value: share, color: cat.$3, height: 0.7.h),
          ],
        ),
      ),
    );
  }

  /// A category below zero: listed with its value, not drawn in the ring.
  Widget _negativeCategoryRow((String, double) cat) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.6.w, vertical: 1.1.h),
        child: Row(
          children: [
            Icon(
              Icons.south_rounded,
              size: 3.6.w,
              color: InventoryPalette.stockOut,
            ),
            1.7.width,
            Expanded(
              child: Text(
                cat.$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.3.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.appDarkColor,
                ),
              ),
            ),
            Text(
              "−${invWhole(cat.$2.abs())}",
              style: TextStyle(
                fontSize: 3.3.sp,
                fontWeight: FontWeight.w800,
                color: InventoryPalette.stockOut,
              ),
            ),
            SizedBox(
              width: 13.w,
              child: Text(
                "Below 0",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 2.7.sp,
                  fontWeight: FontWeight.w600,
                  color: InventoryPalette.stockOut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Stores

  Widget _storePanel(List<InventoryStoreBalance> balances) {
    final rows = balances.where((s) => (s.balance ?? 0) != 0).toList()
      ..sort((a, b) => (b.balance ?? 0).compareTo(a.balance ?? 0));
    final maxAbs = rows.fold<double>(
      0,
      (m, s) => math.max(m, (s.balance ?? 0).abs().toDouble()),
    );
    final positiveTotal = rows.fold<double>(
      0,
      (s, r) => s + math.max(0, (r.balance ?? 0).toDouble()),
    );

    return InventoryPanel(
      icon: BoxIcons.bxs_store,
      title: "Balance by store",
      subtitle: "Quantity on hand in each store",
      child: rows.isEmpty
          ? _inlineEmpty("No store has stock right now")
          : Column(
              children: [
                for (final (i, s) in rows.indexed) ...[
                  if (i > 0) 1.6.height,
                  _storeRow(s, maxAbs, positiveTotal),
                ],
              ],
            ),
    );
  }

  Widget _storeRow(InventoryStoreBalance s, double maxAbs, double total) {
    final balance = (s.balance ?? 0).toDouble();
    final negative = balance < 0;
    final color = negative
        ? InventoryPalette.stockOut
        : InventoryPalette.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InventoryAvatar(name: s.storeName ?? "", size: 8.w, color: color),
            2.5.width,
            Expanded(
              child: Text(
                (s.storeName ?? "").trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.3.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.appDarkColor,
                ),
              ),
            ),
            Text(
              negative ? "−${invQty(balance.abs())}" : invQty(balance),
              style: TextStyle(
                fontSize: 3.4.sp,
                fontWeight: FontWeight.w800,
                color: negative
                    ? InventoryPalette.stockOut
                    : AppColor.appDarkColor,
              ),
            ),
            SizedBox(
              width: 13.w,
              child: Text(
                negative ? "Negative" : invPercent(balance, total),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 2.7.sp,
                  fontWeight: FontWeight.w600,
                  color: negative ? InventoryPalette.stockOut : AppColor.grey,
                ),
              ),
            ),
          ],
        ),
        0.9.height,
        Padding(
          padding: EdgeInsets.only(left: 10.5.w),
          child: InventoryMeter(
            value: maxAbs <= 0 ? 0 : balance.abs() / maxAbs,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Negative stock

  Widget _negativePanel(List<NegativeStockItem> items) {
    return InventoryPanel(
      icon: Icons.trending_down_rounded,
      title: "Negative stock",
      subtitle: "Issued more than received, needs a check",
      trailing: items.isEmpty
          ? null
          : InventoryLink(label: "View all", onTap: _openLowStock),
      child: items.isEmpty
          ? _inlineEmpty("No item has negative stock")
          : Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: 2.h,
                      color: AppColor.appLightColor.withValues(alpha: 0.6),
                    ),
                  Row(
                    children: [
                      InventoryAvatar(
                        name: item.name ?? "",
                        size: 9.w,
                        color: InventoryPalette.stockOut,
                      ),
                      3.width,
                      Expanded(
                        child: Text(
                          (item.name ?? "").trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 3.3.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColor.appDarkColor,
                          ),
                        ),
                      ),
                      2.width,
                      SitePill.tint(
                        invQty(item.onHand),
                        InventoryPalette.stockOut,
                        icon: Icons.south_rounded,
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  // ─────────────────────────── Activity

  String _activityDate(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      return DateFormat('dd MMM').format(DateTime.parse(raw));
    } catch (_) {
      return raw.split(" ").first;
    }
  }

  Widget _activityPanel(List<RecentMovement> moves) {
    return InventoryPanel(
      icon: Icons.history_rounded,
      title: "Recent activity",
      subtitle: "Latest stock coming in and going out",
      child: moves.isEmpty
          ? _inlineEmpty("No recent movements")
          : Column(
              children: [
                for (final (i, m) in moves.indexed)
                  _activityRow(m, last: i == moves.length - 1),
              ],
            ),
    );
  }

  Widget _activityRow(RecentMovement m, {required bool last}) {
    final isIn = m.isIn;
    final color = isIn ? InventoryPalette.stockIn : InventoryPalette.stockOut;
    final meta = [
      if ((m.documentType ?? '').isNotEmpty) m.documentType!,
      if ((m.storeName ?? '').isNotEmpty) m.storeName!,
    ].join(" · ");

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(1.8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                  size: 4.w,
                  color: color,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: EdgeInsets.symmetric(vertical: 0.4.h),
                    color: InventoryPalette.grid,
                  ),
                ),
            ],
          ),
          3.width,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 1.8.h, top: 0.2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (m.itemName ?? "").trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.3.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  0.2.height,
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                  ),
                ],
              ),
            ),
          ),
          2.width,
          Padding(
            padding: EdgeInsets.only(top: 0.2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isIn ? '+' : '−'}${invQty(m.qty)}",
                  style: TextStyle(
                    fontSize: 3.4.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                0.2.height,
                Text(
                  _activityDate(m.date),
                  style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineEmpty(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 4.4.w, color: AppColor.grey),
          2.width,
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
            ),
          ),
        ],
      ),
    );
  }
}
