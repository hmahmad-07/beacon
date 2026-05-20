// Responsive class

import 'package:flutter/material.dart';

class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late bool isMobile;
  static late bool isTablet;
  static late bool isDesktop;
  static late double scaleFactor;
  static late Orientation orientation;

  static void init(BuildContext context, {bool debug = false}) {
    screenWidth = MediaQuery.sizeOf(context).width;
    screenHeight = MediaQuery.sizeOf(context).height;
    orientation = MediaQuery.orientationOf(context);

    isMobile = screenWidth < 600;
    isTablet = screenWidth >= 600 && screenWidth < 1200;
    isDesktop = screenWidth >= 1200;

    if (isMobile) {
      scaleFactor = 0.8;
    } else if (isTablet) {
      scaleFactor = 1.0;
    } else if (isDesktop) {
      scaleFactor = 1.2;
    }

    if (orientation == Orientation.landscape) {
      scaleFactor *= 1.1;
    }

    if (isDesktop && screenWidth > 1800) {
      scaleFactor = 1.4;
    }

    scaleFactor = scaleFactor.clamp(0.8, 1.3);
  }

  static int itemCount(int portrait, int landscape) {
    return orientation == Orientation.portrait ? portrait : landscape;
  }
}

extension SizeExtension on num {
  double get h => this * SizeConfig.screenHeight / 100 * SizeConfig.scaleFactor;
  double get w => this * SizeConfig.screenWidth / 100 * SizeConfig.scaleFactor;

  double get sp {
    final base = SizeConfig.screenWidth < SizeConfig.screenHeight
        ? SizeConfig.screenWidth
        : SizeConfig.screenHeight;
    return this * base / 100 * SizeConfig.scaleFactor;
  }

  double get r {
    final base = SizeConfig.screenWidth < SizeConfig.screenHeight
        ? SizeConfig.screenWidth
        : SizeConfig.screenHeight;
    return this * base / 100 * SizeConfig.scaleFactor;
  }

  SizedBox get height => SizedBox(height: h);
  SizedBox get width => SizedBox(width: w);
}
