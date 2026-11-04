import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../extensions/routes.dart';
import '../resources/app_colors.dart';

/// Handles the case where the server rejects the signed-in user's token.
/// It shows one "Session expired" dialog, then signs the user out, which
/// takes them to the login screen.
class SessionGuard {
  SessionGuard._();

  static bool _active = false;

  static Future<void> handleExpired() async {
    if (_active) return;

    final navigatorContext = AppRoutes.navigatorKey.currentContext;
    if (navigatorContext == null) return;

    _active = true;
    try {
      await showDialog<void>(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(
              "Session expired",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
              ),
            ),
            content: Text(
              "Your session has ended. Please sign in again.",
              style: TextStyle(color: AppColor.darkGrey),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      );

      final context = AppRoutes.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        await context.read<AuthController>().logout(context);
      }
    } finally {
      _active = false;
    }
  }
}
