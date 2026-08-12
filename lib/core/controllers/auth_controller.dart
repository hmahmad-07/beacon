// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../ui/view/dashboard/home_view.dart';
import '../../ui/view/splash_view.dart';
import '../constants/constants.dart';
import '../extensions/routes.dart';
import '../utils/utils.dart';

class AuthController extends ChangeNotifier {
  var isLoading = false;

  bool isObscured = true;
  void setObscure(bool value) {
    isObscured = value;
    notifyListeners();
  }

  bool isAcceptedTerms = false;
  void acceptTerms(bool value) {
    isAcceptedTerms = value;
    notifyListeners();
  }

  // ================================================================= Login =================================================================

  final employeeCodeController = TextEditingController();
  final passwordController = TextEditingController();

  Future<bool> login(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final formData = {
        'tag': 'login',
        'email': employeeCodeController.text.trim(),
        'password': passwordController.text.trim(),
      };

      final dio = Dio();
      final response = await dio.post(
        '${Constants.baseUrl}login_api_cspmobile_user.php',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['error'] == 0) {
          Utils.showSnackBar(
            context,
            data['error_msg']?.toString() ?? 'Login successful!',
          );
          await saveUserData(data);

          if (context.mounted) {
            AppRoutes.pushAndRemoveAll(const HomeView());
          }

          employeeCodeController.clear();
          passwordController.clear();
          return true;
        } else {
          if (context.mounted) {
            Utils.showSnackBar(context, data['error_msg'] ?? 'Login failed');
          }
          return false;
        }
      }
      return false;
    } on DioException catch (e) {
      log('Dio error: ${e.response?.data}');
      if (context.mounted) {
        try {
          Utils.showSnackBar(
            context,
            e.response?.data is Map
                ? (e.response?.data['error_msg'] ??
                      'Login failed. Check credentials')
                : 'Login failed. Check credentials',
          );
        } catch (_) {}
      }
      return false;
    } catch (e) {
      log('Unexpected error: $e');
      if (context.mounted) {
        try {
          Utils.showSnackBar(context, 'Something went wrong');
        } catch (_) {}
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    final ss = FlutterSecureStorage();

    await ss.write(key: 'empCode', value: employeeCodeController.text.trim());
    await ss.write(key: 'token', value: data['token'] ?? '');
    await ss.write(key: 'id', value: data['USER_ID'] ?? '');
    await ss.write(key: 'userType', value: data['GROUP_TYPE'] ?? '');
    await ss.write(key: 'name', value: data['USER_NAME'] ?? '');

    await loadUserDetail();
  }

  Future<void> loadUserDetail() async {
    final ss = FlutterSecureStorage();

    Constants.token = await ss.read(key: 'token') ?? '';
    Constants.name = await ss.read(key: 'name') ?? '';
    Constants.id = await ss.read(key: 'id') ?? '';
    Constants.code = await ss.read(key: 'empCode') ?? '';
    Constants.type = await ss.read(key: 'userType') ?? '';

    log('Token: ${Constants.token}');
    log('Name: ${Constants.name}');
    log('ID: ${Constants.id}');
    log('EmpCode: ${Constants.code}');
    log('UserType: ${Constants.type}');
  }

  @override
  void dispose() {
    employeeCodeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================== Logout ===========================================================

  Future<void> logout(BuildContext context) async {
    final ss = FlutterSecureStorage();

    try {
      isLoading = true;
      notifyListeners();

      await ss.delete(key: 'token');
      await ss.delete(key: 'name');
      await ss.delete(key: 'id');
      await ss.delete(key: 'empCode');
      await ss.delete(key: 'userType');

      Constants.token = '';
      Constants.name = '';
      Constants.id = '';
      Constants.code = '';
      Constants.type = '';

      await Phoenix.rebirth(context);

      if (!context.mounted) return;
      AppRoutes.pushAndRemoveAll(const SplashView());
    } catch (e) {
      debugPrint('Logout error: $e');

      if (context.mounted) {
        Utils.showSnackBar(context, "Logout failed");
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
