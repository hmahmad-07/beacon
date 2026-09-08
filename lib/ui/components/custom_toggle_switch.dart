import 'package:flutter/material.dart';

import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

/// A pill-shaped animated toggle used in place of Flutter's stock [Switch]
/// wherever the surrounding module needs to look intentionally designed
/// rather than default-Material (e.g. the Inventory module's filters).
class CustomToggleSwitch extends StatelessWidget {
  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final width = 11.w;
    final height = 6.w;
    final thumbSize = height - 1.2.w;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: width,
        height: height,
        padding: EdgeInsets.all(0.6.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height),
          color: value ? activeColor : AppColor.appLightColor,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.white,
              boxShadow: [
                BoxShadow(
                  color: AppColor.black.withValues(alpha: 0.18),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
