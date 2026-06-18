import 'package:centrex/ui/components/loading_view.dart';
import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/extensions/routes.dart';
import 'package:centrex/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/extensions/sizer.dart';
import '../../../core/resources/app_colors.dart';
import '../../components/custom_button.dart';
import '../../components/custom_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  late AuthController authVC;

  late AnimationController _fadeController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authVC = context.watch<AuthController>();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColor.appLightColor,
                  AppColor.scaffold,
                  AppColor.scaffold,
                  AppColor.white,
                ],
              ),
            ),
          ),
          Positioned(
            top: -10.h,
            right: -15.w,
            child: Container(
              height: 35.h,
              width: 35.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.appColor1.withValues(alpha: 0.1),
              ),
            ),
          ),

          Positioned(
            bottom: -12.h,
            left: -15.w,
            child: Container(
              height: 38.h,
              width: 38.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.appColor2.withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7.w),
                      child: Column(
                        children: [
                          8.height,

                          AnimatedBuilder(
                            animation: _floatingAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _floatingAnimation.value),
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  height: 24.w,
                                  width: 24.w,
                                  padding: EdgeInsets.all(1.5.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColor.appColor1.withValues(
                                        alpha: 0.15,
                                      ),
                                      width: .5.w,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColor.appColor1,
                                          AppColor.appColor2,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColor.appColor1.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 25,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: Colors.white,
                                      size: 10.w,
                                    ),
                                  ),
                                ),

                                4.height,

                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: [
                                        AppColor.appColor1,
                                        AppColor.appColor2,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    "CENTREX",
                                    style: TextStyle(
                                      color: AppColor.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 5,
                                    ),
                                  ),
                                ),
                                1.height,
                                Text(
                                  " MONITORING SYSTEM",
                                  style: TextStyle(
                                    color: AppColor.appDarkColor,
                                    fontSize: 3.8.sp,
                                    letterSpacing: 2.w,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.black.withValues(alpha: 0.06),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome Back",
                                  style: TextStyle(
                                    color: AppColor.appDarkColor,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                1.height,

                                Text(
                                  "Login with your employee credentials to continue.",
                                  style: TextStyle(
                                    color: AppColor.appColor1,
                                    fontSize: 3.8.sp,
                                    height: 1.5,
                                  ),
                                ),
                                4.height,
                                CustomField(
                                  controller: authVC.employeeCodeController,
                                  fieldTitle: 'Employee Code',
                                  isLabel: false,
                                  hintText: "Enter Employee Code",
                                  keyType: TextInputType.number,
                                ),
                                CustomField(
                                  controller: authVC.passwordController,
                                  fieldTitle: 'Password',
                                  isLabel: false,
                                  hintText: "Enter Password",
                                  obscureText: true,
                                  keyType: TextInputType.visiblePassword,
                                ),
                                10.height,
                                RoundButton(
                                  width: double.infinity,
                                  height: 7.h,
                                  title: "SIGN IN",
                                  isLoading: authVC.isLoading,
                                  buttonColor: AppColor.appColor1,

                                  onPress: () async {
                                    if (authVC
                                            .employeeCodeController
                                            .text
                                            .isEmpty ||
                                        authVC
                                            .passwordController
                                            .text
                                            .isEmpty) {
                                      Utils.showSnackBar(
                                        context,
                                        "Please enter credentials",
                                      );
                                      return;
                                    }

                                    AppRoutes.push(
                                      const LoadingView(
                                        title: "Authenticating...",
                                      ),
                                    );

                                    final success = await authVC.login(context);

                                    if (!success && context.mounted) {
                                      Navigator.pop(context);
                                    }

                                    if (success && context.mounted) {
                                      final empController = context
                                          .read<EmployesController>();
                                      await empController.fetchEmployees(
                                        context,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(bottom: 3.h),
                            child: Column(
                              children: [
                                Text(
                                  "Secure Enterprise Access",
                                  style: TextStyle(
                                    color: AppColor.appDarkColor,
                                    fontSize: 3.5.sp,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
