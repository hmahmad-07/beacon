// GET /inventory_expiry.php
// Server returns batches ordered by expiry_date ascending, a per-batch
// status ("expired" | "expiring_soon") and a summary block with the same
// counts -- the screen uses those instead of recomputing thresholds.
import '../../utils/inventory_dates.dart';

class InventoryExpiryModel {
  int? error;
  String? errorMsg;
  List<InventoryExpiryBatch>? data;
  InventoryExpirySummary? summary;

  InventoryExpiryModel({this.error, this.errorMsg, this.data, this.summary});

  factory InventoryExpiryModel.fromJson(Map<String, dynamic> json) =>
      InventoryExpiryModel(
        error: json["error"],
        errorMsg: json["error_msg"],
        data: json["data"] == null
            ? null
            : List<InventoryExpiryBatch>.from(
                json["data"].map((x) => InventoryExpiryBatch.fromJson(x)),
              ),
        summary: json["summary"] == null
            ? null
            : InventoryExpirySummary.fromJson(json["summary"]),
      );
}

class InventoryExpirySummary {
  int? expired;
  int? expiringSoon;
  int? tracked;

  InventoryExpirySummary({this.expired, this.expiringSoon, this.tracked});

  factory InventoryExpirySummary.fromJson(Map<String, dynamic> json) =>
      InventoryExpirySummary(
        expired: json["expired"],
        expiringSoon: json["expiring_soon"],
        tracked: json["tracked"],
      );
}

class InventoryExpiryBatch {
  String? itemId;
  String? itemName;
  String? storeId;
  String? storeName;
  String? grnNo;
  num? receivedQty;
  num? issuedQty;
  num? remainingQty;
  String? expiryDate;
  int? daysRemaining;
  String? status; // expired | expiring_soon
  String? modifiedDate;

  InventoryExpiryBatch({
    this.itemId,
    this.itemName,
    this.storeId,
    this.storeName,
    this.grnNo,
    this.receivedQty,
    this.issuedQty,
    this.remainingQty,
    this.expiryDate,
    this.daysRemaining,
    this.status,
    this.modifiedDate,
  });

  bool get isExpired => status == "expired" || (daysRemaining ?? 0) < 0;
  DateTime? get expiryDateTime => InventoryDates.parse(expiryDate);
  DateTime? get modifiedDateTime => InventoryDates.parse(modifiedDate);

  factory InventoryExpiryBatch.fromJson(Map<String, dynamic> json) =>
      InventoryExpiryBatch(
        itemId: json["item_id"]?.toString(),
        itemName: json["item_name"],
        storeId: json["store_id"]?.toString(),
        storeName: json["store_name"],
        grnNo: json["grn_no"]?.toString(),
        receivedQty: json["received_qty"],
        issuedQty: json["issued_qty"],
        remainingQty: json["remaining_qty"],
        expiryDate: json["expiry_date"],
        daysRemaining: json["days_remaining"],
        status: json["status"],
        modifiedDate: json["modified_date"],
      );
}
