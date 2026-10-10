import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';
import 'lms_models.dart';

/// Contract every LMS adapter must implement.
///
/// The app never trusts a locally computed score. It sends a code snapshot and
/// receives a server-side verdict. If the real LMS does not yet expose an
/// endpoint, keep using a mock and record the missing contract in
/// `docs/LMS_INTEGRATION.md` rather than inventing an API.
abstract class LmsClient {
  /// Current learner identity, obtained from the LMS session.
  Future<LearnerIdentity> getCurrentLearner();

  /// Exercises assigned to the learner.
  Future<List<Exercise>> fetchExercises();

  /// A single exercise (used when opening a deep link / lesson).
  Future<Exercise> fetchExercise(String exerciseId);

  /// Submits a code snapshot. Must be idempotent on `submission.id`.
  Future<SubmissionReceipt> submitSolution(Submission submission);

  /// Retrieves the (possibly updated) server verdict for a submission.
  Future<SubmissionReceipt> getSubmissionStatus(String submissionId);

  /// Server-authoritative progress / points.
  Future<LearnerProgress> fetchProgress();

  /// Server-verified achievements.
  Future<List<Achievement>> fetchAchievements();
}
