import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool hasLeading;
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.hasLeading = true,
    required this.title,
    this.icon,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.appLightColor)),
      ),
      child: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColor.white,
        surfaceTintColor: AppColor.transparent,
        foregroundColor: AppColor.appDarkColor,
        iconTheme: IconThemeData(color: AppColor.appDarkColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColor.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: hasLeading
            ? IconButton(
                tooltip: "Back",
                icon: Icon(
                  icon ?? CupertinoIcons.back,
                  color: AppColor.appDarkColor,
                ),
                onPressed: icon == null
                    ? onTap ?? () => Navigator.pop(context)
                    : onTap,
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 5.8.sp,
            color: AppColor.appDarkColor,
          ),
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(9.h);
}
