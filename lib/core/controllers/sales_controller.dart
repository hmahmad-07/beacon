import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/constants.dart';
import '../models/Sales/sales_common.dart';
import '../models/Sales/sales_ledger_directory.dart';
import '../models/Sales/sales_models.dart';
import '../network/api_client.dart';
import 'sales_period_controller.dart';

/// Thrown for API-level failures (`error != 0`) and transport failures.
class SalesApiException implements Exception {
  const SalesApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Loads the Sales reports for ONE business. Create one per Sales section,
/// so Paani and CC never share state.
///
/// Each report keeps its own loading flag, error and data. A request
/// sequence number per report drops responses that arrive after a newer
/// request for the same report was started, so a quick filter change can't
/// be overwritten by an older response.
///
/// When the query of a new request differs from the query behind the data on
/// screen, that data is dropped first. The screen then shows its loader
/// instead of the previous period's numbers, and a failure is shown rather
/// than hidden behind old figures.
class SalesController extends ChangeNotifier {
  SalesController({required this.business, SalesFilters? initialFilters})
    : filters = initialFilters ?? _currentMonth();

  final SalesBusiness business;

  SalesFilters filters;

  static SalesFilters _currentMonth() {
    final now = DateTime.now();
    return SalesFilters(month: now.month, year: now.year);
  }

  // ----------------------------------------------------------- state per report

  bool internalLoading = false;
  String? internalError;
  SalesPage<InternalClientSales>? internalClients;

  bool externalLoading = false;
  String? externalError;
  ExternalBookersReport? externalBookers;

  bool skuLoading = false;
  String? skuError;
  SalesClientInfo? skuClient;
  SalesPage<ClientSkuSales>? clientSkus;

  bool salespersonLoading = false;
  String? salespersonError;
  SalesPage<SalespersonPerformance>? salespersons;

  bool dashboardLoading = false;
  String? dashboardError;
  SalesDashboard? dashboard;

  bool clientLoading = false;
  String? clientError;
  SalesDashboard? clientDashboard;
  List<ClientSkuSales> clientProducts = const [];

  /// Monthly ledger for the client detail screen (Paani only). A failure here
  /// does not block the rest of the client detail.
  ClientLedger? clientLedger;
  String? clientLedgerError;

  /// When the data on screen last loaded successfully ("Updated 11:52 AM").
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  final Map<String, int> _sequence = {};

  /// The query behind the data currently shown, per report.
  final Map<String, String> _shownKeys = {};

  int _nextSequence(String report) {
    final next = (_sequence[report] ?? 0) + 1;
    _sequence[report] = next;
    return next;
  }

  bool _isCurrent(String report, int seq) => _sequence[report] == seq;

  static String _keyOf(Map<String, dynamic> query) {
    final keys = query.keys.toList()..sort();
    return keys.map((k) => '$k=${query[k]}').join('&');
  }

  /// Starts a request for [report]. If [query] is different from the query
  /// behind the data on screen, [clear] drops that data.
  int _begin(String report, Map<String, dynamic> query, void Function() clear) {
    final seq = _nextSequence(report);
    if (_shownKeys[report] != _keyOf(query)) clear();
    return seq;
  }

  /// Records a successful load of [report] for [query].
  void _commit(String report, Map<String, dynamic> query) {
    _shownKeys[report] = _keyOf(query);
    _lastUpdated = DateTime.now();
  }

  // ----------------------------------------------------------- shared period

  SalesPeriodController? _period;
  Future<void> Function(SalesController)? _reloadOnPeriod;

  /// Follows the Sales period shared by every Sales screen. When the period
  /// changes anywhere, this controller adopts it and calls [reload], so the
  /// report on screen is refreshed for the new period.
  void bindPeriod(
    SalesPeriodController period,
    Future<void> Function(SalesController) reload,
  ) {
    _period?.removeListener(_onSharedPeriodChanged);
    _period = period;
    _reloadOnPeriod = reload;
    period.addListener(_onSharedPeriodChanged);
  }

  void _onSharedPeriodChanged() {
    final shared = _period?.filters;
    if (shared == null || filters.hasSamePeriod(shared)) return;
    filters = filters.withPeriodFrom(shared);
    notifyListeners();
    final reload = _reloadOnPeriod;
    if (reload != null) reload(this);
  }

  @override
  void dispose() {
    _period?.removeListener(_onSharedPeriodChanged);
    super.dispose();
  }

  // ----------------------------------------------------------- filters

  /// Replaces the screen filters (salesperson, booker, client, SKU and type).
  /// Callers reload the report they are showing.
  void setFilters(SalesFilters next) {
    filters = next;
    notifyListeners();
  }

  // ----------------------------------------------------------- reports

  Future<void> loadInternalClients({int page = 1, int perPage = 25}) async {
    const report = 'internal_clients';
    final query = filters.toQuery(page: page, perPage: perPage);
    final seq = _begin(report, query, () {
      internalClients = null;
    });
    internalLoading = true;
    internalError = null;
    notifyListeners();
    try {
      final body = await _get(report, query);
      if (!_isCurrent(report, seq)) return;
      internalClients = _page(body, InternalClientSales.fromJson);
      _commit(report, query);
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      internalError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        internalLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadExternalBookers({int page = 1, int perPage = 25}) async {
    const report = 'external_bookers';
    final query = filters.toQuery(page: page, perPage: perPage);
    final seq = _begin(report, query, () {
      externalBookers = null;
    });
    externalLoading = true;
    externalError = null;
    notifyListeners();
    try {
      final body = await _get(report, query);
      if (!_isCurrent(report, seq)) return;
      final rawBookers = body['order_bookers'];
      externalBookers = ExternalBookersReport(
        page: _page(body, ExternalClientSales.fromJson),
        orderBookers: rawBookers is List
            ? rawBookers
                  .whereType<Map>()
                  .map(
                    (e) => OrderBookerSummary.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
            : const [],
      );
      _commit(report, query);
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      externalError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        externalLoading = false;
        notifyListeners();
      }
    }
  }

  /// `clientId` is required by the API for the SKU breakdown.
  Future<void> loadClientSkus({
    required String clientId,
    int page = 1,
    int perPage = 25,
  }) async {
    const report = 'client_skus';
    final query = filters
        .copyWith(clientId: clientId)
        .toQuery(page: page, perPage: perPage);
    final seq = _begin(report, query, () {
      skuClient = null;
      clientSkus = null;
    });
    skuLoading = true;
    skuError = null;
    notifyListeners();
    try {
      final body = await _get(report, query);
      if (!_isCurrent(report, seq)) return;
      skuClient = SalesClientInfo.fromJson(salesMap(body['client']));
      clientSkus = _page(body, ClientSkuSales.fromJson);
      _commit(report, query);
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      skuError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        skuLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadSalespersons({int page = 1, int perPage = 25}) async {
    const report = 'salespersons';
    final query = filters.toQuery(page: page, perPage: perPage);
    final seq = _begin(report, query, () {
      salespersons = null;
    });
    salespersonLoading = true;
    salespersonError = null;
    notifyListeners();
    try {
      final body = await _get(report, query);
      if (!_isCurrent(report, seq)) return;
      salespersons = _page(body, SalespersonPerformance.fromJson);
      _commit(report, query);
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      salespersonError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        salespersonLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadDashboard() async {
    const report = 'dashboard';
    final query = filters.toQuery();
    final seq = _begin(report, query, () {
      dashboard = null;
    });
    dashboardLoading = true;
    dashboardError = null;
    notifyListeners();
    try {
      final body = await _get(report, query);
      if (!_isCurrent(report, seq)) return;
      dashboard = SalesDashboard.fromJson(salesMap(body['data']));
      _commit(report, query);
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      dashboardError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        dashboardLoading = false;
        notifyListeners();
      }
    }
  }

  /// One client's detail for the selected period: KPIs, the daily and 12-month
  /// sales (dashboard scoped by `client_id`), the monthly ledger (Paani and CC)
  /// and the products sold to that client.
  Future<void> loadClientDetail({required String clientId}) async {
    const report = 'client_detail';
    final scoped = filters.copyWith(clientId: clientId);
    final query = scoped.toQuery();
    final seq = _begin(report, query, () {
      clientDashboard = null;
      clientProducts = const [];
      clientLedger = null;
      clientLedgerError = null;
    });
    clientLoading = true;
    clientError = null;
    notifyListeners();
    try {
      final responses = await Future.wait([
        _get('dashboard', query),
        _get('client_skus', scoped.toQuery(page: 1, perPage: 100)),
      ]);

      ClientLedger? ledger;
      String? ledgerError;
      try {
        ledger = await _loadLedgerFor(clientId);
      } catch (e) {
        ledgerError = _message(e);
      }

      if (!_isCurrent(report, seq)) return;
      clientDashboard = SalesDashboard.fromJson(
        salesMap(responses[0]['data']),
      );
      clientProducts = _page(responses[1], ClientSkuSales.fromJson).items;
      clientLedger = ledger;
      clientLedgerError = ledgerError;
      _commit(report, query);
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      clientError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        clientLoading = false;
        notifyListeners();
      }
    }
  }

  /// The 12-month ledger for one client, ending at the selected period: the
  /// day, the end of the range, or the chosen month.
  Future<ClientLedger?> _loadLedgerFor(String clientId) async {
    final now = DateTime.now();
    final end =
        filters.date ??
        filters.dateTo ??
        DateTime(filters.year ?? now.year, filters.month ?? now.month);
    final query = <String, dynamic>{
      'grain': 'month',
      'year': end.year,
      'month': end.month,
      'months': 12,
      'client_id': clientId,
    };
    final salespersonId = filters.salespersonId?.trim() ?? '';
    if (salespersonId.isNotEmpty) query['salesperson_id'] = salespersonId;
    final orderbookerId = filters.orderbookerId?.trim() ?? '';
    if (orderbookerId.isNotEmpty) query['orderbooker_id'] = orderbookerId;

    final body = await _get('client_ledger', query);
    final raw = body['data'];
    if (raw is! List || raw.isEmpty) return null;
    return ClientLedger.fromJson(Map<String, dynamic>.from(raw.first as Map));
  }

  /// One order booker's trend: the dashboard scoped by `orderbooker_id`,
  /// giving that booker's 12-month and daily sales for the selected period.
  bool bookerLoading = false;
  String? bookerError;
  String? bookerTrendId;
  SalesDashboard? bookerDashboard;

  Future<void> loadOrderBookerTrend({required String orderbookerId}) async {
    const report = 'booker_trend';
    final query = filters.copyWith(orderbookerId: orderbookerId).toQuery();
    final seq = _begin(report, query, () {
      bookerDashboard = null;
    });
    bookerLoading = true;
    bookerError = null;
    bookerTrendId = orderbookerId;
    notifyListeners();
    try {
      final body = await _get('dashboard', query);
      if (!_isCurrent(report, seq)) return;
      bookerDashboard = SalesDashboard.fromJson(salesMap(body['data']));
      _commit(report, query);
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      bookerError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        bookerLoading = false;
        notifyListeners();
      }
    }
  }

  /// Picker lists from the directory endpoint. It is not narrowed by any
  /// salesperson, booker, client or SKU filter, so choosing one person never
  /// hides the others. Only the period applies.
  bool pickerLoading = false;
  String? pickerError;
  SalesDirectory? directory;

  Future<void> loadPickerOptions() async {
    const report = 'directory';
    final seq = _nextSequence(report);
    pickerLoading = true;
    pickerError = null;
    notifyListeners();
    try {
      final query = filters
          .copyWith(
            salespersonId: '',
            orderbookerId: '',
            clientId: '',
            sku: '',
            clientType: '',
          )
          .toQuery();
      if (query.containsKey('date')) {
        final day = query.remove('date');
        query['date_from'] = day;
        query['date_to'] = day;
      }
      final body = await _get(report, query);
      if (!_isCurrent(report, seq)) return;
      directory = SalesDirectory.fromJson(salesMap(body['data']));
    } catch (e) {
      if (!_isCurrent(report, seq)) return;
      pickerError = _message(e);
    } finally {
      if (_isCurrent(report, seq)) {
        pickerLoading = false;
        notifyListeners();
      }
    }
  }

  // ----------------------------------------------------------- transport

  /// Endpoint: `sales_<cc|paani>_<report>.php`.
  String _endpoint(String report) =>
      '${Constants.baseUrl}sales_${business.code}_$report.php';

  Future<Map<String, dynamic>> _get(
    String report,
    Map<String, dynamic> query,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        _endpoint(report),
        queryParameters: query,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );

      final body = response.data;
      if (body is! Map) {
        throw const SalesApiException('Unexpected response from the server.');
      }
      final map = Map<String, dynamic>.from(body);
      if (salesInt(map['error']) != 0) {
        throw SalesApiException(
          salesString(map['error_msg']) ?? 'Could not load this report.',
        );
      }
      return map;
    } on DioException catch (e) {
      throw SalesApiException(_dioMessage(e));
    }
  }

  SalesPage<T> _page<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = body['data'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map((e) => fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <T>[];
    return SalesPage<T>(
      items: items,
      summary: salesMap(body['summary']),
      meta: SalesPageMeta.fromJson(body['meta']),
    );
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && salesString(data['error_msg']) != null) {
      return salesString(data['error_msg'])!;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection and try again.';
      default:
        return 'Something went wrong while loading this report.';
    }
  }

  String _message(Object error) {
    if (error is SalesApiException) return error.message;
    return 'Something went wrong while loading this report.';
  }
}
