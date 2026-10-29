import 'package:flutter/foundation.dart';

import '../models/Sales/sales_common.dart';

/// The period (calendar month, date range or single day) that every Sales
/// screen shows. It is provided above the navigator, so a period chosen on
/// one screen reaches the Sales overview and every report that is open.
class SalesPeriodController extends ChangeNotifier {
  SalesPeriodController() : _filters = _currentMonth();

  SalesFilters _filters;

  SalesFilters get filters => _filters;

  static SalesFilters _currentMonth() {
    final now = DateTime.now();
    return SalesFilters(month: now.month, year: now.year);
  }

  /// Sets the period. Only the period fields are kept. Salesperson, booker,
  /// client and SKU filters belong to the screen that set them.
  void setPeriod(SalesFilters next) {
    _filters = SalesFilters(
      month: next.month,
      year: next.year,
      date: next.date,
      dateFrom: next.dateFrom,
      dateTo: next.dateTo,
    );
    notifyListeners();
  }
}
