import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/sizer.dart';
import '../../../../core/models/Sales/sales_common.dart';
import '../../../../core/models/Sales/sales_models.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../components/app_constants.dart';
import '../../../components/custom_date_picker.dart';
import '../../../components/custom_date_range_picker.dart';
import '../../../components/custom_month_picker.dart';
import 'sales_widgets.dart';

// ============================================================ Formatting

final DateFormat salesMonthYearFormat = DateFormat('MMMM yyyy');
final DateFormat _monthShortFormat = DateFormat('MMM');
final DateFormat _dayLongFormat = DateFormat('dd MMM yyyy');
final DateFormat _dayShortFormat = DateFormat('dd MMM');
final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');
final DateFormat _dayOfMonthFormat = DateFormat('dd');
final DateFormat _clockFormat = DateFormat('h:mm a');

/// "October 2026", "23 Oct 2026" or "01 Oct – 31 Oct 2026".
String salesPeriodLabel(SalesFilters filters) {
  if (filters.date != null) return _dayLongFormat.format(filters.date!);
  if (filters.dateFrom != null && filters.dateTo != null) {
    return '${_dayShortFormat.format(filters.dateFrom!)} – ${_dayLongFormat.format(filters.dateTo!)}';
  }
  final now = DateTime.now();
  return salesMonthYearFormat.format(
    DateTime(filters.year ?? now.year, filters.month ?? now.month),
  );
}

/// "Updated 11:52 AM", or empty before the first successful load.
String salesUpdatedLabel(DateTime? at) =>
    at == null ? "" : "Updated ${_clockFormat.format(at)}";

/// "2026-10" becomes "Oct". Falls back to the raw key if it cannot be parsed.
String salesMonthKeyLabel(String key) {
  try {
    return _monthShortFormat.format(_monthKeyFormat.parseStrict(key));
  } catch (_) {
    return key;
  }
}

/// "2026-10-05" becomes "05".
String salesDayKeyLabel(String key) {
  try {
    return _dayOfMonthFormat.format(_dayKeyFormat.parseStrict(key));
  } catch (_) {
    return key;
  }
}

/// "2026-10-05" becomes "05 Oct 2026".
String salesDayKeyFull(String key) {
  try {
    return _dayLongFormat.format(_dayKeyFormat.parseStrict(key));
  } catch (_) {
    return key;
  }
}

// ============================================================ Surfaces

/// White rounded surface used for every card in the Sales module.
class SalesCard extends StatelessWidget {
  const SalesCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4.r);
    final content = Padding(
      padding: padding ?? EdgeInsets.all(4.w),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: radius,
        boxShadow: AppShadow.soft,
      ),
      child: onTap == null
          ? content
          : Material(
              color: AppColor.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

/// Bold section heading with an optional trailing widget.
class SalesSectionTitle extends StatelessWidget {
  const SalesSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h, top: 0.5.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 3.9.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Headline figure with the growth pill, drawn on the business accent.
class SalesHero extends StatelessWidget {
  const SalesHero({
    super.key,
    required this.accent,
    required this.title,
    required this.value,
    this.subtitle,
    this.comparison,
  });

  final Color accent;
  final String title;
  final String value;
  final String? subtitle;
  final SalesComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(accent, AppColor.appDarkColor, 0.35) ?? accent;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, deep],
        ),
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 2.6.sp,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: AppColor.white.withValues(alpha: 0.85),
            ),
          ),
          1.height,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 7.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.white,
              ),
            ),
          ),
          if (subtitle != null) ...[
            0.8.height,
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 3.1.sp,
                color: AppColor.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (comparison != null) ...[
            1.6.height,
            _GrowthPill(comparison: comparison!),
          ],
        ],
      ),
    );
  }
}

class _GrowthPill extends StatelessWidget {
  const _GrowthPill({required this.comparison});

  final SalesComparison comparison;

  @override
  Widget build(BuildContext context) {
    final percent = comparison.growthPercent;
    final icon = comparison.isUp
        ? Icons.trending_up_rounded
        : comparison.isDown
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    final text = percent == null
        ? 'No previous period'
        : '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}% vs previous';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 4.w, color: AppColor.white),
          1.width,
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 2.9.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label, big value and optional caption, with an optional icon.
class SalesKpi extends StatelessWidget {
  const SalesKpi({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.caption,
    this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final String? caption;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SalesCard(
      padding: EdgeInsets.all(3.5.w),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(2.2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon!, size: 4.5.w, color: accent),
            ),
            2.5.width,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                ),
                0.4.height,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 4.4.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ),
                if (caption != null) ...[
                  0.3.height,
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two or three segment switch (iOS style).
class SalesSegmentedControl<T extends Object> extends StatelessWidget {
  const SalesSegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor: AppColor.appLightColor,
        thumbColor: AppColor.white,
        children: {
          for (final entry in options.entries)
            entry.key: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              child: Text(
                entry.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 3.4.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
            ),
        },
        onValueChanged: (next) {
          if (next == null || next == value) return;
          onChanged(next);
        },
      ),
    );
  }
}

/// Compact button that shows the current filter and opens a sheet.
class SalesPillButton extends StatelessWidget {
  const SalesPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.1.h),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: AppShadow.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 4.w, color: accent),
              2.width,
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.2.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.appDarkColor,
                  ),
                ),
              ),
              1.width,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 5.w,
                color: AppColor.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ Charts

class SalesBar {
  const SalesBar({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final double value;
  final bool highlight;
}

/// Builds chart bars from trend points. The last point is highlighted.
List<SalesBar> salesBarsFrom(
  List<SalesDayPoint> points,
  String Function(String key) labelOf,
) {
  return [
    for (var i = 0; i < points.length; i++)
      SalesBar(
        label: labelOf(points[i].label),
        value: points[i].salesAmount,
        highlight: i == points.length - 1,
      ),
  ];
}

/// Vertical bar chart. Heights are relative to the largest bar.
class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.bars, required this.accent});

  final List<SalesBar> bars;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const SalesEmptyState(message: "No data for this period.");
    }
    final maxValue = bars.fold<double>(
      0,
      (m, bar) => bar.value > m ? bar.value : m,
    );

    return SizedBox(
      height: 24.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.4.w),
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: _ratio(bar.value, maxValue),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bar.highlight
                                  ? accent
                                  : accent.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(1.5.w),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    1.height,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bar.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 2.4.sp,
                          color: AppColor.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _ratio(double value, double max) {
    if (max <= 0 || value <= 0) return 0.02;
    return (value / max).clamp(0.02, 1.0).toDouble();
  }
}

/// One row of a top-N ranking with a proportional bar.
class SalesRankRow extends StatelessWidget {
  const SalesRankRow({
    super.key,
    required this.rank,
    required this.name,
    required this.amount,
    required this.ratio,
    required this.accent,
  });

  final int rank;
  final String name;
  final double amount;
  final double ratio;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 6.w,
              child: Text(
                "$rank",
                style: TextStyle(
                  fontSize: 3.1.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.grey,
                ),
              ),
            ),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.2.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
            ),
            SalesAmount(value: salesMoney(amount), color: accent, fontSize: 3.1),
          ],
        ),
        0.6.height,
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0).toDouble(),
            minHeight: 0.6.h,
            color: accent,
            backgroundColor: accent.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

// ============================================================ Sheets

/// Bottom sheet with a grab handle, title and close button. The content
/// scrolls when it is taller than the sheet.
Future<T?> showSalesSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext sheetContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColor.transparent,
    builder: (sheetContext) => SafeArea(
      child: Container(
        margin: EdgeInsets.all(2.w),
        padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 2.w, 2.h),
        constraints: BoxConstraints(maxHeight: 78.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(6.w),
          boxShadow: AppShadow.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppColor.appLightColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            1.height,
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 4.6.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Close",
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: Icon(Icons.close_rounded, color: AppColor.grey),
                ),
              ],
            ),
            Flexible(child: builder(sheetContext)),
          ],
        ),
      ),
    ),
  );
}

/// One tappable choice inside a sheet.
class SalesOptionTile extends StatelessWidget {
  const SalesOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      leading: Container(
        padding: EdgeInsets.all(2.2.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColor.appColor1.withValues(alpha: 0.1),
        ),
        child: Icon(icon, size: 5.w, color: AppColor.appColor1),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 3.6.sp,
          fontWeight: FontWeight.w600,
          color: AppColor.appDarkColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColor.grey),
      onTap: onTap,
    );
  }
}

/// Period sheet. Each option opens the same picker the other modules use
/// (month, date range or single day). The chosen period is returned to the
/// caller, which applies it to every Sales screen.
Future<SalesFilters?> showSalesPeriodSheet(
  BuildContext context,
  SalesFilters current,
) {
  return showSalesSheet<SalesFilters>(
    context,
    title: "Select period",
    builder: (_) => _PeriodOptions(current: current),
  );
}

class _PeriodOptions extends StatelessWidget {
  const _PeriodOptions({required this.current});

  final SalesFilters current;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(
      current.year ?? now.year,
      current.month ?? now.month,
    );
    final hasRange = current.dateFrom != null && current.dateTo != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesOptionTile(
          icon: Icons.event_available_rounded,
          title: "Calendar month",
          subtitle: current.date == null && !hasRange
              ? salesMonthYearFormat.format(month)
              : "Switch to a whole month",
          onTap: () => _pickMonth(context, month),
        ),
        SalesOptionTile(
          icon: Icons.date_range_rounded,
          title: "Date range",
          subtitle: hasRange
              ? salesPeriodLabel(current)
              : "Choose a start and an end date",
          onTap: () => _pickRange(context),
        ),
        SalesOptionTile(
          icon: Icons.today_rounded,
          title: "Single day",
          subtitle: current.date != null
              ? salesPeriodLabel(current)
              : "Sales for one date",
          onTap: () => _pickDay(context, now),
        ),
      ],
    );
  }

  void _pickMonth(BuildContext context, DateTime month) {
    CustomMonthPicker.showMonthPickerDialog(
      context: context,
      selectedMonth: month,
      onMonthSelected: (picked) => Navigator.pop(
        context,
        current.copyWith(
          month: picked.month,
          year: picked.year,
          clearRange: true,
          clearDate: true,
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final start = current.dateFrom;
    final end = current.dateTo;
    final result = await CustomDateRangePicker.show(
      context,
      initialRange: start != null && end != null
          ? DateTimeRange(start: start, end: end)
          : null,
    );
    final range = result.range;
    if (range == null || !context.mounted) return;
    Navigator.pop(
      context,
      current.copyWith(
        dateFrom: range.start,
        dateTo: range.end,
        clearDate: true,
      ),
    );
  }

  Future<void> _pickDay(BuildContext context, DateTime now) async {
    final picker = CustomDatePicker(
      hint: "Select date",
      selectedDate: current.date ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      onDateSelected: (day) {
        Navigator.pop(context, current.copyWith(date: day, clearRange: true));
      },
    );
    await picker.pickDate(context);
  }
}

/// One entry in a picker sheet (a salesperson or an order booker).
class SalesPickerOption {
  const SalesPickerOption({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final String id;
  final String name;
  final String subtitle;
}

class SalesPickerChoice {
  const SalesPickerChoice(this.option);

  /// Null means "All".
  final SalesPickerOption? option;
}

/// Lets the user pick one salesperson, or "All". Returns null if dismissed.
Future<SalesPickerChoice?> showSalesPickerSheet(
  BuildContext context, {
  required String title,
  required String allLabel,
  required List<SalesPickerOption> options,
  String? selectedId,
}) {
  final selected = selectedId == null || selectedId.isEmpty ? null : selectedId;
  final accent = AppColor.appColor1;

  return showSalesSheet<SalesPickerChoice>(
    context,
    title: title,
    builder: (sheetContext) {
      return ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: Icon(Icons.groups_rounded, color: accent),
            title: Text(
              allLabel,
              style: TextStyle(
                fontSize: 3.6.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.appDarkColor,
              ),
            ),
            trailing: selected == null
                ? Icon(Icons.check_rounded, color: accent)
                : null,
            onTap: () => Navigator.pop(
              sheetContext,
              const SalesPickerChoice(null),
            ),
          ),
          for (final option in options)
            ListTile(
              leading: Icon(Icons.person_rounded, color: AppColor.grey),
              title: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.6.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
              subtitle: Text(
                option.subtitle,
                style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
              ),
              trailing: selected == option.id
                  ? Icon(Icons.check_rounded, color: accent)
                  : null,
              onTap: () => Navigator.pop(
                sheetContext,
                SalesPickerChoice(option),
              ),
            ),
        ],
      );
    },
  );
}
