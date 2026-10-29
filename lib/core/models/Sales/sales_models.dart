import 'sales_common.dart';

/// Money and volume totals shared by the client, SKU and salesperson rows.
class SalesTotals {
  const SalesTotals({
    this.salesAmount = 0,
    this.salesQuantity = 0,
    this.grossSalesAmount = 0,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.saleAmount = 0,
    this.returnAmount = 0,
    this.orderCount = 0,
  });

  final double salesAmount;
  final double salesQuantity;
  final double grossSalesAmount;
  final double discountAmount;
  final double taxAmount;

  /// Sum of the SALE lines only (before returns).
  final double saleAmount;

  /// Signed RETURN amount, as reported by the source (usually negative).
  final double returnAmount;
  final int orderCount;

  factory SalesTotals.fromJson(Map<String, dynamic> map) => SalesTotals(
        salesAmount: salesDouble(map['sales_amount']),
        salesQuantity: salesDouble(map['sales_quantity']),
        grossSalesAmount: salesDouble(map['gross_sales_amount']),
        discountAmount: salesDouble(map['discount_amount']),
        taxAmount: salesDouble(map['tax_amount']),
        saleAmount: salesDouble(map['sale_amount']),
        returnAmount: salesDouble(map['return_amount']),
        orderCount: salesInt(map['order_count']),
      );
}

class InternalClientSales {
  const InternalClientSales({
    required this.clientId,
    required this.clientName,
    required this.clientStatus,
    required this.totals,
    required this.comparison,
  });

  final String clientId;
  final String clientName;
  final int clientStatus;
  final SalesTotals totals;
  final SalesComparison comparison;

  bool get isActive => clientStatus == 1;

  factory InternalClientSales.fromJson(Map<String, dynamic> map) =>
      InternalClientSales(
        clientId: salesString(map['client_id']) ?? '-',
        clientName: salesString(map['client_name']) ?? 'Unnamed client',
        clientStatus: salesInt(map['client_status']),
        totals: SalesTotals.fromJson(map),
        comparison: SalesComparison.fromJson(map['comparison']),
      );
}

class ExternalClientSales {
  const ExternalClientSales({
    required this.clientId,
    required this.clientName,
    required this.clientStatus,
    required this.orderbookerId,
    required this.orderbookerName,
    required this.totals,
    required this.comparison,
  });

  final String clientId;
  final String clientName;
  final int clientStatus;
  final String? orderbookerId;
  final String orderbookerName;
  final SalesTotals totals;
  final SalesComparison comparison;

  bool get isActive => clientStatus == 1;

  factory ExternalClientSales.fromJson(Map<String, dynamic> map) =>
      ExternalClientSales(
        clientId: salesString(map['client_id']) ?? '-',
        clientName: salesString(map['client_name']) ?? 'Unnamed client',
        clientStatus: salesInt(map['client_status']),
        orderbookerId: salesString(map['orderbooker_id']),
        orderbookerName: salesString(map['orderbooker_name']) ?? 'Unassigned',
        totals: SalesTotals.fromJson(map),
        comparison: SalesComparison.fromJson(map['comparison']),
      );
}

class OrderBookerSummary {
  const OrderBookerSummary({
    required this.orderbookerId,
    required this.orderbookerName,
    required this.clientCount,
    required this.salesAmount,
    required this.salesQuantity,
    required this.orderCount,
  });

  final String? orderbookerId;
  final String orderbookerName;
  final int clientCount;
  final double salesAmount;
  final double salesQuantity;
  final int orderCount;

  /// The server keeps unassigned clients in an `Unassigned` group.
  bool get isUnassigned => orderbookerId == null;

  factory OrderBookerSummary.fromJson(Map<String, dynamic> map) =>
      OrderBookerSummary(
        orderbookerId: salesString(map['orderbooker_id']),
        orderbookerName: salesString(map['orderbooker_name']) ?? 'Unassigned',
        clientCount: salesInt(map['client_count']),
        salesAmount: salesDouble(map['sales_amount']),
        salesQuantity: salesDouble(map['sales_quantity']),
        orderCount: salesInt(map['order_count']),
      );
}

/// Full external-client report: the paged client list, plus the complete
/// order-booker group summary (not paged).
class ExternalBookersReport {
  const ExternalBookersReport({
    required this.page,
    required this.orderBookers,
  });

  final SalesPage<ExternalClientSales> page;
  final List<OrderBookerSummary> orderBookers;
}

class ClientSkuSales {
  const ClientSkuSales({
    required this.sku,
    required this.productName,
    required this.itemType,
    required this.totals,
    required this.previousSalesAmount,
    required this.previousSalesQuantity,
    required this.comparison,
  });

  final String sku;
  final String productName;
  final String? itemType;
  final SalesTotals totals;
  final double previousSalesAmount;
  final double previousSalesQuantity;
  final SalesComparison comparison;

  factory ClientSkuSales.fromJson(Map<String, dynamic> map) => ClientSkuSales(
        sku: salesString(map['sku']) ?? '-',
        productName: salesString(map['product_name']) ?? 'Unnamed product',
        itemType: salesString(map['item_type']),
        totals: SalesTotals.fromJson(map),
        previousSalesAmount: salesDouble(map['previous_sales_amount']),
        previousSalesQuantity: salesDouble(map['previous_sales_quantity']),
        comparison: SalesComparison.fromJson(map['comparison']),
      );
}

class SalesClientInfo {
  const SalesClientInfo({
    required this.clientId,
    required this.clientName,
    required this.clientType,
  });

  final String clientId;
  final String clientName;
  final String? clientType;

  factory SalesClientInfo.fromJson(Map<String, dynamic> map) => SalesClientInfo(
        clientId: salesString(map['client_id']) ?? '-',
        clientName: salesString(map['client_name']) ?? 'Unnamed client',
        clientType: salesString(map['client_type']),
      );
}

class SalespersonPerformance {
  const SalespersonPerformance({
    required this.salespersonId,
    required this.employeeCode,
    required this.name,
    required this.salesGroup,
    required this.userStatus,
    required this.salesAmount,
    required this.salesQuantity,
    required this.clientCoverage,
    required this.orderCount,
    required this.targetAmount,
    required this.targetAvailable,
    required this.comparison,
  });

  final int salespersonId;
  final String? employeeCode;
  final String name;
  final String? salesGroup;
  final String? userStatus;
  final double salesAmount;
  final double salesQuantity;
  final int clientCoverage;
  final int orderCount;

  /// Null until the server exposes target data. Shown as "Target not set".
  final double? targetAmount;
  final bool targetAvailable;
  final SalesComparison comparison;

  bool get isActive => (userStatus ?? '').toUpperCase() == 'A';

  factory SalespersonPerformance.fromJson(Map<String, dynamic> map) =>
      SalespersonPerformance(
        salespersonId: salesInt(map['salesperson_id']),
        employeeCode: salesString(map['employee_code']),
        name: salesString(map['salesperson_name']) ?? 'Unnamed user',
        salesGroup: salesString(map['sales_group']),
        userStatus: salesString(map['user_status']),
        salesAmount: salesDouble(map['sales_amount']),
        salesQuantity: salesDouble(map['sales_quantity']),
        clientCoverage: salesInt(map['client_coverage']),
        orderCount: salesInt(map['order_count']),
        targetAmount: salesDoubleOrNull(map['target_amount']),
        targetAvailable: map['target_available'] == true,
        comparison: SalesComparison.fromJson(map['comparison']),
      );
}

/// One row of a top-ten ranking (salesperson, client or SKU).
class RankedSalesRow {
  const RankedSalesRow({
    required this.id,
    required this.name,
    required this.salesAmount,
    required this.salesQuantity,
  });

  final String id;
  final String name;
  final double salesAmount;
  final double salesQuantity;

  factory RankedSalesRow.fromJson(Map<String, dynamic> map) => RankedSalesRow(
        id: salesString(map['id'] ?? map['salesperson_id'] ?? map['client_id'] ?? map['sku']) ?? '-',
        name: salesString(map['name'] ?? map['salesperson_name'] ?? map['client_name'] ?? map['product_name']) ??
            'Unnamed',
        salesAmount: salesDouble(map['sales_amount']),
        salesQuantity: salesDouble(map['sales_quantity']),
      );
}

class SalesDayPoint {
  const SalesDayPoint({
    required this.label,
    required this.salesAmount,
    required this.salesQuantity,
  });

  final String label;
  final double salesAmount;
  final double salesQuantity;

  factory SalesDayPoint.fromJson(Map<String, dynamic> map) => SalesDayPoint(
        label: salesString(map['date'] ?? map['month']) ?? '-',
        salesAmount: salesDouble(map['sales_amount']),
        salesQuantity: salesDouble(map['sales_quantity']),
      );
}

class SalesDashboard {
  const SalesDashboard({
    required this.kpis,
    required this.comparison,
    required this.internalAmount,
    required this.internalQuantity,
    required this.externalAmount,
    required this.externalQuantity,
    required this.activeInternal,
    required this.activeExternal,
    required this.noSalesInternal,
    required this.noSalesExternal,
    required this.topSalespersons,
    required this.topClients,
    required this.topSkus,
    required this.dailyTrend,
    required this.monthlyTrend,
  });

  final SalesTotals kpis;
  final SalesComparison comparison;
  final double internalAmount;
  final double internalQuantity;
  final double externalAmount;
  final double externalQuantity;
  final int activeInternal;
  final int activeExternal;
  final int noSalesInternal;
  final int noSalesExternal;
  final List<RankedSalesRow> topSalespersons;
  final List<RankedSalesRow> topClients;
  final List<RankedSalesRow> topSkus;
  final List<SalesDayPoint> dailyTrend;
  final List<SalesDayPoint> monthlyTrend;

  int get activeTotal => activeInternal + activeExternal;
  int get noSalesTotal => noSalesInternal + noSalesExternal;

  static List<RankedSalesRow> _ranked(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((e) => RankedSalesRow.fromJson(Map<String, dynamic>.from(e)))
          .toList()
      : const [];

  static List<SalesDayPoint> _points(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((e) => SalesDayPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList()
      : const [];

  factory SalesDashboard.fromJson(Map<String, dynamic> data) {
    final kpis = salesMap(data['kpis']);
    final clientType = salesMap(data['client_type_comparison']);
    final internal = salesMap(clientType['internal']);
    final external = salesMap(clientType['external']);
    final clients = salesMap(data['clients']);

    return SalesDashboard(
      kpis: SalesTotals.fromJson(kpis),
      comparison: SalesComparison.fromJson(data['comparison']),
      internalAmount: salesDouble(internal['sales_amount']),
      internalQuantity: salesDouble(internal['sales_quantity']),
      externalAmount: salesDouble(external['sales_amount']),
      externalQuantity: salesDouble(external['sales_quantity']),
      activeInternal: salesInt(clients['active_internal']),
      activeExternal: salesInt(clients['active_external']),
      noSalesInternal: salesInt(clients['no_sales_internal']),
      noSalesExternal: salesInt(clients['no_sales_external']),
      topSalespersons: _ranked(data['top_salespersons']),
      topClients: _ranked(data['top_clients']),
      topSkus: _ranked(data['top_skus']),
      dailyTrend: _points(data['daily_trend']),
      monthlyTrend: _points(data['monthly_trend']),
    );
  }
}
