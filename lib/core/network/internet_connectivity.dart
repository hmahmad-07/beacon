import 'package:flutter/material.dart';
import '../extensions/sizer.dart';
import '../resources/app_colors.dart';

class NoInternetView extends StatelessWidget {
  const NoInternetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 7.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    height: 35.w,
                    width: 35.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.red.withValues(alpha: .12),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 22.r,
                      color: AppColor.red,
                    ),
                  ),
                ),
                5.height,
                Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 6.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                    letterSpacing: -.3,
                  ),
                ),
                1.5.height,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Text(
                    'Your device is currently offline. Please check your Wi-Fi or mobile data connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 3.7.sp,
                      color: AppColor.appColor1,
                      height: 1.6,
                    ),
                  ),
                ),
                5.height,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 7.w,
                    vertical: 1.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.appDarkColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColor.appColor1.withValues(alpha: .08),
                    ),
                  ),
                  child: Text(
                    'Waiting for connection...',
                    style: TextStyle(
                      fontSize: 3.8.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
