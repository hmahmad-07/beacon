// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/HR/employee_salary_type_model.dart';
import '../models/HR/department_salary_cost_model.dart';
import '../models/HR/attendance_report_model.dart';
import '../utils/utils.dart';

class HRController extends ChangeNotifier {
  // ================================================== Salary Type Report State ==================================================

  bool isSalaryReportLoading = false;
  SalaryTypeReportModel? salaryTypeReportModel;

  DateTime selectedDate = DateTime.now();
  String selectedJobType = "ALL";
  int selectedChartType = 0;
  int touchedIndex = -1;

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setSelectedJobType(String jobType) {
    selectedJobType = jobType;
    notifyListeners();
  }

  void setSelectedChartType(int chartType) {
    selectedChartType = chartType;
    notifyListeners();
  }

  void setTouchedIndex(int index) {
    touchedIndex = index;
    notifyListeners();
  }

  void resetReportState() {
    selectedDate = DateTime.now();
    selectedJobType = "ALL";
    selectedChartType = 0;
    touchedIndex = -1;
  }

  Future<void> getEmpSalaryTypeReport(
    BuildContext context, {
    required String month,
    required String year,
    String? shopId,
    String? deptId,
    String? employeeId,
  }) async {
    try {
      isSalaryReportLoading = true;
      salaryTypeReportModel = null;
      notifyListeners();

      final dio = Dio();
      final response = await dio.request(
        '${Constants.baseUrl}report_salary_type.php',
        queryParameters: {
          'month': month,
          'year': year,
          if (shopId != null && shopId.isNotEmpty) 'shop_id': shopId,
          if (deptId != null && deptId.isNotEmpty) 'dept_id': deptId,
          if (employeeId != null && employeeId.isNotEmpty)
            'employee_id': employeeId,
        },
        options: Options(
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        salaryTypeReportModel = SalaryTypeReportModel.fromJson(response.data);
        if (salaryTypeReportModel?.error == 0) {
          log(
            "Salary Report Fetched Successfully: ${salaryTypeReportModel?.totalDepartmentEmployees}",
          );
        } else {
          if (context.mounted) {
            Utils.showSnackBar(
              context,
              salaryTypeReportModel?.errorMsg ?? 'Failed to load report',
            );
          }
        }
      } else {
        if (context.mounted) {
          Utils.showSnackBar(
            context,
            'Server Error: ${response.statusCode} - ${response.statusMessage}',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching salary report: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching salary report: $e');
      if (context.mounted) {
        Utils.showSnackBar(context, 'Something went wrong. Please try again.');
      }
    } finally {
      isSalaryReportLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Salary Cost Report State ==================================================

  bool isSalaryCostReportLoading = false;
  SalaryCostReportModel? salaryCostReportModel;
  String selectedSalaryCostJobType = "ALL";
  int salaryCostTouchedIndex = -1;

  void setSelectedSalaryCostJobType(String jobType) {
    selectedSalaryCostJobType = jobType;
    notifyListeners();
  }

  void setSalaryCostTouchedIndex(int index) {
    salaryCostTouchedIndex = index;
    notifyListeners();
  }

  Future<void> getSalaryCostReport(
    BuildContext context, {
    required String month,
    required String year,
    String? shopId,
    String? deptId,
    String? employeeId,
  }) async {
    try {
      isSalaryCostReportLoading = true;
      salaryCostReportModel = null;
      notifyListeners();

      final dio = Dio();
      final response = await dio.request(
        '${Constants.baseUrl}report_dept_cost.php',
        queryParameters: {
          'month': month,
          'year': year,
          if (shopId != null && shopId.isNotEmpty) 'shop_id': shopId,
          if (deptId != null && deptId.isNotEmpty) 'dept_id': deptId,
          if (employeeId != null && employeeId.isNotEmpty)
            'employee_id': employeeId,
        },
        options: Options(
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        salaryCostReportModel = SalaryCostReportModel.fromJson(response.data);
        if (salaryCostReportModel?.error == 0) {
          log(
            "Salary Cost Report Fetched: ${salaryCostReportModel?.totalDepartmentEmployees}",
          );
        } else if (context.mounted) {
          Utils.showSnackBar(
            context,
            salaryCostReportModel?.errorMsg ?? 'Failed to load salary report',
          );
        }
      } else if (context.mounted) {
        Utils.showSnackBar(
          context,
          'Server Error: ${response.statusCode} - ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      log('Dio error fetching salary cost report: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching salary cost report: $e');
      if (context.mounted) {
        Utils.showSnackBar(context, 'Something went wrong. Please try again.');
      }
    } finally {
      isSalaryCostReportLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Attendance Report State ==================================================

  bool isAttendanceReportLoading = false;
  AttendanceReportModel? attendanceReportModel;
  DateTime attendanceSelectedDate = DateTime.now();

  bool isEmployeeAttendanceLoading = false;
  AttendanceReportModel? employeeAttendanceModel;

  void setAttendanceSelectedDate(DateTime date) {
    attendanceSelectedDate = date;
    notifyListeners();
  }

  Future<void> getAttendanceReport(
    BuildContext context, {
    required String month,
    required String year,
    String? shopId,
    String? deptId,
    String? employeeId,
    bool forEmployeeDetail = false,
  }) async {
    try {
      if (forEmployeeDetail) {
        isEmployeeAttendanceLoading = true;
        employeeAttendanceModel = null;
      } else {
        isAttendanceReportLoading = true;
        attendanceReportModel = null;
      }
      notifyListeners();

      final dio = Dio();
      final response = await dio.request(
        '${Constants.baseUrl}report_attendance.php',
        queryParameters: {
          'month': month,
          'year': year,
          if (shopId != null && shopId.isNotEmpty) 'shop_id': shopId,
          if (deptId != null && deptId.isNotEmpty) 'dept_id': deptId,
          if (employeeId != null && employeeId.isNotEmpty)
            'employee_id': employeeId,
        },
        options: Options(
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final parsed = AttendanceReportModel.fromJson(response.data);
        if (forEmployeeDetail) {
          employeeAttendanceModel = parsed;
        } else {
          attendanceReportModel = parsed;
          if ((parsed.departmentEmployees ?? []).isEmpty) {
            await _loadDepartmentEmployeesForAttendance(
              month: month,
              year: year,
              shopId: shopId,
              deptId: deptId,
            );
          }
        }
        if (parsed.error != 0 && forEmployeeDetail && context.mounted) {
          Utils.showSnackBar(
            context,
            parsed.errorMsg ?? 'Failed to load attendance report',
          );
        }
      } else if (context.mounted) {
        Utils.showSnackBar(
          context,
          'Server Error: ${response.statusCode} - ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      log('Dio error fetching attendance report: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching attendance report: $e');
      if (context.mounted) {
        Utils.showSnackBar(context, 'Something went wrong. Please try again.');
      }
    } finally {
      if (forEmployeeDetail) {
        isEmployeeAttendanceLoading = false;
      } else {
        isAttendanceReportLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> _loadDepartmentEmployeesForAttendance({
    required String month,
    required String year,
    String? shopId,
    String? deptId,
  }) async {
    try {
      if (salaryTypeReportModel?.departmentEmployees?.isNotEmpty == true) {
        _mapSalaryEmployeesToAttendance();
        return;
      }
      final dio = Dio();
      final response = await dio.request(
        '${Constants.baseUrl}report_salary_type.php',
        queryParameters: {
          'month': month,
          'year': year,
          if (shopId != null && shopId.isNotEmpty) 'shop_id': shopId,
          if (deptId != null && deptId.isNotEmpty) 'dept_id': deptId,
        },
        options: Options(
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        salaryTypeReportModel = SalaryTypeReportModel.fromJson(response.data);
        _mapSalaryEmployeesToAttendance();
      }
    } catch (e) {
      log('Could not load department employees for attendance: $e');
    }
  }

  void _mapSalaryEmployeesToAttendance() {
    final salaryEmployees = salaryTypeReportModel?.departmentEmployees ?? [];
    if (salaryEmployees.isEmpty) return;
    attendanceReportModel?.departmentEmployees = salaryEmployees
        .map(
          (e) => AttendanceEmployee.fromDepartmentEmployee(
            id: e.id,
            employeeCode: e.employeeCode,
            name: e.name,
            designation: e.designation,
            gender: e.gender,
            mobile: e.mobile,
            jobType: e.jobType,
            joinDate: e.joinDate,
            shopId: e.shopId,
            shopName: e.shopName,
            departmentId: e.departmentId,
            department: e.department,
            status: e.status,
            profilePic: e.profilePic,
          ),
        )
        .toList();
    attendanceReportModel?.totalDepartmentEmployees =
        attendanceReportModel?.departmentEmployees?.length;
  }
}
