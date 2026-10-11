import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/lessons/inline_code_text.dart';
import 'package:skillbridge_python_lab/features/lessons/lesson.dart';
import 'package:skillbridge_python_lab/features/lessons/lesson_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Advances fake time far enough for the 320ms step transition and the chip
  /// entrance animations, without pumpAndSettle (which would hang on the
  /// indeterminate progress indicator).
  Future<void> pumpSteps(WidgetTester tester, {int count = 8}) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  Lesson lessonOf(int steps) => Lesson(
        steps: [
          for (var i = 0; i < steps; i++)
            LessonStep(prose: 'Step $i teaches about `thing_$i`.'),
        ],
      );

  Exercise exerciseWith(Lesson lesson) => Exercise(
        id: 'ex-test',
        title: 'Test exercise',
        instructions: 'Do the thing.',
        starterCode: '',
        lesson: lesson,
      );

  Widget host({required Exercise exercise, VoidCallback? onFinished}) =>
      MaterialApp(
        home: LessonScreen(exercise: exercise, onFinished: onFinished),
      );

  group('InlineCodeText', () {
    test('parse splits prose and code on backticks', () {
      final segments = InlineCodeText.parse('Use `if` here');
      expect(segments, hasLength(3));
      expect(segments[0].isCode, isFalse);
      expect(segments[0].text, 'Use ');
      expect(segments[1].isCode, isTrue);
      expect(segments[1].text, 'if');
      expect(segments[2].isCode, isFalse);
      expect(segments[2].text, ' here');
    });

    test('parse ignores empty segments from adjacent backticks', () {
      final segments = InlineCodeText.parse('a``b');
      expect(segments.map((s) => s.text).toList(), ['a', 'b']);
    });

    test('an unmatched trailing backtick renders as plain prose', () {
      // No throw, and the stray tick is absorbed rather than shown.
      final segments = InlineCodeText.parse('unclosed `tick');
      expect(segments, hasLength(2));
      expect(segments.every((s) => !s.isCode), isTrue);
    });

    test('empty input produces nothing', () {
      expect(InlineCodeText.parse(''), isEmpty);
      expect(InlineCodeText.parse('```'), isEmpty);
    });

    testWidgets('renders the code text so it is readable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InlineCodeText('Use `if` here'))),
      );
      await pumpSteps(tester);
      // The chip holds the token in a monospace Text, so it is findable and
      // announced as one word.
      expect(find.text('if'), findsOneWidget);
    });

    testWidgets('keeps the prose readable alongside the chip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InlineCodeText('Use `if` here'))),
      );
      await pumpSteps(tester);
      expect(find.textContaining('Use '), findsOneWidget);
    });

    testWidgets('exposes the chip as a single semantic label', (tester) async {
      // The semantics tree is off by default in widget tests; without this the
      // finder sees an empty tree and the assertion is meaningless.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InlineCodeText('say `hello`'))),
      );
      await pumpSteps(tester);

      expect(find.bySemanticsLabel('hello'), findsOneWidget);
      // Disposed here rather than in addTearDown: flutter_test verifies handle
      // disposal at the end of the test body, before addTearDown runs, so a
      // deferred dispose always trips "a SemanticsHandle was active".
      handle.dispose();
    });
  });

  group('LessonScreen', () {
    testWidgets('shows the first step and a progress bar', (tester) async {
      await tester.pumpWidget(host(exercise: exerciseWith(lessonOf(3))));
      await pumpSteps(tester);

      expect(find.textContaining('Step 0'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('advancing swaps the step and keeps one CONTINUE',
        (tester) async {
      await tester.pumpWidget(host(exercise: exerciseWith(lessonOf(3))));
      await pumpSteps(tester);

      await tester.tap(find.text('CONTINUE'));
      await pumpSteps(tester);

      expect(find.textContaining('Step 1'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('the last step offers "Start the challenge" instead',
        (tester) async {
      await tester.pumpWidget(host(exercise: exerciseWith(lessonOf(2))));
      await pumpSteps(tester);

      await tester.tap(find.text('CONTINUE'));
      await pumpSteps(tester);

      expect(find.text('Start the challenge'), findsOneWidget);
      expect(find.text('CONTINUE'), findsNothing);
    });

    testWidgets('the progress bar advances with the steps', (tester) async {
      await tester.pumpWidget(host(exercise: exerciseWith(lessonOf(2))));
      await pumpSteps(tester);

      final first =
          tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      await tester.tap(find.text('CONTINUE'));
      await pumpSteps(tester);

      final second =
          tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(second.value, greaterThan(first.value ?? 0));
    });

    testWidgets('finish calls onFinished exactly once', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(exercise: exerciseWith(lessonOf(1)), onFinished: () => calls++),
      );
      await pumpSteps(tester);

      await tester.tap(find.text('Start the challenge'));
      await pumpSteps(tester);
      // Tapping again must not re-fire: the screen sets a leaving guard.
      await tester.tap(find.text('Start the challenge'), warnIfMissed: false);
      await pumpSteps(tester);

      expect(calls, 1);
    });

    testWidgets('the back arrow steps backwards through the lesson',
        (tester) async {
      await tester.pumpWidget(host(exercise: exerciseWith(lessonOf(3))));
      await pumpSteps(tester);

      await tester.tap(find.text('CONTINUE'));
      await pumpSteps(tester);
      expect(find.textContaining('Step 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous step'));
      await pumpSteps(tester);
      expect(find.textContaining('Step 0'), findsOneWidget);
    });

    testWidgets('back on the first step shows a close affordance',
        (tester) async {
      await tester.pumpWidget(host(exercise: exerciseWith(lessonOf(3))));
      await pumpSteps(tester);

      // On step 0 the leading control closes rather than going "back".
      expect(find.byTooltip('Close lesson'), findsOneWidget);
      expect(find.byTooltip('Previous step'), findsNothing);
    });

    testWidgets('a step with an example renders it as a code block',
        (tester) async {
      final exercise = exerciseWith(
        const Lesson(steps: [
          LessonStep(prose: 'Like this.', exampleCode: 'print("hi")'),
        ]),
      );
      await tester.pumpWidget(host(exercise: exercise));
      await pumpSteps(tester);

      expect(find.byType(CodeBlock), findsOneWidget);
      expect(find.text('print("hi")'), findsOneWidget);
    });

    testWidgets('an empty lesson leaves immediately rather than stalling',
        (tester) async {
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(
                        exercise: exerciseWith(const Lesson(steps: [])),
                      ),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('go'));
      await pumpSteps(tester);

      expect(popped, isTrue,
          reason: 'a lesson with no steps must not present a blank screen');
    });
  });

  group('Lesson model', () {
    test('round-trips through JSON', () {
      const lesson = Lesson(steps: [
        LessonStep(prose: 'A `b` c', exampleCode: 'x = 1'),
        LessonStep(prose: 'plain'),
      ]);
      final restored = Lesson.fromJson(lesson.toJson());
      expect(restored.stepCount, 2);
      expect(restored.steps.first.prose, 'A `b` c');
      expect(restored.steps.first.exampleCode, 'x = 1');
      expect(restored.steps.last.exampleCode, isNull);
    });

    test('drops blank steps rather than showing empty screens', () {
      final lesson = Lesson.fromJson({
        'steps': [
          {'prose': ''},
          {'prose': 'real'},
        ],
      });
      expect(lesson.stepCount, 1);
    });

    test('tolerates missing or malformed input', () {
      expect(Lesson.fromJson(null).isEmpty, isTrue);
      expect(Lesson.fromJson('nonsense').isEmpty, isTrue);
      expect(Lesson.fromJson({'steps': 'nope'}).isEmpty, isTrue);
    });

    test('exercise exposes hasLesson', () {
      const bare = Exercise(
        id: 'a',
        title: 't',
        instructions: 'i',
        starterCode: '',
      );
      expect(bare.hasLesson, isFalse);

      const taught = Exercise(
        id: 'b',
        title: 't',
        instructions: 'i',
        starterCode: '',
        lesson: Lesson(steps: [LessonStep(prose: 'hi')]),
      );
      expect(taught.hasLesson, isTrue);
    });

    test('exercise JSON round-trips the lesson and omits it when empty', () {
      const taught = Exercise(
        id: 'b',
        title: 't',
        instructions: 'i',
        starterCode: '',
        lesson: Lesson(steps: [LessonStep(prose: 'hi `there`')]),
      );
      final json = taught.toJson();
      expect(json['lesson'], isNotNull);
      expect(Exercise.fromJson(json).lesson.stepCount, 1);
      expect(Exercise.fromJson(json).lesson.steps.first.prose, 'hi `there`');

      const bare = Exercise(id: 'c', title: 't', instructions: 'i', starterCode: '');
      expect(bare.toJson().containsKey('lesson'), isFalse);
      expect(Exercise.fromJson(bare.toJson()).hasLesson, isFalse);
    });
  });
}
