import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_stock_report_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/inventory_dates.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_date_header.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_ui.dart';
import 'package:provider/provider.dart';

/// Every filter/page/expand value here lives on WMSController
/// (stockReportStoreId/stockReportSearch/stockReportLowStockOnly/
/// stockReportPage/stockReportExpandedIds) -- this view only reads them
/// and calls controller action methods, no local setState.
class InventoryStockReportView extends StatefulWidget {
  const InventoryStockReportView({
    super.key,
    required this.accentColor,
    this.initialLowStockOnly = false,
    this.heroTag,
  });

  final Color accentColor;

  /// Hero tag of the tile that opened this screen; its icon flies into the
  /// loading view.
  final Object? heroTag;

  /// Forces the low-stock toggle on for this visit -- used by the
  /// Dashboard's "View all" negative-stock link, regardless of whatever
  /// the toggle was last left at.
  final bool initialLowStockOnly;

  @override
  State<InventoryStockReportView> createState() =>
      _InventoryStockReportViewState();
}

class _InventoryStockReportViewState extends State<InventoryStockReportView> {
  // A TextEditingController is a widget-level concern (it drives one
  // TextField instance), not app state -- it stays local.
  final _searchController = TextEditingController();

  /// True once the first load has finished, so data from an earlier visit
  /// never flashes before the fresh report.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<WMSController>().stockReportSearch;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<WMSController>();
      controller.ensureStoresLoaded(context);
      if (widget.initialLowStockOnly) {
        await controller.setStockReportLowStockOnly(context, true);
      } else {
        await controller.getStockReport(context);
      }
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Stock Report"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final model = controller.stockReportModel;
          final loading = controller.isStockReportLoading;
          final displayItems = model?.data ?? [];
          final busy = !_ready || (loading && model == null);
          var i = 0;

          return RefreshIndicator(
            color: widget.accentColor,
            onRefresh: () => controller.getStockReport(context),
            child: busy
                ? InventoryLoadingView(
                    key: const ValueKey('stock-loading'),
                    heroTag: widget.heroTag,
                    icon: BoxIcons.bxs_bar_chart_alt_2,
                    label: "Loading stock…",
                  )
                : AnimationLimiter(
                    key: const ValueKey('stock-content'),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
                      children: [
                        invEnter(
                          i++,
                          InventorySearchBar(
                            controller: _searchController,
                            hintText: "Search items…",
                            accentColor: widget.accentColor,
                            onSubmitted: (q) =>
                                controller.runStockReportSearch(context, q),
                            onFilterTap: () => _openFilters(controller),
                            activeFilterCount:
                                controller.stockReportActiveFilterCount,
                          ),
                        ),
                        1.6.height,
                        invEnter(
                          i++,
                          InventoryQuickFilter<bool>(
                            options: const {
                              false: ("All items", Icons.apps_rounded),
                              true: (
                                "Zero or below",
                                Icons.trending_down_rounded,
                              ),
                            },
                            selected: controller.stockReportLowStockOnly,
                            onChanged: (v) => controller
                                .setStockReportLowStockOnly(context, v),
                          ),
                        ),
                        InventoryActiveFilterChips(
                          accentColor: widget.accentColor,
                          filters: _activeFilters(controller),
                          onClearAll: () => controller.applyStockReportFilters(
                            context,
                            storeId: null,
                            lowStockOnly: controller.stockReportLowStockOnly,
                            range: null,
                          ),
                        ),
                        2.height,
                        if (model?.summary != null)
                          _summaryCards(model!.summary!, i++),
                        invEnter(
                          i++ + 2,
                          InventoryResultLine(
                            text:
                                "${invWhole(model?.meta?.total ?? displayItems.length)} items",
                            trailing: Text(
                              "Tap a card for each store",
                              style: TextStyle(
                                fontSize: 2.8.sp,
                                color: AppColor.grey,
                              ),
                            ),
                          ),
                        ),
                        if (displayItems.isEmpty)
                          SiteEmptyState(
                            icon: BoxIcons.bxs_bar_chart_alt_2,
                            title: "No items found",
                            message: controller.stockReportLowStockOnly
                                ? "No item is at zero or below. Nice."
                                : "Try another search or clear the filters.",
                          )
                        else
                          ..._itemList(controller, displayItems, i + 3),
                        if (model?.meta != null)
                          InventoryPager(
                            current: model!.meta!.currentPage ?? 1,
                            last: model.meta!.lastPage ?? 1,
                            total: model.meta!.total,
                            loading: loading,
                            onPage: (p) =>
                                controller.goToStockReportPage(context, p),
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  List<InventoryActiveFilter> _activeFilters(WMSController c) => [
    if (c.stockReportStoreId != null)
      InventoryActiveFilter(
        icon: Icons.storefront_rounded,
        label: c.storeNameById(c.stockReportStoreId) ?? "Store",
        onRemove: () => c.setStockReportStore(context, null),
      ),
    if (c.stockReportDateRange != null)
      InventoryActiveFilter(
        icon: Icons.event_rounded,
        label: formatRangeLabel(c.stockReportDateRange!),
        onRemove: () => c.setStockReportDateRange(context, null),
      ),
  ];

  // Choices are drafted in the sheet and applied with a single fetch.
  void _openFilters(WMSController controller) {
    String? storeId = controller.stockReportStoreId;
    bool lowStockOnly = controller.stockReportLowStockOnly;
    DateTimeRange? range = controller.stockReportDateRange;

    showInventoryFilterSheet(
      context: context,
      accentColor: widget.accentColor,
      onReset: () {
        storeId = null;
        lowStockOnly = false;
        range = null;
      },
      onApply: () => controller.applyStockReportFilters(
        context,
        storeId: storeId,
        lowStockOnly: lowStockOnly,
        range: range,
      ),
      sections: (sheetContext, setSheet) => [
        InventoryFilterSection(
          title: "Store",
          child: InventoryFilterTile(
            icon: Icons.storefront_rounded,
            placeholder: kAllStoresLabel,
            value: controller.storeNameById(storeId),
            accentColor: widget.accentColor,
            onTap: () async {
              final picked = await showInventoryStorePicker(
                sheetContext,
                selectedStoreId: storeId,
                accentColor: widget.accentColor,
              );
              if (picked != null) setSheet(() => storeId = picked.storeId);
            },
            onClear: () => setSheet(() => storeId = null),
          ),
        ),
        InventoryFilterSection(
          title: "Stock level",
          child: InventorySwitchTile(
            icon: Icons.trending_down_rounded,
            title: "Zero or below stock only",
            subtitle: "Items that need restocking",
            value: lowStockOnly,
            accentColor: widget.accentColor,
            onChanged: (v) => setSheet(() => lowStockOnly = v),
          ),
        ),
        InventoryFilterSection(
          title: "Modified date",
          child: InventoryFilterTile(
            icon: Icons.event_rounded,
            placeholder: "Any date",
            value: range == null ? null : formatRangeLabel(range!),
            accentColor: widget.accentColor,
            onTap: () async {
              final r = await CustomDateRangePicker.show(
                sheetContext,
                initialRange: range,
              );
              if (r.range != null) {
                setSheet(() => range = r.range);
              } else if (r.cancelled) {
                setSheet(() => range = null);
              }
            },
            onClear: () => setSheet(() => range = null),
          ),
        ),
      ],
    );
  }

  Widget _summaryCards(InventoryStockSummary summary, int startIndex) {
    final tiles = [
      SiteStatTile(
        dense: true,
        icon: BoxIcons.bxs_box,
        value: invWhole(summary.totalItems),
        label: "Distinct items",
      ),
      SiteStatTile(
        dense: true,
        icon: BoxIcons.bxs_error,
        color: InventoryPalette.stockOut,
        value: invWhole(summary.zeroOrBelowStock),
        label: "Zero or below",
      ),
      SiteStatTile(
        dense: true,
        icon: BoxIcons.bxs_wallet,
        color: InventoryPalette.deep,
        value: invCompact(summary.totalValue),
        label: "Stock value",
      ),
    ];
    return SiteStatGrid(
      columns: 3,
      children: [
        for (final (i, t) in tiles.indexed) invEnter(startIndex + i, t),
      ],
    );
  }

  // Latest movement first, bucketed under a day header.
  List<Widget> _itemList(
    WMSController controller,
    List<StockReportItem> items,
    int startIndex,
  ) {
    final sorted = InventoryDates.sortLatestFirst(
      items,
      (i) => i.modifiedDateTime,
    );
    final groups = InventoryDates.groupByDay(sorted, (i) => i.modifiedDateTime);
    var n = startIndex;
    return [
      for (final g in groups) ...[
        invEnter(
          n++,
          InventoryDateHeader(
            day: g.key,
            count: g.value.length,
            countLabel: g.value.length == 1 ? "item" : "items",
            accentColor: widget.accentColor,
          ),
        ),
        for (final item in g.value) invEnter(n++, _itemCard(controller, item)),
      ],
    ];
  }

  Widget _itemCard(WMSController controller, StockReportItem item) {
    final expanded = controller.stockReportExpandedIds.contains(item.id);
    final balance = item.balance ?? 0;
    final negative = balance < 0;
    final atZero = balance <= 0;
    final byStore = item.byStore ?? const <StockStoreBreakdown>[];
    final hasByStore = byStore.isNotEmpty;
    final lastDate = item.modifiedDateTime;
    final totalIn = item.totalIn ?? 0;
    final totalOut = item.totalOut ?? 0;
    final used = totalIn <= 0 ? null : totalOut / totalIn;

    return SiteCard(
      margin: EdgeInsets.only(bottom: 1.4.h),
      padding: EdgeInsets.zero,
      onTap: !hasByStore
          ? null
          : () => controller.toggleStockReportExpanded(item.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(3.6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InventoryAvatar(
                      name: item.displayName,
                      color: atZero ? InventoryPalette.stockOut : null,
                    ),
                    3.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 3.6.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColor.appDarkColor,
                              height: 1.2,
                            ),
                          ),
                          0.7.height,
                          Wrap(
                            spacing: 1.5.w,
                            runSpacing: 0.6.h,
                            children: [
                              if ((item.itemClass ?? '').isNotEmpty)
                                InventoryTag(item.itemClass!),
                              if ((item.uom ?? '').isNotEmpty)
                                InventoryTag(
                                  item.uom!,
                                  icon: Icons.straighten_rounded,
                                ),
                              if (lastDate != null)
                                InventoryTag(
                                  InventoryDates.relative(lastDate),
                                  icon: Icons.history_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    2.width,
                    InventoryFigure(
                      label: "Balance",
                      value: invQty(balance),
                      color: negative
                          ? InventoryPalette.stockOut
                          : AppColor.appDarkColor,
                      alignEnd: true,
                      size: 4.4.sp,
                    ),
                  ],
                ),
                1.8.height,
                InventorySplitBar(
                  first: totalIn,
                  second: totalOut,
                  firstColor: InventoryPalette.received,
                  secondColor: InventoryPalette.issued,
                  height: 0.9.h,
                ),
                1.height,
                Row(
                  children: [
                    Expanded(
                      child: InventoryFigure(
                        label: "Received",
                        value: invQty(totalIn),
                        icon: Icons.square_rounded,
                        iconColor: InventoryPalette.received,
                        size: 3.3.sp,
                      ),
                    ),
                    Expanded(
                      child: InventoryFigure(
                        label: "Issued",
                        value: invQty(totalOut),
                        icon: Icons.square_rounded,
                        iconColor: InventoryPalette.issued,
                        size: 3.3.sp,
                      ),
                    ),
                    if (used != null)
                      SitePill.tint(
                        "${invPercent(totalOut, totalIn)} used",
                        used >= 1
                            ? InventoryPalette.stockOut
                            : InventoryPalette.deep,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (hasByStore)
            Container(
              decoration: BoxDecoration(
                color: AppColor.scaffold.withValues(alpha: 0.7),
                border: Border(
                  top: BorderSide(
                    color: AppColor.appLightColor.withValues(alpha: 0.6),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.6.w,
                      vertical: 1.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          BoxIcons.bxs_store,
                          size: 3.8.w,
                          color: widget.accentColor,
                        ),
                        2.width,
                        Expanded(
                          child: Text(
                            "${byStore.length} ${byStore.length == 1 ? 'store' : 'stores'}",
                            style: TextStyle(
                              fontSize: 3.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.darkGrey,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 5.4.w,
                            color: widget.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: expanded
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(
                              3.6.w,
                              0,
                              3.6.w,
                              1.6.h,
                            ),
                            child: _byStore(byStore),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _byStore(List<StockStoreBreakdown> stores) {
    return Column(
      children: [
        for (final (i, s) in stores.indexed) ...[
          if (i > 0) 1.2.height,
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (s.storeName ?? "").trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 3.2.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                    ),
                    Text(
                      invQty(s.balance),
                      style: TextStyle(
                        fontSize: 3.4.sp,
                        fontWeight: FontWeight.w800,
                        color: (s.balance ?? 0) < 0
                            ? InventoryPalette.stockOut
                            : AppColor.appDarkColor,
                      ),
                    ),
                  ],
                ),
                0.8.height,
                InventorySplitBar(
                  first: s.totalIn ?? 0,
                  second: s.totalOut ?? 0,
                  firstColor: InventoryPalette.received,
                  secondColor: InventoryPalette.issued,
                  height: 0.6.h,
                ),
                0.6.height,
                Row(
                  children: [
                    Text(
                      "In ${invQty(s.totalIn)}",
                      style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
                    ),
                    const Spacer(),
                    Text(
                      "Out ${invQty(s.totalOut)}",
                      style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
