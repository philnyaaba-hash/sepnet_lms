import 'dart:async';

import 'package:skillbridge_python_lab/core/config/app_config.dart';
import 'package:skillbridge_python_lab/core/security/id_generator.dart';
import 'package:skillbridge_python_lab/core/storage/app_database.dart';
import 'package:skillbridge_python_lab/core/storage/draft_repository.dart';
import 'package:skillbridge_python_lab/core/storage/exercise_repository.dart';
import 'package:skillbridge_python_lab/core/storage/settings_repository.dart';
import 'package:skillbridge_python_lab/core/storage/submission_repository.dart';
import 'package:skillbridge_python_lab/features/offline_sync/connectivity_service.dart';
import 'package:skillbridge_python_lab/features/offline_sync/submission_sync_service.dart';
import 'package:skillbridge_python_lab/features/python_runtime/python_runtime.dart';
import 'package:skillbridge_python_lab/features/python_runtime/python_runtime_factory.dart';
import 'package:skillbridge_python_lab/integrations/lms/http_lms_client.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_client.dart';
import 'package:skillbridge_python_lab/integrations/lms/mock_lms_client.dart';

/// Composition root. Everything the app needs is created here and injected via
/// `provider`, so tests can substitute fakes without touching widgets.
class AppDependencies {
  AppDependencies({
    required this.config,
    required this.database,
    required this.settings,
    required this.drafts,
    required this.submissions,
    required this.exercises,
    required this.lmsClient,
    required this.connectivity,
    required this.runtime,
    required this.syncService,
    required this.idGenerator,
    required this.learnerRef,
    this.ownsLmsClient = true,
    this.ownsRuntime = true,
  });

  final AppConfig config;
  final AppDatabase database;
  final SettingsRepository settings;
  final DraftRepository drafts;
  final SubmissionRepository submissions;
  final ExerciseRepository exercises;
  final LmsClient lmsClient;
  final ConnectivityService connectivity;
  final PythonRuntime runtime;
  final SubmissionSyncService syncService;
  final IdGenerator idGenerator;
  final String learnerRef;
  final bool ownsLmsClient;
  final bool ownsRuntime;

  /// Builds the real dependency graph for the running app.
  static Future<AppDependencies> create({AppConfig? config}) async {
    final resolved = config ?? AppConfig.forCurrentPlatform();
    final database = AppDatabase();
    await database.open();
    final settings = await SettingsRepository.create();
    final connectivity = ConnectivityPlusService();

    final learnerRef = settings.learnerRef ?? 'local-${IdGenerator().newShortId(10)}';
    await settings.setLearnerRef(learnerRef);

    LmsClient lmsClient;
    var ownsLms = true;
    if (resolved.useMockLms) {
      lmsClient = MockLmsClient();
    } else {
      lmsClient = HttpLmsClient(
        baseUrl: resolved.lmsBaseUrl,
        tokenProvider: StaticTokenProvider(const String.fromEnvironment('SB_LMS_TOKEN')),
      );
    }

    final submissions = SubmissionRepository(database);
    final runtime = createPythonRuntime(resolved);

    return AppDependencies(
      config: resolved,
      database: database,
      settings: settings,
      drafts: DraftRepository(database),
      submissions: submissions,
      exercises: ExerciseRepository(database),
      lmsClient: lmsClient,
      connectivity: connectivity,
      runtime: runtime,
      syncService: SubmissionSyncService(
        lmsClient: lmsClient,
        submissions: submissions,
        connectivity: connectivity,
      ),
      idGenerator: IdGenerator(),
      learnerRef: learnerRef,
      ownsLmsClient: ownsLms,
      ownsRuntime: true,
    );
  }

  Future<void> dispose() async {
    if (ownsRuntime) await runtime.dispose();
    await connectivity.dispose();
    await database.close();
  }
}
