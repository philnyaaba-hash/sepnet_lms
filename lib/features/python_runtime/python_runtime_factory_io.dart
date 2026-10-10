/// Native/desktop implementation of the runtime factory.
///
/// Imported on every platform that has `dart:io` and `dart:ffi`. The browser
/// build resolves to `python_runtime_factory_web.dart` instead, because these
/// two runtimes cannot exist there.
library;

import 'process_python_runtime.dart';
import 'python_runtime.dart';
import 'serious_python_runtime.dart';

/// Real embedded CPython via the `serious_python` plugin.
PythonRuntime createSeriousPythonRuntime({
  required Duration defaultTimeout,
  required int defaultMaxOutputChars,
}) {
  return SeriousPythonRuntime(
    defaultTimeout: defaultTimeout,
    defaultMaxOutputChars: defaultMaxOutputChars,
  );
}

/// Spawns a host CPython child process. Development and test default.
PythonRuntime createProcessPythonRuntime({
  required String pythonExecutable,
  required Duration defaultTimeout,
  required int defaultMaxOutputChars,
}) {
  return ProcessPythonRuntime(
    pythonExecutable: pythonExecutable,
    defaultTimeout: defaultTimeout,
    defaultMaxOutputChars: defaultMaxOutputChars,
  );
}
