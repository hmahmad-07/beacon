import 'dart:convert';

ExternalClientReportModel externalClientReportModelFromJson(String str) =>
    ExternalClientReportModel.fromJson(json.decode(str));

String externalClientReportModelToJson(ExternalClientReportModel data) =>
    json.encode(data.toJson());

class ExternalClientReportModel {
  final int error;
  final String errorMsg;
  final String? entityNo;
  final String? date;
  final int totalOrders;
  final List<ExternalOrder> orders;

  const ExternalClientReportModel({
    required this.error,
    required this.errorMsg,
    this.entityNo,
    this.date,
    required this.totalOrders,
    required this.orders,
  });

  factory ExternalClientReportModel.fromJson(Map<String, dynamic> json) =>
      ExternalClientReportModel(
        error: json["error"] ?? 0,
        errorMsg: json["error_msg"] ?? "",
        entityNo: json["entity_no"]?.toString(),
        date: json["date"]?.toString(),
        totalOrders: int.tryParse(json["total_orders"]?.toString() ?? "0") ?? 0,
        orders: json["orders"] != null
            ? (json["orders"] as List<dynamic>)
                .map((x) => ExternalOrder.fromJson(x as Map<String, dynamic>))
                .toList()
            : [],
      );

  Map<String, dynamic> toJson() => {
        "error": error,
        "error_msg": errorMsg,
        "entity_no": entityNo,
        "date": date,
        "total_orders": totalOrders,
        "orders": orders.map((x) => x.toJson()).toList(),
      };
}

class ExternalOrder {
  final String id;
  final String? entityNo;
  final String? entityName;
  final bool isProductive;
  final String? remarks;
  final String orderDate;
  final String createdAt;
  final List<ExternalOrderItem> items;

  const ExternalOrder({
    required this.id,
    this.entityNo,
    this.entityName,
    required this.isProductive,
    this.remarks,
    required this.orderDate,
    required this.createdAt,
    required this.items,
  });

  factory ExternalOrder.fromJson(Map<String, dynamic> json) => ExternalOrder(
        id: (json["id"] ?? "").toString(),
        entityNo: json["entity_no"]?.toString(),
        entityName: json["entity_name"]?.toString(),
        isProductive: (json["is_productive"] == true ||
            json["is_productive"] == 1 ||
            json["is_productive"] == "1"),
        remarks: json["remarks"]?.toString(),
        orderDate: (json["order_date"] ?? "").toString(),
        createdAt: (json["created_at"] ?? "").toString(),
        items: json["items"] != null
            ? (json["items"] as List<dynamic>)
                .map((x) => ExternalOrderItem.fromJson(x as Map<String, dynamic>))
                .toList()
            : [],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "entity_no": entityNo,
        "entity_name": entityName,
        "is_productive": isProductive,
        "remarks": remarks,
        "order_date": orderDate,
        "created_at": createdAt,
        "items": items.map((x) => x.toJson()).toList(),
      };
}

class ExternalOrderItem {
  final String id;
  final String itemId;
  final String itemName;
  final double qtyPcs;
  final double qtyBox;
  final double qtyFoc;
  final double rate;
  final double totalAmount;

  const ExternalOrderItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.qtyPcs,
    required this.qtyBox,
    required this.qtyFoc,
    required this.rate,
    required this.totalAmount,
  });

  factory ExternalOrderItem.fromJson(Map<String, dynamic> json) =>
      ExternalOrderItem(
        id: (json["id"] ?? "").toString(),
        itemId: (json["item_id"] ?? "").toString(),
        itemName: (json["item_name"] ?? "").toString(),
        qtyPcs: double.tryParse(json["qty_pcs"]?.toString() ?? "0") ?? 0,
        qtyBox: double.tryParse(json["qty_box"]?.toString() ?? "0") ?? 0,
        qtyFoc: double.tryParse(json["qty_foc"]?.toString() ?? "0") ?? 0,
        rate: double.tryParse(json["rate"]?.toString() ?? "0") ?? 0,
        totalAmount: double.tryParse(json["total_amount"]?.toString() ?? "0") ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "item_id": itemId,
        "item_name": itemName,
        "qty_pcs": qtyPcs,
        "qty_box": qtyBox,
        "qty_foc": qtyFoc,
        "rate": rate,
        "total_amount": totalAmount,
      };
}
