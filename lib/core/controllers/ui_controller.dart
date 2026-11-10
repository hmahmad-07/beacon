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
}
