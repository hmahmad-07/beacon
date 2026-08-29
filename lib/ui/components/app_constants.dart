import 'package:flutter/material.dart';

import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class AppPadding {
  static EdgeInsets main = EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h);
}

class AppShadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColor.appDarkColor.withValues(alpha: 0.07),
      blurRadius: 1,
      spreadRadius: 1,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> textShadow = [
    BoxShadow(
      color: AppColor.appDarkColor.withValues(alpha: 0.3),
      blurRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];
}
