// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nominatim_flutter/model/request/request.dart';
import 'package:nominatim_flutter/model/response/response.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import '../constants/constants.dart';
import '../network/api_client.dart';
import 'package:intl/intl.dart';
import '../models/Employees/emp_working_detail_model.dart';
import '../models/Employees/employes_model.dart';
import '../models/Employees/external_client_model.dart';
import '../utils/utils.dart';

class EmployesController extends ChangeNotifier {
  // ============================================= Sites Detail =============================================

  bool isLoading = false;
  SitesDetailModel? sitesDetailModel;

  SitesDetailModel? get employesModel => sitesDetailModel;

  // True when the last getSites attempt failed and there's nothing to show,
  // so HomeView can offer a retry instead of an empty rail.
  bool sitesLoadFailed = false;
  Future<void>? _sitesInFlight;

  /// Splash, login and the reconnect listener can all call this at once;
  /// they share one request instead of racing each other.
  Future<void> getSites(BuildContext context, {String? shopId}) {
    return _sitesInFlight ??= _getSites(
      context,
      shopId: shopId,
    ).whenComplete(() => _sitesInFlight = null);
  }

  Future<void> _getSites(BuildContext context, {String? shopId}) async {
    var succeeded = false;
    try {
      isLoading = true;
      sitesLoadFailed = false;
      notifyListeners();

      final dio = ApiClient.dio;
      final Map<String, dynamic> queryParams = {};
      if (shopId != null && shopId.isNotEmpty && shopId != 'all') {
        queryParams['shop_id'] = shopId;
      }

      final response = await dio.get(
        '${Constants.baseUrl}shop_departments.php',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );
      if (response.statusCode == 200) {
        sitesDetailModel = SitesDetailModel.fromJson(response.data);

        if (sitesDetailModel?.error == 0) {
          succeeded = true;
          log("Sites Fetched Successfully: ${sitesDetailModel?.totalShops}");
          _prefetchActiveEmployeeCounts();
        } else {
          if (context.mounted) {
            Utils.showSnackBar(
              context,
              sitesDetailModel?.errorMsg ?? 'Failed to load sites',
            );
          }
        }
      } else {
        if (context.mounted) {
          Utils.showSnackBar(
            context,
            'Server Error: ${response.statusCode} - ${response.statusMessage}',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error (${e.type}): ${e.message}');
      // response.data can be an HTML/plain-text error page, not a map.
      final data = e.response?.data;
      final serverMsg = data is Map ? data['error_msg']?.toString() : null;
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          serverMsg ??
              'Could not reach the server. Check your connection and retry.',
        );
      }
    } catch (e) {
      log('Unexpected error: $e');
      if (context.mounted) {
        Utils.showSnackBar(context, 'Something went wrong. Please try again.');
      }
    } finally {
      isLoading = false;
      // Keep showing previously loaded shops on a failed refresh.
      sitesLoadFailed = !succeeded && shops.isEmpty;
      notifyListeners();
    }
  }

  // ============================================= Active Count Cache =============================================

  // Key: "deptId" or "deptId_shopId"
  final Map<String, int> _activeCountCache = {};

  int getActiveCount(dynamic deptId, {String? shopId}) {
    final key = shopId != null && shopId.isNotEmpty && shopId != 'all'
        ? '${deptId}_$shopId'
        : '$deptId';
    return _activeCountCache[key] ?? -1; // -1 means not yet fetched
  }

  Future<void> _prefetchActiveEmployeeCounts() async {
    if (sitesDetailModel?.shops == null) return;
    final dio = ApiClient.dio;
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${Constants.token}',
    };

    for (var shop in sitesDetailModel!.shops!) {
      if (shop.departments == null) continue;
      for (var dept in shop.departments!) {
        if (dept.departmentId == null) continue;
        try {
          final queryParams = <String, dynamic>{'dept_id': dept.departmentId};
          if (shop.shopId != null && shop.shopId!.isNotEmpty) {
            queryParams['shop_id'] = shop.shopId;
          }

          final response = await dio.get(
            '${Constants.baseUrl}employees.php',
            queryParameters: queryParams,
            options: Options(headers: headers),
          );

          if (response.statusCode == 200) {
            final model = DepartmentEmployeesModel.fromJson(response.data);
            if (model.error == 0 && model.employees != null) {
              final activeCount = model.employees!
                  .where((e) => e.status?.toUpperCase() == 'A')
                  .length;
              final key = shop.shopId != null && shop.shopId!.isNotEmpty
                  ? '${dept.departmentId}_${shop.shopId}'
                  : '${dept.departmentId}';
              _activeCountCache[key] = activeCount;
            }
          }
        } catch (e) {
          log('Prefetch active count error for dept ${dept.departmentId}: $e');
        }
      }
    }
    notifyListeners();
  }

  // ============================================= Department Employees =============================================

  bool isDeptEmployeesLoading = false;
  DepartmentEmployeesModel? departmentEmployeesModel;

  Future<void> fetchDepartmentEmployees(
    dynamic deptId, [
    BuildContext? context,
    String? shopId,
  ]) async {
    try {
      isDeptEmployeesLoading = true;
      departmentEmployeesModel = null;
      notifyListeners();

      final dio = ApiClient.dio;
      final Map<String, dynamic> queryParams = {'dept_id': deptId};
      if (shopId != null && shopId.isNotEmpty && shopId != 'all') {
        queryParams['shop_id'] = shopId;
      }

      final response = await dio.get(
        '${Constants.baseUrl}employees.php',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        departmentEmployeesModel = DepartmentEmployeesModel.fromJson(
          response.data,
        );
        if (departmentEmployeesModel?.error == 0) {
          log(
            "Department Employees Fetched Successfully: ${departmentEmployeesModel?.totalEmployees}",
          );
        } else if (context != null && context.mounted) {
          Utils.showSnackBar(
            context,
            departmentEmployeesModel?.errorMsg ?? 'Failed to load employees',
          );
        }
      }
    } on DioException catch (e) {
      log('Dio error fetching department employees: ${e.message}');
      if (context != null && context.mounted) {
        Utils.showSnackBar(
          context,
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error fetching department employees: $e');
    } finally {
      isDeptEmployeesLoading = false;
      notifyListeners();
    }
  }

  int? getDepartmentIdByName(String deptName) {
    if (sitesDetailModel?.shops != null) {
      for (var shop in sitesDetailModel!.shops!) {
        if (shop.departments != null) {
          for (var d in shop.departments!) {
            if (d.departmentName?.toLowerCase().trim() ==
                deptName.toLowerCase().trim()) {
              return d.departmentId;
            }
          }
        }
      }
    }
    return null;
  }

  // =============================================> Filtering & Helper Logic

  List<Shop> get shops => sitesDetailModel?.shops ?? [];

  List<String> get departments {
    if (sitesDetailModel?.shops == null) return [];
    final set = <String>{};
    for (var shop in sitesDetailModel!.shops!) {
      if (shop.departments != null) {
        for (var dept in shop.departments!) {
          if (dept.departmentName != null &&
              dept.departmentName!.trim().isNotEmpty) {
            set.add(dept.departmentName!.trim());
          }
        }
      }
    }
    return set.toList();
  }

  List<String> get allDepartments => departments;

  List<User> getEmployeesByDept(String dept, {String? shopId}) {
    if (departmentEmployeesModel?.employees != null) {
      var list = departmentEmployeesModel!.employees!;
      // Only show active employees (status == "A")
      list = list.where((e) => e.status?.toUpperCase() == 'A').toList();
      if (shopId != null && shopId.isNotEmpty && shopId != 'all') {
        list = list
            .where(
              (e) =>
                  e.shopId?.toLowerCase().trim() == shopId.toLowerCase().trim(),
            )
            .toList();
      }
      final currentDeptName = departmentEmployeesModel?.departmentName ?? dept;
      return list.map((e) => e.toUser(currentDeptName)).toList();
    }
    return [];
  }

  // ============================================= External Clients Report =============================================

  ExternalClientReportModel? externalReport;
  bool isExternalReportLoading = false;
  DateTime externalReportDate = DateTime.now();

  Future<void> fetchExternalReport(
    BuildContext context, {
    DateTime? date,
  }) async {
    try {
      isExternalReportLoading = true;
      notifyListeners();

      final targetDate = date != null
          ? DateFormat('yyyy-MM-dd').format(date)
          : DateFormat('yyyy-MM-dd').format(externalReportDate);

      final dio = ApiClient.dio;
      final url =
          '${Constants.baseUrl}tsm_daily_report.php?is_external_client=1&date=$targetDate';
      log("Fetching External Report: $url");

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        externalReport = ExternalClientReportModel.fromJson(response.data);
      } else {
        if (context.mounted) {
          Utils.showSnackBar(context, 'Server Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      log('Error external report: $e');
      if (context.mounted) {
        Utils.showSnackBar(context, 'Failed to load external report');
      }
    } finally {
      isExternalReportLoading = false;
      notifyListeners();
    }
  }

  void updateExternalReportDate(BuildContext context, DateTime date) {
    externalReportDate = date;
    fetchExternalReport(context);
  }

  // ============================================= Employee Working Detail =============================================

  EmployesWorkingDetailModel? workingDetailModel;
  EmployesWorkingDetailModel? get workingDetail => workingDetailModel;
  bool isWorkingDetailLoading = false;
  DateTime selectedDate = DateTime.now();

  List<DateTime> get dateRange {
    final List<DateTime> dates = [];
    final now = DateTime.now();
    for (int i = 0; i < 45; i++) {
      dates.add(now.subtract(Duration(days: i)));
    }
    return dates;
  }

  Future<void> fetchWorkingDetails(
    BuildContext context,
    String userId, {
    String? date,
  }) async {
    try {
      isWorkingDetailLoading = true;
      notifyListeners();

      final targetDate = date ?? DateFormat('yyyy-MM-dd').format(selectedDate);
      final dio = ApiClient.dio;
      final url =
          '${Constants.baseUrl}tsm_daily_report.php?user_id=$userId&date=$targetDate';
      log("URL: $url");

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Constants.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        workingDetailModel = EmployesWorkingDetailModel.fromJson(response.data);
        if (workingDetailModel?.error == 0) {
          log("Working Details Fetched Successfully for User $userId");
        } else {
          log("API Status: ${workingDetailModel?.errorMsg}");
        }
      } else {
        if (context.mounted) {
          Utils.showSnackBar(context, 'Server Error: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      log('Dio error: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(context, 'Network error. Please try again.');
      }
    } catch (e) {
      log('Unexpected error working details: $e');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          'Something went wrong while fetching details',
        );
      }
    } finally {
      isWorkingDetailLoading = false;
      notifyListeners();
    }
  }

  void updateSelectedDate(BuildContext context, String userId, DateTime date) {
    selectedDate = date;
    fetchWorkingDetails(context, userId);
  }

  // ============================================= Master Audit Batch Fetching =============================================

  Future<List<EmployesWorkingDetailModel>> fetchMasterAuditData(
    BuildContext context,
    List<User> users,
    DateTime date,
    Function(int progress, int total) onProgress,
  ) async {
    List<EmployesWorkingDetailModel> reports = [];
    final dio = ApiClient.dio;
    final targetDate = DateFormat('yyyy-MM-dd').format(date);

    for (int i = 0; i < users.length; i++) {
      try {
        onProgress(i + 1, users.length);
        final url =
            '${Constants.baseUrl}tsm_daily_report.php?user_id=${users[i].userId}&date=$targetDate';
        final response = await dio.get(
          url,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${Constants.token}',
            },
          ),
        );

        if (response.statusCode == 200) {
          reports.add(EmployesWorkingDetailModel.fromJson(response.data));
        } else {
          reports.add(
            EmployesWorkingDetailModel(
              error: 1,
              errorMsg: "Server Error",
              visits: [],
              date: date,
              totalVisits: 0,
            ),
          );
        }
      } catch (e) {
        reports.add(
          EmployesWorkingDetailModel(
            error: 1,
            errorMsg: e.toString(),
            visits: [],
            date: date,
            totalVisits: 0,
          ),
        );
      }
    }
    return reports;
  }

  Future<List<EmployesWorkingDetailModel>> fetchMonthlyData(
    BuildContext context,
    String userId,
    DateTime startDate,
    DateTime endDate,
    Function(int progress, int total) onProgress,
  ) async {
    final List<EmployesWorkingDetailModel> reports = [];
    final dio = ApiClient.dio;

    final totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      try {
        onProgress(i + 1, totalDays);
        final targetDate = DateFormat('yyyy-MM-dd').format(currentDate);
        final url =
            '${Constants.baseUrl}tsm_daily_report.php?user_id=$userId&date=$targetDate';
        final response = await dio.get(
          url,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${Constants.token}',
            },
          ),
        );

        if (response.statusCode == 200) {
          final r = EmployesWorkingDetailModel.fromJson(response.data);
          // Only add if there is some activity
          if (r.visits.isNotEmpty || r.checkin != null || r.checkout != null) {
            reports.add(r);
          }
        }
      } catch (e) {
        log("Error fetching day ${i + 1}: $e");
      }
    }
    return reports;
  }

  Future<List<ExternalClientReportModel>> fetchExternalMonthlyData(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
    Function(int progress, int total) onProgress,
  ) async {
    final List<ExternalClientReportModel> reports = [];
    final dio = ApiClient.dio;

    final totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      try {
        onProgress(i + 1, totalDays);
        final targetDate = DateFormat('yyyy-MM-dd').format(currentDate);
        final url =
            '${Constants.baseUrl}tsm_daily_report.php?is_external_client=1&date=$targetDate';
        final response = await dio.get(
          url,
          options: Options(
            headers: {'Accept': 'application/json', 'Bearer': Constants.token},
          ),
        );

        if (response.statusCode == 200) {
          final r = ExternalClientReportModel.fromJson(response.data);
          if (r.orders.isNotEmpty) {
            reports.add(r);
          }
        }
      } catch (e) {
        log("Error fetching external day ${i + 1}: $e");
      }
    }
    return reports;
  }

  // ============================================= Map & Navigation States =============================================

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  final Set<Polygon> polygons = {};

  void clearMapData() {
    markers.clear();
    polylines.clear();
    polygons.clear();
    notifyListeners();
  }

  void updateMarkers(Set<Marker> newMarkers) {
    markers.clear();
    markers.addAll(newMarkers);
    notifyListeners();
  }

  void updatePolylines(Set<Polyline> newPolylines) {
    polylines.clear();
    polylines.addAll(newPolylines);
    notifyListeners();
  }

  void updatePolygons(Set<Polygon> newPolygons) {
    polygons.clear();
    polygons.addAll(newPolygons);
    notifyListeners();
  }

  bool isLoadingRoutes = false;
  void setLoadingRoutes(bool val) {
    isLoadingRoutes = val;
    notifyListeners();
  }

  bool isSheetVisible = false;
  void setSheetVisible(bool val) {
    isSheetVisible = val;
    notifyListeners();
  }

  void toggleSheetVisible() {
    isSheetVisible = !isSheetVisible;
    notifyListeners();
  }

  bool isNavigating = false;
  void setNavigating(bool val) {
    isNavigating = val;
    notifyListeners();
  }

  static bool _isPlusCode(String value) {
    return RegExp(
      r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}$',
      caseSensitive: false,
    ).hasMatch(value.trim());
  }

  static bool _nominatimConfigured = false;

  static void _ensureNominatimConfigured() {
    if (_nominatimConfigured) return;
    NominatimFlutter.instance.configureNominatim(
      userAgent: 'PaaniFieldAuditApp/1.0',
    );
    _nominatimConfigured = true;
  }

  /// Builds an English, most-specific-first address from a Nominatim
  /// response, or null when it has nothing finer than city/province.
  static String? _formatNominatimAddress(NominatimResponse response) {
    final addr = response.address;
    if (addr == null) return null;

    String? field(String key) {
      final v = addr[key]?.toString().trim();
      return (v == null || v.isEmpty || _isPlusCode(v)) ? null : v;
    }

    final houseNumber = field('house_number');
    final road = field('road');
    final streetLine = [houseNumber, road].where((e) => e != null).join(', ');

    final neighbourhood = field('neighbourhood') ?? field('quarter');
    final area = field('suburb') ?? field('city_district');
    final city =
        field('city') ??
        field('town') ??
        field('village') ??
        field('municipality');
    final state = field('state');

    final hasFineDetail =
        streetLine.isNotEmpty || neighbourhood != null || area != null;
    if (!hasFineDetail) return null;

    final parts = [
      streetLine.isNotEmpty ? streetLine : null,
      neighbourhood,
      if (area != neighbourhood) area,
      if (city != area && city != neighbourhood) city,
      state,
    ].where((e) => e != null && e.trim().isNotEmpty).toList();

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Resolves an address for [latitude]/[longitude]: tries the device's
  /// fast native geocoder first, and only falls back to a single (slower)
  /// Nominatim/OpenStreetMap lookup when that result is too generic
  /// (nothing finer than city/province).
  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    String? nativeAddress;
    bool hasFineDetail = false;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 6));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street;
        hasFineDetail =
            (street != null &&
                street.trim().isNotEmpty &&
                !_isPlusCode(street)) ||
            (place.subLocality != null && place.subLocality!.trim().isNotEmpty);

        nativeAddress = [
          (street != null && !_isPlusCode(street)) ? street : null,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
        if (nativeAddress.isEmpty) nativeAddress = null;
      }
    } catch (_) {
      // fall through to Nominatim below
    }

    if (hasFineDetail && nativeAddress != null) return nativeAddress;

    _ensureNominatimConfigured();
    try {
      final response = await NominatimFlutter.instance
          .reverse(
            reverseRequest: ReverseRequest(
              lat: latitude,
              lon: longitude,
              addressDetails: true,
            ),
            language: 'en',
          )
          .timeout(const Duration(seconds: 8));
      final better = _formatNominatimAddress(response);
      if (better != null) return better;
    } catch (_) {
      // keep whatever the native geocoder returned, if anything
    }

    return nativeAddress ?? 'Address not found';
  }
}
