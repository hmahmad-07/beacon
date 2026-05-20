// ignore_for_file: file_names, must_be_immutable

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/extensions/routes.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';
import 'docs_viewer.dart';

class CustomDocsFile extends StatelessWidget {
  final String? selectedFile;
  final String? fileExtension;
  final String? fieldTitle;
  final Function(File file, String extension) onFileSelected;
  const CustomDocsFile({
    super.key,
    required this.selectedFile,
    required this.fileExtension,
    required this.onFileSelected,
    this.fieldTitle,
  });

  Future<void> pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension ?? '';
      onFileSelected(file, extension);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldTitle == null
            ? Padding(padding: EdgeInsets.only(bottom: 2.5.h))
            : Padding(
                padding: EdgeInsets.only(top: 1.5.h, bottom: .5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fieldTitle!,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColor.black,
                        fontSize: 4.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedFile != null && selectedFile!.isNotEmpty)
                      InkWell(
                        onTap: () {
                          debugPrint(selectedFile);
                          AppRoutes.push(DocsViewer(path: selectedFile ?? ''));
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: .4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.appColor1,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: Text(
                            'View',
                            style: TextStyle(
                              color: AppColor.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 4.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        InkWell(
          onTap: () {
            pickFile(context);
          },
          child: Container(
            width: double.maxFinite,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(3.r),
              border: Border.all(color: AppColor.appLightColor),
            ),
            child: selectedFile != null
                ? fileExtension == 'pdf' ||
                          selectedFile!.contains('pdf') ||
                          selectedFile!.endsWith('pdf')
                      ? Container(
                          width: double.maxFinite,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: AppColor.appLightColor,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: AppColor.red,
                                size: 10.r,
                              ),
                              2.height,
                              Text(
                                'PDF: ${selectedFile!.split('/').last}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 4.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : selectedFile!.startsWith('http') ||
                            selectedFile!.startsWith('https')
                      ? ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(3.r),
                          child: Image.network(
                            selectedFile!,
                            width: double.maxFinite,
                            height: 20.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return InkWell(
                                onTap: () {},
                                child: Center(
                                  child: Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: AppColor.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 4.sp,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(3.r),
                          child: Image.file(
                            File(selectedFile!),
                            width: double.maxFinite,
                            height: 20.h,
                            fit: BoxFit.cover,
                          ),
                        )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: AppColor.appColor1,
                        size: 10.r,
                      ),
                      2.height,
                      Text(
                        'Upload file',
                        style: TextStyle(
                          color: AppColor.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 4.sp,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
