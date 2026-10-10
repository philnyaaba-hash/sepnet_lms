import 'package:skillbridge_python_lab/core/config/app_config.dart';
import 'fake_python_runtime.dart';
import 'process_python_runtime.dart';
import 'python_runtime.dart';
import 'serious_python_runtime.dart';

/// Constructs the runtime selected by [AppConfig.runtimeKind].
///
/// This is the single place that knows about concrete runtimes, keeping the
/// rest of the app dependent only on the [PythonRuntime] interface.
PythonRuntime createPythonRuntime(AppConfig config) {
  switch (config.runtimeKind) {
    case PythonRuntimeKind.seriousPython:
      return SeriousPythonRuntime(
        defaultTimeout: config.executionTimeout,
        defaultMaxOutputChars: config.maxOutputChars,
      );
    case PythonRuntimeKind.process:
      return ProcessPythonRuntime(
        pythonExecutable: config.pythonExecutable,
        defaultTimeout: config.executionTimeout,
        defaultMaxOutputChars: config.maxOutputChars,
      );
    case PythonRuntimeKind.fake:
      return FakePythonRuntime();
  }
}
