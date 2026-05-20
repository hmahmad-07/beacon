// ignore_for_file: file_names, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class CustomField extends StatelessWidget {
  final Widget? prefix;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyType;
  final ValueChanged<String>? onChanged;
  final int maxLine;
  final String? fieldTitle;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool? readOnly;
  final bool? obscureText;
  final Widget? suffixIcon;
  final bool isLabel;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const CustomField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefix,
    this.maxLine = 1,
    this.onChanged,
    this.keyType,
    this.fieldTitle,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.obscureText,
    this.suffixIcon,
    this.isLabel = true,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldTitle == null
            ? Padding(padding: EdgeInsets.only(bottom: 2.5.h))
            : Padding(
                padding: EdgeInsets.only(top: 1.5.h, bottom: .5.h),
                child: Text(
                  fieldTitle!,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColor.black,
                    fontSize: 4.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        TextField(
          inputFormatters: inputFormatters,
          obscuringCharacter: '●',
          obscureText: obscureText ?? false,
          readOnly: readOnly ?? false,
          keyboardType: keyType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          controller: controller,
          maxLines: maxLine,
          focusNode: focusNode,
          cursorColor: AppColor.black,
          style: TextStyle(
            color: AppColor.black,
            fontSize: 4.5.sp,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            alignLabelWithHint: maxLine > 1,
            visualDensity: VisualDensity(vertical: -1),
            isDense: true,

            prefixIcon: prefix == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: prefix,
                  ),

            prefixIconConstraints: prefix == null
                ? null
                : BoxConstraints(minWidth: 0, minHeight: 0),

            labelText: isLabel ? hintText : null,
            hintText: isLabel ? null : hintText,

            labelStyle: TextStyle(
              color: AppColor.grey,
              fontSize: 4.sp,
              fontWeight: FontWeight.bold,
            ),

            hintStyle: TextStyle(
              color: AppColor.grey,
              fontSize: 4.sp,
              fontWeight: FontWeight.bold,
            ),

            floatingLabelStyle: TextStyle(
              color: AppColor.black,
              fontSize: 4.5.sp,
              fontWeight: FontWeight.bold,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.r),
              borderSide: BorderSide(color: AppColor.appColor1),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.r),
              borderSide: BorderSide(color: AppColor.appLightColor),
            ),

            contentPadding: EdgeInsets.symmetric(
              vertical: 2.2.h,
              horizontal: 3.w,
            ),

            suffixIconConstraints: const BoxConstraints(
              minHeight: 25,
              minWidth: 25,
            ),

            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
