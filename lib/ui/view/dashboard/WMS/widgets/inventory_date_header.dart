import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/inventory_dates.dart';
import 'package:flutter/material.dart';

/// Sticky-looking day divider used above each date group.
class InventoryDateHeader extends StatelessWidget {
  const InventoryDateHeader({
    super.key,
    required this.day,
    required this.count,
    required this.accentColor,
    this.countLabel = 'entries',
  });

  final DateTime? day;
  final int count;
  final Color accentColor;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final label = InventoryDates.dayLabel(day);
    final showFull = day != null && label != InventoryDates.full(day);
    return Padding(
      padding: EdgeInsets.only(top: 1.6.h, bottom: 1.2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_note_rounded, size: 3.6.w, color: accentColor),
                1.5.width,
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 3.sp,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          if (showFull) ...[
            2.width,
            Text(
              InventoryDates.full(day),
              style: TextStyle(
                fontSize: 2.8.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.grey,
              ),
            ),
          ],
          2.5.width,
          Expanded(
            child: Container(
              height: 1,
              color: AppColor.appLightColor.withValues(alpha: 0.7),
            ),
          ),
          2.5.width,
          Text(
            "$count $countLabel",
            style: TextStyle(
              fontSize: 2.7.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.grey,
            ),
          ),
        ],
      ),
    );
  }
}
