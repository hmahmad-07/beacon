import 'package:intl/intl.dart';

/// Date helpers shared by the inventory Items / Stock / Expiry / Ledger
/// screens. Every list there is shown latest-date-first and grouped
/// under a day header, so the parsing, sorting and grouping live here
/// instead of being re-implemented per screen.
class InventoryDates {
  InventoryDates._();

  static final _day = DateFormat('d MMM yyyy');
  static final _dayShort = DateFormat('d MMM');
  static final _weekday = DateFormat('EEEE');
  static final _time = DateFormat('h:mm a');

  /// API dates are "yyyy-MM-dd" or "yyyy-MM-dd HH:mm:ss" (modified_date
  /// is often null). Null/empty/zero dates return null so they sort last.
  static DateTime? parse(String? raw) {
    if (raw == null || raw.isEmpty || raw.startsWith('0000')) return null;
    return DateTime.tryParse(raw);
  }

  /// "yyyy-MM-dd" for the modified_from / modified_to / from_date params.
  static String api(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime? dayOf(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);

  /// Newest first; undated rows go last, original order kept among ties.
  static List<T> sortLatestFirst<T>(
    Iterable<T> items,
    DateTime? Function(T) dateOf,
  ) {
    final indexed = items.toList().asMap().entries.toList();
    indexed.sort((a, b) {
      final da = dateOf(a.value);
      final db = dateOf(b.value);
      if (da == null && db == null) return a.key.compareTo(b.key);
      if (da == null) return 1;
      if (db == null) return -1;
      final c = db.compareTo(da);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  /// Groups an already-sorted list into consecutive day buckets. A null
  /// key means "no date".
  static List<MapEntry<DateTime?, List<T>>> groupByDay<T>(
    List<T> sorted,
    DateTime? Function(T) dateOf,
  ) {
    final groups = <MapEntry<DateTime?, List<T>>>[];
    for (final item in sorted) {
      final day = dayOf(dateOf(item));
      if (groups.isNotEmpty && groups.last.key == day) {
        groups.last.value.add(item);
      } else {
        groups.add(MapEntry(day, [item]));
      }
    }
    return groups;
  }

  /// "Today" / "Yesterday" / "Monday" (within the last week) / "3 Sep 2026".
  static String dayLabel(DateTime? day) {
    if (day == null) return 'No date';
    final today = dayOf(DateTime.now())!;
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return _weekday.format(day);
    return _day.format(day);
  }

  static String full(DateTime? d) => d == null ? '—' : _day.format(d);
  static String short(DateTime? d) => d == null ? '—' : _dayShort.format(d);

  /// Time of day, or null when the API sent a date-only / midnight value.
  static String? timeOf(DateTime? d) {
    if (d == null || (d.hour == 0 && d.minute == 0 && d.second == 0)) {
      return null;
    }
    return _time.format(d);
  }

  /// "Updated 2 days ago"-style relative phrase for card footers.
  static String relative(DateTime? d) {
    if (d == null) return 'No activity';
    final diff = dayOf(DateTime.now())!.difference(dayOf(d)!).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 30) return '$diff days ago';
    return _day.format(d);
  }
}
