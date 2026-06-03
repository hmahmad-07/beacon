import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class CustomMonthPicker extends StatelessWidget {
  final String hint;
  final String? fieldTitle;
  final DateTime? selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomMonthPicker({
    super.key,
    required this.hint,
    this.fieldTitle,
    required this.selectedMonth,
    required this.onMonthSelected,
    this.firstDate,
    this.lastDate,
  });

  Future<void> pickMonth(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());

    final DateTime now = DateTime.now();
    final List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    final DateTime? pickedMonth = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Select Month (${now.year})",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 4.5.sp),
          ),
          content: SizedBox(
            width: 80.w,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 1.h,
              ),
              itemBuilder: (context, index) {
                final bool isSelected = selectedMonth?.month == (index + 1);
                final bool isFuture =
                    (index + 1) > now.month &&
                    now.year == now.year; // Simplified for current year

                return GestureDetector(
                  onTap: isFuture
                      ? null
                      : () {
                          Navigator.pop(context, DateTime(now.year, index + 1));
                        },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.appColor1
                          : isFuture
                          ? AppColor.grey.withValues(alpha: 0.1)
                          : AppColor.scaffold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      months[index].substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isFuture
                            ? AppColor.grey.withValues(alpha: 0.3)
                            : AppColor.appDarkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 3.2.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (pickedMonth != null) {
      onMonthSelected(pickedMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMonth = selectedMonth != null;
    final displayText = hasMonth
        ? DateFormat('MMMM yyyy').format(selectedMonth!)
        : hint;

    final textStyle = TextStyle(
      color: hasMonth ? AppColor.appDarkColor : AppColor.grey,
      fontSize: 4.sp,
      fontWeight: hasMonth ? FontWeight.bold : FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fieldTitle != null)
          Padding(
            padding: EdgeInsets.only(bottom: 0.5.h),
            child: Text(
              fieldTitle!,
              style: TextStyle(color: AppColor.grey, fontSize: 3.8.sp),
            ),
          ),
        GestureDetector(
          onTap: () => pickMonth(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
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
                  Iconsax.calendar_2_outline,
                  color: AppColor.appColor1,
                  size: 5.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
