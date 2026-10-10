import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/app/app.dart';
import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/features/editor/widgets/output_console.dart';
import 'package:skillbridge_python_lab/features/home/connectivity_controller.dart';
import 'package:skillbridge_python_lab/features/python_runtime/process_python_runtime.dart';
import 'package:skillbridge_python_lab/features/settings/settings_controller.dart';

import 'support/test_dependencies.dart';

/// The editor, driven end to end against a **real** CPython interpreter.
///
/// Everything else in `widget_test.dart` runs against `FakePythonRuntime`, and
/// everything in `python_runtime_process_test.dart` runs the interpreter with no
/// editor attached. That left the most important path in the app untested: type
/// here, run there. This file joins the two halves, using the production
/// `EditorController`, the production repositories and the production
/// `harness_cli.py` — only the widget tree and the OS are different from a real
/// run.
///
/// Skipped (not silently passed) when no interpreter is available; override
/// with `SB_TEST_PYTHON`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final python = Platform.environment['SB_TEST_PYTHON'] ??
      (Platform.isWindows ? 'python' : 'python3');
  final harnessPath = ProcessPythonRuntime.resolveHarnessPath();

  var pythonAvailable = false;
  var harnessAvailable = false;

  late AppDependencies deps;

  setUpAll(() async {
    harnessAvailable = File(harnessPath).existsSync();
    try {
      final probe = await Process.run(python, ['--version']);
      pythonAvailable = probe.exitCode == 0;
    } on ProcessException {
      pythonAvailable = false;
    }
  });

  setUp(() async {
    deps = await buildTestDependencies(
      runtime: ProcessPythonRuntime(
        pythonExecutable: python,
        harnessPath: harnessPath,
        defaultTimeout: const Duration(seconds: 20),
      ),
    );
  });

  tearDown(() async {
    await deps.dispose();
  });

  /// Returns `true` when the interpreter is unavailable, in which case the
  /// caller must skip rather than pretend the assertion passed.
  bool skipWithoutInterpreter() {
    if (pythonAvailable && harnessAvailable) return false;
    markTestSkipped(
      'Skipped: no usable Python (interpreter="$python" available=$pythonAvailable, '
      'harness="$harnessPath" available=$harnessAvailable). '
      'Set SB_TEST_PYTHON to a working interpreter to run this test.',
    );
    return true;
  }

  /// Advances real time and frames until [finder] matches.
  ///
  /// Spawning an interpreter is genuine I/O, so unlike the rest of the suite
  /// this cannot finish in a few pumped frames: the work completes on the real
  /// event loop, which only turns while `runAsync` is awaited.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxIterations = 120,
    Duration step = const Duration(milliseconds: 50),
  }) async {
    for (var i = 0; i < maxIterations; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.runAsync(() => Future<void>.delayed(step));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> pumpFrames(WidgetTester tester, {int count = 10}) async {
    for (var i = 0; i < count; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDependencies>.value(value: deps),
          ChangeNotifierProvider<SettingsController>(
            create: (_) => SettingsController(deps.settings),
          ),
          ChangeNotifierProvider<ConnectivityController>(
            create: (_) => ConnectivityController(deps),
          ),
        ],
        child: const SkillBridgeApp(),
      ),
    );
    await pumpFrames(tester);
  }

  /// Drives Home -> exercise details -> editor.
  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.text('Hello, World!'));
    await pumpFrames(tester);

    final startCoding = find.text('Start coding');
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 12 && startCoding.evaluate().isEmpty; i++) {
      await tester.drag(scrollable, const Offset(0, -300));
      await pumpFrames(tester, count: 2);
    }
    expect(startCoding, findsOneWidget, reason: 'never became visible');

    await tester.tap(startCoding);
    await pumpFrames(tester);
  }

  /// Everything the output console is showing.
  ///
  /// Success and failure render differently: a run with output uses a
  /// [SelectableText] buffer, while an exception is a plain [Text] inside the
  /// error block. Collecting both keeps assertions valid for either shape.
  String consoleText(WidgetTester tester) {
    final root = find.byType(OutputConsole);
    final buffer = StringBuffer();

    final plain = tester.widgetList<Text>(
      find.descendant(of: root, matching: find.byType(Text)),
    );
    for (final t in plain) {
      buffer.writeln(t.data ?? t.textSpan?.toPlainText() ?? '');
    }

    final selectable = tester.widgetList<SelectableText>(
      find.descendant(of: root, matching: find.byType(SelectableText)),
    );
    for (final s in selectable) {
      buffer.writeln(s.data ?? s.textSpan?.toPlainText() ?? '');
    }

    return buffer.toString();
  }

  group('editor with a real interpreter', () {
    testWidgets('typed code is executed by CPython and its stdout is shown',
        (tester) async {
      if (skipWithoutInterpreter()) return;

      await pumpApp(tester);
      await openEditor(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tap Run to see the output here.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        "import sys\nprint('Hello, World!')\nprint('minor', sys.version_info[1])\n",
      );
      await pumpFrames(tester, count: 3);

      await tester.tap(find.text('Run'));

      // Real execution: wait for the interpreter, not for pumped frames.
      await pumpUntil(tester, find.text('Finished successfully'));

      expect(find.text('Finished successfully'), findsOneWidget,
          reason: 'the real runtime never reported success');

      final data = consoleText(tester);
      expect(data, contains('Hello, World!'),
          reason: 'stdout did not reach the console: "$data"');
      expect(data, contains('minor'),
          reason: 'a real interpreter must import sys; got "$data"');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a syntax error surfaces as a Python exception, not a crash',
        (tester) async {
      if (skipWithoutInterpreter()) return;

      await pumpApp(tester);
      await openEditor(tester);

      await tester.enterText(
        find.byType(TextField),
        "def broken(:\n    pass\n",
      );
      await pumpFrames(tester, count: 3);

      await tester.tap(find.text('Run'));
      await pumpUntil(
        tester,
        find.textContaining('SyntaxError'),
      );

      expect(find.text('Stopped with an error'), findsOneWidget,
          reason: 'the real runtime never reported the failure');

      final data = consoleText(tester);
      expect(data, contains('SyntaxError'),
          reason: 'expected a real Python SyntaxError; got "$data"');
      // The app must survive it: the Run button is still there.
      expect(find.text('Run'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
