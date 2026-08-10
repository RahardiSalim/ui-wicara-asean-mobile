import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wicara_mobile/src/features/edge_ai/domain/edge_ai_models.dart';
import 'package:wicara_mobile/src/features/edge_ai/domain/edge_ai_runtime.dart';
import 'package:wicara_mobile/src/features/offline_learning/data/local_curriculum_repository.dart';
import 'package:wicara_mobile/src/features/offline_learning/data/local_mastery_repository.dart';
import 'package:wicara_mobile/src/features/offline_learning/data/local_session_repository.dart';
import 'package:wicara_mobile/src/features/offline_learning/data/local_wicara_database.dart';
import 'package:wicara_mobile/src/features/offline_pretest/data/local_pretest_repository.dart';
import 'package:wicara_mobile/src/features/offline_learning/data/sync_outbox_repository.dart';
import 'package:wicara_mobile/src/features/offline_pretest/domain/local_evidence_evaluator.dart';
import 'package:wicara_mobile/src/features/offline_pretest/domain/local_pretest_question_generator.dart';
import 'package:wicara_mobile/src/features/pretest/data/pretest_session_store.dart';
import 'package:wicara_mobile/src/features/pretest/domain/pretest_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalWicaraDatabase database;
  late Future<String> Function(String path) assetLoader;

  setUp(() async {
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp('wicara_phase4_test_');
    database = LocalWicaraDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathProvider: () async => tempDir.path,
      databaseName: 'offline_phase4_test.db',
      enforcePlatformSupport: false,
    );
    assetLoader = (assetPath) async {
      final file = File(p.join(Directory.current.path, assetPath));
      return file.readAsString();
    };
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'runs local adaptive pretest and finalizes diagnosis without backend',
    () async {
      final curriculum = LocalCurriculumRepository(
        database: database,
        assetLoader: assetLoader,
      );
      final sessions = LocalSessionRepository(database: database);
      final mastery = LocalMasteryRepository(database: database);
      final outbox = SyncOutboxRepository(database: database);
      final repository = LocalPretestRepository(
        localDatabase: database,
        pretestSessionStore: PretestSessionStore()
          ..learningGoalId = 'local-goal-1'
          ..targetConceptCode = 'km_d_matematika_fungsi_dasar'
          ..targetSubjectCode = 'matematika',
        localCurriculumRepository: curriculum,
        localSessionRepository: sessions,
        localMasteryRepository: mastery,
        syncOutboxRepository: outbox,
        evidenceEvaluator: LocalEvidenceEvaluator(
          runtime: const _FakeRuntime(ready: false),
        ),
        // The on-device question generator needs a ready runtime; the evidence
        // evaluator deliberately runs with a not-ready runtime to exercise the
        // deterministic reasoning fallback.
        questionGenerator: const LocalPretestQuestionGenerator(
          runtime: _PackGeneratingRuntime(),
        ),
        forceLocalForPilot: true,
        allowBackendFallback: false,
      );

      var question = await repository.fetchCurrentQuestion();
      expect(question.progressMax, 10);
      PretestAnswerResult? answerResult;
      for (var i = 0; i < 12; i++) {
        answerResult = await repository.submitAnswer(
          PretestAnswer(
            questionId: question.id,
            optionId: question.options.first.id,
            confidence: 6,
            typedReasoning: 'Saya coba hitung dari data soal.',
          ),
        );
        if (answerResult.completed) {
          break;
        }
        question = answerResult.nextQuestion!;
      }

      expect(answerResult, isNotNull);
      expect(answerResult!.completed, isTrue);
      expect(answerResult.diagnosis, isNotNull);
      expect(answerResult.diagnosis!.recommendedPath.isNotEmpty, isTrue);
      expect(answerResult.diagnosis!.nodeReports.isNotEmpty, isTrue);

      final persistedSessions = await sessions.listSessions();
      expect(
        persistedSessions.any(
          (session) =>
              session.sessionType == 'offline_pretest_pilot' &&
              session.status == 'completed',
        ),
        isTrue,
      );
      final masteryStates = await mastery.listStates();
      expect(masteryStates.isNotEmpty, isTrue);

      final pendingOutbox = await outbox.listPending();
      expect(pendingOutbox.isNotEmpty, isTrue);
    },
  );
}

class _FakeRuntime implements EdgeAiRuntime {
  const _FakeRuntime({required this.ready});

  final bool ready;

  @override
  Future<void> cancel(String requestId) async {}

  @override
  Future<EdgeGenerationResult> generate(EdgeGenerationRequest request) async {
    return EdgeGenerationResult(
      requestId: request.requestId,
      text: 'ok',
      finishReason: 'completed',
      metrics: const EdgeGenerationMetrics(
        totalMs: 20,
        inputChars: 10,
        outputChars: 2,
        outputCharsPerSecond: 100,
      ),
      runtime: 'litert_lm',
      executionLocation: 'device',
      fallbackUsed: false,
      raw: const {},
    );
  }

  @override
  Future<EdgeJsonGenerationResult> generateJson(
    EdgeJsonGenerationRequest request,
  ) async {
    final base = await generate(
      EdgeGenerationRequest(requestId: request.requestId, prompt: request.user),
    );
    return EdgeJsonGenerationResult(
      rawText: '{}',
      parsedJsonString: '{}',
      base: base,
    );
  }

  @override
  Future<EdgeRuntimeStatus> getStatus() async {
    return EdgeRuntimeStatus(
      available: true,
      loaded: ready,
      runtime: 'litert_lm',
      backend: 'cpu',
      executionLocation: ready ? 'device' : 'not_ready',
      defaultModelExists: true,
    );
  }

  @override
  Future<EdgeRuntimeStatus> initialize({
    String? modelPath,
    EdgeRuntimeBackend backend = EdgeRuntimeBackend.cpu,
    int maxTokens = 256,
  }) async {
    return getStatus();
  }

  @override
  Future<EdgeModelInstallResult> installModel({
    required String url,
    String? sha256,
    bool overwrite = false,
    String? modelPath,
  }) async {
    return const EdgeModelInstallResult(
      success: true,
      skipped: true,
      modelPath: '/tmp/model.litertlm',
      bytesDownloaded: 0,
      sha256: '',
    );
  }

  @override
  Future<void> unload() async {}
}

/// A ready runtime whose JSON generation returns a valid on-device pretest pack
/// (easy/medium/hard), so the engine's LiteRT question path produces usable
/// questions without a real model.
class _PackGeneratingRuntime implements EdgeAiRuntime {
  const _PackGeneratingRuntime();

  static const _packJson = '''
{
  "questions": {
    "easy": {
      "prompt": "Soal mudah tentang konsep ini?",
      "helper_text": "Pilih jawaban yang paling tepat.",
      "options": ["A. 2", "B. 4", "C. 6", "D. 8"],
      "correct_option": "B. 4",
      "explanation": "Jawaban benar adalah 4 karena 2 + 2 = 4."
    },
    "medium": {
      "prompt": "Soal sedang tentang konsep ini?",
      "helper_text": "Perhatikan langkah-langkahnya.",
      "options": ["A. 9", "B. 10", "C. 12", "D. 15"],
      "correct_option": "C. 12",
      "explanation": "Jawaban benar adalah 12 karena 3 x 4 = 12."
    },
    "hard": {
      "prompt": "Soal sulit tentang konsep ini?",
      "helper_text": "Gunakan penalaran lengkap.",
      "options": ["A. 21", "B. 24", "C. 27", "D. 30"],
      "correct_option": "B. 24",
      "explanation": "Jawaban benar adalah 24 karena 6 x 4 = 24."
    }
  }
}
''';

  @override
  Future<void> cancel(String requestId) async {}

  @override
  Future<EdgeGenerationResult> generate(EdgeGenerationRequest request) async {
    return EdgeGenerationResult(
      requestId: request.requestId,
      text: _packJson,
      finishReason: 'completed',
      metrics: const EdgeGenerationMetrics(
        totalMs: 20,
        inputChars: 10,
        outputChars: 20,
        outputCharsPerSecond: 100,
      ),
      runtime: 'litert_lm',
      executionLocation: 'device',
      fallbackUsed: false,
      raw: const {'modelId': 'gemma-4-e2b-it-litertlm'},
    );
  }

  @override
  Future<EdgeJsonGenerationResult> generateJson(
    EdgeJsonGenerationRequest request,
  ) async {
    final base = await generate(
      EdgeGenerationRequest(requestId: request.requestId, prompt: request.user),
    );
    return EdgeJsonGenerationResult(
      rawText: _packJson,
      parsedJsonString: _packJson,
      base: base,
    );
  }

  @override
  Future<EdgeRuntimeStatus> getStatus() async {
    return const EdgeRuntimeStatus(
      available: true,
      loaded: true,
      runtime: 'litert_lm',
      backend: 'cpu',
      executionLocation: 'device',
      defaultModelExists: true,
    );
  }

  @override
  Future<EdgeRuntimeStatus> initialize({
    String? modelPath,
    EdgeRuntimeBackend backend = EdgeRuntimeBackend.cpu,
    int maxTokens = 256,
  }) async {
    return getStatus();
  }

  @override
  Future<EdgeModelInstallResult> installModel({
    required String url,
    String? sha256,
    bool overwrite = false,
    String? modelPath,
  }) async {
    return const EdgeModelInstallResult(
      success: true,
      skipped: true,
      modelPath: '/tmp/model.litertlm',
      bytesDownloaded: 0,
      sha256: '',
    );
  }

  @override
  Future<void> unload() async {}
}
