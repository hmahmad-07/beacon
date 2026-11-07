import 'dart:math' as math;

import 'package:beacon/core/controllers/wms_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/WMS/inventory_store_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_filters.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:beacon/ui/view/dashboard/WMS/widgets/inventory_ui.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

/// Mirrors the "Stores" page of the reference stock dashboard, narrowed to
/// active stores only -- inactive/decommissioned entries (kitchens taken
/// offline, the old packing material store) aren't operationally relevant
/// here, just noise in a directory meant to look and feel like a real WMS
/// store list.
class InventoryStoresView extends StatefulWidget {
  const InventoryStoresView({
    super.key,
    required this.accentColor,
    this.heroTag,
  });

  final Color accentColor;

  /// Hero tag of the tile that opened this screen; its icon flies into the
  /// loading view.
  final Object? heroTag;

  @override
  State<InventoryStoresView> createState() => _InventoryStoresViewState();
}

class _InventoryStoresViewState extends State<InventoryStoresView> {
  final _searchController = TextEditingController();

  /// True once the stores have loaded for this visit.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<WMSController>().getStores(context);
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
      appBar: const CustomAppBar(title: "Stores"),
      body: Consumer<WMSController>(
        builder: (context, controller, child) {
          final active = controller.activeStores;
          final filtered = controller.filteredActiveStores;
          final totalIn = active.fold<num>(0, (s, e) => s + (e.totalIn ?? 0));
          final totalOut = active.fold<num>(0, (s, e) => s + (e.totalOut ?? 0));
          final totalBalance = active.fold<num>(
            0,
            (s, e) => s + math.max(0, e.balance ?? 0),
          );

          if (!_ready || controller.isStoresLoading) {
            return RefreshIndicator(
              color: widget.accentColor,
              onRefresh: () => controller.getStores(context),
              child: InventoryLoadingView(
                key: const ValueKey('stores-loading'),
                heroTag: widget.heroTag,
                icon: BoxIcons.bxs_store,
                label: "Loading stores…",
              ),
            );
          }

          return RefreshIndicator(
            color: widget.accentColor,
            onRefresh: () => controller.getStores(context),
            child: AnimationLimiter(
              key: const ValueKey('stores-content'),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
                children: [
                  if (active.isNotEmpty) ...[
                    invEnter(
                      0,
                      InventoryHero(
                        icon: BoxIcons.bxs_store,
                        eyebrow: "Active stores",
                        title: "${active.length} stores",
                        subtitle: "Stock received, issued and on hand",
                        child: InventoryHeroStats(
                          stats: [
                            ("Received", invCompact(totalIn)),
                            ("Issued", invCompact(totalOut)),
                            ("On hand", invCompact(totalBalance)),
                          ],
                        ),
                      ),
                    ),
                    2.4.height,
                  ],
                  invEnter(1, _searchField()),
                  if (filtered.isEmpty)
                    SiteEmptyState(
                      icon: BoxIcons.bxs_store,
                      title: "No stores found",
                      message: controller.storesQuery.isEmpty
                          ? "No active store is set up yet."
                          : "Nothing matches \"${controller.storesQuery}\".",
                    )
                  else ...[
                    invEnter(
                      2,
                      InventoryResultLine(
                        text:
                            "${filtered.length} ${filtered.length == 1 ? 'store' : 'stores'}",
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              BoxIcons.bxs_check_shield,
                              size: 3.6.w,
                              color: InventoryPalette.stockIn,
                            ),
                            1.width,
                            Text(
                              "Active only",
                              style: TextStyle(
                                fontSize: 2.8.sp,
                                color: AppColor.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    1.height,
                    for (final (i, store) in filtered.indexed)
                      invEnter(3 + i, _storeCard(store, totalBalance)),
                  ],
                ],
              ),
            ),
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

  Widget _storeCard(InventoryStore store, num totalBalance) {
    final balance = store.balance ?? 0;
    final negative = balance < 0;
    final totalIn = store.totalIn ?? 0;
    final totalOut = store.totalOut ?? 0;
    final color = negative ? InventoryPalette.stockOut : widget.accentColor;

    return SiteCard(
      margin: EdgeInsets.only(bottom: 1.4.h),
      padding: EdgeInsets.all(3.6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InventoryAvatar(name: store.name ?? "", color: color, size: 12.w),
              3.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (store.name ?? "").trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 3.7.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColor.appDarkColor,
                        height: 1.2,
                      ),
                    ),
                    0.6.height,
                    Row(
                      children: [
                        if ((store.code ?? "").isNotEmpty) ...[
                          InventoryTag(store.code!, icon: Icons.tag_rounded),
                          1.5.width,
                        ],
                        if (!negative && totalBalance > 0)
                          Text(
                            "${invPercent(balance, totalBalance)} of all stock",
                            style: TextStyle(
                              fontSize: 2.7.sp,
                              color: AppColor.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              2.width,
              InventoryFigure(
                label: "On hand",
                value: invQty(balance),
                color: negative
                    ? InventoryPalette.stockOut
                    : AppColor.appDarkColor,
                alignEnd: true,
                size: 4.6.sp,
              ),
            ],
          ),
          1.8.height,
          InventorySplitBar(
            first: totalIn,
            second: totalOut,
            firstColor: InventoryPalette.received,
            secondColor: InventoryPalette.issued,
          ),
          1.height,
          Row(
            children: [
              Expanded(
                child: InventoryFigure(
                  label: "Received",
                  value: invQty(totalIn),
                  icon: Icons.square_rounded,
                  iconColor: InventoryPalette.received,
                  size: 3.3.sp,
                ),
              ),
              Expanded(
                child: InventoryFigure(
                  label: "Issued",
                  value: invQty(totalOut),
                  icon: Icons.square_rounded,
                  iconColor: InventoryPalette.issued,
                  size: 3.3.sp,
                ),
              ),
              if (totalIn > 0)
                SitePill.tint(
                  "${invPercent(totalOut, totalIn)} issued",
                  negative ? InventoryPalette.stockOut : InventoryPalette.deep,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
