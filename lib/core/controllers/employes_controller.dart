// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/constants.dart';
import 'package:intl/intl.dart';
import '../models/emp_working_detail_model.dart';
import '../models/employes_model.dart';
import '../models/external_client_model.dart';
import '../utils/utils.dart';

class EmployesController extends ChangeNotifier {
  // ============================================= Employee List =============================================

  bool isLoading = false;
  EmployesModel? employesModel;

  Future<void> fetchEmployees(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final dio = Dio();
      final response = await dio.get('${Constants.baseUrl}tsm_users_list.php');

      if (response.statusCode == 200) {
        employesModel = EmployesModel.fromJson(response.data);

        if (employesModel?.error == 0) {
          log("Employees Fetched Successfully: ${employesModel?.totalUsers}");
        } else {
          if (context.mounted) {
            Utils.showSnackBar(
              context,
              employesModel?.errorMsg ?? 'Failed to load employees',
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
      log('Dio error: ${e.message}');
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          e.response?.data?['error_msg'] ?? 'Network error. Please try again.',
        );
      }
    } catch (e) {
      log('Unexpected error: $e');
      if (context.mounted) {
        Utils.showSnackBar(context, 'Something went wrong. Please try again.');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================================> Filtering Logic

  List<String> get departments {
    if (employesModel?.users == null) return [];
    final depts = employesModel!.users!
        .map((u) {
          final d = u.department?.trim() ?? "";
          if (d.isEmpty) return "Others";
          if (d.toLowerCase().contains("sales") ||
              d.toLowerCase().contains("marketing")) {
            return "Sales & Marketing";
          }
          return d;
        })
        .toSet()
        .toList();

    final priority = [
      "management",
      "administration",
      "human resource",
      "it",
      "internal audit",
      "account",
      "finance",
      "sales",
      "marketing",
      "production",
      "purchase",
      "supply chain",
      "main store",
      "others",
    ];

    depts.sort((a, b) {
      final aL = a.toLowerCase();
      final bL = b.toLowerCase();

      int getScore(String s) {
        for (int i = 0; i < priority.length; i++) {
          if (s.contains(priority[i])) return i;
        }
        return priority.length;
      }

      return getScore(aL).compareTo(getScore(bL));
    });

    return depts;
  }

  List<User> getEmployeesByDept(String dept) {
    if (employesModel?.users == null) return [];
    return employesModel!.users!.where((u) {
      final d = u.department?.trim() ?? "";
      final normalizedDept = d.isEmpty
          ? "Others"
          : (d.toLowerCase().contains("sales") ||
                d.toLowerCase().contains("marketing"))
          ? "Sales & Marketing"
          : d;
      return normalizedDept == dept;
    }).toList();
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

      final dio = Dio();
      final url =
          '${Constants.baseUrl}tsm_daily_report.php?is_external_client=1&date=$targetDate';
      log("Fetching External Report: $url");

      final response = await dio.get(url);

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
      final dio = Dio();
      final url =
          '${Constants.baseUrl}tsm_daily_report.php?user_id=$userId&date=$targetDate';
      log("Fetching Working Details: $url");

      final response = await dio.get(url);

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
    final dio = Dio();
    final targetDate = DateFormat('yyyy-MM-dd').format(date);

    for (int i = 0; i < users.length; i++) {
      try {
        onProgress(i + 1, users.length);
        final url =
            '${Constants.baseUrl}tsm_daily_report.php?user_id=${users[i].userId}&date=$targetDate';
        final response = await dio.get(url);

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
    final dio = Dio();

    final totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      try {
        onProgress(i + 1, totalDays);
        final targetDate = DateFormat('yyyy-MM-dd').format(currentDate);
        final url =
            '${Constants.baseUrl}tsm_daily_report.php?user_id=$userId&date=$targetDate';
        final response = await dio.get(url);

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
    final dio = Dio();

    final totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      try {
        onProgress(i + 1, totalDays);
        final targetDate = DateFormat('yyyy-MM-dd').format(currentDate);
        final url =
            '${Constants.baseUrl}tsm_daily_report.php?is_external_client=1&date=$targetDate';
        final response = await dio.get(url);

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

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Address not found';
      }

      final place = placemarks.first;

      return [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
    } catch (e) {
      return 'Unable to get address';
    }
  }
}
