import 'package:flutter/material.dart';

import 'package:beacon/core/controllers/al_azeem_checklist_period_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_date_picker.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:beacon/ui/view/dashboard/sales/sales_ui.dart';

/// Shared pieces for the Al-Azeem checklist screens, plus the label helpers
/// that turn API codes into text.

const checklistRoleOptions = <String, String>{
  'caretaker': 'Caretaker',
  'sweeper': 'Sweeper',
  'in_charge': 'In-charge',
  'security_guard': 'Security guard',
  'admin_hod': 'Admin HOD',
  'hr': 'HR',
};

const checklistStatusOptions = <String, String>{
  'in_progress': 'In progress',
  'verified': 'Verified',
};

const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _monthLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "in_progress" -> "In progress", "security_guard" -> "Security guard".
String checklistTitleCase(String raw) {
  final words = raw
      .replaceAll('_', ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  return words.map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

String checklistRoleLabel(String? role) {
  if (role == null || role.isEmpty) return '—';
  return checklistRoleOptions[role] ?? checklistTitleCase(role);
}

String checklistStatusLabel(String status) {
  if (status.isEmpty) return '—';
  return checklistStatusOptions[status] ?? checklistTitleCase(status);
}

Color checklistStatusColor(String status) {
  switch (status) {
    case 'verified':
      return AppColor.green;
    case 'in_progress':
      return AppColor.appColor2;
    default:
      return AppColor.grey;
  }
}

/// "26 Oct 2026".
String checklistDayLabel(DateTime d) =>
    '${d.day} ${_monthShort[d.month - 1]} ${d.year}';

/// Formats a `YYYY-MM-DD` value. Falls back to the raw text.
String checklistDateText(String raw) {
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? raw : checklistDayLabel(parsed);
}

/// "26 Oct 2026, 8:30 AM". Falls back to the raw text.
String checklistDateTimeText(String? raw) {
  if (raw == null) return '—';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final hour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final meridiem = parsed.hour < 12 ? 'AM' : 'PM';
  return '${checklistDayLabel(parsed)}, $hour12:$minute $meridiem';
}

/// The label for the chosen period, for example "26 Oct – 1 Nov 2026",
/// "October 2026" or "26 Oct 2026".
String checklistPeriodLabel(String grain, DateTime date) {
  if (grain == 'week') {
    final start = DateTime(date.year, date.month, date.day - (date.weekday - 1));
    final end = DateTime(start.year, start.month, start.day + 6);
    return '${start.day} ${_monthShort[start.month - 1]} – '
        '${checklistDayLabel(end)}';
  }
  if (grain == 'month') {
    return '${_monthLong[date.month - 1]} ${date.year}';
  }
  return checklistDayLabel(date);
}

/// Period choice shared by every checklist screen. Month opens the app's
/// month picker. Week and single day open the app's date picker.
Future<void> showChecklistPeriodSheet(
  BuildContext context,
  ChecklistPeriodController period,
) async {
  final grain = await showSalesSheet<String>(
    context,
    title: "Select period",
    builder: (sheetContext) => Material(
      color: AppColor.white,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesOptionTile(
          icon: Icons.event_available_rounded,
          title: "Calendar month",
          subtitle: "Whole month",
          onTap: () => Navigator.pop(sheetContext, 'month'),
        ),
        SalesOptionTile(
          icon: Icons.date_range_rounded,
          title: "Week",
          subtitle: "Monday to Sunday",
          onTap: () => Navigator.pop(sheetContext, 'week'),
        ),
        SalesOptionTile(
          icon: Icons.today_rounded,
          title: "Single day",
          subtitle: "One date",
          onTap: () => Navigator.pop(sheetContext, 'day'),
        ),
      ],
    ),
    ),
  );
  if (grain == null || !context.mounted) return;

  if (grain == 'month') {
    await CustomMonthPicker.showMonthPickerDialog(
      context: context,
      selectedMonth: period.date,
      onMonthSelected: (picked) => period.setPeriod(
        grain: 'month',
        date: DateTime(picked.year, picked.month, 1),
      ),
    );
    return;
  }

  await CustomDatePicker(
    hint: "Select date",
    selectedDate: period.date,
    onDateSelected: (day) => period.setPeriod(grain: grain, date: day),
  ).pickDate(context);
}

/// Role choice for the submissions list. "All roles" clears the filter.
Future<void> showChecklistRolePicker(
  BuildContext context,
  String? selected,
  ValueChanged<String?> onPicked,
) async {
  final choice = await showSalesSheet<String>(
    context,
    title: "Role",
    builder: (sheetContext) => Material(
      color: AppColor.white,
      child: ListView(
        shrinkWrap: true,
        children: [
          SalesOptionTile(
            icon: Icons.groups_rounded,
            title: "All roles",
            subtitle: selected == null ? "Selected" : "Show every role",
            onTap: () => Navigator.pop(sheetContext, ''),
          ),
          for (final entry in checklistRoleOptions.entries)
            SalesOptionTile(
              icon: Icons.badge_rounded,
              title: entry.value,
              subtitle: selected == entry.key
                  ? "Selected"
                  : "Show only this role",
              onTap: () => Navigator.pop(sheetContext, entry.key),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  onPicked(choice.isEmpty ? null : choice);
}

/// A white bordered card. Pass [onTap] to make the whole card tappable.
class ChecklistCard extends StatelessWidget {
  const ChecklistCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColor.appLightColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? EdgeInsets.all(4.w),
          child: child,
        ),
      ),
    );
  }
}

/// A small rounded label, used for status and evidence.
class ChecklistPill extends StatelessWidget {
  const ChecklistPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 2.6.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// A thin rounded progress bar. [value] is clamped to 0–1.
class ChecklistProgressBar extends StatelessWidget {
  const ChecklistProgressBar({
    super.key,
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: 6,
        color: color,
        backgroundColor: AppColor.appLightColor,
      ),
    );
  }
}

/// A label and a value on one row.
class ChecklistInfoRow extends StatelessWidget {
  const ChecklistInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 3.4.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
