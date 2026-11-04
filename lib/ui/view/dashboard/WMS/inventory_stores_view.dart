import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_store_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Stores" page of the reference stock dashboard, narrowed to
/// active stores only -- inactive/decommissioned entries (kitchens taken
/// offline, the old packing material store) aren't operationally relevant
/// here, just noise in a directory meant to look and feel like a real WMS
/// store list.
class InventoryStoresView extends StatefulWidget {
  const InventoryStoresView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<InventoryStoresView> createState() => _InventoryStoresViewState();
}

class _InventoryStoresViewState extends State<InventoryStoresView> {
  final _searchController = TextEditingController();
  final _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WMSController>().ensureStoresLoaded(context);
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
          final active = controller.activeStores;
          final filtered = controller.filteredActiveStores;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchField(),
                    1.height,
                    Row(
                      children: [
                        Icon(
                          BoxIcons.bxs_check_shield,
                          size: 3.5.w,
                          color: AppColor.green,
                        ),
                        1.2.width,
                        Text(
                          "${active.length} active stores",
                          style: TextStyle(
                            fontSize: 3.1.sp,
                            fontWeight: FontWeight.w600,
                            color: widget.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.isStoresLoading && active.isEmpty
                    ? const AppLoadingView()
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
                        separatorBuilder: (context, index) => 1.4.height,
                        itemBuilder: (context, index) =>
                            _storeCard(filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return InventorySearchBar(
      controller: _searchController,
      hintText: "Search store name or code…",
      accentColor: widget.accentColor,
      onChanged: (v) => context.read<WMSController>().setStoresQuery(v),
    );
  }

  Widget _storeCard(InventoryStore store) {
    final negative = (store.balance ?? 0) < 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
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
                padding: EdgeInsets.all(3.5.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        BoxIcons.bxs_building,
                        color: widget.accentColor,
                        size: 6.w,
                      ),
                    ),
                    3.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 3.8.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.appDarkColor,
                            ),
                          ),
                          0.3.height,
                          Text(
                            store.code ?? "",
                            style: TextStyle(
                              fontSize: 2.7.sp,
                              color: AppColor.grey,
                            ),
                          ),
                          1.4.height,
                          Row(
                            children: [
                              _metric(
                                "In",
                                store.totalIn,
                                icon: BoxIcons.bxs_up_arrow,
                                iconColor: AppColor.green,
                              ),
                              _metric(
                                "Out",
                                store.totalOut,
                                icon: BoxIcons.bxs_down_arrow,
                                iconColor: AppColor.red,
                              ),
                              _metric(
                                "Balance",
                                store.balance,
                                highlight: negative,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    String label,
    num? value, {
    bool highlight = false,
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
                style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
              ),
            ],
          ),
          0.2.height,
          Text(
            _decimalFormat.format(value ?? 0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 3.2.sp,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColor.red : AppColor.appDarkColor,
            ),
          ),
        ],
      ),
    );
  }
}
