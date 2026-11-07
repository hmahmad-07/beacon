import 'dart:math' as math;

import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/inventory_dates.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_ui.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// One item: stock on hand, stock in each store, the balance over time and
/// the stock ledger (latest posting first).
class InventoryItemDetailView extends StatefulWidget {
  const InventoryItemDetailView({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.accentColor,
    this.storeId,
    this.storeName,
  });

  final String itemId;
  final String itemName;
  final Color accentColor;

  final String? storeId;
  final String? storeName;

  @override
  State<InventoryItemDetailView> createState() =>
      _InventoryItemDetailViewState();
}

class _InventoryItemDetailViewState extends State<InventoryItemDetailView> {
  Color get _accent => widget.accentColor;

  /// True once this item has loaded, so the item opened before never
  /// flashes on screen.
  bool _ready = false;

  Object get _heroTag => 'inv-item-${widget.itemId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<WMSController>().openItemDetail(
        context,
        widget.itemId,
        storeId: widget.storeId,
      );
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Item Details"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          if (!_ready || controller.isItemDetailLoading) {
            // The item's avatar flies here from the list while it loads.
            return InventoryLoadingView(
              key: const ValueKey('item-loading'),
              heroTag: _heroTag,
              leading: InventoryAvatar(
                name: widget.itemName,
                size: 17.w,
                color: _accent,
              ),
              title: widget.itemName,
              label: "Loading item…",
            );
          }
          final item = controller.itemDetailModel?.data;
          if (item == null) {
            return SiteEmptyState(
              icon: BoxIcons.bxs_box,
              title: "Item not found",
              message: "This item could not be loaded.",
              onRetry: () => controller.openItemDetail(
                context,
                widget.itemId,
                storeId: widget.storeId,
              ),
            );
          }

          final movements = item.movements ?? const <InventoryItemMovement>[];
          var i = 0;
          return AnimationLimiter(
            key: const ValueKey('item-content'),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
              children: [
                invEnter(i++, _hero(item)),
                2.4.height,
                invEnter(
                  i++,
                  InventoryPanel(
                    icon: BoxIcons.bxs_store,
                    title: "Stock by store",
                    subtitle: "Where this item is kept",
                    child: _storeBreakdown(item.stock?.byStore ?? []),
                  ),
                ),
                invEnter(
                  i++,
                  InventoryPanel(
                    icon: Icons.show_chart_rounded,
                    title: "Balance over time",
                    subtitle: "Tap and slide along the line",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ledgerFilters(controller),
                        1.8.height,
                        _balanceTrend(movements),
                      ],
                    ),
                  ),
                ),
                invEnter(
                  i++,
                  InventoryPanel(
                    icon: Icons.receipt_long_rounded,
                    title: "Stock ledger",
                    subtitle: "Every posting, latest first",
                    child: _ledger(movements),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────── Hero

  Widget _hero(InventoryItemDetail item) {
    final total = item.stock?.total ?? 0;
    final cost = item.costPrice ?? 0;
    final value = total * cost;
    final meta = [
      if ((item.type ?? '').isNotEmpty) item.type!,
      if ((item.itemClass ?? '').isNotEmpty) item.itemClass!,
    ].join(" · ");

    return InventoryHero(
      leading: invHero(
        _heroTag,
        InventoryAvatar(
          name: item.displayName.isEmpty ? widget.itemName : item.displayName,
          color: Colors.white,
          size: 12.w,
        ),
      ),
      eyebrow: meta.isEmpty ? "Item" : meta,
      title: item.displayName.isEmpty ? widget.itemName : item.displayName,
      titleSize: 5.2.sp,
      subtitle: item.modifiedDateTime == null
          ? null
          : "Updated ${InventoryDates.full(item.modifiedDateTime)} · "
                "${InventoryDates.relative(item.modifiedDateTime)}",
      pills: [
        if ((item.barcode ?? '').isNotEmpty)
          SiteBannerPill(item.barcode!, icon: Icons.qr_code_rounded),
        SiteBannerPill(
          total <= 0 ? "Out of stock" : "In stock",
          icon: total <= 0
              ? Icons.remove_shopping_cart_outlined
              : Icons.check_circle_rounded,
        ),
      ],
      child: InventoryHeroStats(
        stats: [
          ("On hand", invQty(total)),
          ("Cost price", invQty(cost)),
          ("Stock value", invCompact(value)),
        ],
      ),
    );
  }

  // ─────────────────────────── Stores

  Widget _storeBreakdown(List<InventoryStoreBalance> byStore) {
    final rows = byStore.where((s) => (s.balance ?? 0) != 0).toList()
      ..sort((a, b) => (b.balance ?? 0).compareTo(a.balance ?? 0));
    if (rows.isEmpty) return _empty("No store holds this item right now");
    final total = rows.fold<double>(
      0,
      (s, r) => s + math.max(0, (r.balance ?? 0).toDouble()),
    );
    final maxAbs = rows.fold<double>(
      0,
      (m, r) => math.max(m, (r.balance ?? 0).abs().toDouble()),
    );

    return Column(
      children: [
        for (final (i, s) in rows.indexed) ...[
          if (i > 0) 1.6.height,
          Builder(
            builder: (context) {
              final balance = (s.balance ?? 0).toDouble();
              final negative = balance < 0;
              final color = negative ? InventoryPalette.stockOut : _accent;
              return Column(
                children: [
                  Row(
                    children: [
                      InventoryAvatar(
                        name: s.storeName ?? "",
                        size: 8.w,
                        color: color,
                      ),
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
                        negative
                            ? "−${invQty(balance.abs())}"
                            : invQty(balance),
                        style: TextStyle(
                          fontSize: 3.4.sp,
                          fontWeight: FontWeight.w800,
                          color: negative ? color : AppColor.appDarkColor,
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
                            color: negative ? color : AppColor.grey,
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
            },
          ),
        ],
      ],
    );
  }

  // ─────────────────────────── Filters

  Widget _ledgerFilters(WMSController controller) {
    final range = controller.itemDetailDateRange;
    void setRange(DateTimeRange? r) => controller.setItemDetailDateRange(
      context,
      widget.itemId,
      storeId: widget.storeId,
      range: r,
    );

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: [
        _chip(
          icon: Icons.event_rounded,
          label: range == null ? "All dates" : formatRangeLabel(range),
          active: range != null,
          onTap: () async {
            final r = await CustomDateRangePicker.show(
              context,
              initialRange: range,
            );
            if (r.range != null) {
              setRange(r.range);
            } else if (r.cancelled && range != null) {
              setRange(null);
            }
          },
          onClear: range == null ? null : () => setRange(null),
        ),
        if (widget.storeId != null)
          _chip(
            icon: Icons.storefront_rounded,
            label: controller.itemDetailScopedToStore
                ? (widget.storeName ?? "Selected store")
                : "All stores",
            active: controller.itemDetailScopedToStore,
            trailingIcon: Icons.swap_horiz_rounded,
            onTap: () => controller.toggleItemDetailStoreScope(
              context,
              widget.itemId,
              storeId: widget.storeId,
            ),
          ),
      ],
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
    IconData trailingIcon = Icons.keyboard_arrow_down_rounded,
  }) {
    final color = active ? _accent : AppColor.darkGrey;
    return SitePressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.9.h),
        decoration: BoxDecoration(
          color: active ? InventoryPalette.wash : AppColor.scaffold,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active
                ? _accent.withValues(alpha: 0.35)
                : AppColor.appLightColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 4.w, color: color),
            1.5.width,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 40.w),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            1.width,
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 4.2.w, color: color),
              )
            else
              Icon(trailingIcon, size: 4.4.w, color: color),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Balance trend

  /// Postings oldest first. The API sends them oldest first with the
  /// running balance worked out in that order.
  List<InventoryItemMovement> _chronological(
    List<InventoryItemMovement> movements,
  ) {
    final indexed = movements.indexed.toList()
      ..sort((a, b) {
        final da = a.$2.dateTime;
        final db = b.$2.dateTime;
        if (da == null || db == null || da == db) return a.$1.compareTo(b.$1);
        return da.compareTo(db);
      });
    return [for (final e in indexed) e.$2];
  }

  Widget _balanceTrend(List<InventoryItemMovement> movements) {
    if (movements.isEmpty) return _empty("No postings in this period");
    final points = _chronological(
      movements,
    ).where((m) => m.runningBalance != null).toList();
    if (points.length < 2) {
      return _summaryStrip(movements);
    }
    final values = [for (final m in points) m.runningBalance!.toDouble()];
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final pad = math.max((maxV - minV) * 0.25, maxV.abs() * 0.02 + 1);
    final lastIndex = values.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryStrip(movements),
        2.height,
        SizedBox(
          height: 20.h,
          child: LineChart(
            LineChartData(
              minY: minV - pad,
              maxY: maxV + pad,
              minX: 0,
              maxX: lastIndex.toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
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
                    reservedSize: 10.w,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) {
                        return const SizedBox.shrink();
                      }
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
                    reservedSize: 3.4.h,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.round();
                      if (value != idx.toDouble() ||
                          idx < 0 ||
                          idx > lastIndex) {
                        return const SizedBox.shrink();
                      }
                      // First, last and a few in between.
                      final step = math.max(1, (lastIndex / 4).ceil());
                      if (idx != 0 && idx != lastIndex && idx % step != 0) {
                        return const SizedBox.shrink();
                      }
                      final d = points[idx].dateTime;
                      return Padding(
                        padding: EdgeInsets.only(top: 0.8.h),
                        child: Text(
                          d == null ? "" : DateFormat('d MMM').format(d),
                          style: TextStyle(
                            fontSize: 2.5.sp,
                            color: AppColor.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                getTouchedSpotIndicator: (bar, indexes) => [
                  for (final _ in indexes)
                    TouchedSpotIndicatorData(
                      FlLine(
                        color: _accent.withValues(alpha: 0.35),
                        strokeWidth: 1.5,
                        dashArray: [3, 3],
                      ),
                      FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: _accent,
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
                    for (final s in spots)
                      LineTooltipItem(
                        "${invQty(s.y)}\n",
                        TextStyle(
                          fontSize: 3.2.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: InventoryDates.full(
                              points[s.x.round()].dateTime,
                            ),
                            style: TextStyle(
                              fontSize: 2.5.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              extraLinesData: minV < 0
                  ? ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 0,
                          color: InventoryPalette.stockOut.withValues(
                            alpha: 0.5,
                          ),
                          strokeWidth: 1,
                        ),
                      ],
                    )
                  : null,
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: _accent,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, bar) => spot.x == lastIndex,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4.5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: _accent,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        _accent.withValues(alpha: 0.22),
                        _accent.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
          ),
        ),
      ],
    );
  }

  ({num? opening, num totalIn, num totalOut, num? closing}) _totals(
    List<InventoryItemMovement> movements,
  ) {
    final ordered = _chronological(movements);
    final totalIn = movements.fold<num>(0, (s, m) => s + (m.inQty ?? 0));
    final totalOut = movements.fold<num>(0, (s, m) => s + (m.outQty ?? 0));
    final first = ordered.first;
    final last = ordered.last;
    final num? opening = first.runningBalance == null
        ? null
        : first.runningBalance! - (first.inQty ?? 0) + (first.outQty ?? 0);
    return (
      opening: opening,
      totalIn: totalIn,
      totalOut: totalOut,
      closing: last.runningBalance,
    );
  }

  Widget _summaryStrip(List<InventoryItemMovement> movements) {
    final t = _totals(movements);
    final closing = t.closing;
    final tiles = [
      ("Opening", t.opening == null ? "—" : invQty(t.opening), null),
      ("In", "+${invQty(t.totalIn)}", InventoryPalette.stockIn),
      ("Out", "−${invQty(t.totalOut)}", InventoryPalette.stockOut),
      (
        "Closing",
        closing == null ? "—" : invQty(closing),
        (closing ?? 0) < 0 ? InventoryPalette.stockOut : InventoryPalette.deep,
      ),
    ];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.3.h, horizontal: 1.w),
      decoration: BoxDecoration(
        color: InventoryPalette.wash,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, t) in tiles.indexed) ...[
              if (i > 0)
                Container(width: 1, color: _accent.withValues(alpha: 0.15)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      t.$1,
                      style: TextStyle(
                        fontSize: 2.6.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.grey,
                      ),
                    ),
                    0.3.height,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        t.$2,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 3.5.sp,
                          fontWeight: FontWeight.w800,
                          color: t.$3 ?? AppColor.appDarkColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Ledger

  Widget _ledger(List<InventoryItemMovement> movements) {
    if (movements.isEmpty) return _empty("No postings in this period");

    final latestFirst = _chronological(movements).reversed.toList();
    final groups = InventoryDates.groupByDay(latestFirst, (m) => m.dateTime);
    final t = _totals(movements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.closing != null)
          _balanceRow(
            "Closing balance",
            InventoryDates.full(latestFirst.first.dateTime),
            t.closing!,
          ),
        for (final g in groups) ...[
          _dayHeader(g.key, g.value),
          for (final (i, m) in g.value.indexed)
            _postingRow(m, last: i == g.value.length - 1),
        ],
        if (t.opening != null)
          _balanceRow(
            "Opening balance",
            InventoryDates.full(latestFirst.last.dateTime),
            t.opening!,
          ),
        1.height,
        Text(
          "${movements.length} postings over ${groups.length} days",
          style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
        ),
      ],
    );
  }

  Widget _balanceRow(String label, String date, num value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.8.h),
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: AppColor.scaffold,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 4.6.w,
            color: _accent,
          ),
          2.5.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 3.2.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.appDarkColor,
                  ),
                ),
                Text(
                  "as of $date",
                  style: TextStyle(fontSize: 2.6.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
          Text(
            invQty(value),
            style: TextStyle(
              fontSize: 3.8.sp,
              fontWeight: FontWeight.w800,
              color: value < 0
                  ? InventoryPalette.stockOut
                  : AppColor.appDarkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayHeader(DateTime? day, List<InventoryItemMovement> rows) {
    final dayIn = rows.fold<num>(0, (s, m) => s + (m.inQty ?? 0));
    final dayOut = rows.fold<num>(0, (s, m) => s + (m.outQty ?? 0));
    final label = InventoryDates.dayLabel(day);
    final full = InventoryDates.full(day);
    return Padding(
      padding: EdgeInsets.only(top: 1.4.h, bottom: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              day != null && label != full ? "$label · $full" : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 3.sp,
                fontWeight: FontWeight.w800,
                color: InventoryPalette.deep,
              ),
            ),
          ),
          if (dayIn > 0)
            SitePill.tint("+${invQty(dayIn)}", InventoryPalette.stockIn),
          if (dayIn > 0 && dayOut > 0) 1.5.width,
          if (dayOut > 0)
            SitePill.tint("−${invQty(dayOut)}", InventoryPalette.stockOut),
        ],
      ),
    );
  }

  Widget _postingRow(InventoryItemMovement m, {required bool last}) {
    final inQty = m.inQty ?? 0;
    final outQty = m.outQty ?? 0;
    final isIn = inQty > 0 || (inQty == 0 && outQty == 0);
    final qty = isIn ? inQty : outQty;
    final color = isIn ? InventoryPalette.stockIn : InventoryPalette.stockOut;
    final time = InventoryDates.timeOf(m.dateTime);
    final meta = [
      if ((m.documentNo ?? '').isNotEmpty) m.documentNo!,
      if ((m.storeName ?? '').isNotEmpty) m.storeName!,
      ?time,
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
              padding: EdgeInsets.only(bottom: last ? 0.4.h : 1.6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _docTypeLabel(m.documentType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.2.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    0.2.height,
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          2.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isIn ? '+' : '−'}${invQty(qty)}",
                style: TextStyle(
                  fontSize: 3.5.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (m.runningBalance != null)
                Text(
                  "Balance ${invQty(m.runningBalance)}",
                  style: TextStyle(fontSize: 2.6.sp, color: AppColor.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // document_type values seen from inventory_items.php?item_id=...
  static const _docTypeLabels = {
    'GOODS_RECEIPT': 'Goods receipt',
    'GRN': 'Goods receipt',
    'SIN': 'Store issue',
    'STORE_RETURN': 'Store return',
    'STORE_TRANSFER_IN': 'Transfer in',
    'STORE_TRANSFER_OUT': 'Transfer out',
  };

  String _docTypeLabel(String? type) {
    if (type == null || type.isEmpty) return 'Entry';
    final known = _docTypeLabels[type];
    if (known != null) return known;
    final words = type.replaceAll('_', ' ').toLowerCase();
    return words[0].toUpperCase() + words.substring(1);
  }

  Widget _empty(String message) {
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
