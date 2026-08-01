// ignore_for_file: must_be_immutable, file_names

import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';
import 'custom_field.dart';

class CustomSearchDropdown extends StatefulWidget {
  final String hintText;
  final String? fieldTitle;
  final String? selectedItem;
  final List<String> menuList;
  final void Function(String value) onChange;

  const CustomSearchDropdown({
    super.key,
    required this.hintText,
    this.fieldTitle,
    required this.selectedItem,
    required this.menuList,
    required this.onChange,
  });

  @override
  State<CustomSearchDropdown> createState() => _CustomSearchDropdownState();
}

class _CustomSearchDropdownState extends State<CustomSearchDropdown> {
  final searchController = TextEditingController();

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
                    fontSize: 4.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        GestureDetector(
          onTap: _showSearchDialog,
          child: Container(
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
                    (widget.selectedItem != null &&
                            widget.menuList.contains(widget.selectedItem))
                        ? widget.selectedItem!
                        : widget.hintText,
                    style: TextStyle(
                      color:
                          (widget.selectedItem != null &&
                              widget.menuList.contains(widget.selectedItem))
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
                  Iconsax.search_normal_outline,
                  color: AppColor.darkGrey,
                  size: 5.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchDialog() {
    searchController.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredList = widget.menuList
                .where(
                  (item) =>
                      item.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                constraints: BoxConstraints(maxHeight: 65.h),
                decoration: BoxDecoration(
                  color: AppColor.appColor1,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(2.5.r),
                      ),
                      child: CustomField(
                        controller: searchController,
                        hintText: 'Search here...',
                        isLabel: false,
                        prefix: Icon(
                          Iconsax.search_normal_1_outline,
                          color: AppColor.appColor1.withValues(alpha: 0.7),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),

                    2.height,
                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Text(
                                "No results found",
                                style: TextStyle(
                                  color: AppColor.white.withValues(alpha: 0.6),
                                  fontSize: 4.sp,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredList.length,
                              separatorBuilder: (_, _) => Divider(
                                color: AppColor.white.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final item = filteredList[index];
                                final isSelected = widget.selectedItem == item;

                                return Material(
                                  color: isSelected
                                      ? AppColor.white.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2.r),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(2.r),
                                    onTap: () {
                                      widget.onChange(item);
                                      Navigator.pop(context);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 1.5.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                color: AppColor.white,
                                                fontSize: 4.2.sp,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              color: AppColor.white,
                                              size: 2.2.h,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
