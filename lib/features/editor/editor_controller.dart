import 'dart:async';

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_models.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/python_runtime/execution_result.dart';
import 'package:skillbridge_python_lab/features/python_runtime/python_runtime.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';

/// Result of a submit action, from the learner's perspective.
enum SubmitOutcome { queuedOffline, accepted, rejected, failed, authExpired }

/// Drives a single editing session: the code buffer, execution, draft autosave
/// and submission. Keeping this logic out of the widget makes it unit-testable.
class EditorController extends ChangeNotifier {
  EditorController({
    required AppDependencies deps,
    required this.exercise,
    Duration? autosaveDebounce,
  })  : _deps = deps,
        _autosaveDebounce = autosaveDebounce ?? const Duration(milliseconds: 1500);

  final AppDependencies _deps;
  final Exercise exercise;
  final Duration _autosaveDebounce;

  String _code = '';
  ExecutionResult? _result;
  bool _isRunning = false;
  bool _isSubmitting = false;
  bool _hasUnsavedChanges = false;
  DateTime? _savedAt;
  SubmitOutcome? _lastSubmitOutcome;
  String? _submitMessage;

  /// Lines fed to `input()` during execution.
  String _stdinText = '';
  Timer? _autosaveTimer;

  String get code => _code;
  ExecutionResult? get result => _result;
  bool get isRunning => _isRunning;
  bool get isSubmitting => _isSubmitting;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  DateTime? get savedAt => _savedAt;
  SubmitOutcome? get lastSubmitOutcome => _lastSubmitOutcome;
  String? get submitMessage => _submitMessage;
  String get stdinText => _stdinText;

  /// True when the algorithm has run at least once.
  bool get hasRun => _result != null;

  /// Initialises state from a saved draft, falling back to starter code.
  Future<void> load() async {
    final draft = await _deps.drafts.find(_deps.learnerRef, exercise.id);
    _code = draft?.code ?? exercise.starterCode;
    _savedAt = draft?.updatedAt;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void updateCode(String value, {bool markDirty = true}) {
    _code = value;
    if (markDirty) {
      _hasUnsavedChanges = true;
      _scheduleAutosave();
    }
    notifyListeners();
  }

  void setStdinText(String value) {
    _stdinText = value;
    notifyListeners();
  }

  List<String> get stdinLines =>
      _stdinText.isEmpty ? exercise.sampleStdin : _stdinText.split('\n');

  void _scheduleAutosave() {
    if (!_deps.settings.autoSaveDraft) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDebounce, () {
      unawaited(saveDraft());
    });
  }

  /// Persists the current buffer.
  Future<void> saveDraft() async {
    _autosaveTimer?.cancel();
    await _deps.drafts.save(
      learnerRef: _deps.learnerRef,
      exerciseId: exercise.id,
      exerciseVersion: exercise.version,
      code: _code,
    );
    _savedAt = DateTime.now();
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Discards edits and restores the original starter code.
  Future<void> resetToStarter() async {
    _code = exercise.starterCode;
    _hasUnsavedChanges = true;
    _result = null;
    await saveDraft();
    notifyListeners();
  }

  /// Executes the current buffer on the selected runtime.
  Future<ExecutionResult> run() async {
    if (_isRunning) {
      return _result ?? ExecutionResult.cancelled();
    }
    _isRunning = true;
    _result = null;
    notifyListeners();
    try {
      final result = await _deps.runtime.execute(ExecutionRequest(
        code: _code,
        stdinLines: stdinLines,
        timeout: _deps.config.executionTimeout,
        maxOutputChars: _deps.config.maxOutputChars,
      ));
      _result = result;
      return result;
    } catch (e) {
      final failure = ExecutionResult.runtimeFailure('Execution failed: $e');
      _result = failure;
      return failure;
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _deps.runtime.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// Creates a durable submission and attempts to sync it immediately.
  ///
  /// The submission is always persisted **before** any network call, so an
  /// offline tap is never lost. Rewards are decided by the server response.
  Future<SubmitOutcome> submit() async {
    _isSubmitting = true;
    _lastSubmitOutcome = null;
    _submitMessage = null;
    notifyListeners();

    final submission = Submission(
      id: _deps.idGenerator.newUuid(),
      learnerRef: _deps.learnerRef,
      exerciseId: exercise.id,
      exerciseVersion: exercise.version,
      code: _code,
      createdAt: DateTime.now(),
    );

    try {
      await _deps.drafts.save(
        learnerRef: _deps.learnerRef,
        exerciseId: exercise.id,
        exerciseVersion: exercise.version,
        code: _code,
      );

      final inserted = await _deps.submissions.enqueue(submission);
      if (!inserted) {
        // Defensive: identical id already queued (should not happen with UUID).
        _lastSubmitOutcome = SubmitOutcome.failed;
        _submitMessage = 'This submission was already saved.';
        return _lastSubmitOutcome!;
      }

      if (!_deps.connectivity.isOnline) {
        _lastSubmitOutcome = SubmitOutcome.queuedOffline;
        _submitMessage = "Saved offline. It will be sent when you're back online.";
        return _lastSubmitOutcome!;
      }

      _lastSubmitOutcome = await _syncAndInterpret(submission);
      return _lastSubmitOutcome!;
    } catch (e) {
      _lastSubmitOutcome = SubmitOutcome.failed;
      _submitMessage = 'Could not save your submission. Please try again.';
      return _lastSubmitOutcome!;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<SubmitOutcome> _syncAndInterpret(Submission submission) async {
    try {
      final receipt = await _deps.lmsClient.submitSolution(submission);
      final accepted = receipt.verdict == GradeVerdict.accepted;
      await _deps.submissions.update(submission.copyWith(
        syncState: accepted ? SubmissionSyncState.accepted : SubmissionSyncState.rejected,
        attemptCount: submission.attemptCount + 1,
        lastAttemptAt: DateTime.now(),
        serverResponseRef: receipt.serverRef,
        serverStatus: receipt.verdict.name,
      ));
      _submitMessage = receipt.message;
      return accepted ? SubmitOutcome.accepted : SubmitOutcome.rejected;
    } on AuthenticationException {
      await _deps.submissions.update(submission.copyWith(
        syncState: SubmissionSyncState.failed,
        lastError: 'Session expired',
      ));
      _submitMessage = 'Saved. Sign in again to send it.';
      return SubmitOutcome.authExpired;
    } on NetworkException {
      await _deps.submissions.update(submission.copyWith(
        syncState: SubmissionSyncState.failed,
        lastError: 'Network problem',
      ));
      _submitMessage = "Saved. It will send when you're back online.";
      return SubmitOutcome.queuedOffline;
    } on AppException catch (e) {
      await _deps.submissions.update(submission.copyWith(
        syncState: SubmissionSyncState.failed,
        lastError: e.userMessage,
      ));
      _submitMessage = e.userMessage;
      return SubmitOutcome.failed;
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }
}
