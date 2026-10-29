import 'package:flutter/foundation.dart';

/// The period every Al-Azeem checklist screen shows: a grain (day, week or
/// month) and one date inside it. It is provided above the navigator, the
/// same way the Sales period is, so a change on one screen reaches the others.
class ChecklistPeriodController extends ChangeNotifier {
  ChecklistPeriodController()
    : _grain = 'day',
      _date = dateOnly(DateTime.now());

  String _grain;
  DateTime _date;

  /// 'day', 'week' or 'month'.
  String get grain => _grain;

  /// Any date inside the period.
  DateTime get date => _date;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void setPeriod({required String grain, required DateTime date}) {
    final next = dateOnly(date);
    if (grain == _grain && next == _date) return;
    _grain = grain;
    _date = next;
    notifyListeners();
  }

  /// Moves the period one step back (-1) or forward (+1).
  void shift(int step) {
    if (_grain == 'week') {
      _date = DateTime(_date.year, _date.month, _date.day + 7 * step);
    } else if (_grain == 'month') {
      _date = DateTime(_date.year, _date.month + step, 1);
    } else {
      _date = DateTime(_date.year, _date.month, _date.day + step);
    }
    notifyListeners();
  }
}
