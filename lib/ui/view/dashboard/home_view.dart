import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/models/project_model.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/view/employees/employee_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
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
  late String _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = "all";
  }

  Color get _accentColor {
    if (_selectedProjectId == "all") {
      return AppColor.appColor1;
    }
    return AppProject.all
        .firstWhere(
          (p) => p.id == _selectedProjectId,
          orElse: () => AppProject.all.first,
        )
        .accent;
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

              final grouped = controller.projectDepartments;
              final isAll = _selectedProjectId == "all";
              final visibleDepts = isAll
                  ? controller.allDepartments
                  : grouped[_selectedProjectId] ?? const <String>[];
              final displayName = isAll
                  ? "All Departments"
                  : AppProject.all
                        .firstWhere(
                          (p) => p.id == _selectedProjectId,
                          orElse: () => AppProject.all.first,
                        )
                        .name;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProjectRail(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isAll)
                          _buildProjectTitle(visibleDepts.length, displayName),
                        Expanded(
                          child: visibleDepts.isEmpty
                              ? _buildEmptyState(
                                  icon: Icons.folder_off_rounded,
                                  message: "No departments in $displayName",
                                )
                              : isAll
                              ? _buildAllProjectsGrid(controller)
                              : _buildDeptGrid(controller, visibleDepts),
                        ),
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

  Widget _buildProjectRail() {
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
              children: [
                _allTab(),
                ...AppProject.all.map(
                  (project) => _projectTab(project: project),
                ),
              ],
            ),
          ),
          _railLogout(),
        ],
      ),
    );
  }

  Widget _allTab() {
    final bool isSelected = _selectedProjectId == "all";
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedProjectId = "all");
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: 0.8.h, right: 1.5.w),
        padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 1.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.appDarkColor.withValues(alpha: 0.1)
              : AppColor.transparent,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(8.r)),
        ),
        child: Column(
          children: [
            0.4.height,
            Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: AppColor.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColor.appDarkColor
                      : AppColor.appLightColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 15.w,
                width: 15.w,
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColor.appDarkColor : AppColor.white,

                  boxShadow: isSelected ? AppShadow.soft : null,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: isSelected ? AppColor.white : AppColor.grey,
                  size: 8.w,
                ),
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

  Widget _projectTab({required AppProject project}) {
    final bool isSelected = _selectedProjectId == project.id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedProjectId = project.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: 0.8.h, right: 1.5.w),
        padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 1.w),
        decoration: BoxDecoration(
          color: isSelected
              ? project.accent.withValues(alpha: 0.1)
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
                  color: isSelected ? project.accent : AppColor.appLightColor,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? AppShadow.soft : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.asset(project.asset, fit: BoxFit.contain),
              ),
            ),
            0.8.height,
            Text(
              project.shortName,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 3.sp,
                height: 1.2,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? project.accent : AppColor.grey,
              ),
            ),
            0.5.height,
          ],
        ),
      ),
    );
  }

  // ========================================= Department Grid =========================================

  Widget _buildProjectTitle(int deptCount, String displayName) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        children: [
          Container(
            width: 1.w,
            height: 3.h,
            color: _selectedProjectId == "all"
                ? AppColor.appColor1
                : AppProject.all
                      .firstWhere(
                        (p) => p.id == _selectedProjectId,
                        orElse: () => AppProject.all.first,
                      )
                      .accent,
          ),
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

  Widget _buildDeptGrid(EmployesController controller, List<String> depts) {
    return AnimationLimiter(
      key: ValueKey(_selectedProjectId),
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
          final count = controller.getEmployeesByDept(dept).length;
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 3,
            duration: const Duration(milliseconds: 400),
            child: ScaleAnimation(
              scale: 0.92,
              child: FadeInAnimation(
                child: _deptCard(dept: dept, memberCount: count),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _deptCard({required String dept, required int memberCount}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.r),
        boxShadow: AppShadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AppRoutes.push(EmployeeListView(department: dept)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(2.6.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _accentColor.withValues(alpha: 0.85),
                        _accentColor,
                      ],
                    ),
                  ),
                  child: Icon(
                    _getDeptIcon(dept),
                    color: AppColor.white,
                    size: 5.5.w,
                  ),
                ),
                1.height,
                Flexible(
                  child: Text(
                    dept,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 2.7.sp,
                      height: 1.2,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ),
                0.4.height,
                Text(
                  "$memberCount Members",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 2.4.sp,
                    color: AppColor.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllProjectsGrid(EmployesController controller) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 4.h),
      itemCount: AppProject.all.length,
      itemBuilder: (context, projectIndex) {
        final project = AppProject.all[projectIndex];
        final grouped = controller.projectDepartments;
        final projectDepts = grouped[project.id] ?? const <String>[];
        final nonEmptyDepts = projectDepts
            .where((dept) => controller.getEmployeesByDept(dept).isNotEmpty)
            .toList();

        if (nonEmptyDepts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1.5.h, bottom: 1.h),
              child: Row(
                children: [
                  Container(width: 1.w, height: 2.5.h, color: project.accent),
                  2.width,
                  Text(
                    project.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 4.2.sp,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 3.w,
                crossAxisSpacing: 3.w,
                childAspectRatio: 0.72,
              ),
              itemCount: nonEmptyDepts.length,
              itemBuilder: (context, deptIndex) {
                final dept = nonEmptyDepts[deptIndex];
                final count = controller.getEmployeesByDept(dept).length;
                return _deptCardWithProjectAccent(
                  dept: dept,
                  memberCount: count,
                  accentColor: project.accent,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _deptCardWithProjectAccent({
    required String dept,
    required int memberCount,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.r),
        boxShadow: AppShadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AppRoutes.push(EmployeeListView(department: dept)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(2.6.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.85),
                        accentColor,
                      ],
                    ),
                  ),
                  child: Icon(
                    _getDeptIcon(dept),
                    color: AppColor.white,
                    size: 5.5.w,
                  ),
                ),
                1.height,
                Flexible(
                  child: Text(
                    dept,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 2.7.sp,
                      height: 1.2,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ),
                0.4.height,
                Text(
                  "$memberCount Members",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 2.4.sp,
                    color: AppColor.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
