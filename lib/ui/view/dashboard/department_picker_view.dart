import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/department_icons.dart';
import 'package:beacon/ui/components/animated_option_card.dart';
import 'package:beacon/ui/view/dashboard/HR/hr_view.dart';
import 'package:beacon/ui/view/dashboard/employees/employee_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Department grid for one project. Used as the right pane of the Employees
/// and HR workspace, so it renders a body only (no Scaffold, no app bar).
class DepartmentGrid extends StatelessWidget {
  const DepartmentGrid({
    super.key,
    required this.module,
    required this.shop,
    required this.accentColor,
    this.siteImage,
  });

  final AppModule module;
  final Shop shop;
  final Color accentColor;
  final String? siteImage;

  @override
  Widget build(BuildContext context) {
    final depts = shop.departments ?? [];

    if (depts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_off_rounded,
                size: 15.w,
                color: AppColor.grey.withValues(alpha: 0.4),
              ),
              2.height,
              Text(
                "No departments in ${shop.shopName ?? 'this project'}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(3.w, 1.5.h, 3.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select department",
            style: TextStyle(
              fontSize: 3.8.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          Expanded(child: _grid(context, depts)),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, List<Department> depts) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: EdgeInsets.only(top: 0.5.h, bottom: 4.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2.w,
          crossAxisSpacing: 2.w,
          childAspectRatio: 0.9,
        ),
        itemCount: depts.length,
        itemBuilder: (context, index) {
          final dept = depts[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 2,
            duration: const Duration(milliseconds: 400),
            child: ScaleAnimation(
              scale: 0.92,
              child: FadeInAnimation(
                child: AnimatedOptionCard(
                  title: dept.departmentName ?? "Department",
                  icon: departmentIcon(dept.departmentName ?? ""),
                  accentColor: accentColor,
                  onTap: () => _openDepartment(context, dept),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDepartment(BuildContext context, Department dept) {
    final deptName = dept.departmentName ?? "Department";

    if (module.id == AppModule.hr.id) {
      AppRoutes.push(
        HumanResourceView(
          siteName: shop.shopName ?? "N/A",
          siteID: shop.shopId ?? "N/A",
          deptName: deptName,
          deptID: dept.departmentId ?? 0,
          clr: accentColor,
          siteImage: siteImage,
        ),
      );
      return;
    }

    AppRoutes.push(
      EmployeeListView(
        department: deptName,
        departmentId: dept.departmentId,
        shopId: shop.shopId,
        shopName: shop.shopName,
        siteImage: siteImage,
      ),
    );
  }
}
