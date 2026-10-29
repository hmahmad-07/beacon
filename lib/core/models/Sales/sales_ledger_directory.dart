import 'sales_common.dart';

/// One month (or one day) of a client's ledger.
class LedgerRow {
  const LedgerRow({
    required this.period,
    required this.salesAmount,
    required this.salesQuantity,
    required this.returnAmount,
    required this.orderCount,
  });

  /// `YYYY-MM` for monthly rows, `YYYY-MM-DD` for daily rows.
  final String period;
  final double salesAmount;
  final double salesQuantity;

  /// Signed; returns are negative.
  final double returnAmount;
  final int orderCount;

  factory LedgerRow.fromJson(Map<String, dynamic> map) => LedgerRow(
        period: salesString(map['period']) ?? '-',
        salesAmount: salesDouble(map['sales_amount']),
        salesQuantity: salesDouble(map['sales_quantity']),
        returnAmount: salesDouble(map['return_amount']),
        orderCount: salesInt(map['order_count']),
      );
}

/// One client from the client ledger endpoint, with its period rows.
class ClientLedger {
  const ClientLedger({
    required this.clientId,
    required this.clientName,
    required this.clientType,
    required this.clientStatus,
    required this.orderbookerId,
    required this.orderbookerName,
    required this.salespersonId,
    required this.rows,
  });

  final String clientId;
  final String clientName;
  final String? clientType;
  final int clientStatus;
  final String? orderbookerId;
  final String orderbookerName;
  final String? salespersonId;
  final List<LedgerRow> rows;

  factory ClientLedger.fromJson(Map<String, dynamic> map) {
    final raw = map['rows'];
    return ClientLedger(
      clientId: salesString(map['client_id']) ?? '-',
      clientName: salesString(map['client_name']) ?? 'Unnamed client',
      clientType: salesString(map['client_type']),
      clientStatus: salesInt(map['client_status']),
      orderbookerId: salesString(map['orderbooker_id']),
      orderbookerName: salesString(map['orderbooker_name']) ?? 'Unassigned',
      salespersonId: salesString(map['salesperson_id']),
      rows: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => LedgerRow.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

/// A salesperson from the directory: a Sales-department user in the business.
class DirectorySalesperson {
  const DirectorySalesperson({
    required this.salespersonId,
    required this.employeeCode,
    required this.name,
    required this.department,
    required this.salesGroup,
    required this.userStatus,
    required this.linkedOrderbookerId,
  });

  final int salespersonId;
  final String? employeeCode;
  final String name;
  final String? department;
  final String? salesGroup;
  final String? userStatus;
  final String? linkedOrderbookerId;

  bool get isActive => (userStatus ?? '').toUpperCase() == 'A';

  factory DirectorySalesperson.fromJson(Map<String, dynamic> map) =>
      DirectorySalesperson(
        salespersonId: salesInt(map['salesperson_id']),
        employeeCode: salesString(map['employee_code']),
        name: salesString(map['salesperson_name']) ?? 'Unnamed user',
        department: salesString(map['department']),
        salesGroup: salesString(map['sales_group']),
        userStatus: salesString(map['user_status']),
        linkedOrderbookerId: salesString(map['linked_orderbooker_id']),
      );
}

/// An order booker from the directory. `orderbookerId` is null for the
/// Unassigned group.
class DirectoryBooker {
  const DirectoryBooker({
    required this.orderbookerId,
    required this.name,
    required this.clientCount,
    required this.isActive,
    required this.linkedUserId,
  });

  final String? orderbookerId;
  final String name;
  final int clientCount;
  final bool isActive;
  final int? linkedUserId;

  bool get isUnassigned => orderbookerId == null;

  factory DirectoryBooker.fromJson(Map<String, dynamic> map) => DirectoryBooker(
        orderbookerId: salesString(map['orderbooker_id']),
        name: salesString(map['orderbooker_name']) ?? 'Unassigned',
        clientCount: salesInt(map['client_count']),
        isActive: map['is_active'] == true,
        linkedUserId: map['linked_user_id'] == null
            ? null
            : salesInt(map['linked_user_id']),
      );
}

/// The full picker lists for one business. Not narrowed by any filter.
class SalesDirectory {
  const SalesDirectory({required this.salespersons, required this.orderBookers});

  final List<DirectorySalesperson> salespersons;
  final List<DirectoryBooker> orderBookers;

  factory SalesDirectory.fromJson(Map<String, dynamic> data) {
    final sp = data['salespersons'];
    final bk = data['order_bookers'];
    return SalesDirectory(
      salespersons: sp is List
          ? sp
                .whereType<Map>()
                .map((e) => DirectorySalesperson.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      orderBookers: bk is List
          ? bk
                .whereType<Map>()
                .map((e) => DirectoryBooker.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}
