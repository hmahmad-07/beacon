import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/department_icons.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/HR/hr_view.dart';
import 'package:beacon/ui/view/dashboard/employees/employee_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class DepartmentGrid extends StatelessWidget {
  const DepartmentGrid({
    super.key,
    required this.module,
    required this.shop,
    required this.accentColor,
    this.siteImage,
    this.siteName,
    this.description,
    this.heroTag,
  });

  final AppModule module;
  final Shop shop;
  final Color accentColor;
  final String? siteImage;
  final String? siteName;
  final String? description;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final depts = shop.departments ?? [];
    final name = siteName ?? shop.shopName ?? "this project";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GridHeader(
          moduleTitle: module.title,
          siteName: name,
          description: description,
          count: depts.length,
          accentColor: accentColor,
          siteImage: siteImage,
          heroTag: heroTag,
        ),
        Expanded(
          child: depts.isEmpty ? _emptyState(name) : _grid(context, depts),
        ),
      ],
    );
  }

  Widget _emptyState(String name) {
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
              "No departments in $name",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, List<Department> depts) {
    return AnimationLimiter(
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 3.5.w,
          crossAxisSpacing: 3.5.w,
          childAspectRatio: 0.88,
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
                child: _DepartmentCard(
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

class _GridHeader extends StatelessWidget {
  const _GridHeader({
    required this.moduleTitle,
    required this.siteName,
    required this.count,
    required this.accentColor,
    this.description,
    this.siteImage,
    this.heroTag,
  });

  final String moduleTitle;
  final String siteName;
  final String? description;
  final int count;
  final Color accentColor;
  final String? siteImage;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? logo;
    if (siteImage != null) {
      logo = SiteLogo(asset: siteImage!, accent: accentColor, size: 16.w);
      if (heroTag != null) logo = Hero(tag: heroTag!, child: logo);
    }

    return Container(
      padding: EdgeInsets.all(3.5.w),
      margin: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 0.5.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          if (logo != null) ...[logo, SizedBox(width: 3.5.w)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleTitle,
                  style: TextStyle(
                    fontSize: 4.8.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF14151C),
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  siteName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.3.sp,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.sp,
                      color: AppColor.grey,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count ${count == 1 ? 'dept' : 'depts'}",
              style: TextStyle(
                fontSize: 3.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatefulWidget {
  const _DepartmentCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<_DepartmentCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hsl = HSLColor.fromColor(widget.accentColor);
    final light = hsl
        .withLightness((hsl.lightness + 0.14).clamp(0.0, 0.85))
        .toColor();
    final base = widget.accentColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 1.5.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [light, base],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: base.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 6.5.w),
              ),
              2.height,
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 2.5.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: AppColor.appDarkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
