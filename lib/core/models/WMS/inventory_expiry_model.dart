// GET /inventory_expiry.php
// Always empty in the current database (no GRN line has EXPIRE_DATE set
// yet), so fields below are inferred from the API doc's sample row rather
// than a live response — kept nullable throughout for that reason.
class InventoryExpiryModel {
  int? error;
  String? errorMsg;
  List<InventoryExpiryBatch>? data;

  InventoryExpiryModel({this.error, this.errorMsg, this.data});

  factory InventoryExpiryModel.fromJson(Map<String, dynamic> json) =>
      InventoryExpiryModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        data: json["data"] == null
            ? null
            : List<InventoryExpiryBatch>.from(
                json["data"].map((x) => InventoryExpiryBatch.fromJson(x)),
              ),
      );
}

class InventoryExpiryBatch {
  String? itemId;
  String? itemName;
  String? storeName;
  String? grnNo;
  num? receivedQty;
  num? issuedQty;
  num? remainingQty;
  String? expiryDate;
  int? daysRemaining;

  InventoryExpiryBatch({
    this.itemId,
    this.itemName,
    this.storeName,
    this.grnNo,
    this.receivedQty,
    this.issuedQty,
    this.remainingQty,
    this.expiryDate,
    this.daysRemaining,
  });

  factory InventoryExpiryBatch.fromJson(Map<String, dynamic> json) =>
      InventoryExpiryBatch(
        itemId: json["item_id"]?.toString(),
        itemName: json["item_name"],
        storeName: json["store_name"],
        grnNo: json["grn_no"],
        receivedQty: json["received_qty"],
        issuedQty: json["issued_qty"],
        remainingQty: json["remaining_qty"],
        expiryDate: json["expiry_date"],
        daysRemaining: json["days_remaining"],
      );
}
