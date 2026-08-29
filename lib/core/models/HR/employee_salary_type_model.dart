import 'dart:convert';

SalaryTypeReportModel salaryTypeReportModelFromJson(String str) =>
    SalaryTypeReportModel.fromJson(json.decode(str));

class SalaryTypeReportModel {
  int? error;
  String? errorMsg;
  ReportFilters? filters;
  ReportData? data;
  List<DepartmentEmployee>? departmentEmployees;
  int? totalDepartmentEmployees;

  SalaryTypeReportModel({
    this.error,
    this.errorMsg,
    this.filters,
    this.data,
    this.departmentEmployees,
    this.totalDepartmentEmployees,
  });

  factory SalaryTypeReportModel.fromJson(Map<String, dynamic> json) =>
      SalaryTypeReportModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        filters: json["filters"] == null
            ? null
            : ReportFilters.fromJson(json["filters"]),
        data: json["data"] == null ? null : ReportData.fromJson(json["data"]),
        departmentEmployees: json["department_employees"] == null
            ? null
            : List<DepartmentEmployee>.from(
                json["department_employees"].map(
                  (x) => DepartmentEmployee.fromJson(x),
                ),
              ),
        totalDepartmentEmployees: json["total_department_employees"],
      );
}

class ReportFilters {
  String? month;
  String? year;
  String? shopId;
  String? deptId;
  String? employeeId;

  ReportFilters({
    this.month,
    this.year,
    this.shopId,
    this.deptId,
    this.employeeId,
  });

  factory ReportFilters.fromJson(Map<String, dynamic> json) => ReportFilters(
    month: json["month"],
    year: json["year"],
    shopId: json["shop_id"],
    deptId: json["dept_id"],
    employeeId: json["employee_id"],
  );
}

class ReportData {
  List<TableData>? tableData;
  ChartData? chartData;

  ReportData({this.tableData, this.chartData});

  factory ReportData.fromJson(Map<String, dynamic> json) => ReportData(
    tableData: json["table_data"] == null
        ? null
        : List<TableData>.from(
            json["table_data"].map((x) => TableData.fromJson(x)),
          ),
    chartData: json["chart_data"] == null
        ? null
        : ChartData.fromJson(json["chart_data"]),
  );
}

class TableData {
  String? jobType;
  num? totalSalary;

  TableData({this.jobType, this.totalSalary});

  factory TableData.fromJson(Map<String, dynamic> json) => TableData(
        jobType: json["job_type"]?.toString(),
        totalSalary: json["total_salary"] != null
            ? num.tryParse(json["total_salary"].toString())
            : null,
      );
}

class ChartData {
  List<String>? labels;
  List<ChartDataset>? datasets;

  ChartData({this.labels, this.datasets});

  factory ChartData.fromJson(Map<String, dynamic> json) => ChartData(
        labels: json["labels"] == null
            ? null
            : List<String>.from(json["labels"].map((x) => x.toString())),
        datasets: json["datasets"] == null
            ? null
            : List<ChartDataset>.from(
                json["datasets"].map((x) => ChartDataset.fromJson(x)),
              ),
      );
}

class ChartDataset {
  List<num>? data;

  ChartDataset({this.data});

  factory ChartDataset.fromJson(Map<String, dynamic> json) => ChartDataset(
        data: json["data"] == null
            ? null
            : List<num>.from(
                json["data"].map((x) => num.tryParse(x.toString()) ?? 0),
              ),
      );
}

class DepartmentEmployee {
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

  DepartmentEmployee({
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
  });

  factory DepartmentEmployee.fromJson(Map<String, dynamic> json) =>
      DepartmentEmployee(
        id: json["id"],
        employeeCode: json["employee_code"],
        name: json["name"],
        designation: json["designation"],
        gender: json["gender"],
        mobile: json["mobile"],
        jobType: json["job_type"],
        joinDate: json["join_date"],
        shopId: json["shop_id"],
        shopName: json["shop_name"],
        departmentId: json["department_id"],
        department: json["department"],
        status: json["status"],
        profilePic: json["profile_pic"],
      );
}
