import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';

/// Exposes connection status, the pending-submission count and a manual sync
/// trigger to the UI. Also auto-syncs when connectivity is restored.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController(this._deps) {
    _online = _deps.connectivity.isOnline;
    _subscription = _deps.connectivity.onChanged.listen(_onConnectivityChanged);
    unawaited(refreshPendingCount());
  }

  final AppDependencies _deps;
  StreamSubscription<bool>? _subscription;

  bool _online = true;
  int _pendingCount = 0;
  bool _syncing = false;
  DateTime? _lastSyncAt;
  String? _lastMessage;

  bool get isOnline => _online;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _syncing;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastMessage => _lastMessage;

  Future<void> refreshPendingCount() async {
    _pendingCount = await _deps.submissions.pendingCount(_deps.learnerRef);
    notifyListeners();
  }

  void _onConnectivityChanged(bool online) {
    _online = online;
    notifyListeners();
    if (online) {
      unawaited(syncNow());
    }
  }

  /// Runs a synchronization pass and updates local status.
  Future<void> syncNow() async {
    if (_syncing) return;
    if (!_deps.connectivity.isOnline) {
      _lastMessage = "You're offline. Work is saved and will sync later.";
      notifyListeners();
      return;
    }
    _syncing = true;
    _lastMessage = null;
    notifyListeners();
    try {
      final report = await _deps.syncService.syncPending(_deps.learnerRef);
      _lastSyncAt = DateTime.now();
      await _deps.settings.setLastSyncAt(_lastSyncAt!);
      if (report.authExpired) {
        _lastMessage = 'Please sign in again to sync your work.';
      } else if (report.didWork) {
        _lastMessage = 'Synced ${report.accepted + report.rejected} of ${report.attempted} submissions.';
      } else {
        _lastMessage = 'Everything is up to date.';
      }
    } finally {
      _syncing = false;
      await refreshPendingCount();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
