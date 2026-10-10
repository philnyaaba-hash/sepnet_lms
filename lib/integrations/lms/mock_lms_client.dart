import 'dart:async';

import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
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
        ),
      ];
}
