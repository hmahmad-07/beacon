import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class CustomDateRangePicker extends StatelessWidget {
  final String hint;
  final String? fieldTitle;
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange> onRangeSelected;
  final VoidCallback? onClear;

  /// When true, tapping CANCEL in the calendar clears the current range
  /// (calls [onClear]) instead of just closing. Tapping outside the
  /// dialog still leaves the range untouched.
  final bool resetOnCancel;

  const CustomDateRangePicker({
    super.key,
    required this.hint,
    this.fieldTitle,
    required this.selectedRange,
    required this.onRangeSelected,
    this.onClear,
    this.resetOnCancel = false,
  });

  Future<void> _pickRange(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());

    final result = await showDialog<Object>(
      context: context,
      builder: (context) => _CustomCalendarDialog(initialRange: selectedRange),
    );

    if (result is DateTimeRange) {
      onRangeSelected(result);
    } else if (identical(result, _cancelled) && resetOnCancel) {
      onClear?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = selectedRange != null;
    final displayText = hasRange
        ? "${DateFormat('dd MMM').format(selectedRange!.start)} - ${DateFormat('dd MMM').format(selectedRange!.end)}"
        : hint;

    final textStyle = TextStyle(
      color: hasRange ? AppColor.appDarkColor : AppColor.grey,
      fontSize: 4.sp,
      fontWeight: hasRange ? FontWeight.bold : FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fieldTitle != null)
          Padding(
            padding: EdgeInsets.only(bottom: 0.5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fieldTitle!,
                  style: TextStyle(color: AppColor.grey, fontSize: 3.8.sp),
                ),
                if (hasRange && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Text(
                      "Clear",
                      style: TextStyle(
                        color: AppColor.appColor1,
                        fontSize: 3.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => _pickRange(context),
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

// Popped by the CANCEL button, so it can be told apart from a barrier
// dismiss (which pops null).
const Object _cancelled = Object();

class _CustomCalendarDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _CustomCalendarDialog({this.initialRange});

  @override
  State<_CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  late DateTime currentMonth;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    startDate = widget.initialRange?.start;
    endDate = widget.initialRange?.end;
    if (startDate != null) {
      currentMonth = DateTime(startDate!.year, startDate!.month);
    } else {
      final now = DateTime.now();
      currentMonth = DateTime(now.year, now.month);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDayTapped(DateTime day) {
    setState(() {
      if (startDate == null) {
        startDate = day;
        endDate = null;
      } else if (startDate != null && endDate == null) {
        if (day.isBefore(startDate!)) {
          startDate = day;
        } else {
          endDate = day;
        }
      } else {
        startDate = day;
        endDate = null;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    int firstWeekday = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    ).weekday;
    int offset = firstWeekday % 7; // Sunday = 0

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppColor.appDarkColor),
            onPressed: _prevMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(currentMonth),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 4.5.sp),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: AppColor.appDarkColor),
            onPressed: _nextMonth,
          ),
        ],
      ),
      content: SizedBox(
        width: 85.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Text(
                      d,
                      style: TextStyle(
                        color: AppColor.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 3.5.sp,
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 1.5.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 0.5.h,
              ),
              itemCount: daysInMonth + offset,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox();
                int day = index - offset + 1;
                DateTime thisDate = DateTime(
                  currentMonth.year,
                  currentMonth.month,
                  day,
                );

                bool isStart =
                    startDate != null && _isSameDay(thisDate, startDate!);
                bool isEnd = endDate != null && _isSameDay(thisDate, endDate!);
                bool inRange =
                    startDate != null &&
                    endDate != null &&
                    thisDate.isAfter(startDate!) &&
                    thisDate.isBefore(endDate!);

                final now = DateTime.now();
                if (thisDate.isAfter(DateTime(now.year, now.month, now.day))) {
                  return Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: AppColor.grey.withValues(alpha: 0.3),
                        fontSize: 3.2.sp,
                      ),
                    ),
                  );
                }

                BorderRadius? radius;
                if (isStart && isEnd) {
                  radius = BorderRadius.circular(8);
                } else if (isStart) {
                  radius = BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  );
                  if (endDate == null) radius = BorderRadius.circular(8);
                } else if (isEnd) {
                  radius = BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  );
                } else if (inRange) {
                  radius = BorderRadius.zero;
                } else {
                  radius = BorderRadius.circular(8);
                }

                return GestureDetector(
                  onTap: () => _onDayTapped(thisDate),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isStart || isEnd
                          ? AppColor.appColor1
                          : inRange
                          ? AppColor.appColor1.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: radius,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: isStart || isEnd
                              ? Colors.white
                              : inRange
                              ? AppColor.appColor1
                              : AppColor.appDarkColor,
                          fontWeight: (isStart || isEnd || inRange)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 3.2.sp,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _cancelled),
          child: Text(
            "CANCEL",
            style: TextStyle(
              color: AppColor.grey,
              fontWeight: FontWeight.bold,
              fontSize: 4.sp,
            ),
          ),
        ),
        TextButton(
          onPressed: (startDate != null && endDate != null)
              ? () {
                  Navigator.pop(
                    context,
                    DateTimeRange(start: startDate!, end: endDate!),
                  );
                }
              : null,
          child: Text(
            "CONFIRM",
            style: TextStyle(
              color: AppColor.appColor1,
              fontWeight: FontWeight.bold,
              fontSize: 4.sp,
            ),
          ),
        ),
      ],
    );
  }
}
