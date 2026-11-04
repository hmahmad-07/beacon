import 'package:beacon/core/constants/constants.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/site_entry.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/site_home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/module_model.dart';
import '../privacy/privacy_policy_view.dart';
import '../privacy/terms_conditions_view.dart';
import 'WMS/inventory_hub_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final emp = context.read<EmployesController>();
      if (emp.shops.isEmpty && !emp.isLoading) {
        emp.getSites(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.scaffold,
        body: Consumer<EmployesController>(
          builder: (context, emp, _) {
            final sites = SiteEntry.fromShops(emp.shops);
            return Column(
              children: [
                const _Header(),
                Expanded(child: _body(context, emp, sites)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    EmployesController emp,
    List<SiteEntry> sites,
  ) {
    final notLoadedYet = emp.sitesDetailModel == null && !emp.sitesLoadFailed;
    if (notLoadedYet || (emp.isLoading && sites.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (sites.isEmpty) {
      return AppErrorView(
        icon: emp.sitesLoadFailed
            ? Icons.cloud_off_rounded
            : Icons.store_mall_directory_outlined,
        message: emp.sitesLoadFailed
            ? "Could not load your sites. Check your connection and try again."
            : "No sites are assigned to this account.",
        onRetry: () => emp.getSites(context),
      );
    }

    return RefreshIndicator(
      color: AppColor.appColor1,
      onRefresh: () => emp.getSites(context),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2.5.w,
          crossAxisSpacing: 2.5.w,
          childAspectRatio: 0.82,
        ),
        itemCount: sites.length,
        itemBuilder: (context, index) {
          final site = sites[index];
          return _SiteCard(
            site: site,
            onTap: () => AppRoutes.push(SiteHomeView(site: site)),
          );
        },
      ),
    );
  }
}

void openSiteMenu(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Close menu",
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, animation, secondaryAnimation) =>
        const AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Align(alignment: Alignment.centerLeft, child: _SiteDrawer()),
        ),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final name = Constants.name.trim();
    final greeting = name.isEmpty ? "Hello" : "Hello, $name";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.appLightColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
          child: Row(
            children: [
              IconButton.filled(
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  backgroundColor: WidgetStatePropertyAll(
                    AppColor.appLightColor,
                  ),
                ),
                tooltip: "Menu",
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => openSiteMenu(context),
              ),
              2.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CENTREX",
                      style: TextStyle(
                        color: AppColor.appColor1,
                        fontSize: 6.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    0.5.height,
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.appDarkColor,
                        fontSize: 4.sp,
                        fontWeight: FontWeight.bold,
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

class _SiteDrawer extends StatelessWidget {
  const _SiteDrawer();

  // Inventory covers every site's stores, so it is not tied to one site.
  void _openInventory(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColor.scaffold,
          appBar: const CustomAppBar(title: "Inventory"),
          body: InventoryHubView(
            siteName: "All sites",
            accentColor: AppColor.appColor1,
          ),
        ),
      ),
    );
  }

  void _openPrivacy(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyView()),
    );
  }

  void _openTerms(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const TermsConditionsView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.7,
      backgroundColor: AppColor.white,
      shape: const RoundedRectangleBorder(),
      // The header paints under the status bar, so SafeArea skips the top.
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              name: Constants.name.trim(),
              role: Constants.type.trim(),
            ),

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
                        Icon(Icons.chevron_right_rounded, color: AppColor.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            1.5.height,

            _DrawerItem(
              icon: Icons.privacy_tip_outlined,
              label: "Privacy policy",
              subtitle: "How your information is handled",
              onTap: () => _openPrivacy(context),
            ),
            _DrawerItem(
              icon: Icons.gavel_rounded,
              label: "Terms & conditions",
              subtitle: "Rules for using Beacon",
              onTap: () => _openTerms(context),
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
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                confirmLogout(navigator.context);
              },
            ),
            1.height,
          ],
        ),
      ),
    );
  }
}

/// Top of the menu: brand, the signed-in user's avatar, name and role. It also
/// paints under the status bar so the top of the drawer is one colour.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? "Signed in" : name;
    final initial = name.isEmpty ? "?" : name[0].toUpperCase();
    final displayRole = role.isEmpty
        ? ""
        : role[0].toUpperCase() + role.substring(1);
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(6.w, statusBarHeight + 3.h, 6.w, 3.5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.appColor1, AppColor.appDarkColor],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "CENTREX",
            style: TextStyle(
              color: AppColor.appColor2,
              fontSize: 3.6.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
          3.height,
          Row(
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white.withValues(alpha: 0.12),
                  border: Border.all(color: AppColor.appColor2, width: 2),
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 6.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              4.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (displayRole.isNotEmpty) ...[
                      1.height,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 3.6.sp,
                              color: AppColor.appColor2,
                            ),
                            1.5.width,
                            Text(
                              displayRole,
                              style: TextStyle(
                                color: AppColor.white.withValues(alpha: 0.92),
                                fontSize: 3.3.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                      style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
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

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site, required this.onTap});

  final SiteEntry site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = site.screenModules.length;

    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.appLightColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: SiteLogo(
                    asset: site.asset,
                    accent: site.accent,
                    size: 22.w,
                  ),
                ),
              ),
              1.height,
              Text(
                site.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.8.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
              0.4.height,
              Text(
                "$count ${count == 1 ? 'module' : 'modules'}",
                style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
