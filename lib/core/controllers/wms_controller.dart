// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/WMS/inventory_store_model.dart';
import '../models/WMS/inventory_item_model.dart';
import '../models/WMS/inventory_stock_report_model.dart';
import '../models/WMS/inventory_expiry_model.dart';
import '../models/WMS/inventory_dashboard_model.dart';
import '../utils/utils.dart';

class WMSController extends ChangeNotifier {
  Map<String, dynamic> _headers() => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${Constants.token}',
  };

  // ================================================== Stores ==================================================

  bool isStoresLoading = false;
  InventoryStoresModel? storesModel;

  Future<void> getStores(BuildContext context) async {
    try {
      isStoresLoading = true;
      notifyListeners();

      final dio = Dio();
      final response = await dio.get(
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
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching stores: $e');
    } finally {
      isStoresLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Items (list) ==================================================

  bool isItemsLoading = false;
  InventoryItemsListModel? itemsModel;
  final List<InventoryItemSummary> items = [];

  Future<void> getItems(
    BuildContext context, {
    String? storeId,
    String? search,
    String? status,
    int page = 1,
    int perPage = 25,
    bool append = false,
  }) async {
    try {
      isItemsLoading = true;
      if (!append) items.clear();
      notifyListeners();

      final dio = Dio();
      final response = await dio.get(
        '${Constants.baseUrl}inventory_items.php',
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          'per_page': perPage,
          'page': page,
        },
        options: Options(headers: _headers()),
      );

      if (response.statusCode == 200) {
        itemsModel = InventoryItemsListModel.fromJson(response.data);
        if (itemsModel?.error == 0) {
          if (append) {
            items.addAll(itemsModel?.data ?? []);
          } else {
            items
              ..clear()
              ..addAll(itemsModel?.data ?? []);
          }
        } else if (context.mounted) {
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
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching items: $e');
    } finally {
      isItemsLoading = false;
      notifyListeners();
    }
  }

  bool get hasMoreItems {
    final meta = itemsModel?.meta;
    if (meta?.currentPage == null || meta?.lastPage == null) return false;
    return meta!.currentPage! < meta.lastPage!;
  }

  // ================================================== Item detail ==================================================

  bool isItemDetailLoading = false;
  InventoryItemDetailModel? itemDetailModel;

  Future<void> getItemDetail(
    BuildContext context,
    String itemId, {
    String? storeId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      isItemDetailLoading = true;
      itemDetailModel = null;
      notifyListeners();

      final dio = Dio();
      final response = await dio.get(
        '${Constants.baseUrl}inventory_items.php',
        queryParameters: {
          'item_id': itemId,
          if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
          if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
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
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching item detail: $e');
    } finally {
      isItemDetailLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Stock report ==================================================

  bool isStockReportLoading = false;
  InventoryStockReportModel? stockReportModel;

  Future<void> getStockReport(
    BuildContext context, {
    String? storeId,
    String? itemType,
    String? classId,
    bool lowStockOnly = false,
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      isStockReportLoading = true;
      stockReportModel = null;
      notifyListeners();

      final dio = Dio();
      final response = await dio.get(
        '${Constants.baseUrl}inventory_stock.php',
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
          if (itemType != null && itemType.isNotEmpty) 'item_type': itemType,
          if (classId != null && classId.isNotEmpty) 'class_id': classId,
          if (lowStockOnly) 'low_stock_only': 1,
          'per_page': perPage,
          'page': page,
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
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
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

  Future<void> getExpiryReport(BuildContext context, {String? storeId}) async {
    try {
      isExpiryLoading = true;
      expiryModel = null;
      notifyListeners();

      final dio = Dio();
      final response = await dio.get(
        '${Constants.baseUrl}inventory_expiry.php',
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
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
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching expiry report: $e');
    } finally {
      isExpiryLoading = false;
      notifyListeners();
    }
  }

  // ================================================== Dashboard ==================================================

  bool isDashboardLoading = false;
  InventoryDashboardModel? dashboardModel;

  Future<void> getDashboard(BuildContext context, {String? storeId}) async {
    try {
      isDashboardLoading = true;
      dashboardModel = null;
      notifyListeners();

      final dio = Dio();
      final response = await dio.get(
        '${Constants.baseUrl}inventory_dashboard.php',
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
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
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching inventory dashboard: $e');
    } finally {
      isDashboardLoading = false;
      notifyListeners();
    }
  }
}
