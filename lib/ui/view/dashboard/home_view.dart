import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/models/employes_model.dart';
import 'package:beacon/core/models/project_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:provider/provider.dart';
import '../../../../core/controllers/auth_controller.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/sizer.dart';
import '../../../../core/resources/app_colors.dart';
import '../../components/app_constants.dart';
import 'department_options_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _selectedShopId = "";
  bool _didSelectDefaultShop = false;

  // Snack Shack renders last in the rail; everyone else keeps the
  // order the API returns them in.
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
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final shops = _orderedShops(controller.shops);

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
                          selectedShop.departments?.length ?? 0,
                          displayName,
                          _getShopAccent(selectedShop),
                        ),
                        Expanded(child: _buildSingleShopView(selectedShop)),
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

  // ========================================= Department Grid =========================================

  Widget _buildProjectTitle(
    int deptCount,
    String displayName,
    Color accentColor,
  ) {
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

  Widget _buildSingleShopView(Shop? shop) {
    final depts = shop?.departments ?? [];
    if (depts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_off_rounded,
        message: "No departments in ${shop?.shopName ?? 'this shop'}",
      );
    }

    final accent = shop != null ? _getShopAccent(shop) : AppColor.appColor1;

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
        itemCount: depts.length,
        itemBuilder: (context, index) {
          final dept = depts[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 3,
            duration: const Duration(milliseconds: 400),
            child: ScaleAnimation(
              scale: 0.92,
              child: FadeInAnimation(
                child: _deptCard(
                  dept: dept,
                  accentColor: accent,
                  shopId: shop?.shopId,
                  shopName: shop?.shopName,
                  siteImage: shop != null
                      ? _getMatchingProject(shop)?.asset
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _deptCard({
    required Department dept,
    required Color accentColor,
    String? shopId,
    String? shopName,
    String? siteImage,
  }) {
    final name = dept.departmentName ?? "Department";

    return _AnimatedDepartmentCard(
      name: name,
      icon: _getDeptIcon(name),
      accentColor: accentColor,
      onTap: () {
        AppRoutes.push(
          DepartmentOptionsView(
            siteImage: siteImage,
            deptName: name,
            deptId: dept.departmentId ?? 0,
            shopId: shopId ?? "N/A",
            shopName: shopName ?? "N/A",
            accentColor: accentColor,
          ),
        );
      },
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

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.w, color: Colors.grey.shade300),
            2.height,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 3.5.sp),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeptIcon(String dept) {
    final d = dept.toLowerCase();
    if (d.contains("kitchen")) return IonIcons.restaurant;
    if (d.contains("internal audit") || d.contains("audit")) {
      return BoxIcons.bx_clipboard;
    }
    if (RegExp(r"\bit\b").hasMatch(d)) return BoxIcons.bx_laptop;
    if (d.contains("sales")) return BoxIcons.bx_bar_chart_alt;
    if (d.contains("admin")) return BoxIcons.bx_shield;
    if (d.contains("hr") || d.contains("human")) return BoxIcons.bx_user;
    if (d.contains("account") || d.contains("finance")) {
      return BoxIcons.bx_wallet;
    }
    if (d.contains("marketing")) return IonIcons.megaphone;
    if (d.contains("operation")) return BoxIcons.bx_cog;
    if (d.contains("production")) return IonIcons.construct;
    if (d.contains("purchase")) return BoxIcons.bx_cart;
    if (d.contains("supply chain")) return BoxIcons.bx_package;
    if (d.contains("store")) return BoxIcons.bx_store;
    return BoxIcons.bx_buildings;
  }
}

class _AnimatedDepartmentCard extends StatefulWidget {
  const _AnimatedDepartmentCard({
    required this.name,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_AnimatedDepartmentCard> createState() =>
      _AnimatedDepartmentCardState();
}

class _AnimatedDepartmentCardState extends State<_AnimatedDepartmentCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.5.r),
        child: Material(
          color: AppColor.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColor.white,
                          AppColor.white,
                          AppColor.white,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -7.w,
                  right: -6.w,
                  child: _glassOrb(size: 22.w),
                ),
                Positioned(
                  bottom: -10.w,
                  left: -8.w,
                  child: _glassOrb(size: 25.w),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 2.2.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(3.5.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accentColor,
                          ),
                          child: Icon(
                            widget.icon,
                            color: AppColor.white,
                            size: 7.w,
                          ),
                        ),
                        1.5.height,
                        Flexible(
                          child: Text(
                            widget.name,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColor.black,
                              fontSize: 3.sp,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: AppColor.appDarkColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassOrb({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.accentColor.withValues(alpha: 0.1),
        border: Border.all(color: AppColor.white.withValues(alpha: 0.12)),
      ),
    );
  }
}
