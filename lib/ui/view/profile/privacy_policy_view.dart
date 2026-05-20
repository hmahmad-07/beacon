import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:flutter/material.dart';
import '../../../../core/extensions/sizer.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Privacy Policy"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
              ),
            ),
            2.height,
            Text(
              "This privacy policy applied to the CENTREX Field Force Monitoring app. We are committed to protecting your personal data and ensuring transparency in how we collect and use your information.",
              style: TextStyle(
                fontSize: 3.5.sp,
                color: AppColor.grey,
                height: 1.5,
              ),
            ),
            3.height,
            _policySection(
              "Data Collection",
              "We collect employee ID, name, and monitoring logs strictly for internal field force optimization and attendance management.",
            ),
            _policySection(
              "Location Access",
              "The app may request location access to verify field visits and track force movement during active duty hours.",
            ),
            _policySection(
              "Data Security",
              "All user data is encrypted and stored securely on our private enterprise servers.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _policySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 4.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.appDarkColor,
          ),
        ),
        1.height,
        Text(
          content,
          style: TextStyle(fontSize: 3.5.sp, color: AppColor.grey, height: 1.5),
        ),
        3.height,
      ],
    );
  }
}
