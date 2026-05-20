import 'package:centrex/core/extensions/sizer.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final String title;
  const LoadingView({super.key, this.title = "Processing..."});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.appColor1.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 25.w,
                    width: 25.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5.w,
                      color: AppColor.appColor1,
                      backgroundColor: AppColor.appColor1.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColor.appColor1,
                    size: 12.w,
                  ),
                ],
              ),
            ),
            4.height,
            Text(
              title,
              style: TextStyle(
                fontSize: 5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
              ),
            ),
            1.height,
            Text(
              "Please wait while loading ...",
              style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }
}
