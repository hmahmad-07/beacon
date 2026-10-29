import 'package:dio/dio.dart';

import '../constants/constants.dart';
import '../models/AlAzeem/al_azeem_checklist_models.dart';
import '../models/Sales/sales_common.dart';
import 'api_client.dart';

/// Thrown for API-level failures (`error != 0`) and transport failures.
/// `toString()` is the message to show the user.
class AlAzeemChecklistApiException implements Exception {
  const AlAzeemChecklistApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Read-only calls to the Al-Azeem checklist admin endpoints. Every call uses
/// the Centrex bearer token, the same as the other modules.
class AlAzeemChecklistApi {
  AlAzeemChecklistApi._();

  /// Dashboard totals for the window selected by `grain` and `date`.
  static Future<ChecklistCounts> dashboard(Map<String, dynamic> query) async {
    final body = await _get('al_azeem_checklist_dashboard.php', query);
    final data = salesMap(body['data']);
    return ChecklistCounts.fromJson(salesMap(data['summary']));
  }

  /// One page of submissions for the window. `page` and `per_page` are set
  /// by the caller.
  static Future<ChecklistPage> list(Map<String, dynamic> query) async {
    final body = await _get('al_azeem_checklists.php', query);
    return ChecklistPage.fromEnvelope(body);
  }

  /// One submission with all of its tasks. The server returns HTTP 404 when
  /// the submission does not exist.
  static Future<ChecklistDetail> detail(int submissionId) async {
    final body = await _get('al_azeem_checklist_detail.php', {
      'submission_id': submissionId,
    });
    return ChecklistDetail.fromJson(salesMap(body['data']));
  }

  static Future<Map<String, dynamic>> _get(
    String file,
    Map<String, dynamic> query,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        '${Constants.baseUrl}$file',
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
        throw const AlAzeemChecklistApiException(
          'Unexpected response from the server.',
        );
      }
      final map = Map<String, dynamic>.from(body);
      if (salesInt(map['error']) != 0) {
        throw AlAzeemChecklistApiException(
          salesString(map['error_msg']) ?? 'Could not load checklists.',
        );
      }
      return map;
    } on DioException catch (e) {
      throw AlAzeemChecklistApiException(_dioMessage(e));
    }
  }

  static String _dioMessage(DioException e) {
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
        return 'Something went wrong while loading checklists.';
    }
  }
}
