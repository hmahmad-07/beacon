import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_stock_report_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_3d_loader.dart';
import 'package:beacon/ui/components/custom_button.dart';
import 'package:beacon/ui/components/custom_field.dart';
import 'package:beacon/ui/components/custom_toggle_switch.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_store_filter.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
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
  });

  final Color accentColor;

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

  final _wholeFormat = NumberFormat('#,##0', 'en_US');
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<WMSController>();
      if (widget.initialLowStockOnly) {
        controller.setStockReportLowStockOnly(context, true);
      } else {
        controller.getStockReport(context);
      }
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
      appBar: CustomAppBar(title: "Stock Report"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final model = controller.stockReportModel;
          final loading = controller.isStockReportLoading;
          final displayItems = model?.data ?? [];

          return ListView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            children: [
              InventoryStoreFilter(
                selectedStoreId: controller.stockReportStoreId,
                onChanged: (id) => controller.setStockReportStore(context, id),
              ),
              _searchBar(controller),
              2.height,
              _lowStockToggle(controller),
              2.height,
              if (model?.summary != null) _summaryCards(model!.summary!),
              2.height,
              if (loading && model == null)
                _loadingSkeleton()
              else if (displayItems.isEmpty)
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
                _itemList(controller, displayItems),
              if (model?.meta != null)
                _pager(controller, model!.meta!, loading),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBar(WMSController controller) {
    void runSearch() =>
        controller.runStockReportSearch(context, _searchController.text);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 4,
          child: CustomField(
            controller: _searchController,
            hintText: "Search…",
            isLabel: false,
            onSubmitted: (_) => runSearch(),
            prefix: Icon(Icons.search, color: AppColor.grey, size: 5.w),
          ),
        ),
        2.width,
        Expanded(
          child: RoundButton(
            width: double.infinity,
            buttonColor: widget.accentColor,
            onPress: runSearch,
            title: "Search",
            textColor: AppColor.white,
            height: 6.5.h,
            fontSize: 3.2.sp,
          ),
        ),
      ],
    );
  }

  Widget _lowStockToggle(WMSController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.r),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.6.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accentColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              BoxIcons.bxs_low_vision,
              color: widget.accentColor,
              size: 4.5.w,
            ),
          ),
          3.width,
          Expanded(
            child: Text(
              "Zero or below stock only",
              style: TextStyle(
                fontSize: 3.6.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
          CustomToggleSwitch(
            value: controller.stockReportLowStockOnly,
            activeColor: widget.accentColor,
            onChanged: (v) => controller.setStockReportLowStockOnly(context, v),
          ),
        ],
      ),
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
                    fontSize: 4.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
                0.3.height,
                Text(
                  t.$1,
                  maxLines: 2,
                  style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Back to separate cards (not one continuous table) -- only the
  // expanded by-store breakdown is a table. A colored accent bar, an
  // icon-badged expand toggle, and small directional icons on the In/Out
  // stats replace the plain text-only row from before.
  Widget _itemList(WMSController controller, List<StockReportItem> items) {
    return Column(
      children: items.map((item) => _itemCard(controller, item)).toList(),
    );
  }

  Widget _itemCard(WMSController controller, StockReportItem item) {
    final expanded = controller.stockReportExpandedIds.contains(item.id);
    final negative = (item.balance ?? 0) < 0;
    final hasByStore = (item.byStore ?? []).isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 1.4.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: !hasByStore
                ? null
                : () => controller.toggleStockReportExpanded(item.id),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 1.1.w,
                    color: negative ? AppColor.red : widget.accentColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(3.w, 1.8.h, 3.5.w, 1.8.h),
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
                                      item.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 3.6.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.appDarkColor,
                                      ),
                                    ),
                                    0.3.height,
                                    Text(
                                      "${item.itemClass ?? ''}"
                                      "${item.uom != null && item.uom!.isNotEmpty ? ' · ${item.uom}' : ''}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 2.9.sp,
                                        color: AppColor.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasByStore) ...[
                                2.width,
                                _expandBadge(expanded),
                              ],
                            ],
                          ),
                          1.4.height,
                          Row(
                            children: [
                              _statCell(
                                "Total in",
                                _decimalFormat.format(item.totalIn ?? 0),
                                icon: BoxIcons.bxs_up_arrow,
                                iconColor: AppColor.green,
                              ),
                              _statCell(
                                "Total out",
                                _decimalFormat.format(item.totalOut ?? 0),
                                icon: BoxIcons.bxs_down_arrow,
                                iconColor: AppColor.red,
                              ),
                              _statCell(
                                "Balance",
                                _decimalFormat.format(item.balance ?? 0),
                                valueColor: negative
                                    ? AppColor.red
                                    : AppColor.green,
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
          if (expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(3.5.w, 0, 3.5.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppColor.appLightColor, height: 2.h),
                  _byStoreTable(item.byStore ?? []),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _expandBadge(bool expanded) {
    return Container(
      padding: EdgeInsets.all(1.2.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.accentColor.withValues(alpha: 0.12),
      ),
      child: Icon(
        expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        size: 4.5.w,
        color: widget.accentColor,
      ),
    );
  }

  Widget _statCell(
    String label,
    String value, {
    Color? valueColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 2.4.w, color: iconColor ?? AppColor.grey),
                0.8.width,
              ],
              Text(
                label,
                style: TextStyle(fontSize: 2.6.sp, color: AppColor.grey),
              ),
            ],
          ),
          0.3.height,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 3.4.sp,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColor.appDarkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _byStoreTable(List<StockStoreBreakdown> stores) {
    if (stores.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.5.r),
      child: Table(
        border: TableBorder.all(color: AppColor.appLightColor, width: 1),
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.3),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppColor.darkGrey),
            children: [
              _tableHeaderCell("Store", labelColor: AppColor.white),
              _tableHeaderCell(
                "In",
                align: TextAlign.right,
                labelColor: AppColor.white,
              ),
              _tableHeaderCell(
                "Out",
                align: TextAlign.right,
                labelColor: AppColor.white,
              ),
              _tableHeaderCell(
                "Balance",
                align: TextAlign.right,
                labelColor: AppColor.white,
              ),
            ],
          ),
          for (int i = 0; i < stores.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppColor.white
                    : AppColor.appLightColor.withValues(alpha: 0.35),
              ),
              children: [
                _tableCell(stores[i].storeName ?? "", color: AppColor.darkGrey),
                _tableCell(
                  _decimalFormat.format(stores[i].totalIn ?? 0),
                  align: TextAlign.right,
                  color: AppColor.darkGrey,
                ),
                _tableCell(
                  _decimalFormat.format(stores[i].totalOut ?? 0),
                  align: TextAlign.right,
                  color: AppColor.darkGrey,
                ),
                _tableCell(
                  _decimalFormat.format(stores[i].balance ?? 0),
                  align: TextAlign.right,
                  bold: true,
                  color: (stores[i].balance ?? 0) < 0
                      ? AppColor.red
                      : AppColor.green,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(
    String text, {
    TextAlign align = TextAlign.left,
    Color? labelColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 2.8.sp,
          fontWeight: FontWeight.bold,
          color: labelColor ?? AppColor.grey,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    TextAlign align = TextAlign.left,
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 3.sp,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColor.black,
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
    InventoryStockMeta meta,
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
            onTap: () => controller.goToStockReportPage(context, current - 1),
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
            onTap: () => controller.goToStockReportPage(context, current + 1),
          ),
        ],
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Custom3DLoader(
          color: widget.accentColor,
          label: "Loading stock report …",
        ),
      ),
    );
  }
}
