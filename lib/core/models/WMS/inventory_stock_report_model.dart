import 'inventory_item_model.dart' show InventoryStoreBalance;

// GET /inventory_stock.php
class InventoryStockReportModel {
  int? error;
  String? errorMsg;
  List<StockReportItem>? data;
  InventoryStockMeta? meta;
  InventoryStockSummary? summary;

  InventoryStockReportModel({
    this.error,
    this.errorMsg,
    this.data,
    this.meta,
    this.summary,
  });

  factory InventoryStockReportModel.fromJson(Map<String, dynamic> json) =>
      InventoryStockReportModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        data: json["data"] == null
            ? null
            : List<StockReportItem>.from(
                json["data"].map((x) => StockReportItem.fromJson(x)),
              ),
        meta: json["meta"] == null
            ? null
            : InventoryStockMeta.fromJson(json["meta"]),
        summary: json["summary"] == null
            ? null
            : InventoryStockSummary.fromJson(json["summary"]),
      );
}

class InventoryStockMeta {
  int? currentPage;
  int? perPage;
  int? total;
  int? lastPage;

  InventoryStockMeta({
    this.currentPage,
    this.perPage,
    this.total,
    this.lastPage,
  });

  factory InventoryStockMeta.fromJson(Map<String, dynamic> json) =>
      InventoryStockMeta(
        currentPage: json["current_page"],
        perPage: json["per_page"],
        total: json["total"],
        lastPage: json["last_page"],
      );
}

class InventoryStockSummary {
  int? totalItems;
  int? zeroOrBelowStock;
  num? totalValue;

  InventoryStockSummary({
    this.totalItems,
    this.zeroOrBelowStock,
    this.totalValue,
  });

  factory InventoryStockSummary.fromJson(Map<String, dynamic> json) =>
      InventoryStockSummary(
        totalItems: json["total_items"],
        zeroOrBelowStock: json["zero_or_below_stock"],
        totalValue: json["total_value"],
      );
}

class StockReportItem {
  String? id;
  String? name;
  String? type;
  String? itemClass;
  num? costPrice;
  num? totalIn;
  num? totalOut;
  num? balance;
  List<InventoryStoreBalance>? byStore;

  StockReportItem({
    this.id,
    this.name,
    this.type,
    this.itemClass,
    this.costPrice,
    this.totalIn,
    this.totalOut,
    this.balance,
    this.byStore,
  });

  String get displayName => (name ?? "").trim();

  factory StockReportItem.fromJson(Map<String, dynamic> json) =>
      StockReportItem(
        id: json["id"]?.toString(),
        name: json["name"],
        type: json["type"],
        itemClass: json["class"],
        costPrice: json["cost_price"],
        totalIn: json["total_in"],
        totalOut: json["total_out"],
        balance: json["balance"],
        byStore: json["by_store"] == null
            ? null
            : List<InventoryStoreBalance>.from(
                json["by_store"].map((x) => InventoryStoreBalance.fromJson(x)),
              ),
      );
}
