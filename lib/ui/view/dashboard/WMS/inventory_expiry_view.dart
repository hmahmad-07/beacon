import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_expiry_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/inventory_dates.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_3d_loader.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_date_header.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Expiry" page of the reference dashboard. Batches are
/// grouped under expiry-date headers -- latest date on top by default, or
/// soonest expiry on top via the sort toggle (controller.expirySortLatest).
/// modified_date is shown on the card when the API sends it (it's null for
/// every batch today, so it can't be the grouping key).
class InventoryExpiryView extends StatefulWidget {
  const InventoryExpiryView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryExpiryView> createState() => _InventoryExpiryViewState();
}

class _InventoryExpiryViewState extends State<InventoryExpiryView> {
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');
  static const _warning = Color(0xFFFF9F43);

  final _searchController = TextEditingController();

  static const Map<bool, (String, IconData)> _sortOptions = {
    true: ("Latest date first", Icons.south_rounded),
    false: ("Expiring soonest", Icons.hourglass_bottom_rounded),
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<WMSController>().expiryQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<WMSController>();
      controller.ensureStoresLoaded(context);
      controller.getExpiryReport(context);
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
    if (!c.expirySortLatest)
      InventoryActiveFilter(
        icon: Icons.hourglass_bottom_rounded,
        label: "Expiring soonest",
        onRemove: () => c.setExpirySortLatest(true),
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
      appBar: CustomAppBar(title: "Expiry Report"),
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

          return ListView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            children: [
              InventorySearchBar(
                controller: _searchController,
                hintText: "Search item, GRN or store…",
                accentColor: widget.accentColor,
                onChanged: controller.setExpiryQuery,
                onFilterTap: () => _openFilters(controller),
                activeFilterCount: controller.expiryActiveFilterCount,
              ),
              InventoryActiveFilterChips(
                accentColor: widget.accentColor,
                filters: _activeFilters(controller),
                onClearAll: () => controller.applyExpiryFilters(
                  context,
                  storeId: null,
                  range: null,
                  sortLatest: true,
                ),
              ),
              2.height,
              _summaryRow(expired, expiringSoon, tracked),
              1.5.height,
              if (loading)
                Center(child: Custom3DLoader(color: widget.accentColor))
              else if (allBatches.isEmpty)
                _emptyState()
              else if (batches.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Center(
                    child: Text(
                      "No batches match \"${controller.expiryQuery}\"",
                      style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey),
                    ),
                  ),
                )
              else
                for (final g in groups) ...[
                  InventoryDateHeader(
                    day: g.key,
                    count: g.value.length,
                    countLabel: g.value.length == 1
                        ? "batch expiring"
                        : "batches expiring",
                    accentColor: widget.accentColor,
                  ),
                  ...g.value.map(_batchTile),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(int expired, int expiringSoon, int tracked) {
    final tiles = [
      ("Expired", expired, AppColor.red),
      ("Expiring soon", expiringSoon, _warning),
      ("Tracked batches", tracked, widget.accentColor),
    ];
    return Row(
      children: tiles.map((t) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 2.w),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(3.r),
              boxShadow: AppShadow.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${t.$2}",
                  style: TextStyle(
                    fontSize: 4.2.sp,
                    fontWeight: FontWeight.bold,
                    color: t.$3,
                  ),
                ),
                0.3.height,
                Text(
                  t.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 2.3.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  (String, Color) _status(InventoryExpiryBatch b) {
    final days = b.daysRemaining;
    if (b.isExpired) {
      return (days == null ? "Expired" : "Expired ${-days}d ago", AppColor.red);
    }
    if (days == null) return ("Expiring soon", _warning);
    if (days == 0) return ("Expires today", AppColor.red);
    return ("$days days left", days <= 7 ? _warning : AppColor.green);
  }

  Widget _batchTile(InventoryExpiryBatch batch) {
    final (label, color) = _status(batch);

    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 1.1.w, color: color),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batch.itemName ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 3.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.appDarkColor,
                                ),
                              ),
                              0.3.height,
                              Text(
                                [
                                  if ((batch.storeName ?? "").isNotEmpty)
                                    batch.storeName!,
                                  if ((batch.grnNo ?? "").isNotEmpty)
                                    "GRN ${batch.grnNo}",
                                ].join(" · "),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 2.6.sp,
                                  color: AppColor.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        2.width,
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.4.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2.5.r),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 2.6.sp,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    1.2.height,
                    Row(
                      children: [
                        _dateCell(
                          "Expiry date",
                          InventoryDates.full(batch.expiryDateTime),
                          Icons.event_busy_outlined,
                          valueColor: color,
                        ),
                        _dateCell(
                          "Modified",
                          InventoryDates.full(batch.modifiedDateTime),
                          Icons.edit_calendar_outlined,
                        ),
                      ],
                    ),
                    1.2.height,
                    Row(
                      children: [
                        _qtyCell("Received", batch.receivedQty),
                        _qtyCell("Issued", batch.issuedQty),
                        _qtyCell(
                          "Remaining",
                          batch.remainingQty,
                          valueColor: widget.accentColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateCell(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 4.w, color: AppColor.grey),
          1.5.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 2.4.sp, color: AppColor.grey),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 2.9.sp,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColor.appDarkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyCell(String label, num? value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 2.4.sp, color: AppColor.grey),
          ),
          Text(
            value == null ? "—" : _decimalFormat.format(value),
            style: TextStyle(
              fontSize: 3.2.sp,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColor.appDarkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 15.w,
              color: Colors.grey.shade300,
            ),
            2.height,
            Text(
              "No expiry dates recorded yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 3.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.appDarkColor,
              ),
            ),
            0.8.height,
            Text(
              "Once expiry dates are entered during goods receipt, batches\nwill show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }
}
