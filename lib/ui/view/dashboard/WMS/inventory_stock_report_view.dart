import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_stock_report_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_store_filter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// Mirrors the "Stock" report page of the reference dashboard: summary
/// cards, a store filter, a low-stock-only toggle, and a paginated list
/// with each item's per-store breakdown.
///
/// item_type/class_id filters from the API are left out for now: those
/// take internal ITEM_TYPE_ID/CLS_ID values and there's no endpoint yet
/// that maps those ids to the labels the reference dashboard shows.
class InventoryStockReportView extends StatefulWidget {
  const InventoryStockReportView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryStockReportView> createState() =>
      _InventoryStockReportViewState();
}

class _InventoryStockReportViewState extends State<InventoryStockReportView> {
  String? _storeId;
  bool _lowStockOnly = false;
  int _page = 1;
  final Set<String> _expanded = {};

  final _wholeFormat = NumberFormat('#,##0', 'en_US');
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    context.read<WMSController>().getStockReport(
      context,
      storeId: _storeId,
      lowStockOnly: _lowStockOnly,
      page: _page,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Stock Report"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final model = controller.stockReportModel;
          final loading = controller.isStockReportLoading;

          return ListView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
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
              _lowStockToggle(),
              2.height,
              if (model?.summary != null) _summaryCards(model!.summary!),
              2.height,
              if (loading && model == null)
                _loadingSkeleton()
              else if ((model?.data ?? []).isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Text(
                      "No items found",
                      style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey),
                    ),
                  ),
                )
              else
                ..._itemList(model!.data!),
              if (model?.meta != null) _pager(model!.meta!, loading),
            ],
          );
        },
      ),
    );
  }

  Widget _lowStockToggle() {
    return Row(
      children: [
        Switch(
          value: _lowStockOnly,
          activeThumbColor: widget.accentColor,
          onChanged: (v) {
            setState(() {
              _lowStockOnly = v;
              _page = 1;
            });
            _fetch();
          },
        ),
        Text(
          "Zero or below stock only",
          style: TextStyle(fontSize: 3.2.sp, color: AppColor.appDarkColor),
        ),
      ],
    );
  }

  Widget _summaryCards(InventoryStockSummary summary) {
    final tiles = [
      ("Distinct items", _wholeFormat.format(summary.totalItems ?? 0)),
      ("Zero/below stock", _wholeFormat.format(summary.zeroOrBelowStock ?? 0)),
      ("Total value", _wholeFormat.format(summary.totalValue ?? 0)),
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
                  t.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.6.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
                0.3.height,
                Text(
                  t.$1,
                  maxLines: 2,
                  style: TextStyle(fontSize: 2.3.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _itemList(List<StockReportItem> items) {
    return items.map((item) {
      final expanded = _expanded.contains(item.id);
      final negative = (item.balance ?? 0) < 0;
      return Container(
        margin: EdgeInsets.only(bottom: 1.2.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(3.5.r),
          boxShadow: AppShadow.soft,
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(3.5.r),
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expanded.remove(item.id);
                  } else if (item.id != null) {
                    _expanded.add(item.id!);
                  }
                });
              },
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
                              fontSize: 3.5.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.appDarkColor,
                            ),
                          ),
                          0.3.height,
                          Text(
                            item.itemClass ?? "",
                            style: TextStyle(
                              fontSize: 2.5.sp,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _decimalFormat.format(item.balance ?? 0),
                          style: TextStyle(
                            fontSize: 3.6.sp,
                            fontWeight: FontWeight.bold,
                            color: negative ? AppColor.red : AppColor.green,
                          ),
                        ),
                        Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColor.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: EdgeInsets.fromLTRB(3.5.w, 0, 3.5.w, 2.h),
                child: Column(
                  children: (item.byStore ?? []).map((s) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.4.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.storeName ?? "",
                              style: TextStyle(
                                fontSize: 2.8.sp,
                                color: AppColor.black,
                              ),
                            ),
                          ),
                          Text(
                            _decimalFormat.format(s.balance ?? 0),
                            style: TextStyle(
                              fontSize: 2.8.sp,
                              fontWeight: FontWeight.w600,
                              color: (s.balance ?? 0) < 0
                                  ? AppColor.red
                                  : AppColor.appDarkColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _pager(InventoryStockMeta meta, bool loading) {
    final current = meta.currentPage ?? 1;
    final last = meta.lastPage ?? 1;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: current > 1 && !loading
                ? () {
                    setState(() => _page = current - 1);
                    _fetch();
                  }
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            "Page $current of $last",
            style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
          ),
          IconButton(
            onPressed: current < last && !loading
                ? () {
                    setState(() => _page = current + 1);
                    _fetch();
                  }
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(6, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: 1.2.h),
            height: 9.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3.5.r),
            ),
          );
        }),
      ),
    );
  }
}
