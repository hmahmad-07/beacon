import 'package:flutter/material.dart';

import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

/// A rounded, pill-style segmented filter -- the designed replacement for
/// Material's default [ChoiceChip] row wherever a module needs a more
/// deliberate, on-brand look (e.g. the Inventory module's stock-level
/// filter).
class CustomSegmentedTabs extends StatelessWidget {
  const CustomSegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.activeColor,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(0.7.w),
      decoration: BoxDecoration(
        color: AppColor.appLightColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : AppColor.transparent,
                  borderRadius: BorderRadius.circular(2.5.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 2.8.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColor.white : AppColor.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
