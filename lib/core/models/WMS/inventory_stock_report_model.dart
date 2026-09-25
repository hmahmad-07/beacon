// GET /inventory_stock.php
import '../../utils/inventory_dates.dart';

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
  String? uom;
  String? type;
  String? itemClass;
  num? costPrice;
  num? totalIn;
  num? totalOut;
  num? balance;
  List<StockStoreBreakdown>? byStore;
  String? modifiedDate;

  StockReportItem({
    this.id,
    this.name,
    this.uom,
    this.type,
    this.itemClass,
    this.costPrice,
    this.totalIn,
    this.totalOut,
    this.balance,
    this.byStore,
    this.modifiedDate,
  });

  String get displayName => (name ?? "").trim();
  DateTime? get modifiedDateTime => InventoryDates.parse(modifiedDate);

  factory StockReportItem.fromJson(Map<String, dynamic> json) =>
      StockReportItem(
        id: json["id"]?.toString(),
        name: json["name"],
        uom: json["uom"],
        type: json["type"],
        itemClass: json["class"],
        costPrice: json["cost_price"],
        totalIn: json["total_in"],
        totalOut: json["total_out"],
        balance: json["balance"],
        byStore: json["by_store"] == null
            ? null
            : List<StockStoreBreakdown>.from(
                json["by_store"].map((x) => StockStoreBreakdown.fromJson(x)),
              ),
        modifiedDate: json["modified_date"],
      );
}

// Distinct from InventoryStoreBalance (used by the dashboard/item-detail
// endpoints, which only carry a balance) -- inventory_stock.php's by_store
// rows also carry total_in/total_out per store.
class StockStoreBreakdown {
  String? storeId;
  String? storeName;
  num? totalIn;
  num? totalOut;
  num? balance;

  StockStoreBreakdown({
    this.storeId,
    this.storeName,
    this.totalIn,
    this.totalOut,
    this.balance,
  });

  factory StockStoreBreakdown.fromJson(Map<String, dynamic> json) =>
      StockStoreBreakdown(
        storeId: json["store_id"]?.toString(),
        storeName: json["store_name"],
        totalIn: json["total_in"],
        totalOut: json["total_out"],
        balance: json["balance"],
      );
}
