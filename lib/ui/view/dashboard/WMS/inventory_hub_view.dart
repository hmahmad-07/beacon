import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_dashboard_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_expiry_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_items_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stock_report_view.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_stores_view.dart';
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

  static const _sections = [
    "Dashboard",
    "Items",
    "Stock Report",
    "Expiry Report",
    "Stores",
  ];

  IconData _iconFor(String section) {
    switch (section) {
      case "Dashboard":
        return BoxIcons.bxs_dashboard;
      case "Items":
        return BoxIcons.bxs_box;
      case "Stock Report":
        return BoxIcons.bxs_bar_chart_alt_2;
      case "Expiry Report":
        return BoxIcons.bxs_calendar_x;
      case "Stores":
        return BoxIcons.bx_store;
      default:
        return BoxIcons.bx_folder;
    }
  }

  void _onTap(String section) {
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
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Inventory"),
      body: Column(
        children: [
          Expanded(
            child: AnimationLimiter(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                itemCount: _sections.length,
                separatorBuilder: (context, index) => 1.5.height,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      horizontalOffset: 80,
                      curve: Curves.easeOutCubic,
                      child: FadeInAnimation(
                        child: _sectionTile(
                          section: section,
                          onTap: () => _onTap(section),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile({required String section, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.5.r),
        child: Material(
          color: AppColor.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 6.w,
              vertical: 0.6.h,
            ),
            leading: Icon(_iconFor(section), color: accentColor, size: 8.r),
            title: Text(
              section,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 4.5.sp,
                color: AppColor.black,
                shadows: AppShadow.textShadow,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 4.r,
              color: AppColor.grey,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
