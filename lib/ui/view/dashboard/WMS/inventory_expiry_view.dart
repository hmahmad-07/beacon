import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_expiry_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/inventory_dates.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_date_header.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_ui.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Expiry" page of the reference dashboard. Batches are
/// grouped under expiry-date headers -- latest date on top by default, or
/// soonest expiry on top via the sort toggle (controller.expirySortLatest).
/// modified_date is shown on the card when the API sends it (it's null for
/// every batch today, so it can't be the grouping key).
class InventoryExpiryView extends StatefulWidget {
  const InventoryExpiryView({
    super.key,
    required this.accentColor,
    this.heroTag,
  });

  final Color accentColor;

  /// Hero tag of the tile that opened this screen; its icon flies into the
  /// loading view.
  final Object? heroTag;

  @override
  State<InventoryExpiryView> createState() => _InventoryExpiryViewState();
}

class _InventoryExpiryViewState extends State<InventoryExpiryView> {
  final _searchController = TextEditingController();

  static const Map<bool, (String, IconData)> _sortOptions = {
    true: ("Latest date first", Icons.south_rounded),
    false: ("Expiring soonest", Icons.hourglass_bottom_rounded),
  };

  /// True once the first load has finished.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<WMSController>().expiryQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<WMSController>();
      controller.ensureStoresLoaded(context);
      await controller.getExpiryReport(context);
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryActiveFilter> _activeFilters(WMSController c) => [
    if (c.expiryStoreId != null)
      InventoryActiveFilter(
        icon: Icons.storefront_rounded,
        label: c.storeNameById(c.expiryStoreId) ?? "Store",
        onRemove: () => c.setExpiryStore(context, null),
      ),
    if (c.expiryDateRange != null)
      InventoryActiveFilter(
        icon: Icons.event_rounded,
        label: formatRangeLabel(c.expiryDateRange!),
        onRemove: () => c.setExpiryDateRange(context, null),
      ),
  ];

  // Choices are drafted in the sheet and applied with a single fetch.
  void _openFilters(WMSController controller) {
    String? storeId = controller.expiryStoreId;
    DateTimeRange? range = controller.expiryDateRange;
    bool sortLatest = controller.expirySortLatest;

    showInventoryFilterSheet(
      context: context,
      accentColor: widget.accentColor,
      onReset: () {
        storeId = null;
        range = null;
        sortLatest = true;
      },
      onApply: () => controller.applyExpiryFilters(
        context,
        storeId: storeId,
        range: range,
        sortLatest: sortLatest,
      ),
      sections: (sheetContext, setSheet) => [
        InventoryFilterSection(
          title: "Sort by",
          child: InventoryChoiceChips<bool>(
            options: _sortOptions,
            selected: sortLatest,
            accentColor: widget.accentColor,
            onChanged: (v) => setSheet(() => sortLatest = v),
          ),
        ),
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

  List<InventoryExpiryBatch> _sorted(
    List<InventoryExpiryBatch> batches,
    bool latest,
  ) {
    final newestFirst = InventoryDates.sortLatestFirst(
      batches,
      (b) => b.expiryDateTime,
    );
    return latest ? newestFirst : newestFirst.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Expiry Report"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final allBatches = controller.expiryModel?.data ?? [];
          final batches = controller.filteredExpiryBatches;
          final loading = controller.isExpiryLoading;
          final latest = controller.expirySortLatest;

          final summary = controller.expiryModel?.summary;
          final expired =
              summary?.expired ?? allBatches.where((b) => b.isExpired).length;
          final expiringSoon =
              summary?.expiringSoon ??
              allBatches.where((b) => !b.isExpired).length;
          final tracked = summary?.tracked ?? allBatches.length;

          final sorted = _sorted(batches, latest);
          final groups = InventoryDates.groupByDay(
            sorted,
            (b) => b.expiryDateTime,
          );

          var i = 0;
          return RefreshIndicator(
            color: widget.accentColor,
            onRefresh: () => controller.getExpiryReport(context),
            child: !_ready || loading
                ? InventoryLoadingView(
                    key: const ValueKey('expiry-loading'),
                    heroTag: widget.heroTag,
                    icon: BoxIcons.bxs_calendar_x,
                    label: "Loading batches…",
                  )
                : AnimationLimiter(
                    key: const ValueKey('expiry-content'),
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
                            hintText: "Search item, GRN or store…",
                            accentColor: widget.accentColor,
                            onChanged: controller.setExpiryQuery,
                            onFilterTap: () => _openFilters(controller),
                            activeFilterCount:
                                controller.expiryActiveFilterCount,
                          ),
                        ),
                        InventoryActiveFilterChips(
                          accentColor: widget.accentColor,
                          filters: _activeFilters(controller),
                          onClearAll: () => controller.applyExpiryFilters(
                            context,
                            storeId: null,
                            range: null,
                            sortLatest: controller.expirySortLatest,
                          ),
                        ),
                        2.height,
                        _summaryRow(expired, expiringSoon, tracked, i),
                        2.height,
                        invEnter(
                          i += 4,
                          SiteSegmented(
                            labels: const [
                              "Latest date first",
                              "Expiring soonest",
                            ],
                            icons: const [
                              Icons.south_rounded,
                              Icons.hourglass_bottom_rounded,
                            ],
                            selected: latest ? 0 : 1,
                            onChanged: (v) =>
                                controller.setExpirySortLatest(v == 0),
                          ),
                        ),
                        if (allBatches.isEmpty)
                          _emptyState()
                        else if (batches.isEmpty)
                          SiteEmptyState(
                            icon: Icons.search_off_rounded,
                            title: "No match",
                            message:
                                "No batch matches \"${controller.expiryQuery}\".",
                          )
                        else
                          for (final g in groups) ...[
                            invEnter(
                              ++i,
                              InventoryDateHeader(
                                day: g.key,
                                count: g.value.length,
                                countLabel: g.value.length == 1
                                    ? "batch expiring"
                                    : "batches expiring",
                                accentColor: widget.accentColor,
                              ),
                            ),
                            for (final b in g.value)
                              invEnter(++i, _batchTile(b)),
                          ],
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _summaryRow(
    int expired,
    int expiringSoon,
    int tracked,
    int startIndex,
  ) {
    final tiles = [
      SiteStatTile(
        dense: true,
        icon: BoxIcons.bxs_calendar_x,
        color: InventoryPalette.stockOut,
        value: invWhole(expired),
        label: "Expired",
      ),
      SiteStatTile(
        dense: true,
        icon: Icons.hourglass_bottom_rounded,
        color: InventoryPalette.warning,
        value: invWhole(expiringSoon),
        label: "Expiring soon",
      ),
      SiteStatTile(
        dense: true,
        icon: BoxIcons.bxs_layer,
        value: invWhole(tracked),
        label: "Tracked batches",
      ),
    ];
    return SiteStatGrid(
      columns: 3,
      children: [
        for (final (i, t) in tiles.indexed) invEnter(startIndex + i, t),
      ],
    );
  }

  /// Label, colour and icon for a batch's expiry state.
  (String, Color, IconData) _status(InventoryExpiryBatch b) {
    final days = b.daysRemaining;
    if (b.isExpired) {
      return (
        days == null ? "Expired" : "Expired ${-days}d ago",
        InventoryPalette.stockOut,
        Icons.event_busy_rounded,
      );
    }
    if (days == null) {
      return (
        "Expiring soon",
        InventoryPalette.warning,
        Icons.schedule_rounded,
      );
    }
    if (days == 0) {
      return ("Expires today", InventoryPalette.stockOut, Icons.alarm_rounded);
    }
    if (days <= 7) {
      return (
        "$days days left",
        InventoryPalette.warning,
        Icons.hourglass_bottom_rounded,
      );
    }
    return (
      "$days days left",
      InventoryPalette.stockIn,
      Icons.check_circle_rounded,
    );
  }

  Widget _countdown(InventoryExpiryBatch b, Color color) {
    final days = b.daysRemaining;
    final big = days == null ? "—" : "${days.abs()}";
    final small = days == null
        ? "days"
        : b.isExpired
        ? "days ago"
        : days == 1
        ? "day left"
        : "days left";
    // The ring fills as the date gets closer (a month or more = empty).
    final urgency = b.isExpired || days == null
        ? 1.0
        : (1 - days / 30).clamp(0.08, 1.0);
    return SizedBox(
      width: 15.w,
      height: 15.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: urgency),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                big,
                style: TextStyle(
                  fontSize: 4.4.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.appDarkColor,
                  height: 1,
                ),
              ),
              Text(
                small,
                style: TextStyle(
                  fontSize: 2.1.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _batchTile(InventoryExpiryBatch batch) {
    final (label, color, icon) = _status(batch);
    final received = batch.receivedQty ?? 0;
    final remaining = batch.remainingQty ?? 0;
    final share = received <= 0 ? 0.0 : (remaining / received).toDouble();

    return SiteCard(
      margin: EdgeInsets.only(bottom: 1.4.h),
      padding: EdgeInsets.all(3.6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _countdown(batch, color),
              3.5.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.itemName ?? "",
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
                        if ((batch.storeName ?? "").isNotEmpty)
                          InventoryTag(
                            batch.storeName!,
                            icon: Icons.storefront_rounded,
                          ),
                        if ((batch.grnNo ?? "").isNotEmpty)
                          InventoryTag(
                            batch.grnNo!,
                            icon: Icons.receipt_long_rounded,
                          ),
                      ],
                    ),
                    1.height,
                    SitePill.tint(label, color, icon: icon),
                  ],
                ),
              ),
            ],
          ),
          1.8.height,
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColor.scaffold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InventoryFigure(
                        label: "Expiry date",
                        value: InventoryDates.full(batch.expiryDateTime),
                        icon: Icons.event_rounded,
                        size: 3.2.sp,
                      ),
                    ),
                    InventoryFigure(
                      label: "Left in stock",
                      value: "${invQty(remaining)} of ${invQty(received)}",
                      alignEnd: true,
                      size: 3.2.sp,
                    ),
                  ],
                ),
                1.1.height,
                InventoryMeter(value: share, color: color, height: 0.8.h),
                0.8.height,
                Row(
                  children: [
                    Text(
                      "Issued ${invQty(batch.issuedQty)}",
                      style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
                    ),
                    const Spacer(),
                    if (batch.modifiedDateTime != null)
                      Text(
                        "Updated ${InventoryDates.relative(batch.modifiedDateTime)}",
                        style: TextStyle(
                          fontSize: 2.7.sp,
                          color: AppColor.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const SiteEmptyState(
      icon: Icons.event_busy_rounded,
      title: "No expiry dates yet",
      message:
          "Once expiry dates are entered during goods receipt, batches will show up here.",
    );
  }
}
