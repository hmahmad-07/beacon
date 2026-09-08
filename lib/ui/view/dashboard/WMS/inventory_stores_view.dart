import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_store_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// Mirrors the "Stores" page of the reference stock dashboard: a flat,
/// site-independent list of every store known to the inventory system.
class InventoryStoresView extends StatefulWidget {
  const InventoryStoresView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryStoresView> createState() => _InventoryStoresViewState();
}

class _InventoryStoresViewState extends State<InventoryStoresView> {
  final _searchController = TextEditingController();
  String _query = "";
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<WMSController>();
      if (controller.storesModel == null) {
        controller.getStores(context);
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
      appBar: CustomAppBar(title: "Stores"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final all = controller.storesModel?.data ?? [];
          final filtered = _query.isEmpty
              ? all
              : all
                    .where(
                      (s) => (s.name ?? "").toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                    )
                    .toList();

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchField(),
                    1.height,
                    Text(
                      "${all.length} stores",
                      style: TextStyle(
                        fontSize: 3.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.isStoresLoading && all.isEmpty
                    ? _loadingSkeleton()
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          "No stores found",
                          style: TextStyle(
                            fontSize: 3.5.sp,
                            color: AppColor.grey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => 1.2.height,
                        itemBuilder: (context, index) =>
                            _storeTile(filtered[index]),
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
      hintText: "Search store name or code…",
      isLabel: false,
      onChanged: (v) => setState(() => _query = v.trim()),
      prefix: Icon(Icons.search, color: AppColor.grey, size: 5.w),
    );
  }

  Widget _storeTile(InventoryStore store) {
    final negative = (store.balance ?? 0) < 0;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  store.name ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.8.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
              ),
              _statusChip(store),
            ],
          ),
          0.4.height,
          Text(
            store.code ?? "",
            style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
          ),
          1.2.height,
          Row(
            children: [
              _metric("In", store.totalIn),
              4.width,
              _metric("Out", store.totalOut),
              4.width,
              _metric("Balance", store.balance, highlight: negative),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(InventoryStore store) {
    final active = store.isActive;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: (active ? AppColor.green : AppColor.grey).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Text(
        active ? "Active" : (store.status ?? "—"),
        style: TextStyle(
          fontSize: 2.4.sp,
          fontWeight: FontWeight.bold,
          color: active ? AppColor.green : AppColor.grey,
        ),
      ),
    );
  }

  Widget _metric(String label, num? value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 2.4.sp, color: AppColor.grey),
          ),
          Text(
            _decimalFormat.format(value ?? 0),
            style: TextStyle(
              fontSize: 3.sp,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColor.red : AppColor.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(bottom: 1.2.h),
          height: 11.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3.5.r),
          ),
        ),
      ),
    );
  }
}
