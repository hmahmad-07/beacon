import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/department_icons.dart';
import 'package:beacon/ui/components/animated_option_card.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/HR/hr_view.dart';
import 'package:beacon/ui/view/dashboard/employees/employee_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class DepartmentPickerView extends StatelessWidget {
  const DepartmentPickerView({
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

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "${module.title} · ${shop.shopName ?? ''}"),
      body: depts.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select department",
                    style: TextStyle(
                      fontSize: 4.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  1.height,
                  Expanded(child: _buildDepartmentGrid(depts)),
                ],
              ),
            ),
    );
  }

  Widget _buildDepartmentGrid(List<Department> depts) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: EdgeInsets.only(top: 0.5.h, bottom: 4.h),
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
                child: AnimatedOptionCard(
                  title: dept.departmentName ?? "Department",
                  icon: departmentIcon(dept.departmentName ?? ""),
                  accentColor: accentColor,
                  onTap: () => _openModule(context, dept),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openModule(BuildContext context, Department dept) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_rounded,
              size: 15.w,
              color: Colors.grey.shade300,
            ),
            2.height,
            Text(
              "No departments in ${shop.shopName ?? 'this shop'}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 3.5.sp),
            ),
          ],
        ),
      ),
    );
  }
}
