class SalaryCostReportModel {
  int? error;
  String? errorMsg;
  SalaryCostFilters? filters;
  SalaryCostData? data;
  List<SalaryCostEmployee>? departmentEmployees;
  int? totalDepartmentEmployees;
  DepartmentTotals? departmentTotals;

  SalaryCostReportModel({
    this.error,
    this.errorMsg,
    this.filters,
    this.data,
    this.departmentEmployees,
    this.totalDepartmentEmployees,
    this.departmentTotals,
  });

  factory SalaryCostReportModel.fromJson(Map<String, dynamic> json) =>
      SalaryCostReportModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        filters: json["filters"] == null
            ? null
            : SalaryCostFilters.fromJson(json["filters"]),
        data: json["data"] == null
            ? null
            : SalaryCostData.fromJson(json["data"]),
        departmentEmployees: json["department_employees"] == null
            ? null
            : List<SalaryCostEmployee>.from(
                json["department_employees"].map(
                  (x) => SalaryCostEmployee.fromJson(x),
                ),
              ),
        totalDepartmentEmployees: json["total_department_employees"],
        departmentTotals: json["department_totals"] == null
            ? null
            : DepartmentTotals.fromJson(json["department_totals"]),
      );
}

class SalaryCostFilters {
  String? month;
  String? year;
  String? shopId;
  String? deptId;
  String? employeeId;

  SalaryCostFilters({
    this.month,
    this.year,
    this.shopId,
    this.deptId,
    this.employeeId,
  });

  factory SalaryCostFilters.fromJson(Map<String, dynamic> json) =>
      SalaryCostFilters(
        month: json["month"]?.toString(),
        year: json["year"]?.toString(),
        shopId: json["shop_id"]?.toString(),
        deptId: json["dept_id"]?.toString(),
        employeeId: json["employee_id"]?.toString(),
      );
}

class SalaryCostData {
  List<SalaryCostTableData>? tableData;
  SalaryCostChartData? chartData;

  SalaryCostData({this.tableData, this.chartData});

  factory SalaryCostData.fromJson(Map<String, dynamic> json) => SalaryCostData(
        tableData: json["table_data"] == null
            ? null
            : List<SalaryCostTableData>.from(
                json["table_data"].map(
                  (x) => SalaryCostTableData.fromJson(x),
                ),
              ),
        chartData: json["chart_data"] == null
            ? null
            : SalaryCostChartData.fromJson(json["chart_data"]),
      );
}

class SalaryCostTableData {
  String? department;
  num? totalSalary;

  SalaryCostTableData({this.department, this.totalSalary});

  factory SalaryCostTableData.fromJson(Map<String, dynamic> json) =>
      SalaryCostTableData(
        department: json["department"]?.toString(),
        totalSalary: json["total_salary"] != null
            ? num.tryParse(json["total_salary"].toString())
            : null,
      );
}

class SalaryCostChartData {
  List<String>? labels;
  List<SalaryCostChartDataset>? datasets;

  SalaryCostChartData({this.labels, this.datasets});

  factory SalaryCostChartData.fromJson(Map<String, dynamic> json) =>
      SalaryCostChartData(
        labels: json["labels"] == null
            ? null
            : List<String>.from(json["labels"].map((x) => x.toString())),
        datasets: json["datasets"] == null
            ? null
            : List<SalaryCostChartDataset>.from(
                json["datasets"].map(
                  (x) => SalaryCostChartDataset.fromJson(x),
                ),
              ),
      );
}

class SalaryCostChartDataset {
  List<num>? data;

  SalaryCostChartDataset({this.data});

  factory SalaryCostChartDataset.fromJson(Map<String, dynamic> json) =>
      SalaryCostChartDataset(
        data: json["data"] == null
            ? null
            : List<num>.from(
                json["data"].map((x) => num.tryParse(x.toString()) ?? 0),
              ),
      );
}

class DepartmentTotals {
  num? totalSalary;

  DepartmentTotals({this.totalSalary});

  factory DepartmentTotals.fromJson(Map<String, dynamic> json) =>
      DepartmentTotals(
        totalSalary: json["total_salary"] != null
            ? num.tryParse(json["total_salary"].toString())
            : null,
      );
}

class SalaryCostEmployee {
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
  num? salary;
  num? paidSalary;
  String? profilePic;

  SalaryCostEmployee({
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
    this.salary,
    this.paidSalary,
    this.profilePic,
  });

  factory SalaryCostEmployee.fromJson(Map<String, dynamic> json) =>
      SalaryCostEmployee(
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
        salary: json["salary"] != null
            ? num.tryParse(json["salary"].toString())
            : 0,
        paidSalary: json["paid_salary"] != null
            ? num.tryParse(json["paid_salary"].toString())
            : 0,
        profilePic: json["profile_pic"]?.toString(),
      );
}
