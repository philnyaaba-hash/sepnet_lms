import 'dart:async';

import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/lessons/lesson.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';
import 'lms_client.dart';
import 'lms_models.dart';

/// In-memory LMS used for development, demos and automated tests.
///
/// It models the *trusted server* semantics we need:
///  * Grading decisions are made "server-side" (here: inside this class).
///  * Submissions are idempotent by [Submission.id]; a repeated POST returns the
///    original receipt with `duplicate: true` and never awards points twice.
///  * Identical behaviour for auth failures / network failures so the app's
///    session-expiry and retry logic can be tested without a real backend.
///
/// Replace with `HttpLmsClient` once the real endpoints exist.
class MockLmsClient implements LmsClient {
  MockLmsClient({
    this.latency = Duration.zero,
    this.learner = const LearnerIdentity(id: 'mock-learner-1', displayName: 'Ama'),
    List<Exercise>? exercises,
    GradeVerdict Function(Submission)? grader,
    int failAuthenticationTimes = 0,
    int failNetworkTimes = 0,
  })  : _exercises = exercises ?? sampleExercises(),
        _grader = grader ?? _defaultGrader,
        _failAuthRemaining = failAuthenticationTimes,
        _failNetworkRemaining = failNetworkTimes;

  final Duration latency;
  final LearnerIdentity learner;
  final List<Exercise> _exercises;
  final GradeVerdict Function(Submission) _grader;

  int _failAuthRemaining;
  int _failNetworkRemaining;

  final Map<String, SubmissionReceipt> _receipts = {};
  final Set<String> _completedExercises = {};
  int _points = 0;

  /// Number of grading operations actually performed (excludes duplicates).
  int gradeCount = 0;

  Future<void> _simulate() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (_failAuthRemaining > 0) {
      _failAuthRemaining--;
      throw const AuthenticationException();
    }
    if (_failNetworkRemaining > 0) {
      _failNetworkRemaining--;
      throw const NetworkException('Temporary network problem. Will retry.');
    }
  }

  @override
  Future<LearnerIdentity> getCurrentLearner() async {
    await _simulate();
    return learner;
  }

  @override
  Future<List<Exercise>> fetchExercises() async {
    await _simulate();
    return List.unmodifiable(_exercises);
  }

  @override
  Future<Exercise> fetchExercise(String exerciseId) async {
    await _simulate();
    for (final exercise in _exercises) {
      if (exercise.id == exerciseId) return exercise;
    }
    throw const NotFoundException('That exercise no longer exists.');
  }

  @override
  Future<SubmissionReceipt> submitSolution(Submission submission) async {
    await _simulate();

    // Idempotency: same id => same receipt, no double grading/reward.
    final existing = _receipts[submission.id];
    if (existing != null) {
      return SubmissionReceipt(
        submissionId: existing.submissionId,
        verdict: existing.verdict,
        serverRef: existing.serverRef,
        pointsAwarded: existing.pointsAwarded,
        message: existing.message,
        duplicate: true,
      );
    }

    if (submission.code.trim().isEmpty) {
      throw const LmsException('The submission was empty.', statusCode: 400);
    }

    gradeCount++;
    final verdict = _grader(submission);
    final accepted = verdict == GradeVerdict.accepted;
    final points = accepted ? 10 : 0;

    if (accepted && _completedExercises.add(submission.exerciseId)) {
      _points += points;
    }

    final receipt = SubmissionReceipt(
      submissionId: submission.id,
      verdict: verdict,
      serverRef: 'SRV-${_shortId(submission.id)}',
      pointsAwarded: points,
      message: accepted
          ? 'Great work! Your solution was accepted.'
          : 'Not quite yet. Review the requirements and try again.',
    );
    _receipts[submission.id] = receipt;
    return receipt;
  }

  @override
  Future<SubmissionReceipt> getSubmissionStatus(String submissionId) async {
    await _simulate();
    final receipt = _receipts[submissionId];
    if (receipt == null) {
      throw const NotFoundException('Unknown submission.');
    }
    return receipt;
  }

  @override
  Future<LearnerProgress> fetchProgress() async {
    await _simulate();
    return LearnerProgress(
      totalPoints: _points,
      completedChallenges: _completedExercises.length,
      totalChallenges: _exercises.length,
    );
  }

  @override
  Future<List<Achievement>> fetchAchievements() async {
    await _simulate();
    if (_completedExercises.isEmpty) return const [];
    final achievements = <Achievement>[
      const Achievement(
        id: 'first-steps',
        title: 'First Steps',
        description: 'You submitted your first Python solution.',
        points: 0,
      ),
    ];
    if (_completedExercises.length >= 3) {
      achievements.add(const Achievement(
        id: 'getting-started',
        title: 'Getting Started',
        description: 'You completed three coding challenges.',
        points: 0,
      ));
    }
    return achievements;
  }

  /// Server reference derived from the client id. Real ids are UUIDs, but the
  /// mock must not crash on short ids used in tests and demos.
  static String _shortId(String id) =>
      id.length >= 8 ? id.substring(0, 8) : id;

  static GradeVerdict _defaultGrader(Submission submission) {
    // Stand-in for server-side tests. Rejects obvious placeholders so the
    // "rejected" path is demonstrable; accepts anything else.
    final code = submission.code;
    if (code.contains('TODO') || code.contains('pass  # your code')) {
      return GradeVerdict.rejected;
    }
    return GradeVerdict.accepted;
  }

  /// Curriculum-aligned sample exercises used until the real LMS ships them.
  ///
  /// Lesson copy follows the voice recorded in `docs/PRODUCT_REFERENCE.md`:
  /// second person, present tense, one idea per screen, and a comparison to
  /// something the learner is already doing. `backticks` become boxed code
  /// chips. Keep steps short — the point is that no screen is a wall of text.
  static List<Exercise> sampleExercises() => const [
        Exercise(
          id: 'ex-hello-world',
          lessonId: 'lesson-1',
          title: 'Hello, World!',
          instructions:
              'Use print() to display a friendly greeting. This is the traditional first program in every language.',
          objectives: ['Understand what a Python program is', 'Use the print() function'],
          requirements: ['Print the text: Hello, World!'],
          starterCode: "# Write your code below\n",
          hints: ["Text must be in quotes: print('Hello, World!')"],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'Think of Python as a super-fast translator. It takes the simple '
                  'instructions you write and turns them into something a computer '
                  'can follow instantly.',
            ),
            LessonStep(
              prose:
                  'Every single line matters. Python reads top-to-bottom, one at a '
                  'time — just like you\'re reading this. It finishes line one before '
                  'it even glances at line two.',
            ),
            LessonStep(
              prose:
                  'To make Python say something out loud, use `print()` and put your '
                  'text inside quote marks. The quotes are how Python knows the words '
                  'are for it to say, not instructions to follow.',
              exampleCode: 'print("Hello, World!")',
            ),
            LessonStep(
              prose:
                  'That\'s it. One line, one job. In the next step you\'ll write it '
                  'yourself — and it will be the first program you\'ve ever run.',
            ),
          ]),
        ),
        Exercise(
          id: 'ex-variables',
          lessonId: 'lesson-2',
          title: 'Variables and Names',
          instructions:
              'Create a variable called name with your name, then print a greeting using it.',
          objectives: ['Store values in variables', 'Combine text with variables'],
          requirements: ['Create a variable named name', 'Print Hello followed by the name'],
          starterCode: "name = \nprint('Hello', name)\n",
          hints: ['A variable uses the = sign: name = "Kofi"'],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'A variable is a labelled box. You put something inside, give the '
                  'box a name, and later you just say the name instead of repeating '
                  'what was inside.',
            ),
            LessonStep(
              prose:
                  'You fill a box with `=`. Whatever sits to the right gets stored '
                  'under the name on the left. Python reads it right-to-left: it '
                  'figures out `"Kofi"` first, then stores it as `name`.',
              exampleCode: 'name = "Kofi"',
            ),
            LessonStep(
              prose:
                  'Now the name works anywhere you\'d use the value. One change to '
                  'the box, and every place you mention it changes too.',
              exampleCode: "name = 'Ama'\nprint('Hello', name)",
            ),
            LessonStep(
              prose:
                  'Good variable names describe what\'s inside. `name` beats `x` — '
                  'including for you, a week from now.',
            ),
          ]),
        ),
        Exercise(
          id: 'ex-arithmetic',
          lessonId: 'lesson-2',
          title: 'Arithmetic',
          instructions: 'Calculate and print the sum and product of two numbers.',
          objectives: ['Use +, -, * and /', 'Understand operator precedence'],
          requirements: ['Print the sum of 7 and 5', 'Print the product of 7 and 5'],
          starterCode: 'a = 7\nb = 5\n',
          hints: ['print(a + b)', 'Multiplication uses the * symbol'],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'Python does sums the way you\'d write them. `+` adds, `-` takes '
                  'away, `*` multiplies and `/` divides.',
              exampleCode: 'print(7 + 5)\nprint(7 - 5)\nprint(7 * 5)\nprint(7 / 5)',
            ),
            LessonStep(
              prose:
                  'Watch the division though. `/` always gives a decimal, even when '
                  'the answer is a whole number — `7 / 5` is `1.4`, not `1`.',
            ),
            LessonStep(
              prose:
                  'Order matters, and Python follows the rules you learned in maths: '
                  'multiply before you add. So `2 + 3 * 4` is `14`, not `20`. '
                  'Use brackets when you want to change that.',
              exampleCode: 'print(2 + 3 * 4)\nprint((2 + 3) * 4)',
            ),
            LessonStep(
              prose:
                  'Variables work here too. Store your numbers first, then do the '
                  'sum — that way changing a number later means changing it once.',
            ),
          ]),
        ),
        Exercise(
          id: 'ex-conditions',
          lessonId: 'lesson-3',
          title: 'Making Decisions',
          instructions:
              'Given a score, print "Pass" when it is 50 or more, otherwise print "Try again".',
          objectives: ['Use if / else', 'Compare values'],
          requirements: ['Use an if statement', 'Handle both outcomes'],
          starterCode: 'score = 72\n',
          hints: ['if score >= 50:', 'Remember the colon at the end of the condition'],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'So far your programs run the same lines every time. `if` lets '
                  'them choose — like a fork in the road.',
            ),
            LessonStep(
              prose:
                  'An `if` asks a yes-or-no question. If the answer is yes, Python '
                  'runs the indented lines underneath. If not, it skips them. '
                  'The colon at the end says "the indented part belongs to me".',
              exampleCode: 'score = 72\nif score >= 50:\n    print("Pass")',
            ),
            LessonStep(
              prose:
                  '`>=` means "greater than or equal to". That little `=` is easy '
                  'to forget, and forgetting it means a score of exactly 50 fails.',
            ),
            LessonStep(
              prose:
                  'But what about the other answer? `else` is the second fork: '
                  'Python takes the `if` branch when the question is true, and the '
                  '`else` branch when it isn\'t.',
              exampleCode:
                  'if score >= 50:\n    print("Pass")\nelse:\n    print("Try again")',
            ),
          ]),
        ),
        Exercise(
          id: 'ex-loops',
          lessonId: 'lesson-3',
          title: 'Loops',
          instructions: 'Print the numbers 1 to 5, one per line, using a loop.',
          objectives: ['Use a for loop', 'Use the range() function'],
          requirements: ['Use a for loop', 'Print 1 through 5'],
          starterCode: '# Use a for loop\n',
          hints: ['for i in range(1, 6):', 'range(1, 6) gives 1,2,3,4,5'],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'Copying the same line five times works, until you need it a '
                  'hundred times. A loop is how you say "do this again" without '
                  'writing it again.',
            ),
            LessonStep(
              prose:
                  '`for` takes each item in a list, one at a time, and runs the '
                  'indented lines for that item. `range(1, 6)` makes the list '
                  '`1, 2, 3, 4, 5` — it stops *before* the last number, which '
                  'catches everyone.',
              exampleCode: 'for i in range(1, 6):\n    print(i)',
            ),
            LessonStep(
              prose:
                  'The `i` is just a name you choose. It starts as `1`, the loop '
                  'runs, then it becomes `2`, runs again, and so on. On the last '
                  'round it\'s `5`, and then the loop is done.',
            ),
            LessonStep(
              prose:
                  'The indented lines are the loop\'s body — they run once per '
                  'number. Put them at the wrong indent and Python will tell you, '
                  'loudly.',
            ),
          ]),
        ),
        Exercise(
          id: 'ex-functions',
          lessonId: 'lesson-4',
          title: 'Reusable Functions',
          instructions: 'Write a function called square that returns a number multiplied by itself.',
          objectives: ['Define functions with def', 'Return values'],
          requirements: ['Define square(n)', 'Return n * n'],
          starterCode: 'def square(n):\n    # your code here\n    pass\n',
          hints: ['return n * n'],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'A function is a recipe you name. You write it once, then call it '
                  'by name as often as you like — no rewriting the steps each time.',
            ),
            LessonStep(
              prose:
                  'Start with `def`, then the name, then brackets. `n` is called a '
                  'parameter: it\'s the ingredient the function needs. And the '
                  'colon-and-indent rule applies exactly as it does with `if`.',
              exampleCode: 'def square(n):\n    return n * n',
            ),
            LessonStep(
              prose:
                  'Defining a function doesn\'t run it. Python just reads the '
                  'recipe and remembers it. It only runs when you *call* it — '
                  'brackets included.',
              exampleCode: 'def square(n):\n    return n * n\n\nprint(square(4))',
            ),
            LessonStep(
              prose:
                  '`return` is what sends the answer back out. Everything after it '
                  'belongs to the function and stops there. Without `return`, a '
                  'function gives back nothing at all.',
            ),
          ]),
        ),
        Exercise(
          id: 'ex-lists',
          lessonId: 'lesson-4',
          title: 'Lists',
          instructions: 'Create a list of three fruits and print each one.',
          objectives: ['Create lists', 'Iterate over lists'],
          requirements: ['Create a list literal', 'Print each fruit'],
          starterCode: 'fruits = []\n',
          hints: ["fruits = ['mango', 'banana', 'orange']", 'for fruit in fruits:'],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'A list is one box with many compartments. Instead of three '
                  'separate names to remember, you keep them together in order.',
              exampleCode: "fruits = ['mango', 'banana', 'orange']",
            ),
            LessonStep(
              prose:
                  'Square brackets mean "this is a list", and commas keep the items '
                  'apart. Python counts from zero, so the first fruit is at position '
                  '`0`, not `1`.',
              exampleCode: "print(fruits[0])\nprint(fruits[2])",
            ),
            LessonStep(
              prose:
                  'A loop and a list are made for each other. `for fruit in fruits` '
                  'hands you one item per round, already named — no counting '
                  'positions at all.',
              exampleCode: "for fruit in fruits:\n    print(fruit)",
            ),
            LessonStep(
              prose:
                  'Lists can change after you make one — add to it, remove from it, '
                  'swap an item. That\'s what makes them more useful than plain '
                  'variables.',
            ),
          ]),
        ),
        Exercise(
          id: 'ex-input',
          lessonId: 'lesson-5',
          title: 'Talking to the User',
          instructions: 'Ask the user for their name with input() and greet them.',
          objectives: ['Read input from the user', 'Store it in a variable'],
          requirements: ['Use input()', 'Print a greeting'],
          starterCode: "name = input('What is your name? ')\n",
          sampleStdin: ['Ama'],
          hints: ['input() returns text', "print('Hello', name)"],
          version: 1,
          lesson: Lesson(steps: [
            LessonStep(
              prose:
                  'Everything so far you typed yourself. `input()` is how a program '
                  'pauses and waits for the person using it.',
            ),
            LessonStep(
              prose:
                  'Anything you put in the brackets is shown as the question. '
                  'Python stops there, waits, and hands back whatever they answer.',
              exampleCode: "name = input('What is your name? ')",
            ),
            LessonStep(
              prose:
                  'Whatever comes back is always **text**, even if they type a '
                  'number. That\'s why it goes straight into `name` — and why you '
                  'can print it with a greeting.',
              exampleCode: "name = input('What is your name? ')\nprint('Hello', name)",
            ),
            LessonStep(
              prose:
                  'Now your program reacts to the person running it. In the next '
                  'step you can try it — this one needs the keyboard.',
            ),
          ]),
        ),
      ];
}
