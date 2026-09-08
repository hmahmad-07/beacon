// GET /inventory_stores.php
class InventoryStoresModel {
  int? error;
  String? errorMsg;
  List<InventoryStore>? data;

  InventoryStoresModel({this.error, this.errorMsg, this.data});

  factory InventoryStoresModel.fromJson(Map<String, dynamic> json) =>
      InventoryStoresModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        data: json["data"] == null
            ? null
            : List<InventoryStore>.from(
                json["data"].map((x) => InventoryStore.fromJson(x)),
              ),
      );
}

class InventoryStore {
  String? id;
  String? name;
  String? code;
  String? status;
  num? totalIn;
  num? totalOut;
  num? balance;

  InventoryStore({
    this.id,
    this.name,
    this.code,
    this.status,
    this.totalIn,
    this.totalOut,
    this.balance,
  });

  bool get isActive => (status ?? "").toUpperCase() == "A";

  factory InventoryStore.fromJson(Map<String, dynamic> json) =>
      InventoryStore(
        id: json["id"]?.toString(),
        name: json["name"],
        code: json["code"],
        status: json["status"],
        totalIn: json["total_in"],
        totalOut: json["total_out"],
        balance: json["balance"],
      );
}
