import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_item_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_3d_loader.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
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
  final _dateFormat = DateFormat('d MMM, yyyy');
  late bool _scopedToStore = widget.storeId != null;

  // API dates come back as "yyyy-MM-dd HH:mm:ss" (always midnight, no real
  // time-of-day) -- reformat to "31 Aug, 2026" instead of showing the raw
  // string with a meaningless 00:00:00.
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return _dateFormat.format(DateTime.parse(raw));
    } catch (_) {
      return raw.split(' ').first;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    context.read<WMSController>().getItemDetail(
      context,
      widget.itemId,
      storeId: _scopedToStore ? widget.storeId : null,
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
                    : (_scopedToStore
                          ? "Showing ${widget.storeName ?? 'the selected store'} only"
                          : "Showing all stores"),
                trailing: widget.storeId == null
                    ? null
                    : TextButton(
                        onPressed: () {
                          setState(() => _scopedToStore = !_scopedToStore);
                          _fetch();
                        },
                        child: Text(
                          _scopedToStore
                              ? "Show all stores"
                              : "Show selected only",
                          style: TextStyle(
                            fontSize: 3.sp,
                            fontWeight: FontWeight.bold,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                child: _movements(item.movements ?? []),
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
    return Column(
      children: reversed.map((m) {
        final isIn = (m.inQty ?? 0) > 0;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.9.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 1.5.w,
                height: 1.5.w,
                margin: EdgeInsets.only(top: 0.8.h, right: 2.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isIn ? AppColor.green : AppColor.red,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${m.documentType ?? ''} · ${m.documentNo ?? ''}",
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "${m.storeName ?? ''} · ${_formatDate(m.date)}",
                      style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
              Text(
                isIn
                    ? "+${_decimalFormat.format(m.inQty ?? 0)}"
                    : "-${_decimalFormat.format(m.outQty ?? 0)}",
                style: TextStyle(
                  fontSize: 3.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isIn ? AppColor.green : AppColor.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
