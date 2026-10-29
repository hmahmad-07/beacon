import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_dashboard_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_expiry_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_items_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stock_report_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stores_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

class InventoryHubView extends StatelessWidget {
  const InventoryHubView({
    super.key,
    required this.siteName,
    required this.accentColor,
    this.siteImage,
  });

  final String siteName;
  final Color accentColor;
  final String? siteImage;

  static const _gridSections = [
    _Section("Items", "Browse the catalogue", BoxIcons.bxs_box),
    _Section(
      "Stock Report",
      "Levels, search & filters",
      BoxIcons.bxs_bar_chart_alt_2,
    ),
    _Section("Expiry Report", "Batch-level tracking", BoxIcons.bxs_calendar_x),
    _Section("Stores", "Active store directory", BoxIcons.bx_store),
  ];

  void _onTap(BuildContext context, String section) {
    switch (section) {
      case "Dashboard":
        AppRoutes.push(InventoryDashboardView(accentColor: accentColor));
        break;
      case "Items":
        AppRoutes.push(InventoryItemsView(accentColor: accentColor));
        break;
      case "Stock Report":
        AppRoutes.push(InventoryStockReportView(accentColor: accentColor));
        break;
      case "Expiry Report":
        AppRoutes.push(InventoryExpiryView(accentColor: accentColor));
        break;
      case "Stores":
        AppRoutes.push(InventoryStoresView(accentColor: accentColor));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView(
          padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 4.h),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 450),
            childAnimationBuilder: (child) => SlideAnimation(
              verticalOffset: 40,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(child: child),
            ),
            children: [
              _dashboardHeroTile(context),
              2.5.height,
              Text(
                "MODULES",
                style: TextStyle(
                  fontSize: 2.8.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColor.grey,
                ),
              ),
              1.2.height,
              MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 3.w,
                crossAxisSpacing: 3.w,
                itemCount: _gridSections.length,
                itemBuilder: (context, index) {
                  final section = _gridSections[index];
                  return _gridTile(context, section);
                },
              ),
            ],
          ),
        ),
    );
  }

  Widget _dashboardHeroTile(BuildContext context) {
    return Material(
      color: AppColor.transparent,
      borderRadius: BorderRadius.circular(4.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(4.r),
        onTap: () => _onTap(context, "Dashboard"),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.2.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor, AppColor.appDarkColor],
            ),
            borderRadius: BorderRadius.circular(4.r),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.6.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white.withValues(alpha: 0.18),
                ),
                child: Icon(
                  BoxIcons.bxs_dashboard,
                  color: AppColor.white,
                  size: 6.5.w,
                ),
              ),
              3.5.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 4.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    0.3.height,
                    Text(
                      "KPIs, movement & stock value overview",
                      style: TextStyle(
                        fontSize: 2.6.sp,
                        color: AppColor.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 4.w,
                color: AppColor.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridTile(BuildContext context, _Section section) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColor.transparent,
        child: InkWell(
          onTap: () => _onTap(context, section.title),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(2.2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(section.icon, color: accentColor, size: 5.5.w),
                ),
                1.5.height,
                Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
                0.4.height,
                Text(
                  section.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 2.4.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final String subtitle;
  final IconData icon;

  const _Section(this.title, this.subtitle, this.icon);
}
