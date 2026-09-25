// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../network/api_client.dart';
import '../models/WMS/inventory_store_model.dart';
import '../models/WMS/inventory_item_model.dart';
import '../models/WMS/inventory_stock_report_model.dart';
import '../models/WMS/inventory_expiry_model.dart';
import '../models/WMS/inventory_dashboard_model.dart';
import '../utils/inventory_dates.dart';
import '../utils/utils.dart';

// Every filter/page/expand-state field below used to live as local
// setState()-managed fields on each screen's State class. They're all
// here instead, namespaced per screen (dashboardStoreId, itemsStoreId,
// stockReportStoreId, ...) so the views stay dumb: they read
// controller fields and call controller action methods, never mutate
// their own state directly.
class WMSController extends ChangeNotifier {
  static Dio get _client => ApiClient.dio;

  Map<String, dynamic> _headers() => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${Constants.token}',
  };

  String? _errorMessageFrom(dynamic responseData) {
    try {
      final json = responseData is String
          ? jsonDecode(responseData) as Map<String, dynamic>
          : responseData as Map<String, dynamic>;
      return json['error_msg']?.toString();
    } catch (_) {
      return null;
    }
  }

  // ================================================== Stores ==================================================

  bool isStoresLoading = false;
  InventoryStoresModel? storesModel;
  String storesQuery = "";

  List<InventoryStore> get activeStores =>
      (storesModel?.data ?? []).where((s) => s.isActive).toList();

  List<InventoryStore> get filteredActiveStores {
    if (storesQuery.isEmpty) return activeStores;
    final q = storesQuery.toLowerCase();
    return activeStores
        .where(
          (s) =>
              (s.name ?? "").toLowerCase().contains(q) ||
              (s.code ?? "").toLowerCase().contains(q),
        )
        .toList();
  }

  void setStoresQuery(String query) {
    storesQuery = query.trim();
    notifyListeners();
  }

  Future<void> getStores(BuildContext context) async {
    try {
      isStoresLoading = true;
      notifyListeners();

      final response = await _client.get(
        '${Constants.baseUrl}inventory_stores.php',
        options: Options(headers: _headers()),
      );

      if (response.statusCode == 200) {
        storesModel = InventoryStoresModel.fromJson(response.data);
        if (storesModel?.error != 0 && context.mounted) {
          Utils.showSnackBar(
            context,
            storesModel?.errorMsg ?? 'Failed to load stores',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching stores: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          _errorMessageFrom(e.response?.data) ??
              'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching stores: $e');
    } finally {
      isStoresLoading = false;
      notifyListeners();
    }
  }

  void ensureStoresLoaded(BuildContext context) {
    if (storesModel == null && !isStoresLoading) getStores(context);
  }

  String? storeNameById(String? id) {
    if (id == null) return null;
    final match = activeStores.where((s) => s.id == id);
    return match.isEmpty ? null : match.first.name;
  }

  // ================================================== Dashboard ==================================================

  bool isDashboardLoading = false;
  InventoryDashboardModel? dashboardModel;
  String? dashboardStoreId;

  Future<void> setDashboardStore(BuildContext context, String? storeId) {
    dashboardStoreId = storeId;
    return getDashboard(context);
  }

  Future<void> getDashboard(BuildContext context) async {
    try {
      isDashboardLoading = true;
      dashboardModel = null;
      notifyListeners();

      final response = await _client.get(
        '${Constants.baseUrl}inventory_dashboard.php',
        queryParameters: {
          if (dashboardStoreId != null && dashboardStoreId!.isNotEmpty)
            'store_id': dashboardStoreId,
        },
        options: Options(headers: _headers()),
      );

      if (response.statusCode == 200) {
        dashboardModel = InventoryDashboardModel.fromJson(response.data);
        if (dashboardModel?.error != 0 && context.mounted) {
          Utils.showSnackBar(
            context,
            dashboardModel?.errorMsg ?? 'Failed to load dashboard',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching inventory dashboard: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          _errorMessageFrom(e.response?.data) ??
              'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching inventory dashboard: $e');
    } finally {
      isDashboardLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Items (paginated) ==================================================

  bool isItemsLoading = false;
  InventoryItemsListModel? itemsModel;
  String? itemsStoreId;
  String itemsStatus = "";
  String itemsSearch = "";
  int itemsPage = 1;
  DateTimeRange? itemsDateRange; // modified_from / modified_to

  Future<void> setItemsDateRange(BuildContext context, DateTimeRange? range) {
    itemsDateRange = range;
    itemsPage = 1;
    return getItems(context);
  }

  Future<void> setItemsStore(BuildContext context, String? storeId) {
    itemsStoreId = storeId;
    itemsPage = 1;
    return getItems(context);
  }

  Future<void> setItemsStatus(BuildContext context, String status) {
    itemsStatus = status;
    itemsPage = 1;
    return getItems(context);
  }

  Future<void> runItemsSearch(BuildContext context, String query) {
    itemsSearch = query.trim();
    itemsPage = 1;
    return getItems(context);
  }

  Future<void> goToItemsPage(BuildContext context, int page) {
    itemsPage = page;
    return getItems(context);
  }

  Future<void> getItems(BuildContext context) async {
    try {
      isItemsLoading = true;
      itemsModel = null;
      notifyListeners();

      final response = await _client.get(
        '${Constants.baseUrl}inventory_items.php',
        queryParameters: {
          if (itemsStoreId != null && itemsStoreId!.isNotEmpty)
            'store_id': itemsStoreId,
          if (itemsSearch.isNotEmpty) 'search': itemsSearch,
          if (itemsStatus.isNotEmpty) 'status': itemsStatus,
          ..._modifiedRangeParams(itemsDateRange),
          'per_page': 25,
          'page': itemsPage,
        },
        options: Options(headers: _headers()),
      );

      if (response.statusCode == 200) {
        itemsModel = InventoryItemsListModel.fromJson(response.data);
        if (itemsModel?.error != 0 && context.mounted) {
          Utils.showSnackBar(
            context,
            itemsModel?.errorMsg ?? 'Failed to load items',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching items: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          _errorMessageFrom(e.response?.data) ??
              'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching items: $e');
    } finally {
      isItemsLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Item detail ==================================================

  bool isItemDetailLoading = false;
  InventoryItemDetailModel? itemDetailModel;
  bool itemDetailScopedToStore = false;
  DateTimeRange? itemDetailDateRange;

  /// Resets the detail-screen filters for a freshly-opened item (so a
  /// previous item's date range/store scope never leaks in) and fetches.
  Future<void> openItemDetail(
    BuildContext context,
    String itemId, {
    String? storeId,
  }) {
    itemDetailScopedToStore = storeId != null;
    itemDetailDateRange = null;
    return getItemDetail(context, itemId, storeId: storeId);
  }

  Future<void> toggleItemDetailStoreScope(
    BuildContext context,
    String itemId, {
    required String? storeId,
  }) {
    itemDetailScopedToStore = !itemDetailScopedToStore;
    return getItemDetail(context, itemId, storeId: storeId);
  }

  Future<void> setItemDetailDateRange(
    BuildContext context,
    String itemId, {
    required String? storeId,
    required DateTimeRange? range,
  }) {
    itemDetailDateRange = range;
    return getItemDetail(context, itemId, storeId: storeId);
  }

  Future<void> getItemDetail(
    BuildContext context,
    String itemId, {
    String? storeId,
  }) async {
    try {
      isItemDetailLoading = true;
      itemDetailModel = null;
      notifyListeners();

      final effectiveStoreId = itemDetailScopedToStore ? storeId : null;
      final range = itemDetailDateRange;

      final response = await _client.get(
        '${Constants.baseUrl}inventory_items.php',
        queryParameters: {
          'item_id': itemId,
          if (effectiveStoreId != null && effectiveStoreId.isNotEmpty)
            'store_id': effectiveStoreId,
          if (range != null) 'from_date': _apiDate(range.start),
          if (range != null) 'to_date': _apiDate(range.end),
        },
        options: Options(headers: _headers()),
      );

      if (response.statusCode == 200) {
        itemDetailModel = InventoryItemDetailModel.fromJson(response.data);
        if (itemDetailModel?.error != 0 && context.mounted) {
          Utils.showSnackBar(
            context,
            itemDetailModel?.errorMsg ?? 'Failed to load item',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching item detail: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          _errorMessageFrom(e.response?.data) ??
              'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching item detail: $e');
    } finally {
      isItemDetailLoading = false;
      notifyListeners();
    }
  }

  String _apiDate(DateTime d) => InventoryDates.api(d);

  // Items / stock / expiry all filter on modified_date server-side.
  Map<String, dynamic> _modifiedRangeParams(DateTimeRange? range) => {
    if (range != null) 'modified_from': _apiDate(range.start),
    if (range != null) 'modified_to': _apiDate(range.end),
  };

  // ================================================== Stock report (paginated) ==================================================

  // Unlike getItems, this stays page-by-page: the report now has its own
  // search box (search is a documented inventory_stock.php filter as of
  // the latest backend build), and normal pagination is the expected UX
  // once a filter/search narrows the result set.
  bool isStockReportLoading = false;
  InventoryStockReportModel? stockReportModel;
  String? stockReportStoreId;
  String stockReportSearch = "";
  bool stockReportLowStockOnly = false;
  int stockReportPage = 1;
  DateTimeRange? stockReportDateRange; // modified_from / modified_to
  final Set<String> stockReportExpandedIds = {};

  Future<void> setStockReportDateRange(
    BuildContext context,
    DateTimeRange? range,
  ) {
    stockReportDateRange = range;
    stockReportPage = 1;
    return getStockReport(context);
  }

  Future<void> setStockReportStore(BuildContext context, String? storeId) {
    stockReportStoreId = storeId;
    stockReportPage = 1;
    return getStockReport(context);
  }

  Future<void> runStockReportSearch(BuildContext context, String query) {
    stockReportSearch = query.trim();
    stockReportPage = 1;
    return getStockReport(context);
  }

  Future<void> setStockReportLowStockOnly(BuildContext context, bool value) {
    stockReportLowStockOnly = value;
    stockReportPage = 1;
    return getStockReport(context);
  }

  Future<void> goToStockReportPage(BuildContext context, int page) {
    stockReportPage = page;
    return getStockReport(context);
  }

  void toggleStockReportExpanded(String? itemId) {
    if (itemId == null) return;
    if (stockReportExpandedIds.contains(itemId)) {
      stockReportExpandedIds.remove(itemId);
    } else {
      stockReportExpandedIds.add(itemId);
    }
    notifyListeners();
  }

  Future<void> getStockReport(BuildContext context) async {
    try {
      isStockReportLoading = true;
      stockReportModel = null;
      notifyListeners();

      final response = await _client.get(
        '${Constants.baseUrl}inventory_stock.php',
        queryParameters: {
          if (stockReportStoreId != null && stockReportStoreId!.isNotEmpty)
            'store_id': stockReportStoreId,
          if (stockReportSearch.isNotEmpty) 'search': stockReportSearch,
          if (stockReportLowStockOnly) 'low_stock_only': 1,
          ..._modifiedRangeParams(stockReportDateRange),
          'per_page': 25,
          'page': stockReportPage,
        },
        options: Options(headers: _headers()),
      );

      if (response.statusCode == 200) {
        stockReportModel = InventoryStockReportModel.fromJson(response.data);
        if (stockReportModel?.error != 0 && context.mounted) {
          Utils.showSnackBar(
            context,
            stockReportModel?.errorMsg ?? 'Failed to load stock report',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching stock report: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          _errorMessageFrom(e.response?.data) ??
              'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching stock report: $e');
    } finally {
      isStockReportLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Expiry report ==================================================

  bool isExpiryLoading = false;
  InventoryExpiryModel? expiryModel;
  String? expiryStoreId;
  // true: latest received/expiry date on top; false: soonest expiry on top.
  bool expirySortLatest = true;
  DateTimeRange? expiryDateRange; // modified_from / modified_to

  void setExpirySortLatest(bool value) {
    expirySortLatest = value;
    notifyListeners();
  }

  Future<void> setExpiryDateRange(BuildContext context, DateTimeRange? range) {
    expiryDateRange = range;
    return getExpiryReport(context);
  }

  Future<void> setExpiryStore(BuildContext context, String? storeId) {
    expiryStoreId = storeId;
    return getExpiryReport(context);
  }

  Future<void> getExpiryReport(BuildContext context) async {
    try {
      isExpiryLoading = true;
      expiryModel = null;
      notifyListeners();

      final response = await _client.get(
        '${Constants.baseUrl}inventory_expiry.php',
        queryParameters: {
          if (expiryStoreId != null && expiryStoreId!.isNotEmpty)
            'store_id': expiryStoreId,
          ..._modifiedRangeParams(expiryDateRange),
        },
        options: Options(headers: _headers()),
      );

      if (response.statusCode == 200) {
        expiryModel = InventoryExpiryModel.fromJson(response.data);
        if (expiryModel?.error != 0 && context.mounted) {
          Utils.showSnackBar(
            context,
            expiryModel?.errorMsg ?? 'Failed to load expiry report',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching expiry report: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          _errorMessageFrom(e.response?.data) ??
              'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching expiry report: $e');
    } finally {
      isExpiryLoading = false;
      notifyListeners();
    }
  }
}
