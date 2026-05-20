// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../extensions/sizer.dart';
import '../resources/app_colors.dart';
// import '../resources/app_images.dart';

class Utils {
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppColor.white,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container(
            //   decoration: BoxDecoration(
            //     color: AppColor.white,
            //     shape: BoxShape.circle,
            //   ),
            //   child: Icon(Icons.info_outline, color: AppColor.appColor1),
            // ),
            // 4.width,
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppColor.appDarkColor,
                  fontSize: 4.2.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> names = name.split(' ');
    if (names.length > 1) {
      return (names[0][0] + names[names.length - 1][0]).toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  static String formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  static Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  static void loadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColor.grey.withValues(alpha: .1),
                blurRadius: 3,
                spreadRadius: 2,
                offset: const Offset(0, .3),
              ),
            ],
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
