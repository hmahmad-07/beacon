import 'dart:math' as math;

import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_dashboard_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_dashboard_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_expiry_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_items_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stock_report_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stores_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_ui.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Inventory home: a live overview of every store, what needs attention,
/// and the inventory reports.
class InventoryHubView extends StatefulWidget {
  const InventoryHubView({
    super.key,
    required this.siteName,
    required this.accentColor,
    this.siteImage,
  });

  final String siteName;
  final Color accentColor;
  final String? siteImage;

  @override
  State<InventoryHubView> createState() => _InventoryHubViewState();
}

class _InventoryHubViewState extends State<InventoryHubView> {
  Color get _accent => widget.accentColor;

  /// True once the first load has finished; until then the whole screen
  /// shows one loader instead of half-filled cards.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Loads the overview. It always covers every store, so a store picked
  /// earlier on the dashboard is cleared here.
  Future<void> _load() async {
    final c = context.read<WMSController>();
    c.ensureStoresLoaded(context);
    await Future.wait([
      c.dashboardStoreId != null
          ? c.setDashboardStore(context, null)
          : c.getDashboard(context),
      c.getExpiryReport(context),
    ]);
    if (mounted && !_ready) setState(() => _ready = true);
  }

  /// Opens [page]; when the dashboard was switched to one store meanwhile,
  /// the overview is loaded again for every store.
  Future<void> _open(Widget page) async {
    await pushInSite(_accent, page);
    if (!mounted) return;
    final c = context.read<WMSController>();
    if (c.dashboardStoreId != null || c.dashboardModel == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return SiteScope.wrap(
      accent: _accent,
      child: Builder(
        builder: (context) => Consumer<WMSController>(
          builder: (context, c, _) {
            final loading =
                !_ready ||
                c.isDashboardLoading ||
                c.isExpiryLoading ||
                (c.isStoresLoading && c.activeStores.isEmpty);

            return RefreshIndicator(
              color: _accent,
              onRefresh: _load,
              child: loading
                  ? const InventoryLoadingView(
                      key: ValueKey('hub-loading'),
                      icon: BoxIcons.bx_package,
                      label: "Loading inventory…",
                    )
                  : AnimationLimiter(
                      key: const ValueKey('hub-content'),
                      child: _content(c),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _content(WMSController c) {
    final data = c.dashboardModel?.data;
    final kpis = data?.kpis;
    final stores = c.activeStores.length;
    final expiryFiltered = c.expiryStoreId != null || c.expiryDateRange != null;
    final expiry = expiryFiltered ? null : c.expiryModel?.summary;
    final zeroStock = kpis?.negativeStockItems ?? 0;
    final expired = expiry?.expired ?? 0;
    final soon = expiry?.expiringSoon ?? 0;

    var i = 0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
      children: [
        invEnter(i++, _hero(data, stores)),
        2.4.height,
        if ((data?.movementLast6Months ?? const []).isNotEmpty)
          invEnter(i++, _trendPanel(data!.movementLast6Months!)),
        1.height,
        invEnter(i++, const SiteSectionTitle("Needs attention")),
        if (zeroStock > 0)
          invEnter(
            i++,
            InventoryAlertTile(
              heroTag: 'inv-alert-zero',
              icon: BoxIcons.bxs_error,
              color: InventoryPalette.stockOut,
              title: "Zero or below stock",
              subtitle: "Issued more than received, restock or check",
              count: invWhole(zeroStock),
              onTap: () => _open(
                InventoryStockReportView(
                  accentColor: _accent,
                  initialLowStockOnly: true,
                  heroTag: 'inv-alert-zero',
                ),
              ),
            ),
          ),
        if (expired > 0)
          invEnter(
            i++,
            InventoryAlertTile(
              heroTag: 'inv-alert-expired',
              icon: BoxIcons.bxs_calendar_x,
              color: InventoryPalette.stockOut,
              title: "Expired batches",
              subtitle: "Past their expiry date, still in stock",
              count: invWhole(expired),
              onTap: () => _open(
                InventoryExpiryView(
                  accentColor: _accent,
                  heroTag: 'inv-alert-expired',
                ),
              ),
            ),
          ),
        if (soon > 0)
          invEnter(
            i++,
            InventoryAlertTile(
              heroTag: 'inv-alert-soon',
              icon: Icons.hourglass_bottom_rounded,
              color: InventoryPalette.warning,
              title: "Expiring soon",
              subtitle: "Batches close to their expiry date",
              count: invWhole(soon),
              onTap: () => _open(
                InventoryExpiryView(
                  accentColor: _accent,
                  heroTag: 'inv-alert-soon',
                ),
              ),
            ),
          ),
        if (zeroStock == 0 && expired == 0 && soon == 0)
          invEnter(
            i++,
            InventoryAlertTile(
              icon: BoxIcons.bxs_check_shield,
              color: InventoryPalette.stockIn,
              title: "All clear",
              subtitle: "No negative stock or expiring batches",
            ),
          ),
        1.6.height,
        invEnter(i++, const SiteSectionTitle("Reports")),
        _moduleGrid(
          startIndex: i,
          items: kpis?.totalItems,
          zeroStock: zeroStock,
          expiring: expiry == null ? null : expired + soon,
          stores: stores,
        ),
      ],
    );
  }

  // ─────────────────────────── Overview hero

  Widget _hero(InventoryDashboardData? data, int stores) {
    final kpis = data?.kpis;
    void openDashboard() => _open(InventoryDashboardView(accentColor: _accent));

    return InventoryHero(
      heroTag: kInventoryHeroTag,
      icon: BoxIcons.bx_package,
      eyebrow: "${widget.siteName} · $stores stores",
      title: "Inventory",
      subtitle: "Stock, movement and expiry across every store",
      onTap: openDashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryHeroStats(
            stats: [
              ("Stock value", kpis == null ? "—" : invCompact(kpis.stockValue)),
              ("Items", kpis == null ? "—" : invWhole(kpis.totalItems)),
              (
                "Categories",
                data == null ? "—" : "${data.valueByCategory?.length ?? 0}",
              ),
            ],
          ),
          1.8.height,
          Row(
            children: [
              Expanded(
                child: Text(
                  "Charts for value, stores and stock",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 2.9.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              InventoryHeroButton(
                label: "Open dashboard",
                onTap: openDashboard,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Received and issued over the last six months, with a tap readout.
  Widget _trendPanel(List<MonthlyMovement> months) {
    final received = months.fold<num>(0, (s, m) => s + (m.received ?? 0));
    final issued = months.fold<num>(0, (s, m) => s + (m.issued ?? 0));
    final net = received - issued;
    final values = [
      for (final m in months) ...[
        (m.received ?? 0).toDouble(),
        (m.issued ?? 0).toDouble(),
      ],
    ];
    final maxV = values.fold<double>(0, math.max);
    final step = invNiceStep(maxV);
    // Round top with a little headroom above the highest point.
    final top = maxV <= 0 ? 4.0 : ((maxV * 1.08) / step).ceil() * step;
    final lastIndex = months.length - 1;

    String monthName(String? raw, String pattern) {
      if (raw == null || raw.isEmpty) return "";
      try {
        return DateFormat(pattern).format(DateFormat('yyyy-MM').parse(raw));
      } catch (_) {
        return raw;
      }
    }

    LineChartBarData line(
      Color color,
      num? Function(MonthlyMovement) pick,
      double t, {
      bool area = false,
    }) => LineChartBarData(
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.4,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, bar) => spot.x == lastIndex,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: Colors.white,
          strokeWidth: 2.6,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: area,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      spots: [
        for (var i = 0; i < months.length; i++)
          FlSpot(i.toDouble(), (pick(months[i]) ?? 0).toDouble() * t),
      ],
    );

    return InventoryPanel(
      margin: EdgeInsets.zero,
      icon: Icons.show_chart_rounded,
      title: "Stock movement",
      subtitle: "Received and issued, last 6 months",
      trailing: InventoryLink(
        label: "Details",
        onTap: () => _open(InventoryDashboardView(accentColor: _accent)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InventoryFigure(
                  label: "Received",
                  value: invCompact(received),
                  icon: Icons.square_rounded,
                  iconColor: InventoryPalette.received,
                ),
              ),
              Expanded(
                child: InventoryFigure(
                  label: "Issued",
                  value: invCompact(issued),
                  icon: Icons.square_rounded,
                  iconColor: InventoryPalette.issued,
                ),
              ),
              InventoryFigure(
                label: "Net change",
                value:
                    "${net > 0
                        ? '+'
                        : net < 0
                        ? '−'
                        : ''}${invCompact(net.abs())}",
                color: net < 0
                    ? InventoryPalette.stockOut
                    : InventoryPalette.stockIn,
                alignEnd: true,
              ),
            ],
          ),
          2.height,
          SizedBox(
            height: 19.h,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('trend_${months.length}_$maxV'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => LineChart(
                LineChartData(
                  minX: 0,
                  maxX: lastIndex.toDouble(),
                  minY: 0,
                  maxY: top,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: InventoryPalette.grid,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 9.w,
                        interval: step,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const SizedBox();
                          return Padding(
                            padding: EdgeInsets.only(right: 1.5.w),
                            child: Text(
                              invCompact(value),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 2.5.sp,
                                color: AppColor.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 3.4.h,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if (value != idx.toDouble() ||
                              idx < 0 ||
                              idx > lastIndex) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 0.8.h),
                            child: Text(
                              monthName(months[idx].month, 'MMM'),
                              style: TextStyle(
                                fontSize: 2.6.sp,
                                fontWeight: idx == lastIndex
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: idx == lastIndex
                                    ? InventoryPalette.deep
                                    : AppColor.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (bar, indexes) => [
                      for (final _ in indexes)
                        TouchedSpotIndicatorData(
                          FlLine(
                            color: AppColor.grey.withValues(alpha: 0.35),
                            strokeWidth: 1.4,
                            dashArray: [3, 3],
                          ),
                          FlDotData(
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                                  radius: 4.5,
                                  color: Colors.white,
                                  strokeWidth: 2.8,
                                  strokeColor: bar.color ?? _accent,
                                ),
                          ),
                        ),
                    ],
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColor.appDarkColor,
                      tooltipBorderRadius: BorderRadius.circular(10),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) => [
                        for (final (k, s) in spots.indexed)
                          LineTooltipItem(
                            k == 0
                                ? "${monthName(months[s.x.round()].month, 'MMM yyyy')}\n"
                                : "",
                            TextStyle(
                              fontSize: 2.6.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            children: [
                              TextSpan(
                                text:
                                    "${s.barIndex == 0 ? 'Received' : 'Issued'} "
                                    "${invQty(s.y)}",
                                style: TextStyle(
                                  fontSize: 3.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    line(
                      InventoryPalette.received,
                      (m) => m.received,
                      t,
                      area: true,
                    ),
                    line(InventoryPalette.issued, (m) => m.issued, t),
                  ],
                ),
                duration: Duration.zero,
              ),
            ),
          ),
          1.2.height,
          const Wrap(
            spacing: 16,
            children: [
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
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Reports

  Widget _moduleGrid({
    required int startIndex,
    required int? items,
    required int zeroStock,
    required int? expiring,
    required int stores,
  }) {
    final tiles = [
      _ModuleTile(
        heroTag: 'inv-module-items',
        icon: BoxIcons.bxs_box,
        title: "Items",
        subtitle: "Catalogue and stock per item",
        metric: items == null ? null : "${invWhole(items)} items",
        onTap: () => _open(
          InventoryItemsView(accentColor: _accent, heroTag: 'inv-module-items'),
        ),
      ),
      _ModuleTile(
        heroTag: 'inv-module-stock',
        icon: BoxIcons.bxs_bar_chart_alt_2,
        title: "Stock report",
        subtitle: "In, out and balance by store",
        metric: zeroStock > 0 ? "$zeroStock at zero or below" : null,
        metricColor: InventoryPalette.stockOut,
        onTap: () => _open(
          InventoryStockReportView(
            accentColor: _accent,
            heroTag: 'inv-module-stock',
          ),
        ),
      ),
      _ModuleTile(
        heroTag: 'inv-module-expiry',
        icon: BoxIcons.bxs_calendar_x,
        title: "Expiry",
        subtitle: "Batches by expiry date",
        metric: expiring == null || expiring == 0
            ? null
            : "$expiring need a look",
        metricColor: InventoryPalette.warning,
        onTap: () => _open(
          InventoryExpiryView(
            accentColor: _accent,
            heroTag: 'inv-module-expiry',
          ),
        ),
      ),
      _ModuleTile(
        heroTag: 'inv-module-stores',
        icon: BoxIcons.bxs_store,
        title: "Stores",
        subtitle: "Every active store",
        metric: stores == 0 ? null : "$stores active",
        onTap: () => _open(
          InventoryStoresView(
            accentColor: _accent,
            heroTag: 'inv-module-stores',
          ),
        ),
      ),
    ];
    return SiteStatGrid(
      children: [
        for (final (i, t) in tiles.indexed) invEnter(startIndex + i, t),
      ],
    );
  }
}

/// Square report tile: gradient icon, title, note and a live figure.
class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.heroTag,
    this.metric,
    this.metricColor,
  });

  final Object heroTag;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? metric;
  final Color? metricColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return SiteCard(
      onTap: onTap,
      padding: EdgeInsets.all(3.8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              invHero(
                heroTag,
                SiteIconBadge(icon, size: 11.w, radius: 14, color: accent),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 4.6.w,
                color: accent.withValues(alpha: 0.7),
              ),
            ],
          ),
          1.6.height,
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 3.9.sp,
              fontWeight: FontWeight.w800,
              color: AppColor.appDarkColor,
            ),
          ),
          0.3.height,
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 2.8.sp,
              height: 1.25,
              color: AppColor.grey,
            ),
          ),
          1.2.height,
          SitePill.tint(
            metric ?? "Open",
            metric == null ? accent : (metricColor ?? accent),
          ),
        ],
      ),
    );
  }
}
