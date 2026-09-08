// GET /inventory_items.php (list mode: no item_id; detail mode: item_id set)

class InventoryItemsListModel {
  int? error;
  String? errorMsg;
  List<InventoryItemSummary>? data;
  InventoryItemsMeta? meta;

  InventoryItemsListModel({this.error, this.errorMsg, this.data, this.meta});

  factory InventoryItemsListModel.fromJson(Map<String, dynamic> json) =>
      InventoryItemsListModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        data: json["data"] == null
            ? null
            : List<InventoryItemSummary>.from(
                json["data"].map((x) => InventoryItemSummary.fromJson(x)),
              ),
        meta: json["meta"] == null
            ? null
            : InventoryItemsMeta.fromJson(json["meta"]),
      );
}

class InventoryItemsMeta {
  int? currentPage;
  int? perPage;
  int? total;
  int? lastPage;

  InventoryItemsMeta({
    this.currentPage,
    this.perPage,
    this.total,
    this.lastPage,
  });

  factory InventoryItemsMeta.fromJson(Map<String, dynamic> json) =>
      InventoryItemsMeta(
        currentPage: json["current_page"],
        perPage: json["per_page"],
        total: json["total"],
        lastPage: json["last_page"],
      );
}

class InventoryItemSummary {
  String? id;
  String? name;
  String? barcode;
  String? type;
  String? itemClass;
  String? uom;
  num? costPrice;
  num? stock;
  String? status; // in_stock | out_of_stock

  InventoryItemSummary({
    this.id,
    this.name,
    this.barcode,
    this.type,
    this.itemClass,
    this.uom,
    this.costPrice,
    this.stock,
    this.status,
  });

  String get displayName => (name ?? "").trim();
  bool get isOutOfStock => status == "out_of_stock";

  factory InventoryItemSummary.fromJson(Map<String, dynamic> json) =>
      InventoryItemSummary(
        id: json["id"]?.toString(),
        name: json["name"],
        barcode: json["barcode"],
        type: json["type"],
        itemClass: json["class"],
        uom: json["uom"],
        costPrice: json["cost_price"],
        stock: json["stock"],
        status: json["status"],
      );
}

// ------------------------------- Detail mode -------------------------------

class InventoryItemDetailModel {
  int? error;
  String? errorMsg;
  InventoryItemDetail? data;

  InventoryItemDetailModel({this.error, this.errorMsg, this.data});

  factory InventoryItemDetailModel.fromJson(Map<String, dynamic> json) =>
      InventoryItemDetailModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        data: json["data"] == null
            ? null
            : InventoryItemDetail.fromJson(json["data"]),
      );
}

class InventoryItemDetail {
  String? id;
  String? name;
  String? barcode;
  String? type;
  String? itemClass;
  num? costPrice;
  String? status;
  InventoryItemStock? stock;
  List<InventoryItemMovement>? movements;

  InventoryItemDetail({
    this.id,
    this.name,
    this.barcode,
    this.type,
    this.itemClass,
    this.costPrice,
    this.status,
    this.stock,
    this.movements,
  });

  String get displayName => (name ?? "").trim();

  factory InventoryItemDetail.fromJson(Map<String, dynamic> json) =>
      InventoryItemDetail(
        id: json["id"]?.toString(),
        name: json["name"],
        barcode: json["barcode"],
        type: json["type"],
        itemClass: json["class"],
        costPrice: json["cost_price"],
        status: json["status"],
        stock: json["stock"] == null
            ? null
            : InventoryItemStock.fromJson(json["stock"]),
        movements: json["movements"] == null
            ? null
            : List<InventoryItemMovement>.from(
                json["movements"].map(
                  (x) => InventoryItemMovement.fromJson(x),
                ),
              ),
      );
}

class InventoryItemStock {
  num? total;
  List<InventoryStoreBalance>? byStore;

  InventoryItemStock({this.total, this.byStore});

  factory InventoryItemStock.fromJson(Map<String, dynamic> json) =>
      InventoryItemStock(
        total: json["total"],
        byStore: json["by_store"] == null
            ? null
            : List<InventoryStoreBalance>.from(
                json["by_store"].map((x) => InventoryStoreBalance.fromJson(x)),
              ),
      );
}

class InventoryStoreBalance {
  String? storeId;
  String? storeName;
  num? balance;

  InventoryStoreBalance({this.storeId, this.storeName, this.balance});

  factory InventoryStoreBalance.fromJson(Map<String, dynamic> json) =>
      InventoryStoreBalance(
        storeId: json["store_id"]?.toString(),
        storeName: json["store_name"],
        balance: json["balance"],
      );
}

class InventoryItemMovement {
  String? date;
  String? documentType; // GRN | ISSUE | RETURN | TRANSFER_IN | TRANSFER_OUT
  String? documentNo;
  String? storeId;
  String? storeName;
  num? inQty;
  num? outQty;
  num? runningBalance;

  InventoryItemMovement({
    this.date,
    this.documentType,
    this.documentNo,
    this.storeId,
    this.storeName,
    this.inQty,
    this.outQty,
    this.runningBalance,
  });

  factory InventoryItemMovement.fromJson(Map<String, dynamic> json) =>
      InventoryItemMovement(
        date: json["date"],
        documentType: json["document_type"],
        documentNo: json["document_no"],
        storeId: json["store_id"]?.toString(),
        storeName: json["store_name"],
        inQty: json["in_qty"],
        outQty: json["out_qty"],
        runningBalance: json["running_balance"],
      );
}
