// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class IntlField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<PhoneNumber> onChanged;
  final String? fieldTitle;
  final String hintText;

  const IntlField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.fieldTitle,
    this.hintText = 'Mobile Number',
  });

  @override
  State<IntlField> createState() => _IntlFieldState();
}

class _IntlFieldState extends State<IntlField> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();

    if (widget.controller.text.isNotEmpty) {
      String number = widget.controller.text;
      if (number.startsWith('+')) {
        number = number.replaceFirst(RegExp(r'^\+\d{1,4}'), '');
      }
      _internalController.text = number;
    }
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.fieldTitle == null
            ? Padding(padding: EdgeInsets.only(bottom: 2.5.h))
            : Padding(
                padding: EdgeInsets.only(top: 1.5.h, bottom: .5.h),
                child: Text(
                  widget.fieldTitle!,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColor.black,
                    fontSize: 4.5.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

        IntlPhoneField(
          controller: _internalController,
          cursorColor: AppColor.black,
          textAlignVertical: TextAlignVertical.center,
          autofocus: false,

          style: TextStyle(
            color: AppColor.black,
            fontSize: 4.5.sp,
            fontWeight: FontWeight.bold,
          ),

          dropdownTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 5.sp,
            color: AppColor.black,
          ),

          pickerDialogStyle: PickerDialogStyle(
            searchFieldInputDecoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.r),
                borderSide: BorderSide(color: AppColor.appLightColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.r),
                borderSide: BorderSide(color: AppColor.appLightColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.r),
                borderSide: BorderSide(color: AppColor.appColor1),
              ),
              suffixIcon: Icon(Icons.search, size: 20, color: AppColor.grey),
              labelText: 'Search Country',
              labelStyle: TextStyle(
                fontSize: 4.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.grey,
              ),
              floatingLabelStyle: TextStyle(
                fontSize: 4.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.black,
              ),
            ),
            searchFieldPadding: EdgeInsets.symmetric(
              vertical: 5.h,
              horizontal: 2.w,
            ),
            countryNameStyle: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: AppColor.white,
            countryCodeStyle: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.black,
            ),
          ),

          dropdownIcon: Icon(
            Icons.keyboard_arrow_down,
            size: 6.r,
            color: AppColor.grey,
          ),
          dropdownIconPosition: IconPosition.trailing,

          showCountryFlag: true,
          initialCountryCode: 'PK',
          invalidNumberMessage: null,
          flagsButtonPadding: EdgeInsets.only(left: 3.w),

          decoration: InputDecoration(
            visualDensity: VisualDensity(vertical: -1),

            labelText: widget.hintText,
            labelStyle: TextStyle(
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

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.r),
              borderSide: BorderSide(color: AppColor.red),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.r),
              borderSide: BorderSide(color: AppColor.red),
            ),

            contentPadding: EdgeInsets.symmetric(
              vertical: 2.2.h,
              horizontal: 3.w,
            ),

            counterText: '',
          ),

          onChanged: (PhoneNumber phone) {
            widget.controller.text = phone.completeNumber;
            widget.onChanged(phone);
          },
        ),
      ],
    );
  }
}
