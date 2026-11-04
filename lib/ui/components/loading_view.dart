import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/material.dart';

/// Full-screen loader used while signing in and similar steps. It uses the
/// same loader as every other screen.
class LoadingView extends StatelessWidget {
  final String title;
  const LoadingView({super.key, this.title = "Processing..."});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      body: AppLoadingView(label: title),
    );
  }
}
