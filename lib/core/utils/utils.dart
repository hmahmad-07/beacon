// ignore_for_file: deprecated_member_use

import 'package:centrex/core/resources/app_images.dart';
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
            Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(height: 5.w, width: 5.w, ImageAssets.appIcon),
            ),
            4.width,
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
      DateTime dt = parseDateTime(dateStr);
      return DateFormat('dd MMM, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      final String amPm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return time;
    }
  }

  static DateTime parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return DateTime(2000);

    String cleanDate = dateStr.trim().toUpperCase();

    try {
      return DateTime.parse(cleanDate);
    } catch (_) {
      try {
        final months = {
          'JAN': '01',
          'FEB': '02',
          'MAR': '03',
          'APR': '04',
          'MAY': '05',
          'JUN': '06',
          'JUL': '07',
          'AUG': '08',
          'SEP': '09',
          'OCT': '10',
          'NOV': '11',
          'DEC': '12',
        };

        String temp = cleanDate;
        for (var entry in months.entries) {
          if (temp.contains(entry.key)) {
            temp = temp.replaceFirst(entry.key, entry.value);
            break;
          }
        }

        // After replacement: 20-05-26 02:24 PM
        // Format: dd-MM-yy hh:mm a
        return DateFormat("dd-MM-yy hh:mm a").parse(temp);
      } catch (e) {
        debugPrint("Parse Error for '$dateStr': $e");
        return DateTime(2000); // Fallback
      }
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
