import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:flutter/material.dart';

/// In-app terms and conditions. This is a draft and must be reviewed and
/// approved by the company before release.
class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  static const _sections = <_Section>[
    _Section(
      title: "Acceptance of these terms",
      body:
          "By signing in to Beacon you agree to these terms. Beacon is for authorised staff of CENTREX and its group sites. If you do not agree, do not use the app.",
    ),
    _Section(
      title: "Your account",
      body:
          "Keep your employee code and password confidential. Do not share your sign-in with anyone, and do not sign in on someone else's behalf. Tell your Beacon administrator straight away if you think your account has been used without your permission.",
    ),
    _Section(
      title: "What you may use the app for",
      body:
          "Use Beacon only for your own work. You may view and act on the sites, modules and data that your role allows. Do not try to reach information outside your access, change data you are not authorised to change, or interfere with the app or its servers.",
    ),
    _Section(
      title: "Company information",
      body:
          "Sites, employee, HR, inventory and sales information shown in Beacon is company information. Do not copy, share or publish it outside the company except as your job requires.",
    ),
    _Section(
      title: "Availability of the app",
      body:
          "Beacon needs an internet connection and the company's systems to work. Features may be changed, paused or temporarily unavailable, and information shown may take time to update.",
    ),
    _Section(
      title: "Suspension and ending access",
      body:
          "Your access may be suspended or removed if your role or employment changes, if you breach these terms, or if needed to protect company information.",
    ),
    _Section(
      title: "Limits of responsibility",
      body:
          "Beacon is provided for internal use. To the extent the law allows, the company is not responsible for losses caused by the app being unavailable, or by decisions taken on information that was not up to date.",
    ),
    _Section(
      title: "Changes to these terms",
      body:
          "These terms may be updated from time to time. The latest version is always shown in the app. Continuing to use Beacon after a change means you accept the updated terms.",
    ),
    _Section(
      title: "Contact",
      body:
          "For questions about these terms, contact the Beacon administrator in your company.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: const CustomAppBar(title: "Terms & conditions"),
      body: ListView(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        children: [
          Text(
            "Last updated: 4 November 2026",
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
