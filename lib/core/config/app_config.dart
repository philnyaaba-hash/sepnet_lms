import 'package:flutter/foundation.dart';

import 'platform.dart';

/// Which concrete [PythonRuntime] implementation the app should build.
enum PythonRuntimeKind {
  /// Real embedded CPython via the `serious_python` plugin. On-device default.
  seriousPython,

  /// Spawns a host CPython child process. Development/test default.
  process,

  /// In-process fake that returns canned results. Used by widget tests that do
  /// not care about real execution.
  fake,
}

/// Central, compile-time/`--dart-define`-driven configuration.
///
/// Nothing here contains secrets. Anything environment specific (LMS base URL,
/// auth provider) is injected at build time via `--dart-define` and validated
/// at startup. See `docs/LMS_INTEGRATION.md`.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.lmsBaseUrl,
    required this.lmsClientId,
    required this.runtimeKind,
    required this.pythonExecutable,
    required this.executionTimeout,
    required this.maxOutputChars,
  });

  final String environment;
  final String lmsBaseUrl;
  final String lmsClientId;

  /// True when no real LMS URL was supplied and the mock must be used.
  bool get useMockLms => lmsBaseUrl.isEmpty;

  final PythonRuntimeKind runtimeKind;
  final String pythonExecutable;
  final Duration executionTimeout;
  final int maxOutputChars;

  static const String _env = String.fromEnvironment('SB_ENV', defaultValue: 'development');
  static const String _lmsBaseUrl = String.fromEnvironment('SB_LMS_BASE_URL');
  static const String _lmsClientId = String.fromEnvironment('SB_LMS_CLIENT_ID');
  static const String _runtime = String.fromEnvironment('SB_PYTHON_RUNTIME');
  static const String _pythonExe = String.fromEnvironment('SB_PYTHON_EXECUTABLE', defaultValue: '');

  /// Builds the configuration for the current platform.
  ///
  /// Runtime selection rules:
  ///  * Explicit `SB_PYTHON_RUNTIME` always wins.
  ///  * Otherwise mobile (Android/iOS) uses the embedded runtime and desktop
  ///    (dev/test) uses the host process, which is what makes automated
  ///    execution tests possible on a developer machine.
  factory AppConfig.forCurrentPlatform() {
    final kind = _resolveRuntimeKind();
    return AppConfig(
      environment: _env,
      lmsBaseUrl: _lmsBaseUrl,
      lmsClientId: _lmsClientId,
      runtimeKind: kind,
      pythonExecutable: _pythonExe.isEmpty ? _defaultPythonExecutable() : _pythonExe,
      executionTimeout: const Duration(seconds: 10),
      maxOutputChars: 200000,
    );
  }

  /// Configuration used by tests; the runtime kind is always injected.
  factory AppConfig.test({
    PythonRuntimeKind runtimeKind = PythonRuntimeKind.fake,
    String lmsBaseUrl = '',
  }) {
    return AppConfig(
      environment: 'test',
      lmsBaseUrl: lmsBaseUrl,
      lmsClientId: 'test-client',
      runtimeKind: runtimeKind,
      pythonExecutable: _defaultPythonExecutable(),
      executionTimeout: const Duration(seconds: 10),
      maxOutputChars: 200000,
    );
  }

  static PythonRuntimeKind _resolveRuntimeKind() {
    switch (_runtime) {
      case 'serious':
      case 'serious_python':
        return PythonRuntimeKind.seriousPython;
      case 'process':
        return PythonRuntimeKind.process;
      case 'fake':
        return PythonRuntimeKind.fake;
    }
    if (kIsWeb) return PythonRuntimeKind.fake;
    if (isAndroid || isIOS) {
      return PythonRuntimeKind.seriousPython;
    }
    return PythonRuntimeKind.process;
  }

  static String _defaultPythonExecutable() {
    if (kIsWeb) return 'python';
    return isWindows ? 'python' : 'python3';
  }
}
