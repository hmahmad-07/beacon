import 'dart:async';

import 'package:flutter/foundation.dart';

class UiController extends ChangeNotifier {
  final Map<Object, Object?> _values = {};

  T valueOf<T>(Object owner, T fallback) => (_values[owner] as T?) ?? fallback;

  void setValue(Object owner, Object? value) {
    if (_values[owner] == value) return;
    _values[owner] = value;
    notifyListeners();
  }

  void initValue(Object owner, Object? value) => _values[owner] = value;

  void forget(Object owner) => _values.remove(owner);

  // ================================================================= Clock =================================================================
  // Drives the live time and date on the home greeting. Kept in its own
  // notifier so a tick only rebuilds the greeting, not every UiController
  // listener.

  /// Current time, kept in step with DateTime.now(). Changes once a minute.
  final ValueNotifier<DateTime> clock = ValueNotifier(DateTime.now());

  Timer? _clockTimer;

  /// Starts checking DateTime.now() every second. Safe to call more than once.
  void startClock() {
    _syncClock();
    if (_clockTimer?.isActive ?? false) return;
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncClock(),
    );
  }

  /// Updates [clock] only when the minute changes, so the greeting rebuilds
  /// once a minute rather than every second.
  void _syncClock() {
    final now = DateTime.now();
    final shown = clock.value;
    final sameMinute =
        now.year == shown.year &&
        now.month == shown.month &&
        now.day == shown.day &&
        now.hour == shown.hour &&
        now.minute == shown.minute;
    if (!sameMinute) clock.value = now;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    clock.dispose();
    super.dispose();
  }
}
