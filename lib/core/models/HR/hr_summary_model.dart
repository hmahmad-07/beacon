class HRSummaryModel {
  int? error;
  String? errorMsg;
  HRSummaryFilters? filters;
  HRSummaryData? data;

  HRSummaryModel({this.error, this.errorMsg, this.filters, this.data});

  factory HRSummaryModel.fromJson(Map<String, dynamic> json) => HRSummaryModel(
    error: json["error"],
    errorMsg: json["error_msg"]?.toString(),
    filters: json["filters"] == null
        ? null
        : HRSummaryFilters.fromJson(json["filters"]),
    data: json["data"] == null ? null : HRSummaryData.fromJson(json["data"]),
  );
}

class HRSummaryFilters {
  String? month;
  String? year;
  String? shopId;
  String? deptId;
  String? employeeId;

  HRSummaryFilters({
    this.month,
    this.year,
    this.shopId,
    this.deptId,
    this.employeeId,
  });

  factory HRSummaryFilters.fromJson(Map<String, dynamic> json) =>
      HRSummaryFilters(
        month: json["month"]?.toString(),
        year: json["year"]?.toString(),
        shopId: json["shop_id"]?.toString(),
        deptId: json["dept_id"]?.toString(),
        employeeId: json["employee_id"]?.toString(),
      );
}

class HRSummaryData {
  HRSummaryKpiCards? kpiCards;

  HRSummaryData({this.kpiCards});

  factory HRSummaryData.fromJson(Map<String, dynamic> json) => HRSummaryData(
    kpiCards: json["kpi_cards"] == null
        ? null
        : HRSummaryKpiCards.fromJson(json["kpi_cards"]),
  );
}

class HRSummaryKpiCards {
  int? totalHeadcount;
  num? totalSalaryPaid;
  num? totalGrossSalary;
  int? newJoiners;
  int? totalLeavers;

  HRSummaryKpiCards({
    this.totalHeadcount,
    this.totalSalaryPaid,
    this.totalGrossSalary,
    this.newJoiners,
    this.totalLeavers,
  });

  factory HRSummaryKpiCards.fromJson(Map<String, dynamic> json) =>
      HRSummaryKpiCards(
        totalHeadcount: json["total_headcount"] != null
            ? int.tryParse(json["total_headcount"].toString())
            : 0,
        totalSalaryPaid: json["total_salary_paid"] != null
            ? num.tryParse(json["total_salary_paid"].toString())
            : 0,
        totalGrossSalary: json["total_gross_salary"] != null
            ? num.tryParse(json["total_gross_salary"].toString())
            : 0,
        newJoiners: json["new_joiners"] != null
            ? int.tryParse(json["new_joiners"].toString())
            : 0,
        totalLeavers: json["total_leavers"] != null
            ? int.tryParse(json["total_leavers"].toString())
            : 0,
      );
}
