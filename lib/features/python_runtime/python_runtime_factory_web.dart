/// Web implementation of the runtime factory.
///
/// A browser cannot spawn a subprocess (`dart:io`) and cannot load a native
/// library (`dart:ffi`), so neither real runtime exists here. `AppConfig`
/// already selects [PythonRuntimeKind.fake] on web, so these two paths should
/// be unreachable; if they are reached it is because someone forced
/// `SB_PYTHON_RUNTIME` to a native value at build time, and a loud error beats
/// a silent one.
library;

import 'package:skillbridge_python_lab/core/config/app_config.dart';
import 'python_runtime.dart';

/// Refused: the web build has no embedded interpreter.
PythonRuntime createSeriousPythonRuntime({
  required Duration defaultTimeout,
  required int defaultMaxOutputChars,
}) {
  throw UnsupportedError(
    'The embedded Python runtime is not available on the web: it needs '
    'dart:ffi, which browsers do not provide. Build for Android or iOS, or '
    'set SB_PYTHON_RUNTIME=fake.',
  );
}

/// Refused: the web build cannot spawn a subprocess.
PythonRuntime createProcessPythonRuntime({
  required String pythonExecutable,
  required Duration defaultTimeout,
  required int defaultMaxOutputChars,
}) {
  throw UnsupportedError(
    'The host-process Python runtime is not available on the web: it needs '
    'dart:io, which browsers do not provide. Build for desktop or mobile, or '
    'set SB_PYTHON_RUNTIME=fake.',
  );
}
