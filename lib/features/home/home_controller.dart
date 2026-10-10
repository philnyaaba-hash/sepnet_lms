import 'package:flutter/foundation.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'package:skillbridge_python_lab/core/storage/draft_repository.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_models.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';

/// Backs the Home screen: recent exercises, drafts, progress and offline state.
class HomeController extends ChangeNotifier {
  HomeController(this._deps);

  final AppDependencies _deps;

  List<Exercise> _exercises = const [];
  List<Draft> _drafts = const [];
  LearnerProgress _progress = LearnerProgress.empty;
  bool _loading = false;
  String? _error;
  bool _fromCache = false;

  List<Exercise> get exercises => _exercises;
  List<Draft> get drafts => _drafts;
  LearnerProgress get progress => _progress;
  bool get isLoading => _loading;
  String? get error => _error;

  /// True when we served exercises from the local cache (offline or API error).
  bool get isFromCache => _fromCache;

  /// "Continue coding" target: the most recently edited draft, else first exercise.
  Exercise? get continueExercise {
    if (_drafts.isNotEmpty) {
      final draftExercise = _exerciseById(_drafts.first.exerciseId);
      if (draftExercise != null) return draftExercise;
    }
    return _exercises.isEmpty ? null : _exercises.first;
  }

  Draft? draftFor(String exerciseId) {
    for (final draft in _drafts) {
      if (draft.exerciseId == exerciseId) return draft;
    }
    return null;
  }

  Exercise? _exerciseById(String id) {
    for (final exercise in _exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  /// Returns `false` when the whole load failed, so the caller decides whether
  /// that is worth telling the learner about.
  Future<bool> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _refreshExercises();
      await _refreshLocal();
      await _refreshProgress();
      return true;
    } catch (_) {
      // A storage or unexpected failure must not escape as an unhandled async
      // error from initState; surface it as a message instead.
      _error = 'Something went wrong while loading. Pull down to try again.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshExercises() async {
    try {
      final remote = await _deps.lmsClient.fetchExercises();
      await _deps.exercises.upsertAll(remote);
      _exercises = remote;
      _fromCache = false;
    } catch (e) {
      // Offline-first: fall back to whatever we cached previously.
      final cached = await _deps.exercises.listAll();
      _exercises = cached;
      _fromCache = true;
      if (cached.isEmpty) {
        _error = e is AppException
            ? e.userMessage
            : 'We could not load your exercises. Pull down to try again.';
      }
    }
  }

  Future<void> _refreshLocal() async {
    try {
      _drafts = await _deps.drafts.listFor(_deps.learnerRef);
    } catch (_) {
      // Drafts are a local optimisation; losing them must not break the screen.
      _drafts = const [];
    }
  }

  Future<void> _refreshProgress() async {
    try {
      _progress = await _deps.lmsClient.fetchProgress();
    } catch (_) {
      _progress = LearnerProgress.empty;
    }
  }

  /// Re-reads local drafts (after returning from the editor).
  Future<void> refreshLocal() async {
    await _refreshLocal();
    notifyListeners();
  }
}
