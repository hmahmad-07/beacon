import 'dart:typed_data';
import 'package:beacon/core/models/Employees/emp_working_detail_model.dart';
import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nominatim_flutter/model/request/request.dart';
import 'package:nominatim_flutter/model/response/response.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/Employees/external_client_model.dart';

/// Builds the field activity PDF reports:
/// - the daily department report (every employee of a department for a day),
/// - the employee report for a month or a date range,
/// - the external client orders report for a month or a date range.
///
/// Every table uses fixed column proportions, so the header and all rows
/// line up, and the header row repeats on each new page. Single-line cells
/// scale down to fit their column instead of overflowing.
class PdfReportGenerator {
  /// Converts a site accent (`Color.toARGB32()`) to the report brand colour.
  static PdfColor brandColorFrom(int argb) => PdfColor.fromInt(argb);

  // ─────────────────────────────────────────────────────────────── Reports

  /// Every employee of [department] for one [date]: a team overview, each
  /// employee's visits with notes, external orders and a department summary.
  static Future<Uint8List> generateDailyMasterReport({
    required List<User> users,
    required List<EmployesWorkingDetailModel> reports,
    required DateTime date,
    required String department,
    ExternalClientReportModel? externalReport,
    String? brandName,
    PdfColor? brandColor,
  }) async {
    final t = _PdfTheme(brandName ?? _siteOf(users), brandColor);
    final isSales =
        _isSalesDept(department) ||
        users.any((u) => _isSalesDept(u.department ?? ''));

    final entries = <_UserDay>[
      for (int i = 0; i < users.length && i < reports.length; i++)
        _UserDay(users[i], reports[i]),
    ];

    final addressByCoord = await _resolveVisitAddresses(
      reports.expand((r) => r.visits),
    );

    final present = entries.where((e) => e.stats.present).length;
    final total = _DayStats.sum([for (final e in entries) e.stats]);
    final longDate = DateFormat('EEEE, dd MMM yyyy').format(date);
    final hasExternal =
        externalReport != null && externalReport.orders.isNotEmpty;

    final pdf = pw.Document(
      title: 'Daily Field Activity - ${_title(department)} - $longDate',
      author: t.brandName,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _pageMargin,
        maxPages: 500,
        header: (context) => _pageHeader(
          t,
          'Daily Field Activity',
          '${_title(department)} · ${DateFormat('dd MMM yyyy').format(date)}',
        ),
        footer: (context) => _pageFooter(t, context),
        build: (context) => [
          _titleBlock(
            t,
            title: 'Daily Field Activity Report',
            subtitle:
                '${_title(department)} department · every employee\'s '
                'attendance, visits and orders for the day',
            meta: [
              _Meta('Report date', longDate),
              _Meta('Department', _title(department)),
              _Meta('Team size', '${entries.length} employees'),
              _Meta('Generated', t.stamp),
            ],
          ),
          pw.SizedBox(height: 10),
          _kpiStrip(t, [
            _Kpi('Team', '${entries.length}'),
            _Kpi('Present', '$present', color: _green),
            _Kpi('Absent', '${entries.length - present}', color: _red),
            _Kpi('Visits', '${total.visits}'),
            if (isSales) ...[
              _Kpi('Productive', '${total.productive}', color: _green),
              _Kpi('Non-productive', '${total.nonProductive}', color: _red),
              _Kpi('Booked value', 'PKR ${_money(total.value)}'),
            ] else ...[
              _Kpi('Avg visits', _avg(total.visits, present)),
              _Kpi('Time in shops', _dur(total.staySeconds)),
            ],
          ]),
          pw.SizedBox(height: 16),
          _sectionTitle(
            t,
            'Team overview',
            trailing: '${entries.length} employees · $longDate',
          ),
          _teamOverviewTable(t, entries, isSales: isSales),
          pw.SizedBox(height: 18),
          for (final (index, e) in entries.indexed)
            ..._userDaySection(
              t,
              e,
              index: index + 1,
              isSales: isSales,
              addressByCoord: addressByCoord,
              lead: [
                if (index == 0)
                  _sectionTitle(t, 'Employee activity', trailing: longDate),
              ],
            ),
          if (externalReport != null && externalReport.orders.isNotEmpty) ...[
            ..._keepTogether([
              _sectionTitle(
                t,
                'External client orders',
                trailing: '${externalReport.orders.length} orders · $longDate',
              ),
              _ordersTable(t, externalReport.orders),
              pw.SizedBox(height: 6),
              _notes(
                t,
                'External orders notes',
                _ordersNotes(externalReport.orders),
              ),
            ], _ordersHeight(externalReport.orders)),
            pw.SizedBox(height: 18),
          ],
          ..._departmentSummary(
            t,
            entries,
            isSales: isSales,
            longDate: longDate,
            external: hasExternal ? externalReport : null,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// One employee over a month or a date range: a daily overview, every
  /// day's visits with day notes, and the period summary at the end.
  static Future<Uint8List> generateMonthlyEmployeeReport({
    required User user,
    required List<EmployesWorkingDetailModel> reports,
    required String dateRangeText,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? brandName,
    PdfColor? brandColor,
  }) async {
    final t = _PdfTheme(brandName ?? _siteOf([user]), brandColor);
    final isSales = _isSalesDept(user.department ?? '');

    final days = [...reports]..sort((a, b) => a.date.compareTo(b.date));
    final stats = [for (final r in days) _DayStats.of(r)];
    final total = _DayStats.sum(stats);
    final activeDays = stats.where((s) => s.present).length;

    final addressByCoord = await _resolveVisitAddresses(
      days.expand((r) => r.visits),
    );

    final name = (user.userName ?? '').trim().isEmpty
        ? 'Employee'
        : user.userName!.trim();

    final pdf = pw.Document(
      title: 'Employee Activity - $name - $dateRangeText',
      author: t.brandName,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _pageMargin,
        maxPages: 500,
        header: (context) =>
            _pageHeader(t, 'Employee Activity', '$name · $dateRangeText'),
        footer: (context) => _pageFooter(t, context),
        build: (context) => [
          _titleBlock(
            t,
            title: name,
            subtitle: [
              if ((user.empCode ?? '').trim().isNotEmpty) user.empCode!.trim(),
              if ((user.designation ?? '').trim().isNotEmpty)
                user.designation!.trim(),
              'Employee activity report',
            ].join('  ·  '),
            initials: _initials(name),
            meta: [
              _Meta('Period', dateRangeText),
              _Meta('Department', _title(user.department ?? '-')),
              _Meta(
                'Site',
                (user.shopName ?? '').trim().isEmpty
                    ? t.brandName
                    : user.shopName!.trim(),
              ),
              _Meta('Generated', t.stamp),
            ],
          ),
          pw.SizedBox(height: 10),
          _kpiStrip(t, [
            _Kpi('Days present', '$activeDays'),
            _Kpi('Visits', '${total.visits}'),
            if (isSales) ...[
              _Kpi('Productive', '${total.productive}', color: _green),
              _Kpi('Non-productive', '${total.nonProductive}', color: _red),
              _Kpi('Productivity', _percent(total.productive, total.visits)),
              _Kpi('Booked value', 'PKR ${_money(total.value)}'),
            ] else ...[
              _Kpi('Avg visits / day', _avg(total.visits, activeDays)),
              _Kpi('Time in shops', _dur(total.staySeconds)),
            ],
          ]),
          pw.SizedBox(height: 16),
          _sectionTitle(
            t,
            'Daily overview',
            trailing: '${days.length} days · $dateRangeText',
          ),
          if (days.isEmpty)
            _notice(
              'No records',
              'No attendance or visits were recorded for this period.',
              _amber,
              _amberBg,
            )
          else
            _dailyOverviewTable(t, days, stats, isSales: isSales),
          pw.SizedBox(height: 18),
          if (days.isNotEmpty) ...[
            for (int i = 0; i < days.length; i++)
              ..._daySection(
                t,
                days[i],
                stats[i],
                isSales: isSales,
                addressByCoord: addressByCoord,
                lead: [
                  if (i == 0)
                    _sectionTitle(
                      t,
                      'Day by day activity',
                      trailing: dateRangeText,
                    ),
                ],
              ),
          ],
          ..._periodSummary(
            t,
            days,
            stats,
            isSales: isSales,
            dateRangeText: dateRangeText,
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// External client orders over a month or a date range: a daily overview,
  /// every day's orders with notes, and the period summary at the end.
  static Future<Uint8List> generateMonthlyExternalReport({
    required List<ExternalClientReportModel> reports,
    required String dateRangeText,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? brandName,
    PdfColor? brandColor,
  }) async {
    final t = _PdfTheme(brandName ?? 'PAANI.', brandColor);
    final days = [...reports]
      ..sort((a, b) => _reportDate(a).compareTo(_reportDate(b)));
    final orders = [for (final r in days) ...r.orders];
    final productive = orders.where((o) => o.isProductive).length;
    final value = orders.fold<double>(0, (a, o) => a + _orderValue(o));
    final clients = _clientCount(orders);

    final pdf = pw.Document(
      title: 'External Client Orders - $dateRangeText',
      author: t.brandName,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _pageMargin,
        maxPages: 500,
        header: (context) =>
            _pageHeader(t, 'External Client Orders', dateRangeText),
        footer: (context) => _pageFooter(t, context),
        build: (context) => [
          _titleBlock(
            t,
            title: 'External Client Orders',
            subtitle: 'Orders booked with external clients, day by day',
            meta: [
              _Meta('Period', dateRangeText),
              _Meta('Days with orders', '${days.length}'),
              _Meta('Clients', '$clients'),
              _Meta('Generated', t.stamp),
            ],
          ),
          pw.SizedBox(height: 10),
          _kpiStrip(t, [
            _Kpi('Orders', '${orders.length}'),
            _Kpi('Productive', '$productive', color: _green),
            _Kpi(
              'Non-productive',
              '${orders.length - productive}',
              color: _red,
            ),
            _Kpi('Productivity', _percent(productive, orders.length)),
            _Kpi('Clients', '$clients'),
            _Kpi('Order value', 'PKR ${_money(value)}'),
          ]),
          pw.SizedBox(height: 16),
          _sectionTitle(
            t,
            'Daily overview',
            trailing: '${days.length} days · $dateRangeText',
          ),
          if (days.isEmpty)
            _notice(
              'No orders',
              'No external client orders were recorded for this period.',
              _amber,
              _amberBg,
            )
          else
            _externalOverviewTable(t, days),
          pw.SizedBox(height: 18),
          if (days.isNotEmpty) ...[
            for (final (i, r) in days.indexed)
              ..._externalDaySection(
                t,
                r,
                lead: [
                  if (i == 0)
                    _sectionTitle(
                      t,
                      'Day by day orders',
                      trailing: dateRangeText,
                    ),
                ],
              ),
          ],
          ..._externalSummary(
            t,
            days,
            dateRangeText: dateRangeText,
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ───────────────────────────────────────────── Address lookup (unchanged)

  static String _visitCoordKey(Visit v) =>
      '${v.effectiveLatitude},${v.effectiveLongitude}';

  /// Some geocoders return an Open Location "Plus Code" (e.g. "F438+34F")
  /// as the street when there's no named street nearby.
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
  /// response. Returns null when Nominatim itself has nothing finer than
  /// city/province — in that case there's nothing worth upgrading to.
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

  /// Resolves a display address per unique visit coordinate.
  ///
  /// Pass 1 (fast, parallel): the device's native geocoder resolves every
  /// location at once.
  /// Pass 2 (sequential, throttled): only the locations pass 1 couldn't
  /// pin down beyond city/province are re-checked against OpenStreetMap's
  /// Nominatim service, which often has finer (village/mohalla/road) data
  /// for areas Google's on-device geocoder only knows coarsely. Locations
  /// pass 1 already resolved well are never touched, so most reports stay
  /// as fast as before — only the generic ones pay the extra lookup cost.
  static Future<Map<String, String>> _resolveVisitAddresses(
    Iterable<Visit> visits,
  ) async {
    final Map<String, String> resolved = {};
    final Map<String, Visit> needsEnrichment = {};
    final Set<String> seenKeys = {};
    final List<Future<void>> lookups = [];

    for (final v in visits) {
      final key = _visitCoordKey(v);
      if (!seenKeys.add(key)) continue;

      final lat = double.tryParse(v.effectiveLatitude);
      final lng = double.tryParse(v.effectiveLongitude);
      final fallback = v.address.isNotEmpty ? v.address : 'N/A';

      if (lat == null || lng == null || (lat == 0 && lng == 0)) {
        resolved[key] = fallback;
        continue;
      }

      lookups.add(() async {
        try {
          final placemarks = await placemarkFromCoordinates(
            lat,
            lng,
          ).timeout(const Duration(seconds: 6));
          if (placemarks.isEmpty) {
            resolved[key] = fallback;
            needsEnrichment[key] = v;
            return;
          }
          final place = placemarks.first;
          final street = place.street;
          final hasFineDetail =
              (street != null &&
                  street.trim().isNotEmpty &&
                  !_isPlusCode(street)) ||
              (place.subLocality != null &&
                  place.subLocality!.trim().isNotEmpty);

          final address = [
            (street != null && !_isPlusCode(street)) ? street : null,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

          resolved[key] = address.isNotEmpty ? address : fallback;
          if (!hasFineDetail) needsEnrichment[key] = v;
        } catch (_) {
          resolved[key] = fallback;
          needsEnrichment[key] = v;
        }
      }());
    }

    await Future.wait(lookups);

    if (needsEnrichment.isEmpty) return resolved;

    _ensureNominatimConfigured();

    final entries = needsEnrichment.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final key = entries[i].key;
      final v = entries[i].value;
      final lat = double.tryParse(v.effectiveLatitude);
      final lng = double.tryParse(v.effectiveLongitude);

      if (lat != null && lng != null) {
        try {
          final response = await NominatimFlutter.instance
              .reverse(
                reverseRequest: ReverseRequest(
                  lat: lat,
                  lon: lng,
                  addressDetails: true,
                ),
                language: 'en',
              )
              .timeout(const Duration(seconds: 8));
          final better = _formatNominatimAddress(response);
          if (better != null) resolved[key] = better;
        } catch (_) {
          // Keep whatever pass 1 already resolved for this key.
        }
      }

      if (i != entries.length - 1) {
        await Future.delayed(const Duration(milliseconds: 1100));
      }
    }

    return resolved;
  }

  // ─────────────────────────────────────────────────────── Report sections

  /// One row per employee: attendance, hours and visit counts for the day.
  static pw.Widget _teamOverviewTable(
    _PdfTheme t,
    List<_UserDay> entries, {
    required bool isSales,
  }) {
    final cols = [
      const _Col('#', 0.42, align: pw.Alignment.center),
      const _Col('Employee', 2.5),
      const _Col('Designation', 1.6),
      const _Col('Status', 1.45, align: pw.Alignment.center),
      const _Col('Check-in', 1.05, align: pw.Alignment.center),
      const _Col('Check-out', 1.05, align: pw.Alignment.center),
      const _Col('On duty', 0.95, align: pw.Alignment.center),
      const _Col('Visits', 0.75, align: pw.Alignment.center),
      if (isSales) ...[
        const _Col('Prod.', 0.75, align: pw.Alignment.center),
        const _Col('Non-prod.', 0.85, align: pw.Alignment.center),
        const _Col('Value (PKR)', 1.25, align: pw.Alignment.centerRight),
      ] else
        const _Col('Shop time', 1.1, align: pw.Alignment.center),
    ];

    final rows = <List<pw.Widget>>[
      for (final (i, e) in entries.indexed)
        [
          _txt('${i + 1}', align: pw.Alignment.center, color: _muted),
          _stack(e.user.userName ?? '-', e.user.empCode),
          _txt(e.user.designation ?? '-', color: _muted),
          _statusPill(e.stats),
          _txt(e.stats.checkInText, align: pw.Alignment.center),
          _txt(e.stats.checkOutText, align: pw.Alignment.center),
          _txt(e.stats.hoursText, align: pw.Alignment.center),
          _txt('${e.stats.visits}', align: pw.Alignment.center, bold: true),
          if (isSales) ...[
            _txt(
              '${e.stats.productive}',
              align: pw.Alignment.center,
              color: e.stats.productive > 0 ? _green : _muted,
            ),
            _txt(
              '${e.stats.nonProductive}',
              align: pw.Alignment.center,
              color: e.stats.nonProductive > 0 ? _red : _muted,
            ),
            _txt(
              e.stats.value > 0 ? _money(e.stats.value) : '-',
              align: pw.Alignment.centerRight,
              bold: e.stats.value > 0,
            ),
          ] else
            _txt(
              e.stats.stayCount > 0 ? _dur(e.stats.staySeconds) : '-',
              align: pw.Alignment.center,
            ),
        ],
    ];

    final total = _DayStats.sum([for (final e in entries) e.stats]);
    final present = entries.where((e) => e.stats.present).length;
    return _grid(
      t,
      cols,
      rows,
      totals: [
        _empty,
        _txt('Team total', bold: true),
        _txt('${entries.length} employees', color: _muted),
        _txt('$present present', align: pw.Alignment.center, bold: true),
        _empty,
        _empty,
        _empty,
        _txt('${total.visits}', align: pw.Alignment.center, bold: true),
        if (isSales) ...[
          _txt(
            '${total.productive}',
            align: pw.Alignment.center,
            bold: true,
            color: _green,
          ),
          _txt(
            '${total.nonProductive}',
            align: pw.Alignment.center,
            bold: true,
            color: _red,
          ),
          _txt(
            _money(total.value),
            align: pw.Alignment.centerRight,
            bold: true,
          ),
        ] else
          _txt(_dur(total.staySeconds), align: pw.Alignment.center, bold: true),
      ],
    );
  }

  /// One employee's day in the daily report: header band, visits and notes.
  static List<pw.Widget> _userDaySection(
    _PdfTheme t,
    _UserDay e, {
    required int index,
    required bool isSales,
    required Map<String, String> addressByCoord,
    List<pw.Widget> lead = const [],
  }) {
    final s = e.stats;
    final name = (e.user.userName ?? '').trim().isEmpty
        ? 'Employee'
        : e.user.userName!.trim();
    final header = _band(
      t,
      lead: _avatar(t, _initials(name), 26),
      title: '${index.toString().padLeft(2, '0')}.  $name',
      subtitle: [
        if ((e.user.empCode ?? '').trim().isNotEmpty) e.user.empCode!.trim(),
        if ((e.user.designation ?? '').trim().isNotEmpty)
          e.user.designation!.trim(),
      ].join('  ·  '),
      chips: [
        _Meta('Check-in', s.checkInText),
        _Meta('Check-out', s.checkOutText),
        _Meta('On duty', s.hoursText),
        _Meta('Visits', '${s.visits}'),
        if (isSales) _Meta('Value', _money(s.value)),
      ],
      status: _status(s),
    );

    final visitsOf = e.report.visits;
    final body = <pw.Widget>[
      if (!s.present)
        _notice(
          'Absent',
          'No check-in and no shop visits were recorded for $name on this day.',
          _red,
          _redBg,
        )
      else if (e.report.visits.isEmpty)
        _notice(
          'No visits',
          '$name checked in but recorded no shop visits on this day.',
          _amber,
          _amberBg,
        )
      else
        _visitTable(
          t,
          e.report.visits,
          isSales: isSales,
          addressByCoord: addressByCoord,
        ),
      if (s.present) ...[
        pw.SizedBox(height: 6),
        _notes(t, 'Notes for $name', _dayNotes(s, isSales: isSales)),
      ],
    ];

    return [
      ..._keepTogether([
        ...lead,
        header,
        pw.SizedBox(height: 6),
        ...body,
      ], _visitsHeight(visitsOf, addressByCoord)),
      pw.SizedBox(height: 16),
    ];
  }

  /// One row per day: attendance, hours and visit counts, with totals.
  static pw.Widget _dailyOverviewTable(
    _PdfTheme t,
    List<EmployesWorkingDetailModel> days,
    List<_DayStats> stats, {
    required bool isSales,
  }) {
    final cols = [
      const _Col('Date', 1.15, align: pw.Alignment.center),
      const _Col('Day', 0.75, align: pw.Alignment.center),
      const _Col('Status', 1.35, align: pw.Alignment.center),
      const _Col('Check-in', 1.05, align: pw.Alignment.center),
      const _Col('Check-out', 1.05, align: pw.Alignment.center),
      const _Col('On duty', 0.95, align: pw.Alignment.center),
      const _Col('Visits', 0.8, align: pw.Alignment.center),
      if (isSales) ...[
        const _Col('Productive', 0.95, align: pw.Alignment.center),
        const _Col('Non-prod.', 0.95, align: pw.Alignment.center),
        const _Col('Value (PKR)', 1.3, align: pw.Alignment.centerRight),
      ] else
        const _Col('Shop time', 1.15, align: pw.Alignment.center),
    ];

    final rows = <List<pw.Widget>>[
      for (int i = 0; i < days.length; i++)
        [
          _txt(
            DateFormat('dd MMM yyyy').format(days[i].date),
            align: pw.Alignment.center,
            bold: true,
          ),
          _txt(
            DateFormat('EEE').format(days[i].date),
            align: pw.Alignment.center,
            color: _muted,
          ),
          _statusPill(stats[i]),
          _txt(stats[i].checkInText, align: pw.Alignment.center),
          _txt(stats[i].checkOutText, align: pw.Alignment.center),
          _txt(stats[i].hoursText, align: pw.Alignment.center),
          _txt('${stats[i].visits}', align: pw.Alignment.center, bold: true),
          if (isSales) ...[
            _txt(
              '${stats[i].productive}',
              align: pw.Alignment.center,
              color: stats[i].productive > 0 ? _green : _muted,
            ),
            _txt(
              '${stats[i].nonProductive}',
              align: pw.Alignment.center,
              color: stats[i].nonProductive > 0 ? _red : _muted,
            ),
            _txt(
              stats[i].value > 0 ? _money(stats[i].value) : '-',
              align: pw.Alignment.centerRight,
              bold: stats[i].value > 0,
            ),
          ] else
            _txt(
              stats[i].stayCount > 0 ? _dur(stats[i].staySeconds) : '-',
              align: pw.Alignment.center,
            ),
        ],
    ];

    final total = _DayStats.sum(stats);
    final present = stats.where((s) => s.present).length;
    return _grid(
      t,
      cols,
      rows,
      totals: [
        _txt('Total', align: pw.Alignment.center, bold: true),
        _txt('${days.length} d', align: pw.Alignment.center, color: _muted),
        _txt('$present present', align: pw.Alignment.center, bold: true),
        _empty,
        _empty,
        _txt(
          total.workedMinutes > 0 ? _durMin(total.workedMinutes) : '-',
          align: pw.Alignment.center,
          bold: true,
        ),
        _txt('${total.visits}', align: pw.Alignment.center, bold: true),
        if (isSales) ...[
          _txt(
            '${total.productive}',
            align: pw.Alignment.center,
            bold: true,
            color: _green,
          ),
          _txt(
            '${total.nonProductive}',
            align: pw.Alignment.center,
            bold: true,
            color: _red,
          ),
          _txt(
            _money(total.value),
            align: pw.Alignment.centerRight,
            bold: true,
          ),
        ] else
          _txt(_dur(total.staySeconds), align: pw.Alignment.center, bold: true),
      ],
    );
  }

  /// One day of the employee report: date band, visits and day notes.
  static List<pw.Widget> _daySection(
    _PdfTheme t,
    EmployesWorkingDetailModel report,
    _DayStats s, {
    required bool isSales,
    required Map<String, String> addressByCoord,
    List<pw.Widget> lead = const [],
  }) {
    final header = _band(
      t,
      lead: _dateBadge(t, report.date),
      title: DateFormat('EEEE').format(report.date),
      subtitle: DateFormat('dd MMMM yyyy').format(report.date),
      chips: [
        _Meta('Check-in', s.checkInText),
        _Meta('Check-out', s.checkOutText),
        _Meta('On duty', s.hoursText),
        _Meta('Visits', '${s.visits}'),
        if (isSales) _Meta('Value', _money(s.value)),
      ],
      status: _status(s),
    );

    if (!s.present) {
      return [
        ..._keepTogether([...lead, header], 0),
        pw.SizedBox(height: 12),
      ];
    }

    final visitsOf = report.visits;
    final body = <pw.Widget>[
      if (report.visits.isEmpty)
        _notice(
          'No visits',
          'Checked in but no shop visits were recorded on this day.',
          _amber,
          _amberBg,
        )
      else
        _visitTable(
          t,
          report.visits,
          isSales: isSales,
          addressByCoord: addressByCoord,
        ),
      pw.SizedBox(height: 6),
      _notes(
        t,
        'Notes for ${DateFormat('dd MMM yyyy').format(report.date)}',
        _dayNotes(s, isSales: isSales),
      ),
    ];

    return [
      ..._keepTogether([
        ...lead,
        header,
        pw.SizedBox(height: 6),
        ...body,
      ], _visitsHeight(visitsOf, addressByCoord)),
      pw.SizedBox(height: 16),
    ];
  }

  /// Visits of one employee for one day, in time order, with a totals row.
  static pw.Widget _visitTable(
    _PdfTheme t,
    List<Visit> visits, {
    required bool isSales,
    required Map<String, String> addressByCoord,
  }) {
    final sorted = _sortedVisits(visits);
    final cols = [
      const _Col('#', 0.45, align: pw.Alignment.center),
      const _Col('Time', 1.0, align: pw.Alignment.center),
      const _Col('Shop & address', 3.4),
      const _Col('Channel', 1.15, align: pw.Alignment.center),
      if (isSales) const _Col('Status', 1.4, align: pw.Alignment.center),
      const _Col('Stay', 0.95, align: pw.Alignment.center),
      if (isSales)
        const _Col('Value (PKR)', 1.2, align: pw.Alignment.centerRight),
      _Col('Remarks', isSales ? 2.45 : 3.6),
    ];

    var productive = 0;
    var value = 0.0;
    var stay = 0;
    final rows = <List<pw.Widget>>[];
    for (final (i, v) in sorted.indexed) {
      final isProductive = _isProductive(v);
      final visitValue = _visitValue(v);
      final seconds = _staySeconds(v);
      if (isProductive) productive++;
      value += visitValue;
      stay += seconds ?? 0;
      rows.add([
        _txt('${i + 1}', align: pw.Alignment.center, color: _muted),
        _txt(_timeText(_visitTime(v)), align: pw.Alignment.center),
        _shopCell(v, addressByCoord),
        _txt(
          v.channel.trim().isEmpty ? '-' : _title(v.channel),
          align: pw.Alignment.center,
        ),
        if (isSales)
          isProductive
              ? _pill('Productive', _green, _greenBg)
              : _pill('Non-productive', _red, _redBg),
        _txt(seconds == null ? '-' : _dur(seconds), align: pw.Alignment.center),
        if (isSales)
          _txt(
            visitValue > 0 ? _money(visitValue) : '-',
            align: pw.Alignment.centerRight,
            bold: visitValue > 0,
          ),
        _para(_remarkText(v)),
      ]);
    }

    return _grid(
      t,
      cols,
      rows,
      totals: [
        _empty,
        _empty,
        _txt(
          'Total  ·  ${sorted.length} visit${sorted.length == 1 ? '' : 's'}',
          bold: true,
        ),
        _empty,
        if (isSales)
          _txt(
            '$productive P  ·  ${sorted.length - productive} NP',
            align: pw.Alignment.center,
            bold: true,
          ),
        _txt(
          stay > 0 ? _dur(stay) : '-',
          align: pw.Alignment.center,
          bold: true,
        ),
        if (isSales)
          _txt(_money(value), align: pw.Alignment.centerRight, bold: true),
        _empty,
      ],
    );
  }

  /// External orders, one row per item, grouped by order.
  static pw.Widget _ordersTable(_PdfTheme t, List<ExternalOrder> orders) {
    final sorted = [...orders]
      ..sort(
        (a, b) => (_orderTime(a) ?? DateTime(2000)).compareTo(
          _orderTime(b) ?? DateTime(2000),
        ),
      );
    final cols = [
      const _Col('Time', 0.95, align: pw.Alignment.center),
      const _Col('Client', 2.6),
      const _Col('Status', 1.35, align: pw.Alignment.center),
      const _Col('Item', 2.75),
      const _Col('Qty', 0.7, align: pw.Alignment.center),
      const _Col('FOC', 0.65, align: pw.Alignment.center),
      const _Col('Rate', 0.85, align: pw.Alignment.centerRight),
      const _Col('Amount (PKR)', 1.3, align: pw.Alignment.centerRight),
    ];

    final rows = <List<pw.Widget>>[];
    final shaded = <bool>[];
    var qty = 0.0;
    var foc = 0.0;
    var amount = 0.0;
    for (final (i, o) in sorted.indexed) {
      final lead = [
        _txt(_timeText(_orderTime(o)), align: pw.Alignment.center),
        _stack(
          (o.entityName ?? '').trim().isEmpty ? '-' : o.entityName!.trim(),
          o.entityNo,
          wrap: true,
        ),
        o.isProductive
            ? _pill('Productive', _green, _greenBg)
            : _pill('Non-productive', _red, _redBg),
      ];
      if (o.items.isEmpty) {
        final remark = (o.remarks ?? '').trim();
        rows.add([
          ...lead,
          _para(
            remark.isEmpty ? 'No items booked' : remark,
            color: _muted,
            italic: true,
          ),
          _txt('-', align: pw.Alignment.center, color: _muted),
          _txt('-', align: pw.Alignment.center, color: _muted),
          _txt('-', align: pw.Alignment.centerRight, color: _muted),
          _txt('-', align: pw.Alignment.centerRight, color: _muted),
        ]);
        shaded.add(i.isOdd);
        continue;
      }
      for (final (k, item) in o.items.indexed) {
        final itemQty = item.qtyPcs + item.qtyBox;
        final itemAmount = _itemAmount(item);
        qty += itemQty;
        foc += item.qtyFoc;
        amount += itemAmount;
        rows.add([
          if (k == 0) ...lead else ...[_empty, _empty, _empty],
          _para(item.itemName.trim().isEmpty ? '-' : item.itemName.trim()),
          _txt(_qty(itemQty), align: pw.Alignment.center, bold: true),
          _txt(
            item.qtyFoc > 0 ? _qty(item.qtyFoc) : '-',
            align: pw.Alignment.center,
            color: item.qtyFoc > 0 ? _green : _muted,
          ),
          _txt(_money(item.rate), align: pw.Alignment.centerRight),
          _txt(_money(itemAmount), align: pw.Alignment.centerRight, bold: true),
        ]);
        shaded.add(i.isOdd);
      }
    }

    final productive = sorted.where((o) => o.isProductive).length;
    return _grid(
      t,
      cols,
      rows,
      shaded: shaded,
      totals: [
        _txt('Total', align: pw.Alignment.center, bold: true),
        _txt(
          '${sorted.length} order${sorted.length == 1 ? '' : 's'}',
          bold: true,
        ),
        _txt(
          '$productive P  ·  ${sorted.length - productive} NP',
          align: pw.Alignment.center,
          bold: true,
        ),
        _txt('${_clientCount(sorted)} clients', color: _muted),
        _txt(_qty(qty), align: pw.Alignment.center, bold: true),
        _txt(foc > 0 ? _qty(foc) : '-', align: pw.Alignment.center, bold: true),
        _empty,
        _txt(_money(amount), align: pw.Alignment.centerRight, bold: true),
      ],
    );
  }

  /// One row per day of external orders, with totals.
  static pw.Widget _externalOverviewTable(
    _PdfTheme t,
    List<ExternalClientReportModel> days,
  ) {
    final cols = [
      const _Col('Date', 1.15, align: pw.Alignment.center),
      const _Col('Day', 0.75, align: pw.Alignment.center),
      const _Col('Orders', 0.85, align: pw.Alignment.center),
      const _Col('Productive', 0.95, align: pw.Alignment.center),
      const _Col('Non-prod.', 0.95, align: pw.Alignment.center),
      const _Col('Clients', 0.85, align: pw.Alignment.center),
      const _Col('Quantity', 0.95, align: pw.Alignment.center),
      const _Col('FOC', 0.75, align: pw.Alignment.center),
      const _Col('Value (PKR)', 1.35, align: pw.Alignment.centerRight),
    ];

    var orders = 0, productive = 0;
    var qty = 0.0, foc = 0.0, value = 0.0;
    final rows = <List<pw.Widget>>[];
    for (final r in days) {
      final date = _reportDate(r);
      final p = r.orders.where((o) => o.isProductive).length;
      final q = r.orders.fold<double>(0, (a, o) => a + _orderQty(o));
      final f = r.orders.fold<double>(0, (a, o) => a + _orderFoc(o));
      final v = r.orders.fold<double>(0, (a, o) => a + _orderValue(o));
      orders += r.orders.length;
      productive += p;
      qty += q;
      foc += f;
      value += v;
      rows.add([
        _txt(
          DateFormat('dd MMM yyyy').format(date),
          align: pw.Alignment.center,
          bold: true,
        ),
        _txt(
          DateFormat('EEE').format(date),
          align: pw.Alignment.center,
          color: _muted,
        ),
        _txt('${r.orders.length}', align: pw.Alignment.center, bold: true),
        _txt('$p', align: pw.Alignment.center, color: p > 0 ? _green : _muted),
        _txt(
          '${r.orders.length - p}',
          align: pw.Alignment.center,
          color: r.orders.length - p > 0 ? _red : _muted,
        ),
        _txt('${_clientCount(r.orders)}', align: pw.Alignment.center),
        _txt(_qty(q), align: pw.Alignment.center),
        _txt(f > 0 ? _qty(f) : '-', align: pw.Alignment.center),
        _txt(
          v > 0 ? _money(v) : '-',
          align: pw.Alignment.centerRight,
          bold: v > 0,
        ),
      ]);
    }

    final allOrders = [for (final r in days) ...r.orders];
    return _grid(
      t,
      cols,
      rows,
      totals: [
        _txt('Total', align: pw.Alignment.center, bold: true),
        _txt('${days.length} d', align: pw.Alignment.center, color: _muted),
        _txt('$orders', align: pw.Alignment.center, bold: true),
        _txt(
          '$productive',
          align: pw.Alignment.center,
          bold: true,
          color: _green,
        ),
        _txt(
          '${orders - productive}',
          align: pw.Alignment.center,
          bold: true,
          color: _red,
        ),
        _txt(
          '${_clientCount(allOrders)}',
          align: pw.Alignment.center,
          bold: true,
        ),
        _txt(_qty(qty), align: pw.Alignment.center, bold: true),
        _txt(foc > 0 ? _qty(foc) : '-', align: pw.Alignment.center, bold: true),
        _txt(_money(value), align: pw.Alignment.centerRight, bold: true),
      ],
    );
  }

  /// One day of external orders: date band, orders and day notes.
  static List<pw.Widget> _externalDaySection(
    _PdfTheme t,
    ExternalClientReportModel r, {
    List<pw.Widget> lead = const [],
  }) {
    final date = _reportDate(r);
    final productive = r.orders.where((o) => o.isProductive).length;
    final value = r.orders.fold<double>(0, (a, o) => a + _orderValue(o));
    final header = _band(
      t,
      lead: _dateBadge(t, date),
      title: DateFormat('EEEE').format(date),
      subtitle: DateFormat('dd MMMM yyyy').format(date),
      chips: [
        _Meta('Orders', '${r.orders.length}'),
        _Meta('Productive', '$productive'),
        _Meta('Clients', '${_clientCount(r.orders)}'),
        _Meta('Value', _money(value)),
      ],
    );

    return [
      ..._keepTogether([
        ...lead,
        header,
        pw.SizedBox(height: 6),
        if (r.orders.isEmpty)
          _notice(
            'No orders',
            'No external orders were recorded on this day.',
            _amber,
            _amberBg,
          )
        else
          _ordersTable(t, r.orders),
        pw.SizedBox(height: 6),
        _notes(
          t,
          'Notes for ${DateFormat('dd MMM yyyy').format(date)}',
          _ordersNotes(r.orders),
        ),
      ], _ordersHeight(r.orders)),
      pw.SizedBox(height: 16),
    ];
  }

  // ─────────────────────────────────────────────────────────────── Summaries

  /// Department figures and highlights for the daily report.
  static List<pw.Widget> _departmentSummary(
    _PdfTheme t,
    List<_UserDay> entries, {
    required bool isSales,
    required String longDate,
    ExternalClientReportModel? external,
  }) {
    final stats = [for (final e in entries) e.stats];
    final total = _DayStats.sum(stats);
    final present = entries.where((e) => e.stats.present).toList();
    String nameOf(_UserDay e) => (e.user.userName ?? '').trim().isEmpty
        ? 'Employee'
        : e.user.userName!.trim();

    final absent = entries.where((e) => !e.stats.present).map(nameOf);
    final noCheckout = entries
        .where((e) => e.stats.checkedIn && !e.stats.checkedOut)
        .map(nameOf);
    final noVisits = entries
        .where((e) => e.stats.present && e.stats.visits == 0)
        .map(nameOf);

    final grid = [
      _Meta('Team size', '${entries.length}'),
      _Meta('Present', '${present.length}', color: _green),
      _Meta(
        'Absent',
        '${entries.length - present.length}',
        color: entries.length > present.length ? _red : null,
      ),
      _Meta('Missing check-outs', '${noCheckout.length}'),
      _Meta('Total visits', '${total.visits}'),
      _Meta('Avg visits per present', _avg(total.visits, present.length)),
      if (isSales) ...[
        _Meta('Productive visits', '${total.productive}', color: _green),
        _Meta('Non-productive visits', '${total.nonProductive}', color: _red),
        _Meta('Productivity', _percent(total.productive, total.visits)),
        _Meta('Booked value', 'PKR ${_money(total.value)}'),
      ],
      _Meta('Time in shops', _dur(total.staySeconds)),
      _Meta('Avg stay per visit', _avgDur(total.staySeconds, total.stayCount)),
    ];

    final points = <String>[];
    if (present.isNotEmpty) {
      final byVisits = [...present]
        ..sort((a, b) => b.stats.visits.compareTo(a.stats.visits));
      if (byVisits.first.stats.visits > 0) {
        points.add(
          'Most visits: ${nameOf(byVisits.first)} with '
          '${byVisits.first.stats.visits} visits.',
        );
      }
      if (isSales) {
        final byValue = [...present]
          ..sort((a, b) => b.stats.value.compareTo(a.stats.value));
        if (byValue.first.stats.value > 0) {
          points.add(
            'Highest booking: ${nameOf(byValue.first)} with '
            'PKR ${_money(byValue.first.stats.value)} from '
            '${byValue.first.stats.productive} productive visits.',
          );
        }
        final byRate = present.where((e) => e.stats.visits >= 3).toList()
          ..sort(
            (a, b) => (b.stats.productive / b.stats.visits).compareTo(
              a.stats.productive / a.stats.visits,
            ),
          );
        if (byRate.isNotEmpty) {
          points.add(
            'Best productivity: ${nameOf(byRate.first)} at '
            '${_percent(byRate.first.stats.productive, byRate.first.stats.visits)}'
            ' (${byRate.first.stats.productive} of '
            '${byRate.first.stats.visits} visits).',
          );
        }
      }
    }
    if (absent.isNotEmpty) points.add('Absent: ${absent.join(', ')}.');
    if (noCheckout.isNotEmpty) {
      points.add('Check-out not recorded: ${noCheckout.join(', ')}.');
    }
    if (noVisits.isNotEmpty) {
      points.add('Present with no visits: ${noVisits.join(', ')}.');
    }
    final channels = _topChannels(total.channels, total.visits);
    if (channels != null) points.add('Channels: $channels.');
    if (external != null) {
      final value = external.orders.fold<double>(
        0,
        (a, o) => a + _orderValue(o),
      );
      points.add(
        'External clients: ${external.orders.length} orders worth '
        'PKR ${_money(value)} from ${_clientCount(external.orders)} clients.',
      );
    }
    if (points.isEmpty) points.add('No activity was recorded for the team.');

    return [
      _block([
        _sectionTitle(t, 'Department summary', trailing: longDate),
        _summaryGrid(t, grid),
        pw.SizedBox(height: 8),
        _notes(t, 'Key points', points, emphasis: true),
      ]),
    ];
  }

  /// Period figures and highlights for the employee report.
  static List<pw.Widget> _periodSummary(
    _PdfTheme t,
    List<EmployesWorkingDetailModel> days,
    List<_DayStats> stats, {
    required bool isSales,
    required String dateRangeText,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final total = _DayStats.sum(stats);
    final presentDays = stats.where((s) => s.present).toList();
    final periodDays = _periodDays(periodStart, periodEnd);
    String day(_DayStats s) => DateFormat('EEE dd MMM').format(s.date);

    final missingCheckout = stats
        .where((s) => s.checkedIn && !s.checkedOut)
        .map(day);
    final noVisitDays = stats.where((s) => s.present && s.visits == 0).map(day);
    final absentDays = stats.where((s) => !s.present).length;
    final dutyDays = stats.where((s) => s.workedMinutes > 0).toList();
    final idleDays = periodDays != null
        ? (periodDays - presentDays.length).clamp(0, periodDays)
        : absentDays;
    final dutyMinutes = dutyDays.fold<int>(0, (a, s) => a + s.workedMinutes);

    final grid = [
      _Meta('Period', dateRangeText),
      if (periodDays != null)
        _Meta('Days in period', '$periodDays')
      else
        _Meta('Days with records', '${days.length}'),
      _Meta('Days present', '${presentDays.length}', color: _green),
      _Meta(
        periodDays != null ? 'Days without activity' : 'Days absent',
        '$idleDays',
        color: idleDays > 0 ? _red : null,
      ),
      _Meta('Total visits', '${total.visits}'),
      _Meta('Avg visits per day', _avg(total.visits, presentDays.length)),
      if (isSales) ...[
        _Meta('Productive visits', '${total.productive}', color: _green),
        _Meta('Non-productive visits', '${total.nonProductive}', color: _red),
        _Meta('Productivity', _percent(total.productive, total.visits)),
        _Meta('Booked value', 'PKR ${_money(total.value)}'),
        _Meta(
          'Avg value per day',
          presentDays.isEmpty
              ? '-'
              : 'PKR ${_money(total.value / presentDays.length)}',
        ),
        _Meta(
          'Avg per productive visit',
          total.productive == 0
              ? '-'
              : 'PKR ${_money(total.value / total.productive)}',
        ),
      ],
      _Meta('Time in shops', _dur(total.staySeconds)),
      _Meta('Avg stay per visit', _avgDur(total.staySeconds, total.stayCount)),
      _Meta(
        'Avg time on duty',
        dutyDays.isEmpty ? '-' : _durMin(dutyMinutes ~/ dutyDays.length),
      ),
      _Meta('Missing check-outs', '${missingCheckout.length}'),
    ];

    final points = <String>[];
    if (isSales) {
      points.add(
        'Visits: ${total.visits} in total, ${total.productive} productive and '
        '${total.nonProductive} non-productive '
        '(${_percent(total.productive, total.visits)} productive).',
      );
    } else {
      points.add(
        'Visits: ${total.visits} shop visits over '
        '${presentDays.length} days present.',
      );
    }
    if (presentDays.isNotEmpty) {
      final busiest = [...presentDays]
        ..sort((a, b) => b.visits.compareTo(a.visits));
      if (busiest.first.visits > 0) {
        points.add(
          'Busiest day: ${day(busiest.first)} with '
          '${busiest.first.visits} visits.',
        );
      }
      if (isSales) {
        final best = [...presentDays]
          ..sort((a, b) => b.value.compareTo(a.value));
        if (best.first.value > 0) {
          points.add(
            'Best booking day: ${day(best.first)} with '
            'PKR ${_money(best.first.value)}.',
          );
        }
      }
      if (presentDays.length > 1) {
        final quiet = busiest.last;
        points.add(
          'Lightest day: ${day(quiet)} with ${quiet.visits} '
          'visit${quiet.visits == 1 ? '' : 's'}.',
        );
      }
    }
    final channels = _topChannels(total.channels, total.visits);
    if (channels != null) points.add('Channels: $channels.');
    final shop = _topShop(days.expand((d) => d.visits));
    if (shop != null) points.add('Most visited shop: $shop.');
    if (missingCheckout.isNotEmpty) {
      points.add('Check-out not recorded on: ${missingCheckout.join(', ')}.');
    }
    if (noVisitDays.isNotEmpty) {
      points.add('Present with no visits on: ${noVisitDays.join(', ')}.');
    }
    if (absentDays > 0) {
      points.add(
        'No check-in or visits on ${stats.where((s) => !s.present).map(day).join(', ')}.',
      );
    }

    return [
      _block([
        _sectionTitle(t, 'Period summary', trailing: dateRangeText),
        _summaryGrid(t, grid),
        pw.SizedBox(height: 8),
        _notes(t, 'Summary points', points, emphasis: true),
      ]),
    ];
  }

  /// Period figures and highlights for the external orders report.
  static List<pw.Widget> _externalSummary(
    _PdfTheme t,
    List<ExternalClientReportModel> days, {
    required String dateRangeText,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final orders = [for (final r in days) ...r.orders];
    final productive = orders.where((o) => o.isProductive).length;
    final value = orders.fold<double>(0, (a, o) => a + _orderValue(o));
    final qty = orders.fold<double>(0, (a, o) => a + _orderQty(o));
    final foc = orders.fold<double>(0, (a, o) => a + _orderFoc(o));
    final periodDays = _periodDays(periodStart, periodEnd);

    final grid = [
      _Meta('Period', dateRangeText),
      if (periodDays != null)
        _Meta('Days in period', '$periodDays')
      else
        _Meta('Days with orders', '${days.length}'),
      _Meta('Total orders', '${orders.length}'),
      _Meta('Avg orders per day', _avg(orders.length, days.length)),
      _Meta('Productive orders', '$productive', color: _green),
      _Meta(
        'Non-productive orders',
        '${orders.length - productive}',
        color: _red,
      ),
      _Meta('Productivity', _percent(productive, orders.length)),
      _Meta('Clients served', '${_clientCount(orders)}'),
      _Meta('Quantity booked', _qty(qty)),
      _Meta('FOC quantity', _qty(foc)),
      _Meta('Order value', 'PKR ${_money(value)}'),
      _Meta(
        'Avg value per day',
        days.isEmpty ? '-' : 'PKR ${_money(value / days.length)}',
      ),
    ];

    final points = <String>[
      'Orders: ${orders.length} in total, $productive productive and '
          '${orders.length - productive} non-productive '
          '(${_percent(productive, orders.length)} productive).',
    ];
    if (days.isNotEmpty) {
      final best = [...days]
        ..sort(
          (a, b) => b.orders
              .fold<double>(0, (s, o) => s + _orderValue(o))
              .compareTo(
                a.orders.fold<double>(0, (s, o) => s + _orderValue(o)),
              ),
        );
      final bestValue = best.first.orders.fold<double>(
        0,
        (s, o) => s + _orderValue(o),
      );
      if (bestValue > 0) {
        points.add(
          'Best day: ${DateFormat('EEE dd MMM').format(_reportDate(best.first))}'
          ' with PKR ${_money(bestValue)} from ${best.first.orders.length} orders.',
        );
      }
    }
    final clients = _topBy(
      orders,
      (o) => (o.entityName ?? o.entityNo ?? '').trim(),
      _orderValue,
    );
    if (clients.isNotEmpty) {
      points.add(
        'Top clients: ${clients.map((e) => '${e.key} (PKR ${_money(e.value)})').join(', ')}.',
      );
    }
    final items = <String, double>{};
    for (final o in orders) {
      for (final i in o.items) {
        final name = i.itemName.trim();
        if (name.isEmpty) continue;
        items[name] = (items[name] ?? 0) + i.qtyPcs + i.qtyBox;
      }
    }
    final topItems = items.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topItems.isNotEmpty) {
      points.add(
        'Top items: ${topItems.take(3).map((e) => '${e.key} (${_qty(e.value)})').join(', ')}.',
      );
    }
    final reasons = <String, int>{};
    for (final o in orders.where((o) => !o.isProductive)) {
      final r = (o.remarks ?? '').trim();
      final key = r.isEmpty ? 'No reason given' : r;
      reasons[key] = (reasons[key] ?? 0) + 1;
    }
    if (reasons.isNotEmpty) {
      final list = reasons.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      points.add(
        'Non-productive reasons: '
        '${list.take(3).map((e) => '${e.key} (${e.value})').join(', ')}.',
      );
    }

    return [
      _block([
        _sectionTitle(t, 'Period summary', trailing: dateRangeText),
        _summaryGrid(t, grid),
        pw.SizedBox(height: 8),
        _notes(t, 'Summary points', points, emphasis: true),
      ]),
    ];
  }

  /// Notes under one employee's day.
  static List<String> _dayNotes(_DayStats s, {required bool isSales}) {
    final points = <String>[];
    if (s.visits == 0) {
      points.add('Visits: none recorded after check-in.');
    } else if (isSales) {
      points.add(
        'Visits: ${s.visits} in total, ${s.productive} productive and '
        '${s.nonProductive} non-productive '
        '(${_percent(s.productive, s.visits)} productive).',
      );
      points.add(
        s.value > 0
            ? 'Booked value: PKR ${_money(s.value)} from ${s.orderLines} order '
                  'line${s.orderLines == 1 ? '' : 's'}, about '
                  'PKR ${_money(s.value / (s.productive == 0 ? 1 : s.productive))}'
                  ' per productive visit.'
            : 'Booked value: no orders were booked.',
      );
    } else {
      points.add('Visits: ${s.visits} shop visits recorded.');
    }
    if (s.checkedIn && s.checkedOut) {
      points.add(
        'Attendance: checked in at ${s.checkInText} and out at '
        '${s.checkOutText}'
        '${s.workedMinutes > 0 ? ' (${_durMin(s.workedMinutes)} on duty)' : ''}.',
      );
    } else if (s.checkedIn) {
      points.add(
        'Attendance: checked in at ${s.checkInText}; check-out was not recorded.',
      );
    } else {
      points.add('Attendance: visits recorded without a check-in.');
    }
    if (s.firstVisit != null && s.lastVisit != null) {
      points.add(
        s.visits == 1
            ? 'Field time: single visit at ${_timeText(s.firstVisit)}.'
            : 'Field time: first visit at ${_timeText(s.firstVisit)}, '
                  'last visit at ${_timeText(s.lastVisit)}.',
      );
    }
    if (s.stayCount > 0) {
      points.add(
        'Time in shops: ${_dur(s.staySeconds)} in total, about '
        '${_avgDur(s.staySeconds, s.stayCount)} per visit.',
      );
    }
    final channels = _topChannels(s.channels, s.visits);
    if (channels != null) points.add('Channels: $channels.');
    return points;
  }

  /// Notes under a list of external orders.
  static List<String> _ordersNotes(List<ExternalOrder> orders) {
    if (orders.isEmpty) return ['No external orders were recorded.'];
    final productive = orders.where((o) => o.isProductive).length;
    final value = orders.fold<double>(0, (a, o) => a + _orderValue(o));
    final qty = orders.fold<double>(0, (a, o) => a + _orderQty(o));
    final foc = orders.fold<double>(0, (a, o) => a + _orderFoc(o));
    final points = <String>[
      'Orders: ${orders.length} in total, $productive productive and '
          '${orders.length - productive} non-productive '
          '(${_percent(productive, orders.length)} productive).',
      'Order value: PKR ${_money(value)} for ${_qty(qty)} units'
          '${foc > 0 ? ' plus ${_qty(foc)} FOC' : ''}.',
    ];
    final top = _topBy(
      orders,
      (o) => (o.entityName ?? o.entityNo ?? '').trim(),
      _orderValue,
    );
    if (top.isNotEmpty) {
      points.add(
        'Top client: ${top.first.key} with PKR ${_money(top.first.value)}.',
      );
    }
    final missed = orders.where((o) => !o.isProductive).map((o) {
      final name = (o.entityName ?? o.entityNo ?? 'Client').trim();
      final r = (o.remarks ?? '').trim();
      return r.isEmpty ? name : '$name ($r)';
    });
    if (missed.isNotEmpty) {
      points.add('Non-productive: ${missed.join(', ')}.');
    }
    return points;
  }

  // ─────────────────────────────────────────────────────────── Page chrome

  static const _pageMargin = pw.EdgeInsets.fromLTRB(28, 22, 28, 20);

  static pw.Widget _pageHeader(_PdfTheme t, String report, String period) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: t.brand, width: 1.6)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 24,
            height: 24,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: t.brand,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              t.mark,
              style: _s(12, bold: true, color: PdfColors.white),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _fit(
                  t.brandName.toUpperCase(),
                  _s(11.5, bold: true, color: t.dark, spacing: 0.8),
                ),
                pw.SizedBox(height: 1),
                _fit('Field Activity Reports', _s(7, color: _muted)),
              ],
            ),
          ),
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _fit(
                  report,
                  _s(9.5, bold: true),
                  align: pw.Alignment.centerRight,
                ),
                pw.SizedBox(height: 1),
                _fit(
                  period,
                  _s(7.5, color: _muted),
                  align: pw.Alignment.centerRight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(_PdfTheme t, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.7)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _fit(
              '${t.brandName}  ·  Field Activity Reports  ·  '
              'Generated ${t.stamp}',
              _s(6.5, color: _muted),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: _s(6.8, bold: true, color: t.dark),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────── Building blocks

  static const _ink = PdfColor.fromInt(0xFF1F2A37);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _line = PdfColor.fromInt(0xFFDCE1E7);
  static const _zebra = PdfColor.fromInt(0xFFF6F8FA);
  static const _green = PdfColor.fromInt(0xFF15803D);
  static const _greenBg = PdfColor.fromInt(0xFFE6F4EA);
  static const _red = PdfColor.fromInt(0xFFC0392B);
  static const _redBg = PdfColor.fromInt(0xFFFBEAE8);
  static const _amber = PdfColor.fromInt(0xFFB45309);
  static const _amberBg = PdfColor.fromInt(0xFFFFF2DE);

  static const _edge = pw.BorderSide(color: _line, width: 0.7);
  static const _inner = pw.BorderSide(color: _line, width: 0.45);
  static const _tableBorder = pw.TableBorder(
    left: _edge,
    top: _edge,
    right: _edge,
    bottom: _edge,
    horizontalInside: _inner,
    verticalInside: _inner,
  );

  /// A fresh empty cell (pdf widgets keep layout state, so never share one).
  static pw.Widget get _empty => pw.SizedBox();

  static pw.TextStyle _s(
    double size, {
    bool bold = false,
    PdfColor color = _ink,
    double? spacing,
    bool italic = false,
  }) => pw.TextStyle(
    fontSize: size,
    color: color,
    letterSpacing: spacing,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
    lineSpacing: 1.2,
  );

  /// Single-line text that shrinks to fit its box instead of overflowing.
  static pw.Widget _fit(
    String text,
    pw.TextStyle style, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    final value = text.trim().isEmpty ? '-' : text.trim();
    return pw.Align(
      alignment: align,
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: align,
        child: pw.Text(value, style: style),
      ),
    );
  }

  /// A single-line table cell value.
  static pw.Widget _txt(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
    bool bold = false,
    PdfColor color = _ink,
    double size = 7.4,
  }) => _fit(
    text,
    _s(size, bold: bold, color: color),
    align: align,
  );

  /// A wrapping table cell value, for long text such as remarks.
  static pw.Widget _para(
    String text, {
    PdfColor color = _ink,
    bool italic = false,
  }) => pw.Text(
    text.trim().isEmpty ? '-' : text.trim(),
    style: _s(7, color: color, italic: italic),
  );

  /// A bold name with a muted second line, each scaled to fit.
  static pw.Widget _stack(String title, String? sub, {bool wrap = false}) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (wrap)
            pw.Text(
              title.trim().isEmpty ? '-' : title.trim(),
              style: _s(7.6, bold: true),
            )
          else
            _fit(title, _s(7.6, bold: true)),
          if ((sub ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 1),
            _fit(sub!.trim(), _s(6.4, color: _muted)),
          ],
        ],
      );

  static pw.Widget _shopCell(Visit v, Map<String, String> addressByCoord) {
    final address = (addressByCoord[_visitCoordKey(v)] ?? v.address).trim();
    final owner = v.ownerName.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          v.placeName.trim().isEmpty ? '-' : v.placeName.trim(),
          style: _s(7.5, bold: true),
        ),
        if (owner.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          _fit(owner, _s(6.4, color: _muted)),
        ],
        pw.SizedBox(height: 1.5),
        pw.Text(
          address.isEmpty ? 'Address not found' : address,
          style: _s(6.3, color: _muted),
        ),
      ],
    );
  }

  static pw.Widget _pill(String text, PdfColor fg, PdfColor bg) => pw.Align(
    alignment: pw.Alignment.center,
    child: pw.FittedBox(
      fit: pw.BoxFit.scaleDown,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.2),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(text, style: _s(6.4, bold: true, color: fg)),
      ),
    ),
  );

  static (String, PdfColor, PdfColor) _status(_DayStats s) {
    if (!s.present) return ('Absent', _red, _redBg);
    if (!s.checkedIn) return ('No check-in', _amber, _amberBg);
    if (!s.checkedOut) return ('No check-out', _amber, _amberBg);
    return ('Present', _green, _greenBg);
  }

  static pw.Widget _statusPill(_DayStats s) {
    final (label, fg, bg) = _status(s);
    return _pill(label, fg, bg);
  }

  /// A table with fixed column proportions. The header row repeats on every
  /// page, so a long table stays readable after a page break.
  static pw.Widget _grid(
    _PdfTheme t,
    List<_Col> cols,
    List<List<pw.Widget>> rows, {
    List<pw.Widget>? totals,
    List<bool>? shaded,
  }) {
    pw.Widget cell(pw.Widget child, {double v = 4.2}) => pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 4.5, vertical: v),
      child: child,
    );

    return pw.Table(
      border: _tableBorder,
      columnWidths: {
        for (final (i, c) in cols.indexed) i: pw.FlexColumnWidth(c.flex),
      },
      children: [
        pw.TableRow(
          repeat: true,
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          decoration: pw.BoxDecoration(color: t.brand),
          children: [
            for (final c in cols)
              cell(
                _fit(
                  c.label.toUpperCase(),
                  _s(6.6, bold: true, color: PdfColors.white, spacing: 0.3),
                  align: c.align,
                ),
                v: 5.5,
              ),
          ],
        ),
        for (final (i, r) in rows.indexed)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(
              color: (shaded != null && i < shaded.length ? shaded[i] : i.isOdd)
                  ? _zebra
                  : PdfColors.white,
            ),
            children: [for (final c in r) cell(c)],
          ),
        if (totals != null)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(color: t.tint),
            children: [for (final c in totals) cell(c, v: 5)],
          ),
      ],
    );
  }

  /// Two label/value pairs per row.
  static pw.Widget _summaryGrid(_PdfTheme t, List<_Meta> items) {
    pw.Widget cell(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: child,
    );

    return pw.Table(
      border: _tableBorder,
      columnWidths: const {
        0: pw.FlexColumnWidth(2.3),
        1: pw.FlexColumnWidth(1.7),
        2: pw.FlexColumnWidth(2.3),
        3: pw.FlexColumnWidth(1.7),
      },
      children: [
        for (var i = 0; i < items.length; i += 2)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(
              color: (i ~/ 2).isOdd ? _zebra : PdfColors.white,
            ),
            children: [
              for (final m in [
                items[i],
                if (i + 1 < items.length) items[i + 1],
              ]) ...[
                cell(_fit(m.label, _s(7.6, color: _muted))),
                cell(
                  _fit(
                    m.value,
                    _s(8.2, bold: true, color: m.color ?? t.dark),
                    align: pw.Alignment.centerRight,
                  ),
                ),
              ],
              if (i + 1 >= items.length) ...[_empty, _empty],
            ],
          ),
      ],
    );
  }

  static pw.Widget _titleBlock(
    _PdfTheme t, {
    required String title,
    String? subtitle,
    String? initials,
    required List<_Meta> meta,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: t.tint,
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: t.soft, width: 0.7),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 11, 12, 10),
            child: pw.Row(
              children: [
                if (initials != null) ...[
                  _avatar(t, initials, 34),
                  pw.SizedBox(width: 10),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _fit(title, _s(16, bold: true)),
                      if ((subtitle ?? '').isNotEmpty) ...[
                        pw.SizedBox(height: 2.5),
                        _fit(subtitle!, _s(8.2, color: _muted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Container(height: 0.7, color: t.soft),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 9),
            child: pw.Row(
              children: [
                for (final (i, m) in meta.indexed) ...[
                  if (i > 0) pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _fit(
                          m.label.toUpperCase(),
                          _s(6.2, bold: true, color: _muted, spacing: 0.4),
                        ),
                        pw.SizedBox(height: 2),
                        _fit(m.value, _s(8.8, bold: true)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpiStrip(_PdfTheme t, List<_Kpi> kpis) {
    return pw.Row(
      children: [
        for (final (i, k) in kpis.indexed) ...[
          if (i > 0) pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Container(
              height: 50,
              padding: const pw.EdgeInsets.fromLTRB(8, 7, 8, 7),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _line, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 14,
                    height: 2.4,
                    decoration: pw.BoxDecoration(
                      color: k.color ?? t.brand,
                      borderRadius: pw.BorderRadius.circular(1.2),
                    ),
                  ),
                  _fit(
                    k.label.toUpperCase(),
                    _s(6, bold: true, color: _muted, spacing: 0.4),
                  ),
                  _fit(k.value, _s(13, bold: true, color: k.color ?? t.dark)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _sectionTitle(
    _PdfTheme t,
    String title, {
    String? trailing,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        children: [
          pw.Container(
            width: 3.5,
            height: 13,
            decoration: pw.BoxDecoration(
              color: t.brand,
              borderRadius: pw.BorderRadius.circular(1.5),
            ),
          ),
          pw.SizedBox(width: 7),
          pw.Text(title.toUpperCase(), style: _s(10, bold: true, spacing: 0.6)),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: trailing == null
                ? _empty
                : _fit(
                    trailing,
                    _s(7.5, color: _muted),
                    align: pw.Alignment.centerRight,
                  ),
          ),
        ],
      ),
    );
  }

  /// The header band above one employee's or one date's activity.
  static pw.Widget _band(
    _PdfTheme t, {
    required pw.Widget lead,
    required String title,
    String? subtitle,
    required List<_Meta> chips,
    (String, PdfColor, PdfColor)? status,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: pw.BoxDecoration(
        color: t.tint,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: t.soft, width: 0.7),
      ),
      child: pw.Row(
        children: [
          lead,
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 30,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _fit(title, _s(10.2, bold: true)),
                if ((subtitle ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 1.5),
                  _fit(subtitle!, _s(7, color: _muted)),
                ],
              ],
            ),
          ),
          for (final c in chips) ...[
            pw.SizedBox(width: 5),
            pw.Expanded(
              flex: 13,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3.5,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: _line, width: 0.6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _fit(
                      c.label.toUpperCase(),
                      _s(5.6, bold: true, color: _muted, spacing: 0.3),
                    ),
                    pw.SizedBox(height: 1.5),
                    _fit(c.value, _s(8.2, bold: true, color: c.color ?? _ink)),
                  ],
                ),
              ),
            ),
          ],
          if (status != null) ...[
            pw.SizedBox(width: 5),
            pw.SizedBox(
              width: 64,
              child: _pill(status.$1, status.$2, status.$3),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _avatar(_PdfTheme t, String initials, double size) {
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(color: t.brand, shape: pw.BoxShape.circle),
      child: pw.Text(
        initials,
        style: _s(size * 0.38, bold: true, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _dateBadge(_PdfTheme t, DateTime date) {
    return pw.Container(
      width: 30,
      height: 30,
      decoration: pw.BoxDecoration(
        color: t.brand,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            DateFormat('dd').format(date),
            style: _s(11.5, bold: true, color: PdfColors.white),
          ),
          pw.Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: _s(5.6, bold: true, color: PdfColors.white, spacing: 0.4),
          ),
        ],
      ),
    );
  }

  /// A bulleted notes box.
  static pw.Widget _notes(
    _PdfTheme t,
    String title,
    List<String> points, {
    bool emphasis = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: pw.BoxDecoration(
        color: emphasis ? t.tint : _zebra,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: emphasis ? t.soft : _line, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: _s(7, bold: true, color: t.dark, spacing: 0.5),
          ),
          pw.SizedBox(height: 3),
          for (final p in points)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2.6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 3.4,
                    height: 3.4,
                    margin: const pw.EdgeInsets.only(top: 2.6, right: 6),
                    decoration: pw.BoxDecoration(
                      color: t.brand,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(child: _point(p)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A note line; the text before the first ": " is shown in bold.
  static pw.Widget _point(String text) {
    final cut = text.indexOf(': ');
    if (cut <= 0 || cut > 40) {
      return pw.Text(text, style: _s(7.6));
    }
    return pw.RichText(
      text: pw.TextSpan(
        style: _s(7.6),
        children: [
          pw.TextSpan(
            text: text.substring(0, cut + 2),
            style: _s(7.6, bold: true),
          ),
          pw.TextSpan(text: text.substring(cut + 2)),
        ],
      ),
    );
  }

  static pw.Widget _notice(
    String label,
    String message,
    PdfColor fg,
    PdfColor bg,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          style: _s(7.8, color: fg),
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: _s(7.8, bold: true, color: fg),
            ),
            pw.TextSpan(text: message),
          ],
        ),
      ),
    );
  }

  /// Keeps a section on one page, so a header band is never left alone at
  /// the bottom of a page and notes stay under their table. A section that
  /// may not fit on one page is returned as separate widgets, so its table
  /// flows across pages with the header row repeated.
  static List<pw.Widget> _keepTogether(
    List<pw.Widget> children,
    double estimatedHeight,
  ) => estimatedHeight > 560 ? children : [_block(children)];

  /// A generous height estimate, in points, of a day section with these
  /// visits: header band, table, totals and notes.
  static double _visitsHeight(
    List<Visit> visits,
    Map<String, String> addressByCoord,
  ) {
    var height = 215.0;
    for (final v in visits) {
      final address = addressByCoord[_visitCoordKey(v)] ?? v.address;
      final shopLines =
          (v.placeName.length / 28).ceil() +
          (v.ownerName.trim().isEmpty ? 0 : 1) +
          (address.length / 38).ceil().clamp(1, 99);
      final remarkLines = (_remarkText(v).length / 22).ceil();
      final lines = [2, shopLines, remarkLines].reduce((a, b) => a > b ? a : b);
      height += lines * 9 + 10;
    }
    return height;
  }

  /// A generous height estimate, in points, of a day of external orders.
  static double _ordersHeight(List<ExternalOrder> orders) {
    var height = 200.0;
    for (final o in orders) {
      final client = (o.entityName ?? '').length;
      final rows = o.items.isEmpty ? 1 : o.items.length;
      height += rows * 18 + (client / 30).ceil() * 9;
    }
    return height;
  }

  static pw.Widget _block(List<pw.Widget> children) => _KeepTogether(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    ),
  );

  // ─────────────────────────────────────────────────────────── Data helpers

  static bool _isSalesDept(String department) {
    final d = department.toLowerCase();
    return d.contains('sales') || d.contains('marketing');
  }

  static String _siteOf(List<User> users) {
    for (final u in users) {
      final name = (u.shopName ?? '').trim();
      if (name.isNotEmpty) return name;
    }
    return 'PAANI.';
  }

  static bool _isProductive(Visit v) => v.orders.any((o) => o.isProductive);

  static double _num(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  /// Visit value = sum of (pieces + boxes) x rate over all order items.
  static double _visitValue(Visit v) {
    var total = 0.0;
    for (final o in v.orders) {
      for (final item in o.items) {
        total +=
            (_num(item['qty_pcs']) + _num(item['qty_box'])) *
            _num(item['rate']);
      }
    }
    return total;
  }

  static String _visitRemarkRaw(Visit v) =>
      v.orders.isNotEmpty && v.orders.first.remarks != null
      ? v.orders.first.remarks!
      : v.remarks ?? '';

  /// Time spent in the shop, stored in the remarks as "(XmYs)".
  static int? _staySeconds(Visit v) {
    final match = RegExp(r'\((\d+)m(\d+)s\)').firstMatch(_visitRemarkRaw(v));
    if (match == null) return null;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  static String _remarkText(Visit v) =>
      _visitRemarkRaw(v).replaceAll(RegExp(r'\(\d+m\d+s\)'), '').trim();

  static DateTime? _visitTime(Visit v) {
    final raw = v.orders.isNotEmpty && v.orders.first.orderDate.isNotEmpty
        ? v.orders.first.orderDate
        : v.createdAt;
    return _parseDate(raw);
  }

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final date = Utils.parseDateTime(raw);
      return date.year <= 2000 ? null : date;
    } catch (_) {
      return null;
    }
  }

  static List<Visit> _sortedVisits(List<Visit> visits) => [...visits]
    ..sort(
      (a, b) => (_visitTime(a) ?? DateTime(2000)).compareTo(
        _visitTime(b) ?? DateTime(2000),
      ),
    );

  /// Check-in/out times arrive as "HH:mm:ss", "hh:mm a" or a full date.
  static DateTime? _parseClock(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    final full = DateTime.tryParse(s);
    if (full != null) {
      return DateTime(2000, 1, 1, full.hour, full.minute, full.second);
    }
    final m = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?$',
    ).firstMatch(s);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final second = int.tryParse(m.group(3) ?? '') ?? 0;
    final meridiem = m.group(4)?.toUpperCase();
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return DateTime(2000, 1, 1, hour, minute, second);
  }

  static String _clockText(String? raw) {
    final parsed = _parseClock(raw);
    if (parsed != null) return DateFormat('hh:mm a').format(parsed);
    final s = (raw ?? '').trim();
    return s.isEmpty ? '-' : s;
  }

  static String _timeText(DateTime? time) =>
      time == null ? '-' : DateFormat('hh:mm a').format(time);

  static double _itemAmount(ExternalOrderItem item) => item.totalAmount > 0
      ? item.totalAmount
      : (item.qtyPcs + item.qtyBox) * item.rate;

  static double _orderValue(ExternalOrder o) =>
      o.items.fold<double>(0, (a, i) => a + _itemAmount(i));

  static double _orderQty(ExternalOrder o) =>
      o.items.fold<double>(0, (a, i) => a + i.qtyPcs + i.qtyBox);

  static double _orderFoc(ExternalOrder o) =>
      o.items.fold<double>(0, (a, i) => a + i.qtyFoc);

  static DateTime? _orderTime(ExternalOrder o) =>
      _parseDate(o.orderDate.isNotEmpty ? o.orderDate : o.createdAt);

  static DateTime _reportDate(ExternalClientReportModel r) {
    final date = DateTime.tryParse(r.date ?? '');
    if (date != null) return date;
    for (final o in r.orders) {
      final t = _orderTime(o);
      if (t != null) return t;
    }
    return DateTime(2000);
  }

  static int _clientCount(List<ExternalOrder> orders) => orders
      .map((o) => (o.entityName ?? o.entityNo ?? '').trim().toLowerCase())
      .where((n) => n.isNotEmpty)
      .toSet()
      .length;

  /// The top three keys by summed value.
  static List<MapEntry<String, double>> _topBy<T>(
    Iterable<T> items,
    String Function(T) key,
    double Function(T) value,
  ) {
    final totals = <String, double>{};
    for (final item in items) {
      final k = key(item);
      if (k.isEmpty) continue;
      totals[k] = (totals[k] ?? 0) + value(item);
    }
    final list = totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(3).toList();
  }

  static String? _topChannels(Map<String, int> channels, int visits) {
    if (channels.isEmpty || visits == 0) return null;
    final list = channels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list
        .take(4)
        .map((e) => '${e.key} ${e.value} (${_percent(e.value, visits)})')
        .join(', ');
  }

  static String? _topShop(Iterable<Visit> visits) {
    final counts = <String, int>{};
    final names = <String, String>{};
    for (final v in visits) {
      final name = v.placeName.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      names[key] = name;
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    if (top.value < 2) return null;
    return '${names[top.key]} (${top.value} visits)';
  }

  static int? _periodDays(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    if (b.isBefore(a)) return null;
    return b.difference(a).inDays + 1;
  }

  static final _moneyFormat = NumberFormat('#,##0');

  static String _money(double value) => _moneyFormat.format(value.round());

  static String _qty(double value) => value == value.roundToDouble()
      ? _moneyFormat.format(value.round())
      : value.toStringAsFixed(1);

  static String _percent(int part, int whole) =>
      whole == 0 ? '0%' : '${(part * 100 / whole).round()}%';

  static String _avg(int total, int count) =>
      count == 0 ? '0' : (total / count).toStringAsFixed(1);

  static String _avgDur(int seconds, int count) =>
      count == 0 ? '-' : _dur(seconds ~/ count);

  /// "1h 05m", "7m 30s" or "45s".
  static String _dur(int seconds) {
    if (seconds <= 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  static String _durMin(int minutes) =>
      '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';

  static String _title(String text) => text
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  static String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }
}

// ───────────────────────────────────────────────────────────────── Models

class _PdfTheme {
  _PdfTheme(String name, PdfColor? color)
    : brandName = name.trim().isEmpty ? 'PAANI.' : name.trim(),
      brand = color ?? const PdfColor.fromInt(0xFF117998),
      stamp = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

  final String brandName;
  final PdfColor brand;
  final String stamp;

  /// A very light wash of the brand colour for panels.
  PdfColor get tint => _mix(PdfColors.white, 0.92);

  /// A light brand colour for panel borders.
  PdfColor get soft => _mix(PdfColors.white, 0.72);

  /// A darker brand colour for headings on light panels.
  PdfColor get dark => _mix(PdfColors.black, 0.22);

  String get mark {
    final letters = brandName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return letters.isEmpty ? 'P' : letters[0].toUpperCase();
  }

  PdfColor _mix(PdfColor other, double amount) => PdfColor(
    brand.red + (other.red - brand.red) * amount,
    brand.green + (other.green - brand.green) * amount,
    brand.blue + (other.blue - brand.blue) * amount,
  );
}

class _Col {
  const _Col(this.label, this.flex, {this.align = pw.Alignment.centerLeft});

  final String label;
  final double flex;
  final pw.Alignment align;
}

class _Meta {
  const _Meta(this.label, this.value, {this.color});

  final String label;
  final String value;
  final PdfColor? color;
}

class _Kpi {
  const _Kpi(this.label, this.value, {this.color});

  final String label;
  final String value;
  final PdfColor? color;
}

class _UserDay {
  _UserDay(this.user, this.report) : stats = _DayStats.of(report);

  final User user;
  final EmployesWorkingDetailModel report;
  final _DayStats stats;
}

/// Attendance and visit figures for one day, or summed over many days.
class _DayStats {
  _DayStats({
    required this.date,
    required this.checkedIn,
    required this.checkedOut,
    required this.checkInText,
    required this.checkOutText,
    required this.workedMinutes,
    required this.visits,
    required this.productive,
    required this.value,
    required this.orderLines,
    required this.staySeconds,
    required this.stayCount,
    required this.firstVisit,
    required this.lastVisit,
    required this.channels,
  });

  factory _DayStats.of(EmployesWorkingDetailModel r) {
    var productive = 0, lines = 0, stay = 0, stayCount = 0;
    var value = 0.0;
    DateTime? first, last;
    final channels = <String, int>{};
    for (final v in r.visits) {
      if (PdfReportGenerator._isProductive(v)) productive++;
      value += PdfReportGenerator._visitValue(v);
      lines += v.orders.fold<int>(0, (a, o) => a + o.items.length);
      final seconds = PdfReportGenerator._staySeconds(v);
      if (seconds != null) {
        stay += seconds;
        stayCount++;
      }
      final time = PdfReportGenerator._visitTime(v);
      if (time != null) {
        if (first == null || time.isBefore(first)) first = time;
        if (last == null || time.isAfter(last)) last = time;
      }
      final channel = v.channel.trim().isEmpty
          ? 'Other'
          : PdfReportGenerator._title(v.channel);
      channels[channel] = (channels[channel] ?? 0) + 1;
    }

    final checkIn = PdfReportGenerator._parseClock(r.checkin?.time);
    final checkOut = PdfReportGenerator._parseClock(r.checkout?.time);
    final worked =
        checkIn != null && checkOut != null && checkOut.isAfter(checkIn)
        ? checkOut.difference(checkIn).inMinutes
        : 0;

    return _DayStats(
      date: r.date,
      checkedIn: r.checkin != null,
      checkedOut: r.checkout != null,
      checkInText: r.checkin == null
          ? '-'
          : PdfReportGenerator._clockText(r.checkin!.time),
      checkOutText: r.checkout == null
          ? '-'
          : PdfReportGenerator._clockText(r.checkout!.time),
      workedMinutes: worked,
      visits: r.visits.length,
      productive: productive,
      value: value,
      orderLines: lines,
      staySeconds: stay,
      stayCount: stayCount,
      firstVisit: first,
      lastVisit: last,
      channels: channels,
    );
  }

  static _DayStats sum(List<_DayStats> days) {
    final channels = <String, int>{};
    for (final d in days) {
      d.channels.forEach((k, v) => channels[k] = (channels[k] ?? 0) + v);
    }
    int add(int Function(_DayStats) f) => days.fold<int>(0, (a, d) => a + f(d));
    return _DayStats(
      date: days.isEmpty ? DateTime(2000) : days.first.date,
      checkedIn: days.any((d) => d.checkedIn),
      checkedOut: days.any((d) => d.checkedOut),
      checkInText: '-',
      checkOutText: '-',
      workedMinutes: add((d) => d.workedMinutes),
      visits: add((d) => d.visits),
      productive: add((d) => d.productive),
      value: days.fold<double>(0, (a, d) => a + d.value),
      orderLines: add((d) => d.orderLines),
      staySeconds: add((d) => d.staySeconds),
      stayCount: add((d) => d.stayCount),
      firstVisit: null,
      lastVisit: null,
      channels: channels,
    );
  }

  final DateTime date;
  final bool checkedIn;
  final bool checkedOut;
  final String checkInText;
  final String checkOutText;
  final int workedMinutes;
  final int visits;
  final int productive;
  final double value;
  final int orderLines;
  final int staySeconds;
  final int stayCount;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
  final Map<String, int> channels;

  /// Present means a check-in or at least one visit was recorded.
  bool get present => checkedIn || visits > 0;
  int get nonProductive => visits - productive;
  String get hoursText =>
      workedMinutes > 0 ? PdfReportGenerator._durMin(workedMinutes) : '-';
}

/// Lays its child out once to measure it. A child that fits on one page is
/// kept whole (moved to the next page if needed); a taller child is allowed
/// to span pages like a plain Column.
class _KeepTogether extends pw.SingleChildWidget {
  _KeepTogether({required pw.Widget child}) : super(child: child);

  /// Safely below the usable A4 height (page minus margins, header and
  /// footer), so a kept block always fits on a fresh page.
  static const _maxHeight = 660.0;

  bool? _span;

  @override
  bool get canSpan => (_span ?? false) && super.canSpan;

  @override
  bool get hasMoreWidgets => (_span ?? false) && super.hasMoreWidgets;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    super.layout(context, constraints, parentUsesSize: parentUsesSize);
    _span ??= box!.height > _maxHeight;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context);
  }
}
