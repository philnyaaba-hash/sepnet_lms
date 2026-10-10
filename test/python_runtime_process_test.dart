import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:skillbridge_python_lab/features/python_runtime/execution_result.dart';
import 'package:skillbridge_python_lab/features/python_runtime/process_python_runtime.dart';
import 'package:skillbridge_python_lab/features/python_runtime/python_runtime.dart';

/// End-to-end execution tests against a **real** CPython interpreter.
///
/// These run `python_app/harness_cli.py`, the exact same executor that ships
/// inside the app, so the behaviour verified here is the behaviour learners get.
///
/// The tests are skipped (not silently passed) when no interpreter is
/// available; the interpreter can be overridden with `SB_TEST_PYTHON`.
void main() {
  final python = Platform.environment['SB_TEST_PYTHON'] ??
      (Platform.isWindows ? 'python' : 'python3');
  final harnessPath = ProcessPythonRuntime.resolveHarnessPath();

  var pythonAvailable = false;
  var harnessAvailable = false;
  String interpreterVersion = '';

  ProcessPythonRuntime runtime() => ProcessPythonRuntime(
        pythonExecutable: python,
        harnessPath: harnessPath,
        defaultTimeout: const Duration(seconds: 20),
      );

  setUpAll(() async {
    harnessAvailable = File(harnessPath).existsSync();
    try {
      final probe = await Process.run(python, ['--version']);
      pythonAvailable = probe.exitCode == 0;
      interpreterVersion =
          ('${probe.stdout}${probe.stderr}').trim();
    } on ProcessException {
      pythonAvailable = false;
    }
  });

  /// Returns `true` when the interpreter is unavailable, in which case the
  /// caller must skip rather than pretend the assertion passed.
  bool skipWithoutInterpreter() {
    if (pythonAvailable && harnessAvailable) return false;
    markTestSkipped(
      'Skipped: no usable Python (interpreter="$python" available=$pythonAvailable, '
      'harness="$harnessPath" available=$harnessAvailable). '
      'Set SB_TEST_PYTHON to a working interpreter to run these tests.',
    );
    return true;
  }

  group('real CPython execution', () {
    test('the interpreter probe reports a real version', () async {
      if (skipWithoutInterpreter()) return;
      expect(interpreterVersion, startsWith('Python 3'));
    });

    test('prepare() verifies the harness and interpreter', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      await rt.prepare();
      expect(rt.isReady, isTrue);
      expect(rt.displayName, contains(python));
      await rt.dispose();
    });

    test('runs a hello world program', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: 'print("Hello, World!")\n',
      ));

      expect(result.status, ExecutionStatus.success);
      expect(result.stdout, 'Hello, World!\n');
      expect(result.stderr, isEmpty);
      expect(result.exception, isNull);
      expect(result.pythonVersion, startsWith('3.'));
      expect(result.durationMs, greaterThanOrEqualTo(0));
      expect(result.isSuccess, isTrue);
    });

    test('feeds input() from stdin lines without blocking', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: "name = input('What is your name? ')\n"
            "age = int(input('How old are you? '))\n"
            "print('Hello', name)\n"
            "print('Next year you will be', age + 1)\n",
        stdinLines: ['Ama', '13'],
      ));

      expect(result.status, ExecutionStatus.success);
      expect(result.stdout, contains('What is your name? '));
      expect(result.stdout, contains('Hello Ama'));
      expect(result.stdout, contains('Next year you will be 14'));
    });

    test('running out of input raises a beginner-friendly EOFError', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: 'first = input()\nsecond = input()\n',
        stdinLines: ['only-one'],
      ));

      expect(result.status, ExecutionStatus.error);
      expect(result.exception!.type, 'EOFError');
      expect(result.exception!.friendlyLabel, isNotEmpty);
    });

    test('evaluates loops, functions and lists correctly', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: 'total = 0\n'
            'for i in range(1, 6):\n'
            '    total += i\n'
            'def square(n):\n'
            '    return n * n\n'
            'fruits = ["mango", "banana"]\n'
            'print(total)\n'
            'print(square(4))\n'
            'for f in fruits:\n'
            '    print(f)\n',
      ));

      expect(result.status, ExecutionStatus.success);
      expect(result.stdout, '15\n16\nmango\nbanana\n');
    });

    test('reports a syntax error with a line number', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: 'print("hello")\ndef broken(:\n    pass\n',
      ));

      expect(result.status, ExecutionStatus.error);
      expect(result.exception!.type, 'SyntaxError');
      expect(result.exception!.line, greaterThan(0));
      expect(result.exception!.message, contains('Syntax error on line'));
      expect(result.exception!.friendlyLabel, startsWith('There is a spelling'));
      expect(
        result.stdout,
        isEmpty,
        reason: 'Python compiles the whole program before running any of it, '
            'so a syntax error means nothing was executed.',
      );
      expect(result.exception!.traceback, contains('def broken(:'));
    });

    test('reports a runtime IndexError from learner code', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: 'items = [1, 2, 3]\nprint(items[99])\n',
      ));

      expect(result.status, ExecutionStatus.error);
      expect(result.exception!.type, 'IndexError');
      expect(result.exception!.friendlyLabel,
          'You asked for an item that is outside the list.');
      expect(result.exception!.traceback, contains('items[99]'));
      expect(result.exception!.traceback, isNot(contains('skillbridge_exec.py')));
    });

    test('reports ZeroDivisionError', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result =
          await rt.execute(const ExecutionRequest(code: 'print(10 / 0)\n'));

      expect(result.status, ExecutionStatus.error);
      expect(result.exception!.type, 'ZeroDivisionError');
    });

    test('truncates runaway output and flags it', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: "print('x' * 5000)\n",
        maxOutputChars: 64,
      ));

      expect(result.status, ExecutionStatus.success);
      expect(result.stdoutTruncated, isTrue);
      expect(result.stdout.length, lessThanOrEqualTo(64));
      expect(result.stdout, endsWith('\n'));
    });

    test('does not flag output that fits within the limit', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final result = await rt.execute(const ExecutionRequest(
        code: "print('short')\n",
        maxOutputChars: 1000,
      ));

      expect(result.stdoutTruncated, isFalse);
      expect(result.stdout, 'short\n');
    });

    test('stops an infinite loop with a timeout', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final sw = Stopwatch()..start();
      final result = await rt.execute(const ExecutionRequest(
        code: 'while True:\n    pass\n',
        timeout: Duration(seconds: 3),
      ));
      sw.stop();

      expect(result.status, ExecutionStatus.timeout);
      expect(result.isTimeout, isTrue);
      expect(result.stderr, contains('infinite loop'));
      expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('cancel() stops a running program', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final execution = rt.execute(const ExecutionRequest(
        code: 'import time\ntime.sleep(20)\nprint("never")\n',
        timeout: Duration(seconds: 30),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 700));
      await rt.cancel();

      final result = await execution;
      expect(result.status, ExecutionStatus.cancelled);
      expect(result.isCancelled, isTrue);
      expect(result.stdout, isNot(contains('never')));
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('multiple executions on one runtime are independent', () async {
      if (skipWithoutInterpreter()) return;
      final rt = runtime();
      addTearDown(rt.dispose);

      final first =
          await rt.execute(const ExecutionRequest(code: 'print("one")\n'));
      final second =
          await rt.execute(const ExecutionRequest(code: 'print("two")\n'));

      expect(first.stdout, 'one\n');
      expect(second.stdout, 'two\n');
      expect(first.status, ExecutionStatus.success);
      expect(second.status, ExecutionStatus.success);
    });

    test('a missing harness fails loudly instead of pretending to run',
        () async {
      if (!pythonAvailable) {
        markTestSkipped('Skipped: no interpreter "$python".');
        return;
      }
      final rt = ProcessPythonRuntime(
        pythonExecutable: python,
        harnessPath: 'definitely/not/a/real/harness.py',
      );
      addTearDown(rt.dispose);

      expect(
        () => rt.prepare(),
        throwsA(isA<Exception>()),
      );
      expect(rt.isReady, isFalse);
    });
  });
}
