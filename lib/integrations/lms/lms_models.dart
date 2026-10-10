/// Data types exchanged with the LMS. Kept separate from the Flutter widgets so
/// the network contract is explicit and testable.
library;

/// The learner as understood by the LMS. Deliberately minimal: no phone number,
/// email or other personal data is required for coding practice.
class LearnerIdentity {
  const LearnerIdentity({
    required this.id,
    required this.displayName,
    this.organisation,
  });

  final String id;
  final String displayName;
  final String? organisation;

  factory LearnerIdentity.fromJson(Map<String, dynamic> json) => LearnerIdentity(
        id: (json['id'] ?? json['learnerRef']) as String,
        displayName: (json['displayName'] as String?) ?? 'Learner',
        organisation: json['organisation'] as String?,
      );
}

/// Server verdict for a submission.
enum GradeVerdict { accepted, rejected, needsReview }

/// The LMS's response to a submitted solution.
class SubmissionReceipt {
  const SubmissionReceipt({
    required this.submissionId,
    required this.verdict,
    this.serverRef,
    this.pointsAwarded = 0,
    this.message,
    this.duplicate = false,
  });

  final String submissionId;
  final GradeVerdict verdict;
  final String? serverRef;
  final int pointsAwarded;
  final String? message;

  /// True when the server recognised the idempotency key and did not re-grade /
  /// re-award. Allows the client to display "already submitted" correctly.
  final bool duplicate;

  factory SubmissionReceipt.fromJson(Map<String, dynamic> json) => SubmissionReceipt(
        submissionId: (json['submissionId'] ?? '') as String,
        verdict: _verdictFromName(json['verdict'] as String?),
        serverRef: json['serverRef'] as String?,
        pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
        message: json['message'] as String?,
        duplicate: json['duplicate'] as bool? ?? false,
      );

  static GradeVerdict _verdictFromName(String? name) {
    switch (name) {
      case 'accepted':
        return GradeVerdict.accepted;
      case 'rejected':
        return GradeVerdict.rejected;
      case 'needs_review':
        return GradeVerdict.needsReview;
      default:
        return GradeVerdict.needsReview;
    }
  }
}

/// Aggregated, server-authoritative learning progress.
class LearnerProgress {
  const LearnerProgress({
    required this.totalPoints,
    required this.completedChallenges,
    required this.totalChallenges,
  });

  final int totalPoints;
  final int completedChallenges;
  final int totalChallenges;

  double get completionRatio =>
      totalChallenges == 0 ? 0 : completedChallenges / totalChallenges;

  factory LearnerProgress.fromJson(Map<String, dynamic> json) => LearnerProgress(
        totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
        completedChallenges: (json['completedChallenges'] as num?)?.toInt() ?? 0,
        totalChallenges: (json['totalChallenges'] as num?)?.toInt() ?? 0,
      );

  static const empty = LearnerProgress(totalPoints: 0, completedChallenges: 0, totalChallenges: 0);
}

/// A server-verified achievement. The app only *displays* these.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.points = 0,
  });

  final String id;
  final String title;
  final String description;
  final int points;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? 'Achievement',
        description: (json['description'] as String?) ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
      );
}
