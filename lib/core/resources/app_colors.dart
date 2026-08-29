// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColor {
  static Color red = const Color.fromARGB(255, 189, 12, 12);
  static Color green = const Color.fromARGB(255, 9, 188, 15);
  static Color appLightColor = const Color(0xFFE3E3E3);
  static Color grey = const Color(0xFF696D75);
  static Color darkGrey = const Color(0xFF4B4B4B);
  static Color scaffold = const Color(0xffF5F7FB);
  static Color appColor1 = const Color(0xFF1E88E5);
  static Color appColor2 = const Color(0xffE5C13C);
  static Color appDarkColor = const Color(0xFF181E4C);
  static Color black = const Color(0xFF111111);
  static Color white = const Color(0xFFFFFFFF);
  static Color transparent = Colors.transparent;
  static Color cc = Color(0xFFAF2F03);
  static Color paani = Color(0xFF3A8C9E);
  static Color rth = Color(0xFFD01372);
  static Color aa = Color(0xFFC9922B);
  static Color ss = Color(0xFFF28C28);
  static Color opd = Color(0xFF00897B);
  static Color amtax = Color(0xFF37474F);

  static void swapColors() {
    final tempWhite = white;
    white = black;
    black = tempWhite;

    final tempLight = appLightColor;
    appLightColor = darkGrey;
    darkGrey = tempLight;
  }
}

class ThemeManager with ChangeNotifier {
  bool _isSwapped = false;

  bool get isSwapped => _isSwapped;

  void toggleTheme() {
    _isSwapped = !_isSwapped;
    AppColor.swapColors();
    notifyListeners();
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColor.appColor1,
      onPrimary: AppColor.white,
      secondary: AppColor.appColor2,
      onSecondary: AppColor.white,
      error: AppColor.red,
      onError: AppColor.white,
      surface: AppColor.white,
      onSurface: AppColor.black,
      surfaceContainerHighest: AppColor.appLightColor,
      outline: AppColor.grey,
      shadow: AppColor.black,
    ),
    scaffoldBackgroundColor: AppColor.white,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColor.appColor1,
      foregroundColor: AppColor.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColor.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColor.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColor.white,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.appColor1,
        foregroundColor: AppColor.white,
        disabledBackgroundColor: AppColor.appLightColor,
        disabledForegroundColor: AppColor.grey,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColor.appColor1,
        side: BorderSide(color: AppColor.appColor1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColor.appColor1),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColor.appColor1,
      foregroundColor: AppColor.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColor.white,
      hintStyle: TextStyle(color: AppColor.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.appLightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.appColor1, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.red),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColor.white,
      elevation: 2,
      shadowColor: AppColor.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: AppColor.appLightColor, thickness: 1),
    iconTheme: IconThemeData(color: AppColor.appDarkColor),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColor.white,
      selectedItemColor: AppColor.appColor1,
      unselectedItemColor: AppColor.grey,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: AppColor.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColor.black.withValues(alpha: 0.06),
      indicatorColor: AppColor.appColor1.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColor.appColor1 : AppColor.grey,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? AppColor.appColor1 : AppColor.grey,
        );
      }),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: AppColor.appDarkColor,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: TextStyle(
        color: AppColor.appDarkColor,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        color: AppColor.appDarkColor,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        color: AppColor.appDarkColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(color: AppColor.black, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
        color: AppColor.black,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: AppColor.black),
      bodyMedium: TextStyle(color: AppColor.darkGrey),
      bodySmall: TextStyle(color: AppColor.grey),
      labelLarge: TextStyle(color: AppColor.white, fontWeight: FontWeight.w600),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColor.appLightColor,
      selectedColor: AppColor.appColor1,
      labelStyle: TextStyle(color: AppColor.black),
      side: BorderSide(color: AppColor.appLightColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColor.appDarkColor,
      contentTextStyle: TextStyle(color: AppColor.white),
      actionTextColor: AppColor.appColor2,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColor.appColor1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColor.appColor1
            : AppColor.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColor.appColor1.withValues(alpha: 0.4)
            : AppColor.appLightColor,
      ),
    ),
  );
}
