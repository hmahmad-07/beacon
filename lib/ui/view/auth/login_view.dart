// ignore_for_file: use_build_context_synchronously

import 'package:beacon/ui/components/loading_view.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/extensions/sizer.dart';
import '../../../core/resources/app_colors.dart';
import '../../components/custom_button.dart';
import '../../components/custom_field.dart';

// The same dark ground and gold accent as the splash and onboarding.
const _ink = Color(0xFF0B0E14);
const _slate = Color(0xFF1F2A37);
const _gold = Color(0xFFE0A447);
const _sapphire = Color(0xFF3B82F6);

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

    _floatingAnimation = Tween<double>(begin: -6, end: 6).animate(
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

  Future<void> _signIn() async {
    if (authVC.employeeCodeController.text.isEmpty ||
        authVC.passwordController.text.isEmpty) {
      Utils.showSnackBar(context, "Please enter credentials");
      return;
    }

    AppRoutes.push(const LoadingView(title: "Authenticating..."));

    final success = await authVC.login(context);

    if (!success && context.mounted) {
      Navigator.pop(context);
    }

    if (success && context.mounted) {
      final empController = context.read<EmployesController>();
      await empController.getSites(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_ink, _ink, _slate],
                ),
              ),
            ),
          ),
          Positioned(top: -10.h, right: -14.w, child: _orb(40.h, _gold, 0.08)),
          Positioned(
            bottom: -14.h,
            left: -16.w,
            child: _orb(44.h, _sapphire, 0.08),
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
                          _brand(),
                          const Spacer(),
                          _card(),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(bottom: 3.h),
                            child: Text(
                              "Secure Enterprise Access",
                              style: TextStyle(
                                color: AppColor.appLightColor,
                                fontSize: 3.5.sp,
                                letterSpacing: 1,
                              ),
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

  /// The real PARC lockup from the app icon: monogram, wordmark, IMPACT and
  /// the tagline. It floats gently.
  Widget _brand() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.5),
          child: child,
        );
      },
      child: Image.asset(
        "assets/parc-logo.png",
        width: 62.w,
        fit: BoxFit.contain,
      ),
    );
  }

  /// The sign-in card: a white panel with a gold accent, holding the form.
  Widget _card() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          2.height,
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
            "Login with your credentials to continue.",
            style: TextStyle(
              color: AppColor.grey,
              fontSize: 3.8.sp,
              height: 1.5,
            ),
          ),
          4.height,
          CustomField(
            controller: authVC.employeeCodeController,
            fieldTitle: 'Code',
            isLabel: false,
            hintText: "Enter Code",
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
            buttonColor: _gold,
            textColor: _ink,
            onPress: _signIn,
          ),
        ],
      ),
    );
  }
}

Widget _orb(double size, Color color, double alpha) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: alpha),
    ),
  );
}
