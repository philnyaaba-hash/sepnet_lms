import 'package:flutter_test/flutter_test.dart';

import 'package:skillbridge_python_lab/features/python_runtime/execution_result.dart';

void main() {
  group('status parsing', () {
    test('maps every known status name', () {
      expect(
        ExecutionResult.statusFromName('success'),
        ExecutionStatus.success,
      );
      expect(
        ExecutionResult.statusFromName('timeout'),
        ExecutionStatus.timeout,
      );
      expect(
        ExecutionResult.statusFromName('cancelled'),
        ExecutionStatus.cancelled,
      );
      expect(ExecutionResult.statusFromName('error'), ExecutionStatus.error);
    });

    test('unknown or missing status falls back to error', () {
      expect(ExecutionResult.statusFromName('nonsense'), ExecutionStatus.error);
      expect(ExecutionResult.statusFromName(null), ExecutionStatus.error);
      expect(ExecutionResult.statusFromName(''), ExecutionStatus.error);
    });
  });

  group('json round trip', () {
    test('keeps every field', () {
      const original = ExecutionResult(
        status: ExecutionStatus.error,
        stdout: 'before the crash\n',
        stderr: 'Traceback...\n',
        exception: ExecutionException(
          type: 'IndexError',
          message: 'list index out of range',
          traceback: 'Traceback (most recent call last)',
          line: 3,
        ),
        durationMs: 42,
        stdoutTruncated: true,
        stderrTruncated: false,
        pythonVersion: '3.14.8',
      );

      final restored = ExecutionResult.fromJson(original.toJson());

      expect(restored.status, ExecutionStatus.error);
      expect(restored.stdout, original.stdout);
      expect(restored.stderr, original.stderr);
      expect(restored.durationMs, 42);
      expect(restored.stdoutTruncated, isTrue);
      expect(restored.stderrTruncated, isFalse);
      expect(restored.pythonVersion, '3.14.8');
      expect(restored.exception, isNotNull);
      expect(restored.exception!.type, 'IndexError');
      expect(restored.exception!.message, 'list index out of range');
      expect(restored.exception!.line, 3);
      expect(
        restored.exception!.traceback,
        'Traceback (most recent call last)',
      );
    });

    test('tolerates a missing or partial payload', () {
      final empty = ExecutionResult.fromJson(const {});
      expect(empty.status, ExecutionStatus.error);
      expect(empty.stdout, isEmpty);
      expect(empty.stderr, isEmpty);
      expect(empty.exception, isNull);
      expect(empty.durationMs, 0);
      expect(empty.stdoutTruncated, isFalse);

      final partial = ExecutionResult.fromJson(const {
        'status': 'success',
        'exception': {
          'type': 'ValueError',
          'message': 'bad value',
          'line': '7',
        },
      });
      expect(partial.status, ExecutionStatus.success);
      expect(partial.exception!.line, 7);
      expect(partial.exception!.friendlyLabel, isNotEmpty);
    });

    test('ignores a non-object exception payload', () {
      final result = ExecutionResult.fromJson(const {
        'status': 'error',
        'exception': 'not a map',
      });
      expect(result.exception, isNull);
      expect(result.hasException, isFalse);
    });

    test('does not throw when runtime fields have unexpected types', () {
      final result = ExecutionResult.fromJson(const {
        'status': 42,
        'stdout': 123,
        'stderr': false,
        'durationMs': 'slow',
        'stdoutTruncated': 'yes',
        'stderrTruncated': 1,
        'exception': {
          'type': 7,
          'message': null,
          'traceback': 99,
          'line': <String>['not', 'a', 'line'],
        },
      });

      expect(result.status, ExecutionStatus.error);
      expect(result.stdout, '123');
      expect(result.stderr, 'false');
      expect(result.durationMs, 0);
      expect(result.stdoutTruncated, isFalse);
      expect(result.exception!.type, '7');
      expect(result.exception!.line, isNull);
    });
  });

  group('factories', () {
    test('timedOut produces a timeout with a learner-facing message', () {
      final result = ExecutionResult.timedOut(const Duration(seconds: 10));
      expect(result.status, ExecutionStatus.timeout);
      expect(result.isTimeout, isTrue);
      expect(result.stderr, contains('10 seconds'));
      expect(result.stderr, contains('infinite loop'));
      expect(result.exception!.type, 'TimeoutError');
      expect(
        result.exception!.friendlyLabel,
        'Your program took too long and was stopped.',
      );
    });

    test('cancelled produces a cancelled result', () {
      final result = ExecutionResult.cancelled();
      expect(result.status, ExecutionStatus.cancelled);
      expect(result.isCancelled, isTrue);
      expect(result.stderr, isNotEmpty);
    });

    test('runtimeFailure reports an infrastructure error', () {
      final result = ExecutionResult.runtimeFailure('missing harness');
      expect(result.status, ExecutionStatus.error);
      expect(result.hasException, isTrue);
      expect(result.exception!.type, 'RuntimeError');
      expect(result.exception!.message, 'missing harness');
    });
  });

  group('helpers', () {
    test('consoleText concatenates stdout then stderr', () {
      const result = ExecutionResult(
        status: ExecutionStatus.error,
        stdout: 'first\n',
        stderr: 'second\n',
      );
      expect(result.consoleText, 'first\nsecond\n');
    });

    test('derived flags track the status', () {
      const success = ExecutionResult(status: ExecutionStatus.success);
      expect(success.isSuccess, isTrue);
      expect(success.hasError, isFalse);

      const error = ExecutionResult(status: ExecutionStatus.error);
      expect(error.hasError, isTrue);
      expect(error.isSuccess, isFalse);
    });
  });

  group('friendly labels', () {
    test('maps common beginner errors to plain language', () {
      const cases = <String, String>{
        'SyntaxError': 'There is a spelling or punctuation mistake on line 4.',
        'NameError': 'You used a variable or name that does not exist yet.',
        'TypeError': 'You mixed values of different types (for example, text and a number).',
        'IndexError': 'You asked for an item that is outside the list.',
        'KeyError': 'The dictionary does not contain that key.',
        'ZeroDivisionError': 'You cannot divide by zero.',
        'IndentationError':
            'The indentation is not correct. Line up blocks of code.',
        'EOFError': 'Your program asked for more input than you provided.',
        'ValueError': 'A value had the right type but the wrong content.',
        'TimeoutError': 'Your program took too long and was stopped.',
      };

      for (final entry in cases.entries) {
        final exception = ExecutionException(
          type: entry.key,
          message: 'raw',
          line: entry.key == 'SyntaxError' ? 4 : null,
        );
        expect(
          exception.friendlyLabel,
          entry.value,
          reason: 'label for ${entry.key}',
        );
      }
    });

    test('falls back to the message for unknown types', () {
      const withMessage = ExecutionException(
        type: 'ArithmeticError',
        message: 'something specific',
      );
      expect(withMessage.friendlyLabel, 'something specific');

      const withoutMessage = ExecutionException(type: 'X', message: '');
      expect(withoutMessage.friendlyLabel, 'Something went wrong.');
    });
  });
}
