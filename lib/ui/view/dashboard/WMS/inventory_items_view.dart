import 'package:beacon/core/controllers/wms_controller.dart';
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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_ui.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Items" page of the reference stock dashboard: store filter,
/// search (tap the Search button, not live-as-you-type), stock-level
/// filter, and a paginated item list. Every filter/page value lives on
/// WMSController (itemsStoreId/itemsSearch/itemsStatus/itemsPage) --
/// this view only reads them and calls controller action methods, no
/// local setState.
class InventoryItemsView extends StatefulWidget {
  const InventoryItemsView({
    super.key,
    required this.accentColor,
    this.heroTag,
  });

  final Color accentColor;

  /// Hero tag of the tile that opened this screen; its icon flies into the
  /// loading view.
  final Object? heroTag;

  @override
  State<InventoryItemsView> createState() => _InventoryItemsViewState();
}

class _InventoryItemsViewState extends State<InventoryItemsView> {
  // A TextEditingController is a widget-level concern (it drives one
  // TextField instance), not app state -- it stays local.
  final _searchController = TextEditingController();

  /// True once the first load has finished, so data from an earlier visit
  /// never flashes before the fresh list.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<WMSController>();
    // Search persists on the controller across visits; mirror it.
    _searchController.text = controller.itemsSearch;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.ensureStoresLoaded(context);
      await controller.getItems(context);
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
      appBar: const CustomAppBar(title: "Items"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final model = controller.itemsModel;
          final items = model?.data ?? [];
          final loading = controller.isItemsLoading;

          final total = model?.meta?.total ?? items.length;
          final busy = !_ready || (loading && model == null);
          var i = 0;

          return RefreshIndicator(
            color: widget.accentColor,
            onRefresh: () => controller.getItems(context),
            child: busy
                ? InventoryLoadingView(
                    key: const ValueKey('items-loading'),
                    heroTag: widget.heroTag,
                    icon: BoxIcons.bxs_box,
                    label: "Loading items…",
                  )
                : AnimationLimiter(
                    key: const ValueKey('items-content'),
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
                                controller.runItemsSearch(context, q),
                            onFilterTap: () => _openFilters(controller),
                            activeFilterCount:
                                controller.itemsActiveFilterCount,
                          ),
                        ),
                        1.6.height,
                        invEnter(
                          i++,
                          InventoryQuickFilter<String>(
                            options: _statusOptions,
                            selected: controller.itemsStatus,
                            onChanged: (v) =>
                                controller.setItemsStatus(context, v),
                          ),
                        ),
                        InventoryActiveFilterChips(
                          accentColor: widget.accentColor,
                          filters: _activeFilters(controller),
                          onClearAll: () => controller.applyItemsFilters(
                            context,
                            storeId: null,
                            status: controller.itemsStatus,
                            range: null,
                          ),
                        ),
                        invEnter(
                          i++,
                          InventoryResultLine(
                            text:
                                "${invWhole(total)} ${total == 1 ? 'item' : 'items'}",
                            trailing: Text(
                              "Latest first",
                              style: TextStyle(
                                fontSize: 2.8.sp,
                                color: AppColor.grey,
                              ),
                            ),
                          ),
                        ),
                        if (items.isEmpty)
                          SiteEmptyState(
                            icon: BoxIcons.bxs_box,
                            title: "No items found",
                            message: controller.itemsSearch.isNotEmpty
                                ? "Nothing matches \"${controller.itemsSearch}\"."
                                : "Try another stock status or clear the filters.",
                          )
                        else
                          ..._datedItems(controller, items, i),
                        if (model?.meta != null)
                          InventoryPager(
                            current: model!.meta!.currentPage ?? 1,
                            last: model.meta!.lastPage ?? 1,
                            total: model.meta!.total,
                            loading: loading,
                            onPage: (p) => controller.goToItemsPage(context, p),
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  static const Map<String, (String, IconData)> _statusOptions = {
    "": ("All items", Icons.apps_rounded),
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
    int startIndex,
  ) {
    var n = startIndex;
    final sorted = InventoryDates.sortLatestFirst(
      items,
      (i) => i.modifiedDateTime,
    );
    final groups = InventoryDates.groupByDay(sorted, (i) => i.modifiedDateTime);
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

  Widget _itemCard(WMSController controller, InventoryItemSummary item) {
    final outOfStock = item.isOutOfStock || (item.stock ?? 0) <= 0;
    final negative = (item.stock ?? 0) < 0;
    final statusColor = outOfStock
        ? InventoryPalette.stockOut
        : InventoryPalette.stockIn;
    final lastDate = item.modifiedDateTime;
    final lastTime = InventoryDates.timeOf(lastDate);
    final value = (item.stock ?? 0) * (item.costPrice ?? 0);

    return SiteCard(
      margin: EdgeInsets.only(bottom: 1.4.h),
      padding: EdgeInsets.all(3.6.w),
      onTap: item.id == null
          ? null
          : () {
              final storeId = controller.itemsStoreId;
              context.pushSite(
                InventoryItemDetailView(
                  itemId: item.id!,
                  itemName: item.displayName,
                  accentColor: widget.accentColor,
                  storeId: storeId,
                  storeName: controller.storeNameById(storeId),
                ),
              );
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              invHero(
                'inv-item-${item.id}',
                InventoryAvatar(
                  name: item.displayName,
                  color: outOfStock
                      ? InventoryPalette.stockOut
                      : widget.accentColor,
                ),
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
                        fontSize: 3.7.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColor.appDarkColor,
                        height: 1.2,
                      ),
                    ),
                    0.8.height,
                    Wrap(
                      spacing: 1.5.w,
                      runSpacing: 0.6.h,
                      children: [
                        if ((item.itemClass ?? '').isNotEmpty)
                          InventoryTag(item.itemClass!),
                        if ((item.type ?? '').isNotEmpty &&
                            item.type != item.itemClass)
                          InventoryTag(item.type!),
                        if ((item.uom ?? '').isNotEmpty)
                          InventoryTag(
                            item.uom!,
                            icon: Icons.straighten_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              2.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    invQty(item.stock),
                    style: TextStyle(
                      fontSize: 4.6.sp,
                      fontWeight: FontWeight.w800,
                      color: negative
                          ? InventoryPalette.stockOut
                          : AppColor.appDarkColor,
                    ),
                  ),
                  Text(
                    (item.uom ?? '').isEmpty
                        ? "on hand"
                        : "${item.uom} on hand",
                    style: TextStyle(fontSize: 2.6.sp, color: AppColor.grey),
                  ),
                ],
              ),
            ],
          ),
          1.4.height,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppColor.scaffold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SitePill.tint(
                  outOfStock ? "Out of stock" : "In stock",
                  statusColor,
                  icon: outOfStock
                      ? Icons.remove_shopping_cart_outlined
                      : Icons.check_circle_rounded,
                ),
                2.width,
                Expanded(
                  child: Text(
                    lastDate == null
                        ? ""
                        : "Updated ${InventoryDates.relative(lastDate)}"
                              "${lastTime != null ? ' · $lastTime' : ''}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
                  ),
                ),
                if (value > 0)
                  Text(
                    "PKR ${invCompact(value)}",
                    style: TextStyle(
                      fontSize: 3.sp,
                      fontWeight: FontWeight.w800,
                      color: InventoryPalette.deep,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
