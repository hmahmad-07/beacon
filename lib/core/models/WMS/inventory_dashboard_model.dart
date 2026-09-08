import 'inventory_item_model.dart' show InventoryStoreBalance;

// GET /inventory_dashboard.php
class InventoryDashboardModel {
  int? error;
  String? errorMsg;
  InventoryDashboardData? data;

  InventoryDashboardModel({this.error, this.errorMsg, this.data});

  factory InventoryDashboardModel.fromJson(Map<String, dynamic> json) =>
      InventoryDashboardModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        data: json["data"] == null
            ? null
            : InventoryDashboardData.fromJson(json["data"]),
      );
}

class InventoryDashboardData {
  InventoryKpis? kpis;
  List<CategoryValue>? valueByCategory;
  List<MonthlyMovement>? movementLast6Months;
  List<InventoryStoreBalance>? balanceByStore;
  List<NegativeStockItem>? negativeStock;

  InventoryDashboardData({
    this.kpis,
    this.valueByCategory,
    this.movementLast6Months,
    this.balanceByStore,
    this.negativeStock,
  });

  factory InventoryDashboardData.fromJson(Map<String, dynamic> json) =>
      InventoryDashboardData(
        kpis: json["kpis"] == null ? null : InventoryKpis.fromJson(json["kpis"]),
        valueByCategory: json["value_by_category"] == null
            ? null
            : List<CategoryValue>.from(
                json["value_by_category"].map((x) => CategoryValue.fromJson(x)),
              ),
        movementLast6Months: json["movement_last_6_months"] == null
            ? null
            : List<MonthlyMovement>.from(
                json["movement_last_6_months"].map(
                  (x) => MonthlyMovement.fromJson(x),
                ),
              ),
        balanceByStore: json["balance_by_store"] == null
            ? null
            : List<InventoryStoreBalance>.from(
                json["balance_by_store"].map(
                  (x) => InventoryStoreBalance.fromJson(x),
                ),
              ),
        negativeStock: json["negative_stock"] == null
            ? null
            : List<NegativeStockItem>.from(
                json["negative_stock"].map((x) => NegativeStockItem.fromJson(x)),
              ),
      );
}

class InventoryKpis {
  int? totalItems;
  num? stockValue;
  int? negativeStockItems;

  InventoryKpis({this.totalItems, this.stockValue, this.negativeStockItems});

  factory InventoryKpis.fromJson(Map<String, dynamic> json) => InventoryKpis(
    totalItems: json["total_items"],
    stockValue: json["stock_value"],
    negativeStockItems: json["negative_stock_items"],
  );
}

class CategoryValue {
  String? category;
  num? value;

  CategoryValue({this.category, this.value});

  factory CategoryValue.fromJson(Map<String, dynamic> json) =>
      CategoryValue(category: json["category"], value: json["value"]);
}

class MonthlyMovement {
  String? month;
  num? received;
  num? issued;

  MonthlyMovement({this.month, this.received, this.issued});

  factory MonthlyMovement.fromJson(Map<String, dynamic> json) =>
      MonthlyMovement(
        month: json["month"],
        received: json["received"],
        issued: json["issued"],
      );
}

class NegativeStockItem {
  String? itemId;
  String? name;
  num? onHand;

  NegativeStockItem({this.itemId, this.name, this.onHand});

  factory NegativeStockItem.fromJson(Map<String, dynamic> json) =>
      NegativeStockItem(
        itemId: json["item_id"]?.toString(),
        name: json["name"],
        onHand: json["on_hand"],
      );
}
