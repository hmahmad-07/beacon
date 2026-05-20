import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class CustomDatePicker extends StatelessWidget {
  final String hint;
  final String? fieldTitle;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool compact;

  const CustomDatePicker({
    super.key,
    required this.hint,
    this.fieldTitle,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.compact = false,
  });

  Future<void> pickDate(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());

    final earliest = firstDate ?? DateTime(2000);
    final latest = lastDate ?? DateTime(2100);

    // Ensure initialDate is within bounds
    DateTime initial = selectedDate ?? DateTime.now();
    if (initial.isBefore(earliest)) initial = earliest;
    if (initial.isAfter(latest)) initial = latest;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: earliest,
      lastDate: latest,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.appColor1,
              onPrimary: AppColor.white,
              onSurface: AppColor.appDarkColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColor.appColor1),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColor.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.w),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppColor.appColor1,
              headerForegroundColor: AppColor.white,
              backgroundColor: AppColor.white,
            ),
          ),
          child: Transform.scale(scaleY: 0.85, scaleX: 0.9, child: child),
        );
      },
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    final displayText = hasDate
        ? DateFormat('dd MMM, yyyy').format(selectedDate!)
        : hint;

    final textStyle = TextStyle(
      color: hasDate ? AppColor.appDarkColor : AppColor.grey,
      fontSize: compact ? 3.2.sp : 4.sp,
      fontWeight: hasDate ? FontWeight.bold : FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fieldTitle != null)
          Padding(
            padding: EdgeInsets.only(bottom: 0.5.h),
            child: Text(
              fieldTitle!,
              style: TextStyle(
                color: AppColor.grey,
                fontSize: compact ? 3.sp : 3.8.sp,
              ),
            ),
          ),
        GestureDetector(
          onTap: () => pickDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 3.w : 4.w,
              vertical: compact ? 1.h : 1.5.h,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(color: AppColor.appLightColor, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(displayText, style: textStyle),
                Icon(
                  Iconsax.calendar_1_outline,
                  color: AppColor.appColor1,
                  size: compact ? 4.5.w : 5.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
