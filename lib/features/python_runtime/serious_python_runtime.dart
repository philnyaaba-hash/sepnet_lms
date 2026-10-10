import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serious_python/serious_python.dart';

import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'execution_result.dart';
import 'python_runtime.dart';

/// Executes Python using the *embedded* CPython runtime provided by the
/// `serious_python` plugin, as required for on-device (Android/iOS) execution.
///
/// Serious Python does not expose a "call this Python function" API. Instead it
/// runs a Python *program* and the two sides communicate over an API the
/// program provides. We package `python_app/main.py`, which starts a
/// loopback-only HTTP server exposing `/health` and `/execute`; this class
/// drives that server over `http://127.0.0.1`.
///
/// Packaging (run once before a device build) — see `docs/BUILD_AND_RELEASE.md`.
/// `serious_python` 5.0.0 stages the processed app into `SERIOUS_PYTHON_APP`,
/// which the platform build then copies into the bundle, so the variable has to
/// be set for both the package command and `flutter build`:
///
/// ```
/// $env:SERIOUS_PYTHON_APP           = "$PWD/build/python-app"
/// $env:SERIOUS_PYTHON_SITE_PACKAGES = "$PWD/build/python-site-packages"
/// dart run serious_python:main package python_app -p Android
/// dart run serious_python:main package python_app -p iOS
/// ```
class SeriousPythonRuntime implements PythonRuntime {
  SeriousPythonRuntime({
    this.port = 8791,
    this.defaultTimeout = const Duration(seconds: 10),
    this.defaultMaxOutputChars = 200000,
    http.Client? httpClient,
    Future<void> Function()? startHook,
  })  : _http = httpClient ?? http.Client(),
        _startHook = startHook ?? _defaultStartHook;

  final int port;
  final Duration defaultTimeout;
  final int defaultMaxOutputChars;
  final http.Client _http;
  final Future<void> Function() _startHook;

  bool _ready = false;
  bool _started = false;

  Uri get _base => Uri.parse('http://127.0.0.1:$port');

  @override
  String get displayName => 'Embedded CPython (Serious Python)';

  @override
  bool get isReady => _ready;

  static Future<void> _defaultStartHook() async {
    // Runs the packaged program on a background thread; this future never
    // completes for our long-lived server, so it must not be awaited.
    unawaited(SeriousPython.run(
      appFileName: 'main.py',
      environmentVariables: {'SKILLBRIDGE_PORT': '8791'},
    ));
  }

  @override
  Future<void> prepare() async {
    if (_ready) return;
    if (!_started) {
      _started = true;
      try {
        await _startHook();
      } catch (e) {
        throw RuntimeException('Could not start the embedded Python runtime.', cause: e);
      }
    }

    // Poll the health endpoint until the interpreter is accepting requests.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await _http
            .get(_base.replace(path: '/health'))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['ok'] == true) {
            _ready = true;
            return;
          }
        }
      } catch (_) {
        // Not up yet; keep polling.
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    throw RuntimeException('The embedded Python runtime did not start in time.');
  }

  @override
  Future<ExecutionResult> execute(ExecutionRequest request) async {
    if (!_ready) {
      await prepare();
    }
    final timeout = request.timeout ?? defaultTimeout;
    final maxChars = request.maxOutputChars ?? defaultMaxOutputChars;

    try {
      final response = await _http
          .post(
            _base.replace(path: '/execute'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': request.code,
              'stdin': request.stdinLines,
              'maxOutputChars': maxChars,
            }),
          )
          // A little grace beyond the in-Python alarm so the result can travel back.
          .timeout(timeout + const Duration(seconds: 2));

      if (response.statusCode != 200) {
        return ExecutionResult.runtimeFailure(
          'The Python runtime returned status ${response.statusCode}.',
        );
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return ExecutionResult.fromJson(map);
    } on TimeoutException {
      // The in-interpreter SIGALRM should fire first on POSIX; this is a fallback.
      return ExecutionResult.timedOut(timeout);
    } catch (e) {
      return ExecutionResult.runtimeFailure('Python execution failed: $e');
    }
  }

  @override
  Future<void> cancel() async {
    // The embedded runtime owns the interpreter thread and exposes no kill
    // primitive. Cancellation is therefore best-effort: the on-device
    // SIGALRM/host timeout stops runaway programs. Documented as a limitation.
  }

  @override
  Future<void> dispose() async {
    _http.close();
    _ready = false;
  }
}
