import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import 'src/app/wicara_app.dart';
import 'src/core/accessibility/speech_accessibility_scope.dart';
import 'src/core/accessibility/speech_api_client.dart';
import 'src/core/accessibility/speech_controller.dart';
import 'src/core/network/api_client.dart';
import 'src/features/auth/application/auth_controller.dart';
import 'src/features/auth/data/api_auth_repository.dart';
import 'src/features/analytics/data/api_analytics_repository.dart';
import 'src/features/auth/data/auth_session_store.dart';
import 'src/features/auth/data/google_web_client_id.dart';
import 'src/features/curriculum/data/api_curriculum_repository.dart';
import 'src/features/curriculum/domain/curriculum_repository.dart';
import 'src/features/home/data/api_home_repository.dart';
import 'src/features/learning_goal/data/api_learning_goal_repository.dart';
import 'src/features/learning_goal/data/local_learning_goal_repository.dart';
import 'src/features/learning_goal/domain/learning_goal_repository.dart';
import 'src/features/onboarding/application/onboarding_controller.dart';
import 'src/features/onboarding/data/api_onboarding_repository.dart';
import 'src/features/onboarding/data/onboarding_profile_store.dart';
import 'src/features/offline_learning/data/curriculum_bootstrap_service.dart';
import 'src/features/offline_learning/data/local_curriculum_repository.dart';
import 'src/features/offline_learning/data/local_wicara_database.dart';
import 'src/features/offline_pretest/data/local_pretest_repository.dart';
import 'src/features/pretest/data/api_pretest_repository.dart';
import 'src/features/pretest/data/pretest_session_store.dart';
import 'src/features/pretest/domain/pretest_repository.dart';
import 'src/features/review/data/api_review_repository.dart';
import 'src/features/workspace/data/api_workspace_repository.dart';
import 'src/features/workspace/data/workspace_session_store.dart';

const _googleWebClientId = String.fromEnvironment(
  'WICARA_GOOGLE_WEB_CLIENT_ID',
);
const _offlineLearningEnabled = bool.fromEnvironment(
  'WICARA_OFFLINE_LEARNING',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localDatabase = LocalWicaraDatabase();
  final localCurriculumRepository = LocalCurriculumRepository(
    database: localDatabase,
  );
  if (_offlineLearningEnabled) {
    await _bootstrapOfflineCurriculum(
      database: localDatabase,
      curriculumRepository: localCurriculumRepository,
    );
  }
  final sessionStore = authSessionStore;
  final pretestStore = pretestSessionStore;
  final workspaceStore = workspaceSessionStore;
  final apiClient = ApiClient(
    baseUrl: ApiClient.resolveRuntimeBaseUrl(ApiClient.defaultBaseUrl),
  );
  final speechController = SpeechController(
    apiClient: SpeechApiClient(baseUrl: apiClient.baseUrl),
    player: AudioPlayer(),
    recorder: AudioRecorder(),
  );
  await speechController.init();
  final googleWebClientId = resolveGoogleWebClientId(_googleWebClientId);
  final authController = AuthController(
    authRepository: ApiAuthRepository(
      apiClient: apiClient,
      sessionStore: sessionStore,
      googleWebClientId: googleWebClientId,
    ),
    sessionStore: sessionStore,
    apiClient: apiClient,
    // Workspace ids are account-scoped; keeping them across a sign-out makes the
    // next account POST ids it does not own and 404 out of every module.
    onSignedOut: [workspaceStore.clearAll],
  );

  await authController.initialize();
  await workspaceStore.read();
  final onboardingController = OnboardingController(
    onboardingRepository: ApiOnboardingRepository(
      apiClient: apiClient,
      sessionStore: sessionStore,
    ),
    profileStore: OnboardingProfileStore(),
  );
  await onboardingController.initialize(
    displayName: authController.session?.displayName ?? 'Learner',
  );

  final backendPretestRepository = ApiPretestRepository(
    apiClient: apiClient,
    sessionStore: sessionStore,
    pretestSessionStore: pretestStore,
  );
  final useOfflineLearning =
      _offlineLearningEnabled && localDatabase.isPlatformSupported;
  final CurriculumRepository curriculumRepository = useOfflineLearning
      ? localCurriculumRepository
      : ApiCurriculumRepository(apiClient: apiClient);
  final LearningGoalRepository learningGoalRepository = useOfflineLearning
      ? LocalLearningGoalRepository(
          localCurriculumRepository: localCurriculumRepository,
          pretestSessionStore: pretestStore,
        )
      : ApiLearningGoalRepository(
          apiClient: apiClient,
          sessionStore: sessionStore,
          pretestSessionStore: pretestStore,
        );
  final PretestRepository pretestRepository = useOfflineLearning
      ? LocalPretestRepository(
          localDatabase: localDatabase,
          pretestSessionStore: pretestStore,
          localCurriculumRepository: localCurriculumRepository,
          backendRepository: backendPretestRepository,
          forceLocalForPilot: true,
          allowBackendFallback: false,
        )
      : backendPretestRepository;

  runApp(
    SpeechAccessibilityScope(
      notifier: speechController,
      child: WicaraApp(
        authController: authController,
        onboardingController: onboardingController,
        curriculumRepository: curriculumRepository,
        learningGoalRepository: learningGoalRepository,
        homeRepository: ApiHomeRepository(
          apiClient: apiClient,
          sessionStore: sessionStore,
        ),
        reviewRepository: ApiReviewRepository(apiClient: apiClient),
        analyticsRepository: ApiAnalyticsRepository(apiClient: apiClient),
        onboardingRepository: ApiOnboardingRepository(
          apiClient: apiClient,
          sessionStore: sessionStore,
        ),
        pretestRepository: pretestRepository,
        workspaceRepository: ApiWorkspaceRepository(
          apiClient: apiClient,
          sessionStore: sessionStore,
          workspaceSessionStore: workspaceStore,
        ),
      ),
    ),
  );
}

Future<void> _bootstrapOfflineCurriculum({
  required LocalWicaraDatabase database,
  required LocalCurriculumRepository curriculumRepository,
}) async {
  if (!database.isPlatformSupported) {
    return;
  }
  final bootstrapService = CurriculumBootstrapService(
    repository: curriculumRepository,
  );
  try {
    await bootstrapService.ensureBootstrapped();
  } catch (error) {
    debugPrint(
      'Offline curriculum bootstrap failed, fallback to pilot graph: $error',
    );
    await curriculumRepository.ensurePilotSliceSeeded();
  }
}
