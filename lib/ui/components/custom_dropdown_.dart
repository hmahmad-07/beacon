// ignore_for_file: must_be_immutable, file_names

import 'package:flutter/material.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class CustomDropdown extends StatelessWidget {
  final String hintText;
  final String? fieldTitle;
  final String? selectedItem;
  final List<String> menuList;
  final List<IconData>? iconList;
  final void Function(String value) onChange;

  const CustomDropdown({
    super.key,
    required this.hintText,
    this.fieldTitle,
    required this.selectedItem,
    required this.menuList,
    required this.onChange,
    this.iconList,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PopupMenuButton<String>(
          offset: Offset(0, 8.h),
          color: AppColor.appColor1,
          elevation: 4,
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
            maxHeight: 40.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.r),
          ),
          onSelected: (String newValue) {
            onChange(newValue);
          },
          itemBuilder: (context) => menuList.asMap().entries.map((entry) {
            int index = entry.key;
            String item = entry.value;

            IconData? icon = (iconList != null && iconList!.length > index)
                ? iconList![index]
                : null;

            return PopupMenuItem<String>(
              value: item,
              height: 4.5.h,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 2.5.h, color: AppColor.white),
                    SizedBox(width: 3.w),
                  ],
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 4.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (selectedItem == item)
                    Icon(Icons.check_circle, color: AppColor.white, size: 2.h),
                ],
              ),
            );
          }).toList(),
          child: Column(
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.8.h),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(3.r),
                  border: Border.all(color: AppColor.appLightColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (selectedItem != null &&
                                menuList.contains(selectedItem))
                            ? selectedItem!
                            : hintText,
                        style: TextStyle(
                          color:
                              (selectedItem != null &&
                                  menuList.contains(selectedItem))
                              ? AppColor.black
                              : AppColor.grey,
                          fontSize: 4.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColor.darkGrey,
                      size: 5.w,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
