import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:flutter/material.dart';

/// In-app privacy policy. This is a draft and should be reviewed and approved
/// before release.
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  static const _sections = <_Section>[
    _Section(
      title: "About Beacon",
      body:
          "Beacon is an internal app used by authorised staff of CENTREX and its group sites to view employee, sales and inventory information.",
    ),
    _Section(
      title: "Information the app uses",
      body:
          "Sign-in details: your employee code and password. The password is sent to our server to sign you in and is not stored on this device.\n\n"
          "Account details: your name, user ID, group type and employee code. These are kept in secure storage on this device so the app can greet you and keep you signed in.\n\n"
          "Business data: sites, employee, HR, inventory and sales reports that the app loads from our server while you use it.",
    ),
    _Section(
      title: "Device permissions",
      body:
          "The app may ask for device permissions, such as location, camera or phone access, when a feature needs them. You can review or change these in your device settings.",
    ),
    _Section(
      title: "How we use this information",
      body:
          "We use it to sign you in, show the sites and reports you are allowed to see, and keep the app working correctly.",
    ),
    _Section(
      title: "Sharing",
      body:
          "We do not sell your information. Data is shared only with the company systems that run Beacon.",
    ),
    _Section(
      title: "Security",
      body:
          "Data travels between the app and our servers over the network. Sign-in tokens are kept in secure device storage. Log out when you use a shared device.",
    ),
    _Section(
      title: "Your choices",
      body:
          "You can log out at any time from the menu. For questions about your access, contact your Beacon administrator.",
    ),
    _Section(
      title: "Contact",
      body:
          "For questions about this policy, contact the Beacon administrator in your company.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: const CustomAppBar(title: "Privacy policy"),
      body: ListView(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        children: [
          Text(
            "Last updated: 28 October 2026",
            style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
          ),
          2.height,
          for (final section in _sections) ...[
            Text(
              section.title,
              style: TextStyle(
                fontSize: 4.0.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.appDarkColor,
              ),
            ),
            0.8.height,
            Text(
              section.body,
              style: TextStyle(
                fontSize: 3.4.sp,
                height: 1.5,
                color: AppColor.darkGrey,
              ),
            ),
            2.4.height,
          ],
        ],
      ),
    );
  }
}

class _Section {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;
}
