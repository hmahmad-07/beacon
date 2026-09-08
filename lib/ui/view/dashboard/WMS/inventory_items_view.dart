import 'dart:async';

import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_field.dart';
import 'package:beacon/ui/components/custom_segmented_tabs.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_item_detail_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_store_filter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// Mirrors the "Items" page of the reference stock dashboard: store filter,
/// stock-level filter chips, search, and a paginated item list.
class InventoryItemsView extends StatefulWidget {
  const InventoryItemsView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryItemsView> createState() => _InventoryItemsViewState();
}

class _InventoryItemsViewState extends State<InventoryItemsView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _storeId;
  String _status = ""; // "" | in_stock | out_of_stock
  String _search = "";
  int _page = 1;

  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');
  final _wholeFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _fetch({bool append = false}) {
    context.read<WMSController>().getItems(
      context,
      storeId: _storeId,
      search: _search,
      status: _status,
      page: _page,
      append: append,
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _search = value.trim();
        _page = 1;
      });
      _fetch();
    });
  }

  void _loadMore() {
    setState(() => _page += 1);
    _fetch(append: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Items"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final total = controller.itemsModel?.meta?.total ?? 0;
          final loading = controller.isItemsLoading;
          final items = controller.items;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InventoryStoreFilter(
                      selectedStoreId: _storeId,
                      onChanged: (id) {
                        setState(() {
                          _storeId = id;
                          _page = 1;
                        });
                        _fetch();
                      },
                    ),
                    1.height,
                    _searchField(),
                    1.height,
                    _statusChips(),
                    0.8.height,
                    Text(
                      "${_wholeFormat.format(total)} items",
                      style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: loading && items.isEmpty
                    ? _loadingSkeleton()
                    : items.isEmpty
                    ? Center(
                        child: Text(
                          "No items found",
                          style: TextStyle(
                            fontSize: 3.5.sp,
                            color: AppColor.grey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                        itemCount: items.length + 1,
                        separatorBuilder: (context, index) => 1.2.height,
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return _loadMoreControl(controller, loading);
                          }
                          return _itemTile(items[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return CustomField(
      controller: _searchController,
      hintText: "Search name or barcode…",
      isLabel: false,
      onChanged: _onSearchChanged,
      prefix: Icon(Icons.search, color: AppColor.grey, size: 5.w),
    );
  }

  static const Map<String, String> _statusOptions = {
    "": "All stock levels",
    "in_stock": "In stock",
    "out_of_stock": "Out of stock",
  };

  Widget _statusChips() {
    return CustomSegmentedTabs(
      options: _statusOptions.values.toList(),
      selected: _statusOptions[_status] ?? _statusOptions[""]!,
      activeColor: widget.accentColor,
      onChanged: (label) {
        final key = _statusOptions.entries
            .firstWhere((e) => e.value == label)
            .key;
        setState(() {
          _status = key;
          _page = 1;
        });
        _fetch();
      },
    );
  }

  Widget _itemTile(InventoryItemSummary item) {
    final outOfStock = item.isOutOfStock;
    return InkWell(
      borderRadius: BorderRadius.circular(3.5.r),
      onTap: () {
        if (item.id == null) return;
        AppRoutes.push(
          InventoryItemDetailView(
            itemId: item.id!,
            itemName: item.displayName,
            accentColor: widget.accentColor,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(3.5.r),
          boxShadow: AppShadow.soft,
        ),
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
                      fontSize: 3.6.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  0.5.height,
                  Text(
                    "${item.itemClass ?? ''} · ${item.uom ?? ''}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 2.6.sp, color: AppColor.grey),
                  ),
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
                    fontSize: 3.6.sp,
                    fontWeight: FontWeight.bold,
                    color: outOfStock ? AppColor.red : AppColor.green,
                  ),
                ),
                0.3.height,
                Text(
                  outOfStock ? "Out of stock" : "In stock",
                  style: TextStyle(
                    fontSize: 2.4.sp,
                    color: outOfStock ? AppColor.red : AppColor.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadMoreControl(WMSController controller, bool loading) {
    if (!controller.hasMoreItems) {
      return SizedBox(height: 2.h);
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: loading
            ? SizedBox(
                width: 5.w,
                height: 5.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: widget.accentColor,
                ),
              )
            : Material(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(3.r),
                  onTap: _loadMore,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.4.h,
                    ),
                    child: Text(
                      "Load more",
                      style: TextStyle(
                        fontSize: 3.2.sp,
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(bottom: 1.2.h),
          height: 9.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3.5.r),
          ),
        ),
      ),
    );
  }
}
