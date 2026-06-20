import 'package:beacon/core/constants/constants.dart';
import 'package:beacon/core/controllers/auth_controller.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_button.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/view/profile/privacy_policy_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/sizer.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "My Account"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  3.height,
                  _buildProfileHeader(),
                  4.height,
                  _buildSectionLabel("Security & Identity"),
                  1.5.height,
                  _buildIdentityCard(),
                  4.height,
                  _buildSectionLabel("Support & Legal"),
                  1.5.height,
                  _buildLegalCard(context),
                  4.height,
                ],
              ),
            ),
          ),
          _buildLogoutFooter(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(4.r),
            boxShadow: AppShadow.soft,
            border: Border.all(
              color: AppColor.appColor1.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(1.w),
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.appColor1.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppColor.appColor1,
                size: 15.w,
              ),
            ),
          ),
        ),
        2.5.height,
        Text(
          Constants.name.isEmpty ? "Authorized Personnel" : Constants.name,
          style: TextStyle(
            fontSize: 5.5.sp,
            fontWeight: FontWeight.w900,
            color: AppColor.appDarkColor,
            letterSpacing: -0.8,
          ),
        ),
        0.5.height,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
          decoration: BoxDecoration(
            color: AppColor.appDarkColor,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            Constants.type.isEmpty
                ? "Standard User"
                : Constants.type.toUpperCase(),
            style: TextStyle(
              fontSize: 2.2.sp,
              color: AppColor.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        children: [
          _buildListTile(
            Icons.fingerprint_rounded,
            "Unique ID",
            Constants.id.isEmpty ? "N/A" : Constants.id,
            AppColor.appColor1,
          ),
          _divider(),
          _buildListTile(
            Icons.badge_outlined,
            "Employee Code",
            Constants.code.isEmpty ? "N/A" : Constants.code,
            AppColor.appColor1,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: _buildListTile(
        Icons.privacy_tip_outlined,
        "Privacy Policy",
        "Terms and data protection details",
        AppColor.appDarkColor,
        showArrow: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyPolicyView()),
          );
        },
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String sub,
    Color color, {
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(icon, color: color, size: 5.w),
            ),
            4.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 3.sp,
                      color: AppColor.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  0.3.height,
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 3.8.sp,
                      color: AppColor.appDarkColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 3.5.sp,
                color: AppColor.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 15.w,
    endIndent: 5.w,
    color: AppColor.grey.withValues(alpha: 0.1),
  );

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 2.2.sp,
          fontWeight: FontWeight.w900,
          color: AppColor.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLogoutFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundButton(
            height: 7.h,
            width: double.maxFinite,
            title: "SIGN OUT",
            buttonColor: AppColor.red,
            textColor: AppColor.white,
            onPress: () => _confirmLogout(context),
          ),
          1.5.height,
          Text(
            "Version 1.0.2 (Build 24)",
            style: TextStyle(
              fontSize: 2.6.sp,
              color: AppColor.grey.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Account Security"),
        content: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Are you sure you want to end your current session and sign out?",
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              "Stay",
              style: TextStyle(
                fontSize: 5.sp,
                color: AppColor.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthController>().logout(context);
            },
            child: Text(
              "Log Out",
              style: TextStyle(
                fontSize: 5.sp,
                color: AppColor.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
