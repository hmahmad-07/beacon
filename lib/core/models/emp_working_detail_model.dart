import 'dart:convert';
import 'package:beacon/core/utils/utils.dart';

EmployesWorkingDetailModel employesWorkingDetailModelFromJson(String str) =>
    EmployesWorkingDetailModel.fromJson(json.decode(str));

String employesWorkingDetailModelToJson(EmployesWorkingDetailModel data) =>
    json.encode(data.toJson());

class EmployesWorkingDetailModel {
  final int error;
  final String errorMsg;
  final DateTime date;
  final Checkin? checkin;
  final Checkout? checkout;
  final int totalVisits;
  final List<Visit> visits;

  const EmployesWorkingDetailModel({
    required this.error,
    required this.errorMsg,
    required this.date,
    this.checkin,
    this.checkout,
    required this.totalVisits,
    required this.visits,
  });

  EmployesWorkingDetailModel copyWith({
    int? error,
    String? errorMsg,
    DateTime? date,
    Checkin? checkin,
    Checkout? checkout,
    int? totalVisits,
    List<Visit>? visits,
  }) {
    return EmployesWorkingDetailModel(
      error: error ?? this.error,
      errorMsg: errorMsg ?? this.errorMsg,
      date: date ?? this.date,
      checkin: checkin ?? this.checkin,
      checkout: checkout ?? this.checkout,
      totalVisits: totalVisits ?? this.totalVisits,
      visits: visits ?? this.visits,
    );
  }

  static bool _is24DVisit(String placeName) {
    final name = placeName.toLowerCase();
    return RegExp(r'24[\s\-]*d').hasMatch(name);
  }

  factory EmployesWorkingDetailModel.fromJson(Map<String, dynamic> json) {
    final rawVisits = json["visits"] != null
        ? (json["visits"] as List<dynamic>)
              .map((x) => Visit.fromJson(x as Map<String, dynamic>))
              .toList()
        : <Visit>[];

    final Map<String, Visit> uniqueVisits = {};

    for (var visit in rawVisits) {
      if (_is24DVisit(visit.placeName)) {
        continue;
      }

      final dateStr =
          visit.orders.isNotEmpty && visit.orders.first.orderDate.isNotEmpty
          ? visit.orders.first.orderDate
          : visit.createdAt;
      final parsedDate = Utils.parseDateTime(dateStr);
      final key =
          '${parsedDate.year}-${parsedDate.month}-${parsedDate.day}_${visit.placeName.trim().toLowerCase()}';

      if (!uniqueVisits.containsKey(key)) {
        uniqueVisits[key] = visit;
      } else {
        final existingVisit = uniqueVisits[key]!;
        final existingProductive = existingVisit.orders.any(
          (o) => o.isProductive,
        );
        final newProductive = visit.orders.any((o) => o.isProductive);
        if (!existingProductive && newProductive) {
          uniqueVisits[key] = visit;
        }
      }
    }

    final finalVisits = uniqueVisits.values.toList();

    return EmployesWorkingDetailModel(
      error: json["error"] as int,
      errorMsg: json["error_msg"] as String,
      date: DateTime.parse(json["date"] as String),
      checkin:
          (json["checkin"] != null &&
              json["checkin"] is Map &&
              (json["checkin"] as Map).isNotEmpty)
          ? Checkin.fromJson(json["checkin"] as Map<String, dynamic>)
          : null,
      checkout:
          (json["checkout"] != null &&
              json["checkout"] is Map &&
              (json["checkout"] as Map).isNotEmpty)
          ? Checkout.fromJson(json["checkout"] as Map<String, dynamic>)
          : null,
      totalVisits: finalVisits.length,
      visits: finalVisits,
    );
  }

  Map<String, dynamic> toJson() => {
    "error": error,
    "error_msg": errorMsg,
    "date":
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    "checkin": checkin?.toJson(),
    "checkout": checkout?.toJson(),
    "total_visits": totalVisits,
    "visits": visits.map((x) => x.toJson()).toList(),
  };
}

class Checkin {
  final String docid;
  final String time;
  final String latitude;
  final String longitude;
  final String imageUrl;
  final String? reason;

  const Checkin({
    required this.docid,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.reason,
  });

  factory Checkin.fromJson(Map<String, dynamic> json) => Checkin(
    docid: (json["docid"] ?? "").toString(),
    time: (json["time"] ?? "").toString(),
    latitude: (json["latitude"] ?? "").toString(),
    longitude: (json["longitude"] ?? "").toString(),
    imageUrl: (json["image_url"] ?? "").toString(),
    reason: json["reason"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "docid": docid,
    "time": time,
    "latitude": latitude,
    "longitude": longitude,
    "image_url": imageUrl,
    "reason": reason,
  };
}

class Checkout {
  final String docid;
  final String time;
  final String latitude;
  final String longitude;
  final String imageUrl;
  final String? reason;

  const Checkout({
    required this.docid,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.reason,
  });

  factory Checkout.fromJson(Map<String, dynamic> json) => Checkout(
    docid: (json["docid"] ?? "").toString(),
    time: (json["time"] ?? "").toString(),
    latitude: (json["latitude"] ?? "").toString(),
    longitude: (json["longitude"] ?? "").toString(),
    imageUrl: (json["image_url"] ?? "").toString(),
    reason: json["reason"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "docid": docid,
    "time": time,
    "latitude": latitude,
    "longitude": longitude,
    "image_url": imageUrl,
    "reason": reason,
  };
}

class Visit {
  final String id;
  final String userId;
  final String placeName;
  final String channel;
  final String ownerName;
  final String phoneNumber;
  final String address;
  final String latitude;
  final String longitude;
  final String createdAt;
  final String? remarks;
  final List<String> photos;
  final List<Order> orders;

  const Visit({
    required this.id,
    required this.userId,
    required this.placeName,
    required this.channel,
    required this.ownerName,
    required this.phoneNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.remarks,
    required this.photos,
    required this.orders,
  });

  String get effectiveLatitude {
    if (orders.isNotEmpty &&
        orders.first.latitude != null &&
        orders.first.latitude!.isNotEmpty) {
      return orders.first.latitude!;
    }
    return latitude;
  }

  String get effectiveLongitude {
    if (orders.isNotEmpty &&
        orders.first.longitude != null &&
        orders.first.longitude!.isNotEmpty) {
      return orders.first.longitude!;
    }
    return longitude;
  }

  List<String> get effectivePhotos {
    if (orders.isNotEmpty && orders.first.photos.isNotEmpty) {
      return orders.first.photos;
    }
    return photos;
  }

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    id: (json["id"] ?? "").toString(),
    userId: (json["user_id"] ?? "").toString(),
    placeName: (json["place_name"] ?? "").toString(),
    channel: (json["channel"] ?? "").toString(),
    ownerName: (json["owner_name"] ?? "").toString(),
    phoneNumber: (json["phone_number"] ?? "").toString(),
    address: (json["address"] ?? "").toString(),
    latitude: (json["latitude"] ?? "").toString(),
    longitude: (json["longitude"] ?? "").toString(),
    createdAt: (json["created_at"] ?? "").toString(),
    remarks: json["remarks"] as String?,
    photos: json["photos"] != null
        ? (json["photos"] as List<dynamic>).map((x) => x.toString()).toList()
        : [],
    orders: json["orders"] != null
        ? (json["orders"] as List<dynamic>)
              .map((x) => Order.fromJson(x as Map<String, dynamic>))
              .toList()
        : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "place_name": placeName,
    "channel": channel,
    "owner_name": ownerName,
    "phone_number": phoneNumber,
    "address": address,
    "latitude": latitude,
    "longitude": longitude,
    "created_at": createdAt,
    "remarks": remarks,
    "photos": photos,
    "orders": orders.map((x) => x.toJson()).toList(),
  };
}

class Order {
  final String id;
  final String visitId;
  final bool isProductive;
  final String? remarks;
  final String orderDate;
  final String createdAt;
  final List<String> photos;
  final List<Map<String, dynamic>> items;
  final String? latitude;
  final String? longitude;

  const Order({
    required this.id,
    required this.visitId,
    required this.isProductive,
    this.remarks,
    required this.orderDate,
    required this.createdAt,
    required this.photos,
    required this.items,
    this.latitude,
    this.longitude,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: (json["id"] ?? "").toString(),
    visitId: (json["visit_id"] ?? "").toString(),
    isProductive:
        (json["is_productive"] == true ||
        json["is_productive"] == 1 ||
        json["is_productive"] == "1"),
    remarks: json["remarks"] as String?,
    orderDate: (json["order_date"] ?? "").toString(),
    createdAt: (json["created_at"] ?? "").toString(),
    photos: json["photos"] != null
        ? (json["photos"] as List<dynamic>).map((x) => x.toString()).toList()
        : [],
    items: json["items"] != null
        ? (json["items"] as List<dynamic>)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList()
        : [],
    latitude: json["latitude"]?.toString(),
    longitude: json["longitude"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "visit_id": visitId,
    "is_productive": isProductive,
    "remarks": remarks,
    "order_date": orderDate,
    "created_at": createdAt,
    "photos": photos,
    "items": items,
    "latitude": latitude,
    "longitude": longitude,
  };
}
