import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/constants.dart';
import '../../core/controllers/employes_controller.dart';
import '../../core/extensions/routes.dart';
import '../components/loading_view.dart';
import 'auth/login_view.dart';
import 'dashboard/home_view.dart';

/// Where the app goes once the splash (and, on first run, onboarding) is
/// done: straight into the home screen when a session exists, otherwise to
/// sign-in.
Future<void> continueStartup(BuildContext context) async {
  if (Constants.token.isNotEmpty) {
    AppRoutes.pushAndRemoveAll(
      const LoadingView(title: "Restoring Session..."),
    );

    if (context.mounted) {
      await context.read<EmployesController>().getSites(context);
      AppRoutes.pushAndRemoveAll(const HomeView());
    }
  } else {
    AppRoutes.pushAndRemoveAll(const LoginView());
  }
}
