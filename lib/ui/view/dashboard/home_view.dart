import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/models/project_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../../../core/controllers/auth_controller.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/sizer.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/utils/utils.dart';
import '../../components/animated_option_card.dart';
import '../../components/app_constants.dart';
import 'WMS/inventory_hub_view.dart';
import 'department_picker_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _selectedShopId = "";
  bool _didSelectDefaultShop = false;

  List<Shop> _orderedShops(List<Shop> shops) {
    final rest = <Shop>[];
    final snackShack = <Shop>[];
    for (final shop in shops) {
      if (_getMatchingProject(shop)?.id == AppProject.snackShack.id) {
        snackShack.add(shop);
      } else {
        rest.add(shop);
      }
    }
    return [...rest, ...snackShack];
  }

  AppProject? _getMatchingProject(Shop shop) {
    final name = (shop.shopName ?? "")
        .toLowerCase()
        .replaceAll(" ", "")
        .replaceAll(".", "");
    final id = (shop.shopId ?? "").toLowerCase();

    for (final project in AppProject.all) {
      final pName = project.name
          .toLowerCase()
          .replaceAll(" ", "")
          .replaceAll(".", "");
      final pShort = project.shortName
          .toLowerCase()
          .replaceAll(" ", "")
          .replaceAll(".", "");
      if (name.contains(pName) ||
          pName.contains(name) ||
          name.contains(pShort) ||
          pShort.contains(name) ||
          id == project.id.toLowerCase()) {
        return project;
      }
    }
    return null;
  }

  Color _getShopAccent(Shop shop) {
    return _getMatchingProject(shop)?.accent ?? AppColor.appColor1;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColor.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColor.scaffold,
        appBar: PreferredSize(
          preferredSize: Size(double.maxFinite, 14.h),
          child: _buildHeader(),
        ),
        body: SafeArea(
          child: Consumer<EmployesController>(
            builder: (context, controller, child) {
              if (controller.isLoading && controller.shops.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final shops = _orderedShops(controller.shops);

              // Splash/login's getSites failed (e.g. connect timeout) --
              // offer a retry instead of an empty rail.
              if (shops.isEmpty) {
                return _loadFailedState(controller);
              }

              if (!_didSelectDefaultShop && shops.isNotEmpty) {
                _didSelectDefaultShop = true;
                final firstId = shops.first.shopId ?? "";
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedShopId = firstId);
                });
              }

              final effectiveShopId =
                  _selectedShopId.isEmpty && shops.isNotEmpty
                  ? shops.first.shopId ?? ""
                  : _selectedShopId;

              final selectedShop = shops.firstWhere(
                (s) => s.shopId == effectiveShopId,
                orElse: () => Shop(shopId: effectiveShopId, shopName: "Shop"),
              );

              final displayName = selectedShop.shopName ?? "Shop";

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProjectRail(controller),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProjectTitle(
                          displayName,
                          _getShopAccent(selectedShop),
                        ),
                        Expanded(child: _buildModuleGrid(selectedShop)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _loadFailedState(EmployesController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16.w,
              color: Colors.grey.shade400,
            ),
            2.height,
            Text(
              controller.sitesLoadFailed
                  ? "Couldn't load your shops"
                  : "No shops found",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 4.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
              ),
            ),
            0.8.height,
            Text(
              controller.sitesLoadFailed
                  ? "The server didn't respond in time. Check your internet and try again."
                  : "Pull the latest list from the server.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
            ),
            3.height,
            ElevatedButton.icon(
              onPressed: () => controller.getSites(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.appColor1,
                foregroundColor: AppColor.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.4.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            2.height,
            TextButton(
              onPressed: () => context.read<AuthController>().logout(context),
              child: Text(
                "Log out",
                style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================ Header ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final statusBarHeight = MediaQuery.of(context).padding.top;
        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.only(top: statusBarHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColor.appColor1, AppColor.appDarkColor],
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(10.w)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 6.w,
              right: 6.w,
              top: 2.h,
              bottom: 3.8.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColor.appColor2, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 8.r,
                    backgroundColor: AppColor.white,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColor.appColor1,
                      size: 8.w,
                    ),
                  ),
                ),
                3.width,
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CENTREX',
                          style: TextStyle(
                            color: AppColor.appColor2,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        0.5.height,
                        Text(
                          'Field Force Monitoring',
                          style: TextStyle(
                            color: AppColor.white,
                            fontSize: 4.sp,
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
      },
    );
  }

  // ========================================= Project Rail =========================================

  Widget _buildProjectRail(EmployesController controller) {
    final shops = _orderedShops(controller.shops);
    return Container(
      width: 28.w,
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(
          right: BorderSide(color: AppColor.appLightColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              children: shops.map((shop) => _shopTab(shop: shop)).toList(),
            ),
          ),
          _railLogout(),
        ],
      ),
    );
  }

  Widget _shopTab({required Shop shop}) {
    final bool isSelected = _selectedShopId == shop.shopId;
    final project = _getMatchingProject(shop);
    final accentColor = project?.accent ?? AppColor.appColor1;
    final title = project?.shortName ?? shop.shopName ?? "Shop";

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedShopId = shop.shopId ?? "");
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: 0.8.h, right: 1.5.w),
        padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 1.w),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : AppColor.transparent,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(8.r)),
        ),
        child: Column(
          children: [
            0.4.height,
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 18.w,
              width: 18.w,
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.white,
                border: Border.all(
                  color: isSelected ? accentColor : AppColor.appLightColor,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? AppShadow.soft : null,
              ),
              child: project != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.asset(project.asset, fit: BoxFit.contain),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      color: isSelected ? accentColor : AppColor.grey,
                      size: 7.w,
                    ),
            ),
            0.8.height,
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 3.sp,
                height: 1.2,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accentColor : AppColor.grey,
              ),
            ),
            0.5.height,
          ],
        ),
      ),
    );
  }

  Widget _railLogout() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(
          top: BorderSide(color: AppColor.appLightColor, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.red.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColor.red,
                    size: 5.w,
                  ),
                ),
                0.6.height,
                Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 3.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================= Module Grid =========================================

  Widget _buildProjectTitle(String displayName, Color accentColor) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        children: [
          Container(width: 1.w, height: 3.h, color: accentColor),
          2.width,
          Expanded(
            child: Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 5.sp,
                height: 1.2,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid(Shop? shop) {
    final hasDepartments = (shop?.departments ?? []).isNotEmpty;
    final accent = shop != null ? _getShopAccent(shop) : AppColor.appColor1;
    final siteImage = shop != null ? _getMatchingProject(shop)?.asset : null;

    return AnimationLimiter(
      key: ValueKey(_selectedShopId),
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 4.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 3.w,
          crossAxisSpacing: 3.w,
          childAspectRatio: 0.72,
        ),
        itemCount: AppModule.all.length,
        itemBuilder: (context, index) {
          final module = AppModule.all[index];

          final isInventory = module.id == AppModule.inventory.id;
          final locked = module.comingSoon || (!hasDepartments && !isInventory);

          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 3,
            duration: const Duration(milliseconds: 400),
            child: ScaleAnimation(
              scale: 0.92,
              child: FadeInAnimation(
                child: AnimatedOptionCard(
                  title: module.title,
                  subtitle: module.subtitle,
                  icon: module.icon,
                  accentColor: accent,
                  locked: locked,
                  onTap: () {
                    if (module.comingSoon) {
                      _showComingSoon(module.title);
                      return;
                    }
                    if (isInventory) {
                      AppRoutes.push(
                        InventoryHubView(
                          siteName: shop?.shopName ?? "Inventory",
                          accentColor: accent,
                          siteImage: siteImage,
                        ),
                      );
                      return;
                    }
                    if (!hasDepartments || shop == null) {
                      _showNoDepartments(shop);
                      return;
                    }
                    AppRoutes.push(
                      DepartmentPickerView(
                        module: module,
                        shop: shop,
                        accentColor: accent,
                        siteImage: siteImage,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComingSoon(String moduleTitle) {
    Utils.showSnackBar(context, "$moduleTitle module is coming soon.");
  }

  void _showNoDepartments(Shop? shop) {
    Utils.showSnackBar(
      context,
      "No departments configured for ${shop?.shopName ?? 'this shop'}.",
    );
  }

  // ============================================= Shared UI =============================================

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          "CENTREX",
          style: TextStyle(color: AppColor.appColor1, fontSize: 8.sp),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 1.h),
          child: Text(
            "Hey ${Constants.name}, Are you sure you want to log out from the system?",
            style: TextStyle(fontSize: 4.sp, color: AppColor.appDarkColor),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text("Cancel", style: TextStyle(color: AppColor.green)),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthController>().logout(context);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
