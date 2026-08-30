class DepartmentHeadcountModel {
  int? error;
  String? errorMsg;
  HeadcountFilters? filters;
  HeadcountData? data;

  DepartmentHeadcountModel({
    this.error,
    this.errorMsg,
    this.filters,
    this.data,
  });

  factory DepartmentHeadcountModel.fromJson(Map<String, dynamic> json) =>
      DepartmentHeadcountModel(
        error: json["error"],
        errorMsg: json["error_msg"]?.toString(),
        filters: json["filters"] == null
            ? null
            : HeadcountFilters.fromJson(json["filters"]),
        data: json["data"] == null
            ? null
            : HeadcountData.fromJson(json["data"]),
      );
}

class HeadcountFilters {
  String? status;
  String? shopId;
  String? deptId;
  String? employeeId;

  HeadcountFilters({this.status, this.shopId, this.deptId, this.employeeId});

  factory HeadcountFilters.fromJson(Map<String, dynamic> json) =>
      HeadcountFilters(
        status: json["status"]?.toString(),
        shopId: json["shop_id"]?.toString(),
        deptId: json["dept_id"]?.toString(),
        employeeId: json["employee_id"]?.toString(),
      );
}

class HeadcountData {
  List<HeadcountTableRow>? tableData;
  HeadcountChartData? chartData;

  HeadcountData({this.tableData, this.chartData});

  factory HeadcountData.fromJson(Map<String, dynamic> json) => HeadcountData(
    tableData: json["table_data"] == null
        ? null
        : List<HeadcountTableRow>.from(
            json["table_data"].map((x) => HeadcountTableRow.fromJson(x)),
          ),
    chartData: json["chart_data"] == null
        ? null
        : HeadcountChartData.fromJson(json["chart_data"]),
  );
}

class HeadcountTableRow {
  String? department;
  int? headcount;

  HeadcountTableRow({this.department, this.headcount});

  factory HeadcountTableRow.fromJson(Map<String, dynamic> json) =>
      HeadcountTableRow(
        department: json["department"]?.toString(),
        headcount: json["headcount"] != null
            ? int.tryParse(json["headcount"].toString())
            : 0,
      );
}

class HeadcountChartData {
  List<String>? labels;
  List<HeadcountChartDataset>? datasets;

  HeadcountChartData({this.labels, this.datasets});

  factory HeadcountChartData.fromJson(Map<String, dynamic> json) =>
      HeadcountChartData(
        labels: json["labels"] == null
            ? null
            : List<String>.from(json["labels"].map((x) => x.toString())),
        datasets: json["datasets"] == null
            ? null
            : List<HeadcountChartDataset>.from(
                json["datasets"].map((x) => HeadcountChartDataset.fromJson(x)),
              ),
      );
}

class HeadcountChartDataset {
  String? label;
  List<num>? data;

  HeadcountChartDataset({this.label, this.data});

  factory HeadcountChartDataset.fromJson(Map<String, dynamic> json) =>
      HeadcountChartDataset(
        label: json["label"]?.toString(),
        data: json["data"] == null
            ? null
            : List<num>.from(
                json["data"].map((x) => num.tryParse(x.toString()) ?? 0),
              ),
      );
}
