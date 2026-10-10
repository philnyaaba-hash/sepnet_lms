import 'package:flutter/foundation.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_models.dart';

/// Backs the Achievements screen. All values shown are **server-authoritative**;
/// the app never computes or mints rewards locally.
class AchievementsController extends ChangeNotifier {
  AchievementsController(this._deps);

  final AppDependencies _deps;

  LearnerProgress _progress = LearnerProgress.empty;
  List<Achievement> _achievements = const [];
  List<SubmissionSummary> _recent = const [];
  bool _loading = false;
  String? _error;

  LearnerProgress get progress => _progress;
  List<Achievement> get achievements => _achievements;
  List<SubmissionSummary> get recentSubmissions => _recent;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _progress = await _deps.lmsClient.fetchProgress();
      _achievements = await _deps.lmsClient.fetchAchievements();
      final submissions = await _deps.submissions.listForLearner(_deps.learnerRef);
      _recent = submissions
          .map((s) => SubmissionSummary(
                exerciseId: s.exerciseId,
                state: s.syncState.name,
                createdAt: s.createdAt,
                serverStatus: s.serverStatus,
              ))
          .toList(growable: false);
    } catch (_) {
      _error = 'Could not refresh your progress right now.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

/// Lightweight view model over a [Submission] for the history list.
class SubmissionSummary {
  const SubmissionSummary({
    required this.exerciseId,
    required this.state,
    required this.createdAt,
    this.serverStatus,
  });

  final String exerciseId;
  final String state;
  final DateTime createdAt;
  final String? serverStatus;
}
