import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 add karo
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: AppColor.grey.withValues(alpha: .1),
            blurRadius: 3,
            spreadRadius: 2,
            offset: const Offset(0, .3),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            AppColor.appColor1,
            AppColor.appDarkColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        foregroundColor: AppColor.white,
        backgroundColor: AppColor.transparent,
        surfaceTintColor: AppColor.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: hasLeading
            ? IconButton(
                icon: Icon(
                  icon ?? CupertinoIcons.arrow_left,
                  color: AppColor.white,
                ),
                onPressed: icon == null
                    ? onTap ?? () => Navigator.pop(context)
                    : onTap,
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 6.5.sp,
            color: AppColor.white,
          ),
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(9.h);
}
