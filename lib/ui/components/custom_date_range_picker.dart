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

  /// Opens the calendar on its own (for filter sheets that don't embed
  /// the field). `cancelled` is true only for the CANCEL button, not for a
  /// tap outside the dialog.
  ///
  /// [allowSingleDay]: one tapped date can be confirmed on its own and is
  /// returned as a one-day range (From = To) until a second date is picked.
  /// [showReset]: when [initialRange] is set, a RESET button clears it
  /// (`cleared` is true).
  static Future<({DateTimeRange? range, bool cancelled, bool cleared})> show(
    BuildContext context, {
    DateTimeRange? initialRange,
    bool allowSingleDay = false,
    bool showReset = false,
  }) async {
    final result = await showDialog<Object>(
      context: context,
      builder: (context) => _CustomCalendarDialog(
        initialRange: initialRange,
        allowSingleDay: allowSingleDay,
        showReset: showReset,
      ),
    );
    return (
      range: result is DateTimeRange ? result : null,
      cancelled: identical(result, _cancelled),
      cleared: identical(result, _cleared),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());

    final result = await show(context, initialRange: selectedRange);

    if (result.range != null) {
      onRangeSelected(result.range!);
    } else if (result.cancelled && resetOnCancel) {
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

// Results popped by the buttons, so they can be told apart from a barrier
// dismiss (which pops null). Each needs its own value: two `const Object()`
// would be one and the same object.
class _DialogResult {
  const _DialogResult(this.name);
  final String name;
}

// Popped by the CANCEL button.
const _cancelled = _DialogResult('cancel');

// Popped by the RESET button.
const _cleared = _DialogResult('reset');

class _CustomCalendarDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final bool allowSingleDay;
  final bool showReset;
  const _CustomCalendarDialog({
    this.initialRange,
    this.allowSingleDay = false,
    this.showReset = false,
  });

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
            if (widget.allowSingleDay) ...[_fromToSummary(), 2.height],
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
        Row(
          children: [
            if (widget.showReset && widget.initialRange != null)
              TextButton(
                onPressed: () => Navigator.pop(context, _cleared),
                child: Text(
                  "RESET",
                  style: TextStyle(
                    color: AppColor.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 4.sp,
                  ),
                ),
              ),
            const Spacer(),
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
              onPressed: _canConfirm
                  ? () {
                      Navigator.pop(
                        context,
                        // One date on its own is a one-day range.
                        DateTimeRange(
                          start: startDate!,
                          end: endDate ?? startDate!,
                        ),
                      );
                    }
                  : null,
              child: Text(
                "CONFIRM",
                style: TextStyle(
                  color: _canConfirm
                      ? AppColor.appColor1
                      : AppColor.grey.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 4.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get _canConfirm =>
      startDate != null && (endDate != null || widget.allowSingleDay);

  /// FROM / TO boxes above the calendar. Until a second date is picked, TO
  /// shows the same day as FROM.
  Widget _fromToSummary() {
    final f = DateFormat('d MMM yyyy');
    final sameDay = startDate != null && endDate == null;
    return Row(
      children: [
        Expanded(
          child: _dateBox(
            "FROM",
            startDate == null ? "Select date" : f.format(startDate!),
            active: startDate != null,
          ),
        ),
        2.width,
        Expanded(
          child: _dateBox(
            "TO",
            startDate == null ? "Select date" : f.format(endDate ?? startDate!),
            active: startDate != null,
            note: sameDay ? "Same day" : null,
          ),
        ),
      ],
    );
  }

  Widget _dateBox(
    String label,
    String value, {
    required bool active,
    String? note,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: active
            ? AppColor.appColor1.withValues(alpha: 0.06)
            : AppColor.scaffold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppColor.appColor1.withValues(alpha: 0.25)
              : AppColor.appLightColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 2.6.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColor.grey,
                ),
              ),
              if (note != null) ...[
                const Spacer(),
                Text(
                  note,
                  style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
                ),
              ],
            ],
          ),
          0.3.height,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 3.4.sp,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? AppColor.appDarkColor : AppColor.grey,
            ),
          ),
        ],
      ),
    );
  }
}
