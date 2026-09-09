import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_3d_loader.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');
  final _ledgerDateFormat = DateFormat('d MMM');

  // API dates come back as "yyyy-MM-dd HH:mm:ss" (always midnight, no real
  // time-of-day) -- reformat to "31 Aug" instead of showing the raw
  // string with a meaningless 00:00:00.
  String _formatLedgerDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return _ledgerDateFormat.format(DateTime.parse(raw));
    } catch (_) {
      return raw.split(' ').first;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<WMSController>().openItemDetail(
        context,
        widget.itemId,
        storeId: widget.storeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: widget.itemName),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          if (controller.isItemDetailLoading) {
            return Center(child: Custom3DLoader(color: widget.accentColor));
          }
          final item = controller.itemDetailModel?.data;
          if (item == null) {
            return Center(
              child: Text(
                "Item not found",
                style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            children: [
              _infoCard(item),
              2.height,
              _sectionCard(
                title: "Stock by store",
                child: _storeBreakdown(item.stock?.byStore ?? []),
              ),
              2.height,
              _sectionCard(
                title: "Movement history",
                subtitle: widget.storeId == null
                    ? null
                    : (controller.itemDetailScopedToStore
                          ? "Showing ${widget.storeName ?? 'the selected store'} only"
                          : "Showing all stores"),
                trailing: widget.storeId == null
                    ? null
                    : TextButton(
                        onPressed: () => controller.toggleItemDetailStoreScope(
                          context,
                          widget.itemId,
                          storeId: widget.storeId,
                        ),
                        child: Text(
                          controller.itemDetailScopedToStore
                              ? "Show all stores"
                              : "Show selected only",
                          style: TextStyle(
                            fontSize: 3.sp,
                            fontWeight: FontWeight.bold,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDateRangePicker(
                      hint: "Select date range",
                      selectedRange: controller.itemDetailDateRange,
                      onRangeSelected: (range) =>
                          controller.setItemDetailDateRange(
                            context,
                            widget.itemId,
                            storeId: widget.storeId,
                            range: range,
                          ),
                      onClear: controller.itemDetailDateRange == null
                          ? null
                          : () => controller.setItemDetailDateRange(
                              context,
                              widget.itemId,
                              storeId: widget.storeId,
                              range: null,
                            ),
                    ),
                    1.5.height,
                    _movements(item.movements ?? []),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard(InventoryItemDetail item) {
    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.displayName,
            style: TextStyle(
              fontSize: 4.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          0.4.height,
          Text(
            "${item.type ?? ''} · ${item.itemClass ?? ''}",
            style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
          ),
          1.5.height,
          Row(
            children: [
              _stat(
                "Total stock",
                _decimalFormat.format(item.stock?.total ?? 0),
              ),
              _stat("Cost price", _decimalFormat.format(item.costPrice ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.bold,
              color: widget.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeBreakdown(List<InventoryStoreBalance> byStore) {
    final nonZero = byStore.where((s) => (s.balance ?? 0) != 0).toList();
    if (nonZero.isEmpty) {
      return _empty("No stock at any store");
    }
    return Column(
      children: nonZero.map((s) {
        final negative = (s.balance ?? 0) < 0;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.7.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.storeName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 3.5.sp, color: AppColor.black),
                ),
              ),
              Text(
                _decimalFormat.format(s.balance ?? 0),
                style: TextStyle(
                  fontSize: 3.5.sp,
                  fontWeight: FontWeight.bold,
                  color: negative ? AppColor.red : AppColor.appDarkColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _movements(List<InventoryItemMovement> movements) {
    if (movements.isEmpty) {
      return _empty("No posted movements");
    }
    final reversed = movements.reversed.toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.5.r),
      child: Table(
        border: TableBorder.all(color: AppColor.appLightColor, width: 1),
        columnWidths: const {
          0: FlexColumnWidth(1.3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1.1),
          3: FlexColumnWidth(1.1),
          4: FlexColumnWidth(1.3),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppColor.appDarkColor),
            children: [
              _ledgerHeaderCell("Date"),
              _ledgerHeaderCell("Document"),
              _ledgerHeaderCell("Debit", align: TextAlign.right),
              _ledgerHeaderCell("Credit", align: TextAlign.right),
              _ledgerHeaderCell("Balance", align: TextAlign.right),
            ],
          ),
          for (int i = 0; i < reversed.length; i++) _ledgerRow(reversed[i], i),
        ],
      ),
    );
  }

  TableRow _ledgerRow(InventoryItemMovement m, int index) {
    final debit = m.inQty ?? 0;
    final credit = m.outQty ?? 0;
    final balance = m.runningBalance ?? 0;

    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven ? AppColor.white : AppColor.scaffold,
      ),
      children: [
        _ledgerCell(_formatLedgerDate(m.date)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.documentType ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 2.7.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
              Text(
                "${m.documentNo ?? ''} · ${m.storeName ?? ''}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 2.3.sp, color: AppColor.grey),
              ),
            ],
          ),
        ),
        _ledgerCell(
          debit > 0 ? _decimalFormat.format(debit) : '—',
          align: TextAlign.right,
          bold: debit > 0,
          color: debit > 0 ? AppColor.green : AppColor.grey,
        ),
        _ledgerCell(
          credit > 0 ? _decimalFormat.format(credit) : '—',
          align: TextAlign.right,
          bold: credit > 0,
          color: credit > 0 ? AppColor.red : AppColor.grey,
        ),
        _ledgerCell(
          _decimalFormat.format(balance),
          align: TextAlign.right,
          bold: true,
          color: balance < 0 ? AppColor.red : AppColor.appDarkColor,
        ),
      ],
    );
  }

  Widget _ledgerHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 2.7.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.white,
        ),
      ),
    );
  }

  Widget _ledgerCell(
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
          fontSize: 2.7.sp,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColor.black,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 4.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      0.3.height,
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          1.height,
          child,
        ],
      ),
    );
  }

  Widget _empty(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Text(
        message,
        style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
      ),
    );
  }
}
