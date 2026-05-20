// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class RoundButton extends StatelessWidget {
  final Widget? child;
  final bool isLoading;
  final String? title;
  final double height, width;
  final VoidCallback? onPress;
  final Color? textColor, buttonColor;
  final double buttonRadius;
  final double elevation;
  final double? fontSize;

  const RoundButton({
    super.key,
    this.textColor,
    required this.buttonColor,
    this.isLoading = false,
    this.title,
    this.height = 44,
    this.width = 50,
    this.fontSize,
    required this.onPress,
    this.buttonRadius = 10,
    this.child,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPress,
        style: ElevatedButton.styleFrom(
          elevation: elevation,
          padding: EdgeInsets.zero,
          backgroundColor: buttonColor,
          shadowColor: AppColor.grey,
          overlayColor: AppColor.black.withValues(alpha: .1),
          surfaceTintColor: AppColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColor.appColor1,
                    strokeWidth: 2,
                  ),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child:
                    child ??
                    Text(
                      maxLines: 1,
                      title ?? '',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: textColor ?? AppColor.white,
                        fontSize: fontSize ?? 5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
      ),
    );
  }
}
