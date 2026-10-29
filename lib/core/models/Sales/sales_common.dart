/// Shared parsing helpers and envelope types for the Sales API.
///
/// Every Sales response uses `{error, error_msg, data, summary?, meta?}`.
/// Money and quantities are rounded to two decimals by the server, but the
/// JSON may still carry them as ints or strings, so parsing is defensive.
library;

double salesDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? salesDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int salesInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String? salesString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> salesMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

/// Before/after comparison against the preceding month or equal-length range.
class SalesComparison {
  const SalesComparison({
    this.currentSalesAmount = 0,
    this.previousSalesAmount = 0,
    this.growthAmount = 0,
    this.growthPercent,
  });

  final double currentSalesAmount;
  final double previousSalesAmount;
  final double growthAmount;

  /// Null when the previous period is zero, so percent growth is undefined.
  final double? growthPercent;

  bool get isUp => growthAmount > 0;
  bool get isDown => growthAmount < 0;

  factory SalesComparison.fromJson(dynamic json) {
    final map = salesMap(json);
    return SalesComparison(
      currentSalesAmount: salesDouble(map['current_sales_amount']),
      previousSalesAmount: salesDouble(map['previous_sales_amount']),
      growthAmount: salesDouble(map['growth_amount']),
      growthPercent: salesDoubleOrNull(map['growth_percent']),
    );
  }
}

class SalesPageMeta {
  const SalesPageMeta({
    this.currentPage = 1,
    this.perPage = 25,
    this.total = 0,
    this.lastPage = 1,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasNext => currentPage < lastPage;
  bool get hasPrevious => currentPage > 1;

  factory SalesPageMeta.fromJson(dynamic json) {
    final map = salesMap(json);
    return SalesPageMeta(
      currentPage: salesInt(map['current_page']).clamp(1, 1 << 30).toInt(),
      perPage: salesInt(map['per_page']).clamp(1, 100).toInt(),
      total: salesInt(map['total']),
      lastPage: salesInt(map['last_page']).clamp(1, 1 << 30).toInt(),
    );
  }
}

/// A paginated report: the rows, the server summary, and the paging meta.
class SalesPage<T> {
  const SalesPage({
    required this.items,
    this.summary = const {},
    this.meta = const SalesPageMeta(),
  });

  final List<T> items;
  final Map<String, dynamic> summary;
  final SalesPageMeta meta;
}

/// Business the Sales API is scoped to. The API route prefix is the
/// `sales_<code>_` family of endpoints.
enum SalesBusiness {
  cc(code: 'cc', label: 'Corporate Canteen'),
  paani(code: 'paani', label: 'Paani.');

  const SalesBusiness({required this.code, required this.label});

  /// Endpoint segment: `sales_cc_*.php` or `sales_paani_*.php`.
  final String code;
  final String label;
}

/// The filter set shared by every Sales report. Use either [month]+[year],
/// a single [date], or both [dateFrom] and [dateTo]; never a mix.
class SalesFilters {
  const SalesFilters({
    this.month,
    this.year,
    this.date,
    this.dateFrom,
    this.dateTo,
    this.salespersonId,
    this.orderbookerId,
    this.clientType,
    this.clientId,
    this.sku,
  });

  final int? month;
  final int? year;
  final DateTime? date;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? salespersonId;
  final String? orderbookerId;

  /// `INTERNAL` or `EXTERNAL`.
  final String? clientType;
  final String? clientId;
  final String? sku;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Query parameters for a GET. Empty and null values are dropped.
  Map<String, dynamic> toQuery({int? page, int? perPage}) {
    final query = <String, dynamic>{};

    if (date != null) {
      query['date'] = _ymd(date!);
    } else if (dateFrom != null && dateTo != null) {
      query['date_from'] = _ymd(dateFrom!);
      query['date_to'] = _ymd(dateTo!);
    } else {
      if (month != null) query['month'] = month;
      if (year != null) query['year'] = year;
    }

    void put(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) query[key] = value.trim();
    }

    put('salesperson_id', salespersonId);
    put('orderbooker_id', orderbookerId);
    put('client_type', clientType);
    put('client_id', clientId);
    put('sku', sku);

    if (page != null) query['page'] = page;
    if (perPage != null) query['per_page'] = perPage;
    return query;
  }

  SalesFilters copyWith({
    int? month,
    int? year,
    DateTime? date,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearRange = false,
    bool clearDate = false,
    String? salespersonId,
    String? orderbookerId,
    String? clientType,
    String? clientId,
    String? sku,
  }) {
    return SalesFilters(
      month: month ?? this.month,
      year: year ?? this.year,
      date: clearDate ? null : (date ?? this.date),
      dateFrom: clearRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearRange ? null : (dateTo ?? this.dateTo),
      salespersonId: salespersonId ?? this.salespersonId,
      orderbookerId: orderbookerId ?? this.orderbookerId,
      clientType: clientType ?? this.clientType,
      clientId: clientId ?? this.clientId,
      sku: sku ?? this.sku,
    );
  }

  /// True when both filters cover the same period. Screen filters are ignored.
  bool hasSamePeriod(SalesFilters other) =>
      month == other.month &&
      year == other.year &&
      _sameDay(date, other.date) &&
      _sameDay(dateFrom, other.dateFrom) &&
      _sameDay(dateTo, other.dateTo);

  /// Takes the period from [period] and keeps this filter's screen filters.
  SalesFilters withPeriodFrom(SalesFilters period) => SalesFilters(
        month: period.month,
        year: period.year,
        date: period.date,
        dateFrom: period.dateFrom,
        dateTo: period.dateTo,
        salespersonId: salespersonId,
        orderbookerId: orderbookerId,
        clientType: clientType,
        clientId: clientId,
        sku: sku,
      );

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
