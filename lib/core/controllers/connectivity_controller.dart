import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../extensions/routes.dart';
import 'employes_controller.dart';

class ConnectivityController extends ChangeNotifier {
  ConnectivityController() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> _init() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _applyResults(initial, notify: false);
      notifyListeners();
    } catch (_) {
      _isOnline = true;
      notifyListeners();
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      _applyResults,
      onError: (_) {
        _isOnline = true;
        notifyListeners();
      },
    );
  }

  void _applyResults(List<ConnectivityResult> results, {bool notify = true}) {
    final next = _resultsIndicateConnection(results);
    final wasOffline = !_isOnline;
    if (next == _isOnline) {
      if (notify) notifyListeners();
      return;
    }
    _isOnline = next;
    if (notify) notifyListeners();

    if (_isOnline && wasOffline) {
      _bestEffortRefreshAfterReconnect();
    }
  }

  static bool _resultsIndicateConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void _bestEffortRefreshAfterReconnect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRoutes.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      try {
        ctx.read<EmployesController>().getSites(ctx);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
