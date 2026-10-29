import 'package:beacon/core/constants/constants.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/models/site_entry.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/WMS/inventory_hub_view.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_hub_view.dart';
import 'package:beacon/ui/view/dashboard/department_picker_view.dart';
import 'package:beacon/ui/view/dashboard/sales/sales_hub_view.dart';
import 'package:beacon/ui/view/privacy/privacy_policy_view.dart';
import 'package:flutter/material.dart';

/// The modules of one site. Employees and HR show only where the site has
/// modules in use. Sales shows only for Paani and Corporate Canteen.
/// Inventory is in the drawer because it covers every site's stores.
class SiteHomeView extends StatelessWidget {
  const SiteHomeView({super.key, required this.site});

  final SiteEntry site;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: AppBar(
        title: Text(site.name),
        leading: Builder(
          builder: (menuContext) => IconButton(
            tooltip: "Menu",
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(menuContext).openDrawer(),
          ),
        ),
      ),
      drawer: _SiteDrawer(site: site),
      body: ListView(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        children: [
          _Banner(site: site),
          2.5.height,
          if (site.hasModules) ...[
            _sectionTitle("Modules"),
            1.5.height,
            _moduleTile(context, AppModule.employees),
            _moduleTile(context, AppModule.hr),
          ],
          if (site.hasChecklists) ...[
            if (site.hasModules) 2.5.height,
            _sectionTitle("Checklists"),
            1.5.height,
            _moduleTile(context, AppModule.checklists),
          ],
          if (site.hasSales) ...[
            if (site.hasModules || site.hasChecklists) 2.5.height,
            _sectionTitle("Sales"),
            1.5.height,
            _moduleTile(context, AppModule.sales),
          ],
          if (site.screenModules.isEmpty)
            const _EmptyNote(
              text: "No modules are set up for this site yet.",
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 4.2.sp,
        fontWeight: FontWeight.bold,
        color: AppColor.appDarkColor,
      ),
    );
  }

  Widget _moduleTile(BuildContext context, AppModule module) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.6.h),
      child: AppTile(
        icon: module.icon,
        title: module.title,
        subtitle: module.subtitle,
        accent: site.accent,
        onTap: () => _open(context, module),
      ),
    );
  }

  void _open(BuildContext context, AppModule module) {
    if (!site.supports(module)) {
      Utils.showSnackBar(
        context,
        "${module.title} is not set up for ${site.name}.",
      );
      return;
    }

    if (module.id == AppModule.checklists.id) {
      _openPage(
        context,
        module.title,
        ChecklistHubView(accentColor: site.accent),
      );
      return;
    }

    if (module.id == AppModule.sales.id) {
      final project = site.project;
      if (project == null) return;
      _openPage(context, module.title, SalesHubView(business: project));
      return;
    }

    final shop = site.shop;
    if (shop == null) return;
    _openPage(
      context,
      module.title,
      DepartmentGrid(
        module: module,
        shop: shop,
        accentColor: site.accent,
        siteImage: site.asset,
      ),
    );
  }

  void _openPage(BuildContext context, String title, Widget body) {
    AppRoutes.push(
      Scaffold(
        backgroundColor: AppColor.scaffold,
        appBar: AppBar(title: Text(title)),
        body: body,
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.site});

  final SiteEntry site;

  @override
  Widget build(BuildContext context) {
    final count = site.screenModules.length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.appLightColor),
      ),
      child: Row(
        children: [
          SiteLogo(asset: site.asset, accent: site.accent, size: 16.w),
          4.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 4.8.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
                0.4.height,
                Text(
                  "$count ${count == 1 ? 'module' : 'modules'} available",
                  style: TextStyle(fontSize: 3.2.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.appLightColor),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 3.4.sp, color: AppColor.grey),
      ),
    );
  }
}

class _SiteDrawer extends StatelessWidget {
  const _SiteDrawer({required this.site});

  final SiteEntry site;

  void _openInventory(BuildContext context) {
    final navigator = Navigator.of(context);
    Scaffold.of(context).closeDrawer();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColor.scaffold,
          appBar: AppBar(title: const Text("Inventory")),
          body: InventoryHubView(
            siteName: site.name,
            accentColor: site.accent,
            siteImage: site.asset,
          ),
        ),
      ),
    );
  }

  void _openPrivacy(BuildContext context) {
    final navigator = Navigator.of(context);
    Scaffold.of(context).closeDrawer();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = Constants.name.trim();
    final initial = name.isEmpty ? "?" : name[0].toUpperCase();

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.7,
      backgroundColor: AppColor.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 3.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 6.w,
                    backgroundColor: AppColor.appColor1,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 4.4.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                  3.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name.isEmpty ? "Signed in" : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 4.2.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColor.appDarkColor,
                          ),
                        ),
                        if (Constants.code.isNotEmpty) ...[
                          0.3.height,
                          Text(
                            "Code ${Constants.code}",
                            style: TextStyle(
                              fontSize: 3.0.sp,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Menu
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.h),
              child: Text(
                "MENU",
                style: TextStyle(
                  fontSize: 2.5.sp,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColor.grey,
                ),
              ),
            ),

            // Inventory: a highlighted card, since it covers every site's stores
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Material(
                color: AppColor.appColor1.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openInventory(context),
                  child: Padding(
                    padding: EdgeInsets.all(3.5.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.6.w),
                          decoration: BoxDecoration(
                            color: AppColor.appColor1,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppModule.inventory.icon,
                            size: 5.w,
                            color: AppColor.white,
                          ),
                        ),
                        3.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppModule.inventory.title,
                                style: TextStyle(
                                  fontSize: 4.0.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.appDarkColor,
                                ),
                              ),
                              0.3.height,
                              Text(
                                "Stock of every site's store",
                                style: TextStyle(
                                  fontSize: 3.0.sp,
                                  color: AppColor.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColor.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            1.5.height,

            _DrawerItem(
              icon: Icons.swap_horiz_rounded,
              label: "Switch site",
              subtitle: "Back to all sites",
              // Back to the first route, which is the sites list.
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            _DrawerItem(
              icon: Icons.privacy_tip_outlined,
              label: "Privacy policy",
              subtitle: "How your information is handled",
              onTap: () => _openPrivacy(context),
            ),

            const Spacer(),

            // Account
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: "Logout",
              subtitle: "Sign out of CENTREX",
              color: AppColor.red,
              // The navigator's context stays valid while the drawer closes.
              onTap: () => confirmLogout(Navigator.of(context).context),
            ),
            1.height,
          ],
        ),
      ),
    );
  }
}

/// One drawer row: a round icon, a title, and a short subtitle. Every row in
/// the drawer uses it, so spacing and size stay the same.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColor.appDarkColor;
    final iconColor = color ?? AppColor.grey;

    return Material(
      color: AppColor.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.8.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.4.w),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 4.8.w, color: iconColor),
              ),
              3.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 3.8.sp,
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                    0.3.height,
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 2.9.sp,
                        color: AppColor.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
