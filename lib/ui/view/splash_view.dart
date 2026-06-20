// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:beacon/core/controllers/auth_controller.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/ui/view/auth/login_view.dart';
import 'package:beacon/ui/components/loading_view.dart';
import 'package:beacon/ui/view/dashboard/home_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: .7, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    _fadeController.forward();
    _scaleController.forward();

    Timer(const Duration(seconds: 3), () async {
      final auth = context.read<AuthController>();
      await auth.loadUserDetail();

      if (context.mounted) {
        if (Constants.token.isNotEmpty) {
          AppRoutes.pushAndRemoveAll(
            const LoadingView(title: "Restoring Session..."),
          );

          if (context.mounted) {
            await context.read<EmployesController>().fetchEmployees(context);
            AppRoutes.pushAndRemoveAll(const HomeView());
          }
        } else {
          AppRoutes.pushAndRemoveAll(const LoginView());
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColor.appDarkColor,
                  AppColor.appDarkColor,
                  AppColor.appColor1,
                ],
              ),
            ),
          ),

          Positioned(
            top: -10.h,
            right: -10.w,
            child: Container(
              height: 35.h,
              width: 35.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.scaffold.withValues(alpha: 0.1),
              ),
            ),
          ),

          Positioned(
            bottom: -12.h,
            left: -15.w,
            child: Container(
              height: 40.h,
              width: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.appColor2.withValues(alpha: 0.3),
              ),
            ),
          ),

          /// Center Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColor.appColor1.withValues(alpha: 0.2),
                            width: .4.w,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColor.appColor1, AppColor.appColor2],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.appColor1.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 35,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.radar_rounded,
                            color: AppColor.white,
                            size: 20.w,
                          ),
                        ),
                      ),
                    ),

                    5.height,

                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [AppColor.white, AppColor.appColor2],
                        ).createShader(bounds);
                      },
                      child: Text(
                        "BEACON",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5,
                        ),
                      ),
                    ),

                    1.height,

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        "MONITORING SYSTEM",
                        style: TextStyle(
                          color: AppColor.white,
                          fontSize: 4.sp,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 1.5.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 6.h,
            left: 8.w,
            right: 8.w,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: .7.h,
                    backgroundColor: AppColor.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(AppColor.appColor2),
                  ),
                ),
                2.height,
                Text(
                  "Initializing System...",
                  style: TextStyle(
                    color: AppColor.appLightColor,
                    fontSize: 3.8.sp,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
