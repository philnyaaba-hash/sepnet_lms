import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/lessons/inline_code_text.dart';
import 'package:skillbridge_python_lab/features/lessons/lesson_screen.dart';
import 'package:skillbridge_python_lab/features/python_runtime/execution_result.dart';
import 'package:skillbridge_python_lab/features/python_runtime/process_python_runtime.dart';
import 'package:skillbridge_python_lab/features/python_runtime/python_runtime.dart';
import 'package:skillbridge_python_lab/integrations/lms/mock_lms_client.dart';
import 'package:skillbridge_python_lab/shared/widgets/code_buddy.dart';
import 'package:skillbridge_python_lab/shared/widgets/entrance.dart';

/// Smoke test for EVERY unit (exercise + lesson) in the curriculum.
///
/// For each unit it checks:
///  1. the lesson has real content,
///  2. a learner can tap through every lesson step to the end, and the lesson
///     hands off exactly once,
///  3. a known-good reference solution runs on real CPython and prints the
///     expected output (skipped, never silently passed, if no Python exists).
///
/// It also checks the animated buddy and the entrance animation.
///
/// When you add a unit to the curriculum, add its reference solution below or
/// the "every unit has a reference solution" test fails on purpose.
class _Solution {
  const _Solution(this.code, this.expected,
      {this.exact = true, this.stdin = const []});
  final String code;
  final String expected;
  final bool exact;
  final List<String> stdin;
}

const _solutions = <String, _Solution>{
  'ex-hello-world': _Solution(
    'print("Hello, World!")\n',
    'Hello, World!\n',
  ),
  'ex-variables': _Solution(
    'name = "Kofi"\nprint("Hello", name)\n',
    'Hello Kofi\n',
  ),
  'ex-arithmetic': _Solution(
    'a = 7\nb = 5\nprint(a + b)\nprint(a * b)\n',
    '12\n35\n',
  ),
  'ex-conditions': _Solution(
    'score = 72\n'
        'if score >= 50:\n'
        '    print("Pass")\n'
        'else:\n'
        '    print("Try again")\n',
    'Pass\n',
  ),
  'ex-loops': _Solution(
    'for i in range(1, 6):\n    print(i)\n',
    '1\n2\n3\n4\n5\n',
  ),
  'ex-functions': _Solution(
    'def square(n):\n    return n * n\n\nprint(square(4))\n',
    '16\n',
  ),
  'ex-lists': _Solution(
    "fruits = ['mango', 'banana', 'orange']\n"
        'for fruit in fruits:\n'
        '    print(fruit)\n',
    'mango\nbanana\norange\n',
  ),
  'ex-input': _Solution(
    "name = input('What is your name? ')\nprint('Hello', name)\n",
    'Hello Ama',
    exact: false,
    stdin: ['Ama'],
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final exercises = MockLmsClient.sampleExercises();

  final python = Platform.environment['SB_TEST_PYTHON'] ??
      (Platform.isWindows ? 'python' : 'python3');
  final harnessPath = ProcessPythonRuntime.resolveHarnessPath();
  var pythonAvailable = false;

  setUpAll(() async {
    try {
      final probe = await Process.run(python, ['--version']);
      pythonAvailable =
          probe.exitCode == 0 && File(harnessPath).existsSync();
    } on ProcessException {
      pythonAvailable = false;
    }
  });

  Future<void> pumpSteps(WidgetTester tester, {int count = 8}) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  group('curriculum', () {
    test('there is at least one unit', () {
      expect(exercises, isNotEmpty);
    });

    test('unit ids are unique', () {
      final ids = exercises.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every unit has a reference solution (add one for new units)', () {
      for (final e in exercises) {
        expect(_solutions.containsKey(e.id), isTrue,
            reason: 'No reference solution for "${e.id}" in '
                'test/all_units_smoke_test.dart');
      }
    });

    test('every unit is complete: title, instructions, hints, lesson', () {
      for (final e in exercises) {
        expect(e.title.trim(), isNotEmpty, reason: '${e.id} title');
        expect(e.instructions.trim(), isNotEmpty, reason: '${e.id} instructions');
        expect(e.requirements, isNotEmpty, reason: '${e.id} requirements');
        expect(e.hasLesson, isTrue, reason: '${e.id} has no lesson');
        for (final step in e.lesson.steps) {
          expect(step.prose.trim(), isNotEmpty,
              reason: '${e.id} has an empty lesson step');
        }
      }
    });
  });

  for (final exercise in exercises) {
    group('unit: ${exercise.title} (${exercise.id})', () {
      testWidgets('lesson: every step can be walked through to the end',
          (tester) async {
        var finished = 0;
        await tester.pumpWidget(MaterialApp(
          home: LessonScreen(exercise: exercise, onFinished: () => finished++),
        ));
        await pumpSteps(tester);

        final steps = exercise.lesson.stepCount;
        for (var i = 0; i < steps - 1; i++) {
          expect(find.byType(InlineCodeText), findsOneWidget,
              reason: 'step ${i + 1} should show its text');
          expect(find.text('CONTINUE'), findsOneWidget);
          await tester.tap(find.text('CONTINUE'));
          await pumpSteps(tester);
        }

        expect(find.text('Start the challenge'), findsOneWidget);
        await tester.tap(find.text('Start the challenge'));
        await pumpSteps(tester);
        expect(finished, 1, reason: 'lesson must hand off exactly once');
        expect(tester.takeException(), isNull);
      });

      test('reference solution runs correctly on real Python', () async {
        final solution = _solutions[exercise.id];
        if (solution == null) {
          fail('No reference solution for ${exercise.id}');
        }
        if (!pythonAvailable) {
          markTestSkipped(
            'Skipped: no usable Python ("$python") or harness. '
            'Set SB_TEST_PYTHON to run this check.',
          );
          return;
        }

        final runtime = ProcessPythonRuntime(
          pythonExecutable: python,
          harnessPath: harnessPath,
          defaultTimeout: const Duration(seconds: 20),
        );
        addTearDown(runtime.dispose);

        final result = await runtime.execute(ExecutionRequest(
          code: solution.code,
          stdinLines: solution.stdin,
        ));

        expect(result.status, ExecutionStatus.success,
            reason: 'stderr: ${result.stderr}');
        if (solution.exact) {
          expect(result.stdout, solution.expected);
        } else {
          expect(result.stdout, contains(solution.expected));
        }
      });
    });
  }

  group('animations and cartoons', () {
    testWidgets('the code buddy draws every mood without errors',
        (tester) async {
      for (final mood in BuddyMood.values) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(child: CodeBuddy(size: 120, mood: mood)),
          ),
        ));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byType(CodeBuddy), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'mood $mood');
      }
    });

    testWidgets('the buddy stays still when animations are disabled',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(body: Center(child: CodeBuddy())),
      ));
      // pumpAndSettle only returns if nothing keeps animating.
      await tester.pumpAndSettle();
      expect(find.byType(CodeBuddy), findsOneWidget);
    });

    testWidgets('the speech bubble shows the message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BuddySays(message: 'Nice work!')),
      ));
      await pumpSteps(tester);
      expect(find.text('Nice work!'), findsOneWidget);
    });

    testWidgets('entrance animation keeps the child and finishes',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Entrance(index: 6, child: Text('hello')),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
