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
  String? storeId; // echoes the store_id filter that produced this response
  InventoryKpis? kpis;
  List<CategoryValue>? valueByCategory;
  List<MonthlyMovement>? movementLast6Months;
  List<InventoryStoreBalance>? balanceByStore;
  List<NegativeStockItem>? negativeStock;
  List<RecentMovement>? recentMovements;

  InventoryDashboardData({
    this.storeId,
    this.kpis,
    this.valueByCategory,
    this.movementLast6Months,
    this.balanceByStore,
    this.negativeStock,
    this.recentMovements,
  });

  factory InventoryDashboardData.fromJson(Map<String, dynamic> json) =>
      InventoryDashboardData(
        storeId: json["store_id"]?.toString(),
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
        recentMovements: json["recent_movements"] == null
            ? null
            : List<RecentMovement>.from(
                json["recent_movements"].map((x) => RecentMovement.fromJson(x)),
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

class RecentMovement {
  String? type; // stock_in | stock_out
  String? itemId;
  String? itemName;
  num? qty;
  String?
  documentType; // SIN | GOODS_RECEIPT | STORE_TRANSFER_IN | STORE_TRANSFER_OUT | ...
  String? documentNo;
  String? storeId;
  String? storeName;
  String? date;

  RecentMovement({
    this.type,
    this.itemId,
    this.itemName,
    this.qty,
    this.documentType,
    this.documentNo,
    this.storeId,
    this.storeName,
    this.date,
  });

  bool get isIn => type == "stock_in";

  factory RecentMovement.fromJson(Map<String, dynamic> json) => RecentMovement(
    type: json["type"],
    itemId: json["item_id"]?.toString(),
    itemName: json["item_name"],
    qty: json["qty"],
    documentType: json["document_type"],
    documentNo: json["document_no"],
    storeId: json["store_id"]?.toString(),
    storeName: json["store_name"],
    date: json["date"],
  );
}
