// ignore_for_file: unused_element_parameter, unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85.w,
      child: Drawer(
        backgroundColor: AppColor.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: AppColor.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
                color: AppColor.appColor1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    10.height,
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 7.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    1.height,
                    Text(
                      Constants.name.isNotEmpty ? Constants.name : 'User',
                      style: TextStyle(
                        fontSize: 5.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    .5.height,
                    Text(
                      'EMP-${Constants.code}',
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        color: AppColor.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              Padding(
                padding: EdgeInsets.all(5.w),
                child: Row(
                  children: [
                    Text(
                      'SalesPro.',
                      style: TextStyle(
                        fontSize: 4.5.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v5.0.0',
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        color: AppColor.grey,
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

  void _logOut(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Logout?"),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text("Are you sure you want to logout?"),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text("Cancel"),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // context.read<AuthController>().logout(context);
            },
            isDestructiveAction: true,
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 5.w, top: 2.h, bottom: 1.h),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 3.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.grey.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 6.w),
      leading: Icon(icon, size: 6.5.w, color: AppColor.appColor1),
      title: Transform.translate(
        offset: Offset(-4.w, 0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 4.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.appDarkColor,
          ),
        ),
      ),
      subtitle: subtitle != null
          ? Transform.translate(
              offset: Offset(-4.w, 0),
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
              ),
            )
          : null,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      onTap: onTap,
    );
  }
}
