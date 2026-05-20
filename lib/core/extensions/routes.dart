// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<dynamic>? push(Widget page) {
    return navigatorKey.currentState?.push(
      ScalePageRoute(builder: (_) => page),
    );
  }

  static Future<dynamic>? pushReplacement(Widget page) {
    return navigatorKey.currentState?.pushReplacement(
      ScalePageRoute(builder: (_) => page),
    );
  }

  static Future<dynamic>? pushAndRemoveUntil(Widget page) {
    return navigatorKey.currentState?.pushAndRemoveUntil(
      ScalePageRoute(builder: (_) => page),
      (Route<dynamic> route) => route.isFirst,
    );
  }

  static Future<dynamic>? pushAndRemoveAll(Widget page) {
    return navigatorKey.currentState?.pushAndRemoveUntil(
      ScalePageRoute(builder: (_) => page),
      (Route<dynamic> route) => false,
    );
  }

  static void pop() {
    return navigatorKey.currentState?.pop();
  }
}

extension NavigationExtension on BuildContext {
  Future<dynamic>? push(Widget page) => AppRoutes.push(page);

  Future<dynamic>? pushReplacement(Widget page) =>
      AppRoutes.pushReplacement(page);

  Future<dynamic>? pushAndRemoveUntil(Widget page) =>
      AppRoutes.pushAndRemoveUntil(page);

  Future<dynamic>? pushAndRemoveAll(Widget page) =>
      AppRoutes.pushAndRemoveAll(page);

  void pop() => AppRoutes.pop();
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  ScalePageRoute({required this.builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
}
