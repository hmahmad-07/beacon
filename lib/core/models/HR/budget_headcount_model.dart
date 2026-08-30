class BudgetHeadcountModel {
  int? error;
  String? errorMsg;
  BudgetHeadcountFilters? filters;
  BudgetHeadcountData? data;

  BudgetHeadcountModel({this.error, this.errorMsg, this.filters, this.data});

  factory BudgetHeadcountModel.fromJson(Map<String, dynamic> json) =>
      BudgetHeadcountModel(
        error: json["error"],
        errorMsg: json["error_msg"]?.toString(),
        filters: json["filters"] == null
            ? null
            : BudgetHeadcountFilters.fromJson(json["filters"]),
        data: json["data"] == null
            ? null
            : BudgetHeadcountData.fromJson(json["data"]),
      );
}

class BudgetHeadcountFilters {
  String? shopId;
  String? deptId;
  String? employeeId;
  String? note;

  BudgetHeadcountFilters({
    this.shopId,
    this.deptId,
    this.employeeId,
    this.note,
  });

  factory BudgetHeadcountFilters.fromJson(Map<String, dynamic> json) =>
      BudgetHeadcountFilters(
        shopId: json["shop_id"]?.toString(),
        deptId: json["dept_id"]?.toString(),
        employeeId: json["employee_id"]?.toString(),
        note: json["note"]?.toString(),
      );
}

class BudgetHeadcountData {
  List<BudgetHeadcountTableRow>? tableData;
  BudgetHeadcountChartData? chartData;

  BudgetHeadcountData({this.tableData, this.chartData});

  factory BudgetHeadcountData.fromJson(Map<String, dynamic> json) =>
      BudgetHeadcountData(
        tableData: json["table_data"] == null
            ? null
            : List<BudgetHeadcountTableRow>.from(
                json["table_data"].map(
                  (x) => BudgetHeadcountTableRow.fromJson(x),
                ),
              ),
        chartData: json["chart_data"] == null
            ? null
            : BudgetHeadcountChartData.fromJson(json["chart_data"]),
      );
}

class BudgetHeadcountTableRow {
  String? department;
  int? actualHeadcount;
  int? budgetHeadcount;

  BudgetHeadcountTableRow({
    this.department,
    this.actualHeadcount,
    this.budgetHeadcount,
  });

  factory BudgetHeadcountTableRow.fromJson(Map<String, dynamic> json) =>
      BudgetHeadcountTableRow(
        department: json["department"]?.toString(),
        actualHeadcount: json["actual_headcount"] != null
            ? int.tryParse(json["actual_headcount"].toString())
            : 0,
        budgetHeadcount: json["budget_headcount"] != null
            ? int.tryParse(json["budget_headcount"].toString())
            : 0,
      );
}

class BudgetHeadcountChartData {
  List<String>? labels;
  List<BudgetHeadcountChartDataset>? datasets;

  BudgetHeadcountChartData({this.labels, this.datasets});

  factory BudgetHeadcountChartData.fromJson(Map<String, dynamic> json) =>
      BudgetHeadcountChartData(
        labels: json["labels"] == null
            ? null
            : List<String>.from(json["labels"].map((x) => x.toString())),
        datasets: json["datasets"] == null
            ? null
            : List<BudgetHeadcountChartDataset>.from(
                json["datasets"].map(
                  (x) => BudgetHeadcountChartDataset.fromJson(x),
                ),
              ),
      );
}

class BudgetHeadcountChartDataset {
  String? label;
  List<num>? data;

  BudgetHeadcountChartDataset({this.label, this.data});

  factory BudgetHeadcountChartDataset.fromJson(Map<String, dynamic> json) =>
      BudgetHeadcountChartDataset(
        label: json["label"]?.toString(),
        data: json["data"] == null
            ? null
            : List<num>.from(
                json["data"].map((x) => num.tryParse(x.toString()) ?? 0),
              ),
      );
}
