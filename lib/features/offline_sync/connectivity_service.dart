import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity signal used by the offline-first features.
///
/// Wrapped behind an interface so tests can drive "online/offline" transitions
/// deterministically without touching platform channels.
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onChanged;
  Future<void> refresh();
  Future<void> dispose();
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen(_emit);
    unawaited(refresh());
  }

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onChanged => _controller.stream;

  @override
  Future<void> refresh() async {
    _emit(await _connectivity.checkConnectivity());
  }

  void _emit(List<ConnectivityResult> results) {
    // "Online" means at least one real transport is available. `none` alone is
    // offline. (A connection existing does not guarantee internet, which is why
    // the LMS client still handles network errors and retries.)
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _online) {
      _online = online;
      _controller.add(online);
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}

/// Deterministic connectivity for tests and previews.
class FakeConnectivityService implements ConnectivityService {
  // ignore: prefer_initializing_formals
  FakeConnectivityService({bool online = true}) : _online = online;

  final _controller = StreamController<bool>.broadcast();
  bool _online;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onChanged => _controller.stream;

  void setOnline(bool value) {
    if (value == _online) return;
    _online = value;
    _controller.add(value);
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> dispose() async => _controller.close();
}
