import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/inventory_dates.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_item_detail_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_date_header.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Items" page of the reference stock dashboard: store filter,
/// search (tap the Search button, not live-as-you-type), stock-level
/// filter, and a paginated item list. Every filter/page value lives on
/// WMSController (itemsStoreId/itemsSearch/itemsStatus/itemsPage) --
/// this view only reads them and calls controller action methods, no
/// local setState.
class InventoryItemsView extends StatefulWidget {
  const InventoryItemsView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryItemsView> createState() => _InventoryItemsViewState();
}

class _InventoryItemsViewState extends State<InventoryItemsView> {
  // A TextEditingController is a widget-level concern (it drives one
  // TextField instance), not app state -- it stays local.
  final _searchController = TextEditingController();

  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');
  final _wholeFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    final controller = context.read<WMSController>();
    // Search persists on the controller across visits; mirror it.
    _searchController.text = controller.itemsSearch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureStoresLoaded(context);
      controller.getItems(context);
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
      appBar: CustomAppBar(title: "Items"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final model = controller.itemsModel;
          final items = model?.data ?? [];
          final loading = controller.isItemsLoading;

          return ListView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            children: [
              InventorySearchBar(
                controller: _searchController,
                hintText: "Search items…",
                accentColor: widget.accentColor,
                onSubmitted: (q) => controller.runItemsSearch(context, q),
                onFilterTap: () => _openFilters(controller),
                activeFilterCount: controller.itemsActiveFilterCount,
              ),
              InventoryActiveFilterChips(
                accentColor: widget.accentColor,
                filters: _activeFilters(controller),
                onClearAll: () => controller.applyItemsFilters(
                  context,
                  storeId: null,
                  status: "",
                  range: null,
                ),
              ),
              1.8.height,
              Text(
                loading
                    ? "Loading items…"
                    : "${_wholeFormat.format(model?.meta?.total ?? 0)} items",
                style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
              ),
              1.height,
              if (loading && model == null)
                const AppLoadingView()
              else if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Text(
                      "No items found",
                      style: TextStyle(fontSize: 3.8.sp, color: AppColor.grey),
                    ),
                  ),
                )
              else
                ..._datedItems(controller, items),
              if (model?.meta != null)
                _pager(controller, model!.meta!, loading),
            ],
          );
        },
      ),
    );
  }

  static const Map<String, (String, IconData)> _statusOptions = {
    "": ("All stock", Icons.inventory_2_outlined),
    "in_stock": ("In stock", Icons.check_circle_outline_rounded),
    "out_of_stock": ("Out of stock", Icons.remove_shopping_cart_outlined),
  };

  List<InventoryActiveFilter> _activeFilters(WMSController c) => [
    if (c.itemsStoreId != null)
      InventoryActiveFilter(
        icon: Icons.storefront_rounded,
        label: c.storeNameById(c.itemsStoreId) ?? "Store",
        onRemove: () => c.setItemsStore(context, null),
      ),
    if (c.itemsStatus.isNotEmpty)
      InventoryActiveFilter(
        icon: _statusOptions[c.itemsStatus]?.$2 ?? Icons.inventory_2_outlined,
        label: _statusOptions[c.itemsStatus]?.$1 ?? c.itemsStatus,
        onRemove: () => c.setItemsStatus(context, ""),
      ),
    if (c.itemsDateRange != null)
      InventoryActiveFilter(
        icon: Icons.event_rounded,
        label: formatRangeLabel(c.itemsDateRange!),
        onRemove: () => c.setItemsDateRange(context, null),
      ),
  ];

  // Choices are drafted in the sheet and applied with a single fetch.
  void _openFilters(WMSController controller) {
    String? storeId = controller.itemsStoreId;
    String status = controller.itemsStatus;
    DateTimeRange? range = controller.itemsDateRange;

    showInventoryFilterSheet(
      context: context,
      accentColor: widget.accentColor,
      onReset: () {
        storeId = null;
        status = "";
        range = null;
      },
      onApply: () => controller.applyItemsFilters(
        context,
        storeId: storeId,
        status: status,
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
          title: "Stock status",
          child: InventoryChoiceChips<String>(
            options: _statusOptions,
            selected: status,
            accentColor: widget.accentColor,
            onChanged: (v) => setSheet(() => status = v),
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

  // Latest activity first, bucketed under a day header.
  List<Widget> _datedItems(
    WMSController controller,
    List<InventoryItemSummary> items,
  ) {
    final sorted = InventoryDates.sortLatestFirst(
      items,
      (i) => i.modifiedDateTime,
    );
    final groups = InventoryDates.groupByDay(sorted, (i) => i.modifiedDateTime);
    return [
      for (final g in groups) ...[
        InventoryDateHeader(
          day: g.key,
          count: g.value.length,
          countLabel: g.value.length == 1 ? "item" : "items",
          accentColor: widget.accentColor,
        ),
        ...g.value.map((i) => _itemCard(controller, i)),
      ],
    ];
  }

  Widget _itemCard(WMSController controller, InventoryItemSummary item) {
    final outOfStock = item.isOutOfStock;
    final lastDate = item.modifiedDateTime;
    final lastTime = InventoryDates.timeOf(lastDate);
    return Container(
      margin: EdgeInsets.only(bottom: 1.4.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: siteCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.id == null) return;
          final storeId = controller.itemsStoreId;
          AppRoutes.push(
            InventoryItemDetailView(
              itemId: item.id!,
              itemName: item.displayName,
              accentColor: widget.accentColor,
              storeId: storeId,
              storeName: controller.storeNameById(storeId),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 1.1.w,
                color: outOfStock ? AppColor.red : widget.accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(3.5.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 3.8.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.appDarkColor,
                              ),
                            ),
                            0.4.height,
                            Text(
                              "${item.itemClass ?? ''}"
                              "${item.uom != null && item.uom!.isNotEmpty ? ' · ${item.uom}' : ''}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 3.2.sp,
                                color: AppColor.grey,
                              ),
                            ),
                            if (lastDate != null) ...[
                              0.6.height,
                              Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 3.4.w,
                                    color: AppColor.grey,
                                  ),
                                  1.width,
                                  Flexible(
                                    child: Text(
                                      "Modified ${InventoryDates.full(lastDate)}"
                                      "${lastTime != null ? ' · $lastTime' : ''}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 2.7.sp,
                                        color: AppColor.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      3.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _decimalFormat.format(item.stock ?? 0),
                            style: TextStyle(
                              fontSize: 3.8.sp,
                              fontWeight: FontWeight.bold,
                              color: outOfStock ? AppColor.red : AppColor.green,
                            ),
                          ),
                          0.3.height,
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (outOfStock ? AppColor.red : AppColor.green)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2.5.r),
                            ),
                            child: Text(
                              outOfStock ? "Out of stock" : "In stock",
                              style: TextStyle(
                                fontSize: 2.8.sp,
                                fontWeight: FontWeight.w600,
                                color: outOfStock
                                    ? AppColor.red
                                    : AppColor.green,
                              ),
                            ),
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
      ),
    );
  }

  Widget _pagerButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = enabled ? widget.accentColor : AppColor.appLightColor;
    return Material(
      color: enabled
          ? widget.accentColor.withValues(alpha: 0.1)
          : AppColor.scaffold,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(2.2.w),
          child: Icon(icon, color: color, size: 5.w),
        ),
      ),
    );
  }

  Widget _pager(
    WMSController controller,
    InventoryItemsMeta meta,
    bool loading,
  ) {
    final current = meta.currentPage ?? 1;
    final last = meta.lastPage ?? 1;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pagerButton(
            icon: Icons.chevron_left_rounded,
            enabled: current > 1 && !loading,
            onTap: () => controller.goToItemsPage(context, current - 1),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Text(
              "Page $current of $last",
              style: TextStyle(
                fontSize: 3.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
          _pagerButton(
            icon: Icons.chevron_right_rounded,
            enabled: current < last && !loading,
            onTap: () => controller.goToItemsPage(context, current + 1),
          ),
        ],
      ),
    );
  }
}
