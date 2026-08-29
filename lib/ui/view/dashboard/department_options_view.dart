import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/view/dashboard/CC/HR/hr_view.dart';
import 'package:beacon/ui/view/employees/employee_list_view.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

class DepartmentOptionsView extends StatelessWidget {
  const DepartmentOptionsView({
    super.key,
    this.siteImage,
    required this.deptName,
    required this.deptId,
    required this.shopId,
    required this.shopName,
    required this.accentColor,
  });

  final String? siteImage;
  final String deptName;
  final int deptId;
  final String shopId;
  final String shopName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: deptName),
      body: Padding(
        padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            3.height,
            Text(
              "Select section",
              style: TextStyle(
                fontSize: 4.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.appDarkColor,
              ),
            ),
            2.height,
            _optionCard(
              title: "General Details",
              subtitle: "Employee list & department records",
              icon: BoxIcons.bxs_user,
              onTap: () {
                AppRoutes.push(
                  EmployeeListView(
                    department: deptName,
                    departmentId: deptId,
                    shopId: shopId,
                    shopName: shopName,
                    siteImage: siteImage,
                  ),
                );
              },
            ),
            2.height,
            _optionCard(
              title: "HR Details",
              subtitle: "Reports, salary types & HR analytics",
              icon: BoxIcons.bxs_group,
              onTap: () {
                AppRoutes.push(
                  CCHumanResourceView(
                    siteName: shopName,
                    siteID: shopId,
                    deptName: deptName,
                    deptID: deptId,
                    clr: accentColor,
                    siteImage: siteImage,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteLogo({double size = 14}) {
    return Container(
      width: size.w,
      height: size.w,
      padding: EdgeInsets.all(1.5.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColor.white,
      ),
      child: siteImage != null && siteImage!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size.w),
              child: Image.asset(siteImage!, fit: BoxFit.contain),
            )
          : Icon(Icons.storefront_rounded, color: accentColor, size: 6.w),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.85),
            AppColor.appDarkColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        children: [
          _buildSiteLogo(),
          3.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 5.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                0.5.height,
                Text(
                  deptName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColor.white.withValues(alpha: 0.85),
                    fontSize: 3.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: Material(
          color: AppColor.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.5.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, color: accentColor, size: 8.w),
                  ),
                  4.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 4.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.appDarkColor,
                          ),
                        ),
                        0.5.height,
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 3.2.sp,
                            color: AppColor.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 4.r,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
