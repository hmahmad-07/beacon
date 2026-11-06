import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/inventory_dates.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_date_range_picker.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/components/site_design.dart';
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
            return AppLoadingView(color: widget.accentColor);
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
                title: "Stock ledger",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ledgerFilters(controller),
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

  // Compact chip row instead of a full-width date field + text button.
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
        _ledgerChip(
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
          _ledgerChip(
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

  Widget _ledgerChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
    IconData trailingIcon = Icons.keyboard_arrow_down_rounded,
  }) {
    final color = active ? widget.accentColor : AppColor.darkGrey;
    return Material(
      color: active
          ? widget.accentColor.withValues(alpha: 0.1)
          : AppColor.scaffold,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active
                  ? widget.accentColor.withValues(alpha: 0.4)
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
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              1.width,
              if (onClear != null)
                InkWell(
                  onTap: onClear,
                  customBorder: const CircleBorder(),
                  child: Icon(Icons.close_rounded, size: 4.2.w, color: color),
                )
              else
                Icon(trailingIcon, size: 4.4.w, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(InventoryItemDetail item) {
    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: siteCardShadow,
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
          if (item.modifiedDateTime != null) ...[
            1.2.height,
            Row(
              children: [
                Icon(
                  Icons.edit_calendar_outlined,
                  size: 3.6.w,
                  color: AppColor.grey,
                ),
                1.5.width,
                Text(
                  "Last modified ${InventoryDates.full(item.modifiedDateTime)}"
                  " · ${InventoryDates.relative(item.modifiedDateTime)}",
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                ),
              ],
            ),
          ],
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

  // ------------------------------- Ledger -------------------------------
  //
  // Reverse-chronological stock ledger: closing balance on top, then one
  // band per day (latest day first) with that day's in/out totals, then
  // each posting, and the opening balance at the bottom. The API returns
  // movements oldest-first with running_balance computed in that order,
  // so it's reversed before the (stable) date sort -- same-day postings
  // then read newest-first too.

  static const _flexParticulars = 3.2;
  static const _flexQty = 1.3;
  static const _flexBalance = 1.5;

  Widget _movements(List<InventoryItemMovement> movements) {
    if (movements.isEmpty) {
      return _empty("No posted movements");
    }

    final sorted = InventoryDates.sortLatestFirst(
      movements.reversed,
      (m) => m.dateTime,
    );
    final groups = InventoryDates.groupByDay(sorted, (m) => m.dateTime);

    final totalIn = movements.fold<num>(0, (s, m) => s + (m.inQty ?? 0));
    final totalOut = movements.fold<num>(0, (s, m) => s + (m.outQty ?? 0));
    final oldest = sorted.last;
    final num? closing = sorted.first.runningBalance;
    final num? opening = oldest.runningBalance == null
        ? null
        : oldest.runningBalance! - (oldest.inQty ?? 0) + (oldest.outQty ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ledgerSummary(opening, totalIn, totalOut, closing),
        1.5.height,
        ClipRRect(
          borderRadius: BorderRadius.circular(2.5.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.appLightColor),
              borderRadius: BorderRadius.circular(2.5.r),
            ),
            child: Column(
              children: [
                _ledgerHeader(),
                if (closing != null)
                  _balanceRow(
                    "Closing balance",
                    InventoryDates.full(sorted.first.dateTime),
                    closing,
                  ),
                for (final g in groups) ...[
                  _dayBand(g.key, g.value),
                  for (int i = 0; i < g.value.length; i++)
                    _ledgerRow(g.value[i], i),
                ],
                if (opening != null)
                  _balanceRow(
                    "Opening balance",
                    InventoryDates.full(oldest.dateTime),
                    opening,
                  ),
              ],
            ),
          ),
        ),
        1.height,
        Text(
          "${movements.length} postings · ${groups.length} days · latest first",
          style: TextStyle(fontSize: 2.6.sp, color: AppColor.grey),
        ),
      ],
    );
  }

  Widget _ledgerSummary(num? opening, num totalIn, num totalOut, num? closing) {
    final tiles = [
      ("Opening", opening, AppColor.appDarkColor),
      ("Total in", totalIn, AppColor.green),
      ("Total out", totalOut, AppColor.red),
      (
        "Closing",
        closing,
        (closing ?? 0) < 0 ? AppColor.red : widget.accentColor,
      ),
    ];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.4.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(2.5.r),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 4.h,
                color: widget.accentColor.withValues(alpha: 0.18),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    tiles[i].$1,
                    style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
                  ),
                  0.3.height,
                  Text(
                    tiles[i].$2 == null
                        ? "—"
                        : _decimalFormat.format(tiles[i].$2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.4.sp,
                      fontWeight: FontWeight.bold,
                      color: tiles[i].$3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ledgerHeader() {
    return Container(
      color: AppColor.appDarkColor,
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.1.h),
      child: Row(
        children: [
          _headerText("Particulars", _flexParticulars),
          _headerText("In", _flexQty, align: TextAlign.right),
          _headerText("Out", _flexQty, align: TextAlign.right),
          _headerText("Balance", _flexBalance, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _headerText(String text, double flex, {TextAlign? align}) {
    return Expanded(
      flex: (flex * 10).round(),
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

  // Full-width date band with that day's in/out totals.
  Widget _dayBand(DateTime? day, List<InventoryItemMovement> rows) {
    final dayIn = rows.fold<num>(0, (s, m) => s + (m.inQty ?? 0));
    final dayOut = rows.fold<num>(0, (s, m) => s + (m.outQty ?? 0));
    final label = InventoryDates.dayLabel(day);
    final full = InventoryDates.full(day);

    return Container(
      width: double.infinity,
      color: widget.accentColor.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 3.2.w,
            color: widget.accentColor,
          ),
          1.5.width,
          Expanded(
            child: Text(
              day != null && label != full ? "$label · $full" : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 2.8.sp,
                fontWeight: FontWeight.bold,
                color: widget.accentColor,
              ),
            ),
          ),
          if (dayIn > 0)
            Text(
              "+${_decimalFormat.format(dayIn)}",
              style: TextStyle(
                fontSize: 2.6.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.green,
              ),
            ),
          if (dayIn > 0 && dayOut > 0) 2.width,
          if (dayOut > 0)
            Text(
              "−${_decimalFormat.format(dayOut)}",
              style: TextStyle(
                fontSize: 2.6.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _ledgerRow(InventoryItemMovement m, int index) {
    final debit = m.inQty ?? 0;
    final credit = m.outQty ?? 0;
    final balance = m.runningBalance ?? 0;
    final typeColor = _docTypeColor(m.documentType);
    final time = InventoryDates.timeOf(m.dateTime);
    final meta = [
      if ((m.documentNo ?? '').isNotEmpty) m.documentNo!,
      if ((m.storeName ?? '').isNotEmpty) m.storeName!,
      ?time,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppColor.white : AppColor.scaffold,
        border: Border(
          top: BorderSide(color: AppColor.appLightColor, width: 0.6),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: (_flexParticulars * 10).round(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.6.w,
                    vertical: 0.2.h,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(1.5.r),
                  ),
                  child: Text(
                    _docTypeLabel(m.documentType),
                    style: TextStyle(
                      fontSize: 2.4.sp,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  0.3.height,
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 2.4.sp, color: AppColor.grey),
                  ),
                ],
              ],
            ),
          ),
          _qtyText(
            debit > 0 ? _decimalFormat.format(debit) : '—',
            _flexQty,
            color: debit > 0 ? AppColor.green : AppColor.grey,
            bold: debit > 0,
          ),
          _qtyText(
            credit > 0 ? _decimalFormat.format(credit) : '—',
            _flexQty,
            color: credit > 0 ? AppColor.red : AppColor.grey,
            bold: credit > 0,
          ),
          _qtyText(
            _decimalFormat.format(balance),
            _flexBalance,
            color: balance < 0 ? AppColor.red : AppColor.appDarkColor,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, String date, num value) {
    return Container(
      color: AppColor.appLightColor.withValues(alpha: 0.45),
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: ((_flexParticulars + 2 * _flexQty) * 10).round(),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 2.8.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  TextSpan(
                    text: "  as of $date",
                    style: TextStyle(fontSize: 2.4.sp, color: AppColor.grey),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _qtyText(
            _decimalFormat.format(value),
            _flexBalance,
            color: value < 0 ? AppColor.red : AppColor.appDarkColor,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _qtyText(
    String text,
    double flex, {
    required Color color,
    bool bold = false,
  }) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 2.8.sp,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  // document_type values seen from inventory_items.php?item_id=...
  static const _docTypeLabels = {
    'GOODS_RECEIPT': 'GOODS RECEIPT',
    'SIN': 'STORE ISSUE',
    'STORE_RETURN': 'STORE RETURN',
    'STORE_TRANSFER_IN': 'TRANSFER IN',
    'STORE_TRANSFER_OUT': 'TRANSFER OUT',
  };

  String _docTypeLabel(String? type) {
    if (type == null || type.isEmpty) return 'ENTRY';
    return _docTypeLabels[type] ?? type.replaceAll('_', ' ');
  }

  Color _docTypeColor(String? type) {
    switch (type) {
      case 'GOODS_RECEIPT':
        return AppColor.green;
      case 'SIN':
        return AppColor.red;
      case 'STORE_RETURN':
        return widget.accentColor;
      case 'STORE_TRANSFER_IN':
        return siteShade(widget.accentColor, 0.22);
      case 'STORE_TRANSFER_OUT':
        return AppColor.grey;
      default:
        return AppColor.darkGrey;
    }
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
        boxShadow: siteCardShadow,
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
