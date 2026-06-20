import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/view/employees/employee_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/constants/constants.dart';
import '../../../core/extensions/sizer.dart';
import '../../../core/resources/app_colors.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
          preferredSize: Size(double.maxFinite, 24.h),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final statusBarHeight = MediaQuery.of(context).padding.top;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: statusBarHeight),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColor.appColor1, AppColor.appDarkColor],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(7.w),
                    bottomRight: Radius.circular(7.w),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.h,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 7.r,
                            backgroundColor: AppColor.white.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AppColor.white,
                              size: 8.w,
                            ),
                          ),
                          3.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BEACON',
                                  style: TextStyle(
                                    color: AppColor.white,
                                    fontSize: 5.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                0.5.height,
                                Text(
                                  'Field Force Monitoring',
                                  style: TextStyle(
                                    color: AppColor.appLightColor,
                                    fontSize: 3.5.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _showLogoutDialog(context),
                            child: Container(
                              padding: EdgeInsets.all(0.8.w),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColor.white.withValues(alpha: 0.2),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 4.w,
                                backgroundColor: AppColor.red.withValues(
                                  alpha: 0.8,
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: AppColor.white,
                                  size: 5.w,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: AppColor.scaffold.withValues(alpha: 0.2),
                      thickness: 0.5,
                      height: 0,
                    ),
                    1.5.height,
                    Consumer<EmployesController>(
                      builder: (context, controller, child) {
                        final total =
                            controller.employesModel?.users?.length ?? 0;
                        final depts = controller.departments.length;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Row(
                            children: [
                              _miniStat(
                                "Total Users",
                                total.toString(),
                                icon: Icons.groups_rounded,
                                iconClr: AppColor.appColor2,
                              ),
                              3.width,
                              _miniStat(
                                "Departments",
                                depts.toString(),
                                icon: Icons.account_tree_rounded,
                                iconClr: AppColor.green,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    2.height,
                  ],
                ),
              );
            },
          ),
        ),
        body: SafeArea(
          child: Consumer<EmployesController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final allDepts = controller.departments;

              return ListView(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                children: [
                  2.height,
                  if (allDepts.isNotEmpty)
                    Text(
                      "Employee Directory",
                      style: TextStyle(
                        fontSize: 6.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColor.appDarkColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  1.height,
                  if (allDepts.isEmpty)
                    _buildEmptyState()
                  else
                    ...allDepts.map((dept) => _deptCard(dept)),
                  4.height,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          "beacon",
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

  Widget _deptCard(String dept) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppRoutes.push(EmployeeListView(department: dept));
            },
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.5.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColor.appColor1.withValues(alpha: 0.8),
                          AppColor.appDarkColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getDeptIcon(dept),
                      color: AppColor.white,
                      size: 7.w,
                    ),
                  ),
                  4.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 4.5.sp,
                            color: AppColor.appDarkColor,
                          ),
                        ),
                        0.5.height,
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 3.5.w,
                              color: AppColor.appColor2,
                            ),
                            1.5.width,
                            Consumer<EmployesController>(
                              builder: (context, controller, child) {
                                final count = controller
                                    .getEmployeesByDept(dept)
                                    .length;
                                return Text(
                                  "$count Members",
                                  style: TextStyle(
                                    fontSize: 3.2.sp,
                                    color: AppColor.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppColor.appColor1.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 3.5.w,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(
    String title,
    String value, {
    required IconData icon,
    required Color iconClr,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: AppColor.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColor.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconClr, size: 5.w),
            3.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 4.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColor.appLightColor,
                    fontSize: 2.8.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: 15.w,
            color: Colors.grey.shade300,
          ),
          2.height,
          Text(
            "No departments found",
            style: TextStyle(color: Colors.grey, fontSize: 4.sp),
          ),
        ],
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
