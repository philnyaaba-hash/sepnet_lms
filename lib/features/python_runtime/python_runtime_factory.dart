import 'package:skillbridge_python_lab/core/config/app_config.dart';
import 'fake_python_runtime.dart';
import 'python_runtime.dart';
import 'python_runtime_factory_io.dart'
    if (dart.library.html) 'python_runtime_factory_web.dart';

/// Constructs the runtime selected by [AppConfig.runtimeKind].
///
/// This is the single place that knows about concrete runtimes, keeping the
/// rest of the app dependent only on the [PythonRuntime] interface.
///
/// The concrete runtimes live behind a conditional import. Both the embedded
/// runtime (`dart:ffi`) and the host-process runtime (`dart:io`) are
/// unavailable in a browser, and merely importing them is a *compile* error on
/// web — not a runtime one. Splitting the implementation lets the web build
/// resolve to a stub that refuses those two kinds outright.
PythonRuntime createPythonRuntime(AppConfig config) {
  switch (config.runtimeKind) {
    case PythonRuntimeKind.seriousPython:
      return createSeriousPythonRuntime(
        defaultTimeout: config.executionTimeout,
        defaultMaxOutputChars: config.maxOutputChars,
      );
    case PythonRuntimeKind.process:
      return createProcessPythonRuntime(
        pythonExecutable: config.pythonExecutable,
        defaultTimeout: config.executionTimeout,
        defaultMaxOutputChars: config.maxOutputChars,
      );
    case PythonRuntimeKind.fake:
      return FakePythonRuntime();
  }
}
