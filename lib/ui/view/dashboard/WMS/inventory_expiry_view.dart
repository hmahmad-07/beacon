import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_expiry_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_store_filter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Expiry" page of the reference dashboard. The API currently
/// always returns an empty list -- no GRN line in the database has
/// EXPIRE_DATE set yet -- so this screen mostly renders the empty state,
/// same as the reference dashboard does today.
class InventoryExpiryView extends StatefulWidget {
  const InventoryExpiryView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryExpiryView> createState() => _InventoryExpiryViewState();
}

class _InventoryExpiryViewState extends State<InventoryExpiryView> {
  String? _storeId;
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    context.read<WMSController>().getExpiryReport(context, storeId: _storeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Expiry Report"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final batches = controller.expiryModel?.data ?? [];
          final loading = controller.isExpiryLoading;

          final expired = batches
              .where((b) => (b.daysRemaining ?? 0) < 0)
              .length;
          final expiringSoon = batches
              .where((b) => (b.daysRemaining ?? 999) >= 0 && (b.daysRemaining ?? 999) <= 7)
              .length;

          return ListView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            children: [
              InventoryStoreFilter(
                selectedStoreId: _storeId,
                onChanged: (id) {
                  setState(() => _storeId = id);
                  _fetch();
                },
              ),
              2.height,
              _summaryRow(expired, expiringSoon, batches.length),
              2.height,
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (batches.isEmpty)
                _emptyState()
              else
                ...batches.map(_batchTile),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(int expired, int expiringSoon, int tracked) {
    final tiles = [
      ("Expired", expired, AppColor.red),
      ("Expiring soon", expiringSoon, const Color(0xFFFF9F43)),
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
                  style: TextStyle(fontSize: 2.3.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _batchTile(InventoryExpiryBatch batch) {
    final days = batch.daysRemaining;
    final expired = (days ?? 0) < 0;
    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
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
                  batch.itemName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.4.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
                0.3.height,
                Text(
                  "${batch.storeName ?? ''} · GRN ${batch.grnNo ?? ''}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
                ),
                0.3.height,
                Text(
                  "Remaining: ${_decimalFormat.format(batch.remainingQty ?? 0)}",
                  style: TextStyle(fontSize: 2.6.sp, color: AppColor.black),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                batch.expiryDate ?? "",
                style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
              ),
              0.3.height,
              Text(
                expired ? "Expired" : "${days ?? '—'} days left",
                style: TextStyle(
                  fontSize: 2.8.sp,
                  fontWeight: FontWeight.bold,
                  color: expired ? AppColor.red : AppColor.green,
                ),
              ),
            ],
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
