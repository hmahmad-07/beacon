import 'package:flutter/foundation.dart';

import '../models/AlAzeem/al_azeem_checklist_models.dart';
import '../network/al_azeem_checklist_api.dart';
import 'al_azeem_checklist_period_controller.dart';

/// Loads the Al-Azeem checklist data for the shared period.
///
/// Each screen creates its own instance and loads only what it shows: the
/// hub and the dashboard call [loadDashboard], the submissions list calls
/// [loadList]. When the period changes, the loads that were requested run
/// again. A request sequence number keeps an older response from overwriting
/// a newer one.
class AlAzeemChecklistController extends ChangeNotifier {
  AlAzeemChecklistController({required this.period}) {
    period.addListener(_onPeriodChanged);
  }

  final ChecklistPeriodController period;

  static const perPage = 25;

  /// Role filter for the submissions list. Null means all roles.
  String? role;

  ChecklistCounts? dashboard;
  bool dashboardLoading = false;
  String? dashboardError;

  ChecklistPage? page;
  int listPage = 1;
  bool listLoading = false;
  String? listError;

  bool _dashboardRequested = false;
  bool _listRequested = false;
  int _dashboardSeq = 0;
  int _listSeq = 0;

  @override
  void dispose() {
    period.removeListener(_onPeriodChanged);
    super.dispose();
  }

  static String _ymd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Map<String, dynamic> get _query => {
    'grain': period.grain,
    'date': _ymd(period.date),
    if (role != null) 'role': role,
  };

  Future<void> loadDashboard() {
    _dashboardRequested = true;
    return _fetchDashboard();
  }

  Future<void> loadList() {
    _listRequested = true;
    return _fetchList();
  }

  /// Shows page [number]. The list shows one loader until the page arrives.
  Future<void> loadPage(int number) {
    _listRequested = true;
    listPage = number;
    page = null;
    listError = null;
    notifyListeners();
    return _fetchList();
  }

  void setRole(String? value) {
    if (value == role) return;
    role = value;
    listPage = 1;
    _reload();
  }

  void _onPeriodChanged() {
    listPage = 1;
    _reload();
  }

  /// Drops the data on screen and loads again. The screen shows its loader in
  /// the meantime, so old figures never sit under a new period.
  void _reload() {
    if (_dashboardRequested) {
      dashboard = null;
      dashboardError = null;
      notifyListeners();
      _fetchDashboard();
    }
    if (_listRequested) {
      page = null;
      listError = null;
      notifyListeners();
      _fetchList();
    }
  }

  Future<void> _fetchDashboard() async {
    final seq = ++_dashboardSeq;
    dashboardLoading = true;
    dashboardError = null;
    notifyListeners();
    try {
      final data = await AlAzeemChecklistApi.dashboard(_query);
      if (seq != _dashboardSeq) return;
      dashboard = data;
    } catch (e) {
      if (seq != _dashboardSeq) return;
      dashboardError = _messageOf(e);
    } finally {
      if (seq == _dashboardSeq) {
        dashboardLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchList() async {
    final seq = ++_listSeq;
    listLoading = true;
    listError = null;
    notifyListeners();
    try {
      final result = await AlAzeemChecklistApi.list({
        ..._query,
        'per_page': perPage,
        'page': listPage,
      });
      if (seq != _listSeq) return;
      page = result;
    } catch (e) {
      if (seq != _listSeq) return;
      listError = _messageOf(e);
    } finally {
      if (seq == _listSeq) {
        listLoading = false;
        notifyListeners();
      }
    }
  }

  static String _messageOf(Object error) {
    if (error is AlAzeemChecklistApiException) return error.message;
    return 'Could not read the checklist data.';
  }
}
