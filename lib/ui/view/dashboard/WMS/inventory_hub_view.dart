import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_dashboard_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_expiry_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_items_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stock_report_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stores_view.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
        pushInSite(accentColor, InventoryDashboardView(accentColor: accentColor));
        break;
      case "Items":
        pushInSite(accentColor, InventoryItemsView(accentColor: accentColor));
        break;
      case "Stock Report":
        pushInSite(accentColor, InventoryStockReportView(accentColor: accentColor));
        break;
      case "Expiry Report":
        pushInSite(accentColor, InventoryExpiryView(accentColor: accentColor));
        break;
      case "Stores":
        pushInSite(accentColor, InventoryStoresView(accentColor: accentColor));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SiteScope.wrap(
      accent: accentColor,
      child: Builder(
        builder: (context) => AnimationLimiter(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
            children: [
              siteStagger(
                0,
                SiteHeaderCard(
                  margin: EdgeInsets.zero,
                  title: "Inventory",
                  subtitle: siteName,
                  description: "Store stock, movement and expiry",
                  logoAsset: siteImage,
                  icon: BoxIcons.bxs_store,
                  badge: "${_gridSections.length + 1} modules",
                ),
              ),
              2.5.height,
              siteStagger(1, _dashboardHeroTile(context)),
              3.height,
              siteStagger(
                2,
                SiteSectionTitle("Reports", count: _gridSections.length),
              ),
              for (final (index, section) in _gridSections.indexed)
                siteStagger(index + 3, _gridTile(context, section)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardHeroTile(BuildContext context) {
    return SiteBanner(
      onTap: () => _onTap(context, "Dashboard"),
      eyebrow: "Overview",
      title: "Dashboard",
      subtitle: "KPIs, movement & stock value overview",
      titleSize: 4.8.sp,
      leading: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(BoxIcons.bxs_dashboard, color: Colors.white, size: 7.w),
      ),
      trailing: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white,
          size: 3.6.w,
        ),
      ),
    );
  }

  Widget _gridTile(BuildContext context, _Section section) {
    return SiteActionTile(
      icon: section.icon,
      title: section.title,
      subtitle: section.subtitle,
      onTap: () => _onTap(context, section.title),
    );
  }

}

class _Section {
  final String title;
  final String subtitle;
  final IconData icon;

  const _Section(this.title, this.subtitle, this.icon);
}
