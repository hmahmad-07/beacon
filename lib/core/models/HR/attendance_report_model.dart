import 'package:flutter/material.dart';

class AttendanceReportModel {
  int? error;
  String? errorMsg;
  AttendanceFilters? filters;
  AttendanceData? data;
  AttendanceEmployee? employee;
  List<AttendanceEmployee>? departmentEmployees;
  int? totalDepartmentEmployees;
  AttendanceChartData? employeeChartData;
  AttendanceChartData? dailyChartData;

  AttendanceReportModel({
    this.error,
    this.errorMsg,
    this.filters,
    this.data,
    this.employee,
    this.departmentEmployees,
    this.totalDepartmentEmployees,
    this.employeeChartData,
    this.dailyChartData,
  });

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) {
    return AttendanceReportModel(
      error: json["error"],
      errorMsg: json["error_msg"]?.toString(),
      filters: json["filters"] == null
          ? null
          : AttendanceFilters.fromJson(json["filters"]),
      data: json["data"] == null ? null : AttendanceData.fromJson(json["data"]),
      employee: json["employee"] == null
          ? null
          : AttendanceEmployee.fromJson(json["employee"]),
      departmentEmployees: json["department_employees"] == null
          ? null
          : List<AttendanceEmployee>.from(
              json["department_employees"].map(
                (x) => AttendanceEmployee.fromJson(x),
              ),
            ),
      totalDepartmentEmployees: json["total_department_employees"],
      employeeChartData: json["employee_chart_data"] == null
          ? null
          : AttendanceChartData.fromJson(json["employee_chart_data"]),
      dailyChartData: json["daily_chart_data"] == null
          ? null
          : AttendanceChartData.fromJson(json["daily_chart_data"]),
    );
  }
}

class AttendanceFilters {
  String? month;
  String? year;
  String? shopId;
  String? deptId;
  String? employeeId;
  String? startDate;
  String? endDate;

  AttendanceFilters({
    this.month,
    this.year,
    this.shopId,
    this.deptId,
    this.employeeId,
    this.startDate,
    this.endDate,
  });

  factory AttendanceFilters.fromJson(Map<String, dynamic> json) =>
      AttendanceFilters(
        month: json["month"]?.toString(),
        year: json["year"]?.toString(),
        shopId: json["shop_id"]?.toString(),
        deptId: json["dept_id"]?.toString(),
        employeeId: json["employee_id"]?.toString(),
        startDate: json["start_date"]?.toString(),
        endDate: json["end_date"]?.toString(),
      );
}

class AttendanceData {
  List<AttendanceStatusCount>? tableData;
  AttendanceChartData? chartData;

  AttendanceData({this.tableData, this.chartData});

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
    tableData: json["table_data"] == null
        ? null
        : List<AttendanceStatusCount>.from(
            json["table_data"].map((x) => AttendanceStatusCount.fromJson(x)),
          ),
    chartData: json["chart_data"] == null
        ? null
        : AttendanceChartData.fromJson(json["chart_data"]),
  );
}

class AttendanceStatusCount {
  String? status;
  int? totalDays;

  AttendanceStatusCount({this.status, this.totalDays});

  factory AttendanceStatusCount.fromJson(Map<String, dynamic> json) =>
      AttendanceStatusCount(
        status: json["status"]?.toString(),
        totalDays: json["total_days"] != null
            ? int.tryParse(json["total_days"].toString()) ?? 0
            : 0,
      );
}

class AttendanceChartData {
  List<String>? labels;
  List<AttendanceChartDataset>? datasets;

  AttendanceChartData({this.labels, this.datasets});

  factory AttendanceChartData.fromJson(Map<String, dynamic> json) =>
      AttendanceChartData(
        labels: json["labels"] == null
            ? null
            : List<String>.from(json["labels"].map((x) => x.toString())),
        datasets: json["datasets"] == null
            ? null
            : List<AttendanceChartDataset>.from(
                json["datasets"].map((x) => AttendanceChartDataset.fromJson(x)),
              ),
      );
}

class AttendanceChartDataset {
  String? label;
  String? employeeCode;
  List<num>? data;

  AttendanceChartDataset({this.label, this.employeeCode, this.data});

  factory AttendanceChartDataset.fromJson(Map<String, dynamic> json) =>
      AttendanceChartDataset(
        label: json["label"]?.toString(),
        employeeCode: json["employee_code"]?.toString(),
        data: json["data"] == null
            ? null
            : List<num>.from(
                json["data"].map((x) => num.tryParse(x.toString()) ?? 0),
              ),
      );
}

class AttendanceEmployee {
  int? id;
  String? employeeCode;
  String? name;
  String? designation;
  String? gender;
  String? mobile;
  String? jobType;
  String? joinDate;
  String? shopId;
  String? shopName;
  int? departmentId;
  String? department;
  String? status;
  String? profilePic;
  List<AttendanceStatusCount>? attendance;
  int? totalDays;
  List<DailyAttendance>? dailyAttendance;

  AttendanceEmployee({
    this.id,
    this.employeeCode,
    this.name,
    this.designation,
    this.gender,
    this.mobile,
    this.jobType,
    this.joinDate,
    this.shopId,
    this.shopName,
    this.departmentId,
    this.department,
    this.status,
    this.profilePic,
    this.attendance,
    this.totalDays,
    this.dailyAttendance,
  });

  factory AttendanceEmployee.fromJson(
    Map<String, dynamic> json,
  ) => AttendanceEmployee(
    id: json["id"],
    employeeCode: json["employee_code"]?.toString(),
    name: json["name"]?.toString(),
    designation: json["designation"]?.toString(),
    gender: json["gender"]?.toString(),
    mobile: json["mobile"]?.toString(),
    jobType: json["job_type"]?.toString(),
    joinDate: json["join_date"]?.toString(),
    shopId: json["shop_id"]?.toString(),
    shopName: json["shop_name"]?.toString(),
    departmentId: json["department_id"],
    department: json["department"]?.toString(),
    status: json["status"]?.toString(),
    profilePic: json["profile_pic"]?.toString(),
    attendance: json["attendance"] == null
        ? null
        : List<AttendanceStatusCount>.from(
            json["attendance"].map((x) => AttendanceStatusCount.fromJson(x)),
          ),
    totalDays: json["total_days"] != null
        ? int.tryParse(json["total_days"].toString())
        : null,
    dailyAttendance: json["daily_attendance"] == null
        ? null
        : List<DailyAttendance>.from(
            json["daily_attendance"].map((x) => DailyAttendance.fromJson(x)),
          ),
  );

  factory AttendanceEmployee.fromDepartmentEmployee({
    required int? id,
    required String? employeeCode,
    required String? name,
    required String? designation,
    required String? gender,
    required String? mobile,
    required String? jobType,
    required String? joinDate,
    required String? shopId,
    required String? shopName,
    required int? departmentId,
    required String? department,
    required String? status,
    required String? profilePic,
  }) => AttendanceEmployee(
    id: id,
    employeeCode: employeeCode,
    name: name,
    designation: designation,
    gender: gender,
    mobile: mobile,
    jobType: jobType,
    joinDate: joinDate,
    shopId: shopId,
    shopName: shopName,
    departmentId: departmentId,
    department: department,
    status: status,
    profilePic: profilePic,
  );
}

class DailyAttendance {
  String? date;
  String? dateIso;
  String? day;
  String? statusCode;
  String? status;
  String? timeIn;
  String? timeOut;

  DailyAttendance({
    this.date,
    this.dateIso,
    this.day,
    this.statusCode,
    this.status,
    this.timeIn,
    this.timeOut,
  });

  factory DailyAttendance.fromJson(Map<String, dynamic> json) =>
      DailyAttendance(
        date: json["date"]?.toString(),
        dateIso: json["date_iso"]?.toString(),
        day: json["day"]?.toString(),
        statusCode: json["status_code"]?.toString(),
        status: json["status"]?.toString(),
        timeIn: json["time_in"]?.toString(),
        timeOut: json["time_out"]?.toString(),
      );
}

class AttendanceStatusStyle {
  static Color colorOf(String? status) {
    final key = (status ?? '').trim().toUpperCase();
    if (key == 'P' || key == 'PRESENT') return const Color(0xFF00A86B);
    if (key == 'PL') return const Color(0xFFFF9F43);
    if (key == 'SP') return const Color(0xFF7367F0);
    if (key == 'A' || key == 'ABSENT') return const Color(0xFFE83E8C);
    if (key == 'H' || key == 'HOLIDAY') return const Color(0xFF8E8E93);
    if (key == 'UNKNOWN') return const Color(0xFF8E8E93);
    if (key.isEmpty || key == 'NO RECORD') return const Color(0xFFB0B0B0);
    return const Color(0xFF007AFF);
  }

  static String labelOf(String? status) {
    final key = (status ?? '').trim();
    if (key.isEmpty) return 'No Record';
    final upper = key.toUpperCase();
    if (upper == 'P') return 'Present';
    if (upper == 'A') return 'Absent';
    if (upper == 'H' || upper == 'HOLIDAY') return 'Holiday';
    return key;
  }
}
