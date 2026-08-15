import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_session_store.dart';
import '../../../core/localization/app_language.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../domain/pretest_models.dart';
import '../domain/pretest_repository.dart';
import 'pretest_session_store.dart';

const _pretestRequestTimeout = Duration(minutes: 5);

/// Copy for the learner's language. The pretest data layer runs outside the
/// widget tree, so it reads the app-wide language mirror.
OnboardingCopy get _copy => AppLanguage.copy;

class ApiPretestRepository implements PretestRepository {
  const ApiPretestRepository({
    required ApiClient apiClient,
    required AuthSessionStore sessionStore,
    required PretestSessionStore pretestSessionStore,
  }) : _apiClient = apiClient,
       _sessionStore = sessionStore,
       _pretestSessionStore = pretestSessionStore;

  final ApiClient _apiClient;
  final AuthSessionStore _sessionStore;
  final PretestSessionStore _pretestSessionStore;

  @override
  Future<PretestQuestion> fetchCurrentQuestion() async {
    final token = _requireToken();
    final learningGoalId = _pretestSessionStore.learningGoalId;
    if (learningGoalId == null || learningGoalId.isEmpty) {
      throw PretestException(_copy.createGoalBeforePretestLabel);
    }

    try {
      final json = await _apiClient.postJson(
        '/api/v1/pretests/start',
        headers: {'Authorization': 'Bearer $token'},
        body: {'learning_goal_id': learningGoalId},
        timeout: _pretestRequestTimeout,
      );
      _pretestSessionStore.pretestSessionId = _string(json['session_id']);
      final current = json['current_question'];
      if (current is! Map<String, dynamic>) {
        throw PretestException(_copy.invalidPretestQuestionLabel);
      }
      return questionFromJson(current);
    } on PretestException {
      rethrow;
    } on ApiClientException catch (error) {
      throw PretestException(error.message);
    }
  }

  @override
  Future<PretestAnswerResult> submitAnswer(PretestAnswer answer) async {
    final token = _requireToken();
    final sessionId = _requirePretestSessionId();
    if (answer.optionId.isEmpty) {
      throw PretestException(_copy.chooseAnswerFirstLabel);
    }

    try {
      final json = await _apiClient.postJson(
        '/api/v1/pretests/$sessionId/answers',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'question_id': answer.questionId,
          'selected_option_id': answer.optionId,
          'confidence': answer.confidence,
          'typed_reasoning': answer.typedReasoning,
          'canvas_asset_id': answer.canvasAssetId,
          'used_canvas': answer.usedCanvas,
        },
        timeout: _pretestRequestTimeout,
      );
      final nextQuestion = json['next_question'];
      if (nextQuestion is Map<String, dynamic>) {
        return PretestAnswerResult(
          completed: false,
          nextQuestion: questionFromJson(nextQuestion),
        );
      }
      final diagnosis = json['diagnosis'];
      if (diagnosis is Map<String, dynamic>) {
        return PretestAnswerResult(
          completed: true,
          diagnosis: knowledgeStateFromDiagnosis(diagnosis),
        );
      }
      throw PretestException(_copy.noNextQuestionLabel);
    } on ApiClientException catch (error) {
      if (_isQuestionAlreadyAnswered(error)) {
        final currentQuestion = await fetchCurrentQuestion();
        return PretestAnswerResult(
          completed: false,
          nextQuestion: currentQuestion,
        );
      }
      throw PretestException(error.message);
    }
  }

  @override
  Future<String> uploadEvidenceImage({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final token = _requireToken();
    try {
      final json = await _apiClient.postMultipartBytes(
        '/api/v1/evidence/image-assets/upload',
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        headers: {'Authorization': 'Bearer $token'},
        timeout: _pretestRequestTimeout,
      );
      final assetId = _string(json['id']);
      if (assetId.isEmpty) {
        throw PretestException(_copy.invalidEvidenceImageLabel);
      }
      return assetId;
    } on ApiClientException catch (error) {
      throw PretestException(error.message);
    }
  }

  @override
  Future<KnowledgeState> selectPath(String pathOption) async {
    final token = _requireToken();
    final learningGoalId = _pretestSessionStore.learningGoalId;
    if (learningGoalId == null || learningGoalId.isEmpty) {
      throw PretestException(_copy.createGoalBeforePathLabel);
    }

    try {
      final json = await _apiClient.postJson(
        '/api/v1/learning-goals/$learningGoalId/path-selection',
        headers: {'Authorization': 'Bearer $token'},
        body: {'path_option': pathOption},
      );
      _pretestSessionStore.trackId = _string(json['track_id']);
      final copy = _copy;
      return KnowledgeState(
        skill: copy.pathSelectedLabel,
        gapLabel: _string(json['goal_status']).toUpperCase(),
        message: copy.adaptivePathReadyLabel,
        pathTitle: copy.personalizedPathGeneratedLabel,
        pathMeta: copy.modulesCountLabel(
          (json['modules'] as List?)?.length ?? 0,
        ),
        pathDescription: copy.continueSelectedPathLabel,
        recommendedPath: pathOption,
        pathOptions: const [],
      );
    } on ApiClientException catch (error) {
      throw PretestException(error.message);
    }
  }

  String _requireToken() {
    final token = _sessionStore.accessToken;
    if (token == null || token.isEmpty) {
      throw PretestException(_copy.loginBeforePretestLabel);
    }
    return token;
  }

  String _requirePretestSessionId() {
    final sessionId = _pretestSessionStore.pretestSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      throw PretestException(_copy.openPretestBeforeSubmitLabel);
    }
    return sessionId;
  }
}

bool _isQuestionAlreadyAnswered(ApiClientException error) {
  final detail = error.detail;
  return detail is Map &&
      detail['error']?.toString() == 'QUESTION_ALREADY_ANSWERED';
}

PretestQuestion questionFromJson(Map<String, dynamic> json) {
  final options = json['options'];
  final progress = json['progress'];
  final conceptTitle = _string(json['concept_title']);
  return PretestQuestion(
    id: _string(json['id']),
    packId: _string(json['pack_id']),
    stepLabel: _string(json['step_label']).isNotEmpty
        ? _string(json['step_label'])
        : 'Question ${_intFromProgress(progress, 'current', fallback: 1)} - Up to ${_intFromProgress(progress, 'max', fallback: 10)} questions',
    topic: conceptTitle.isNotEmpty ? conceptTitle : _string(json['topic']),
    prompt: _string(json['prompt']),
    helper: _string(json['helper']),
    progressCurrent: _intFromProgress(progress, 'current', fallback: 1),
    progressMax: _intFromProgress(progress, 'max', fallback: 10),
    options: options is List
        ? options
              .whereType<Map<String, dynamic>>()
              .map(
                (option) => PretestOption(
                  id: _string(option['id']),
                  label: _string(option['label']),
                  text: _string(option['text']),
                ),
              )
              .toList(growable: false)
        : const [],
  );
}

KnowledgeState knowledgeStateFromDiagnosis(Map<String, dynamic> diagnosis) {
  final copy = _copy;
  final target = diagnosis['target'];
  final analysis = diagnosis['analysis'];
  final targetTitle = target is Map ? _string(target['title']) : '';
  final recommendedPath = _string(diagnosis['recommended_path']);
  final pathOptions = diagnosis['path_options'];
  final answeredCount = _int(diagnosis['pure_answer_total']) ?? 0;
  final correctCount = _int(diagnosis['pure_answer_score']) ?? 0;
  final scorePercent = answeredCount > 0
      ? (correctCount / answeredCount) * 100
      : (_double(diagnosis['pure_answer_percent']) ??
            _double(diagnosis['score_percent']));
  final strengths = analysis is Map
      ? _stringList(analysis['strengths'])
      : const <String>[];
  final gaps = analysis is Map
      ? _stringList(analysis['gaps'])
      : const <String>[];
  final evidenceNotes = analysis is Map
      ? _stringList(analysis['evidence_notes'])
      : const <String>[];
  final recommendedFocus = analysis is Map
      ? _stringList(analysis['recommended_focus'])
      : const <String>[];
  final masteryPercent =
      _double(diagnosis['target_mastery_estimate_percent']) ??
      _double(diagnosis['adaptive_mastery_estimate_percent']) ??
      scorePercent;
  final masteryScore = _percentToUnit(masteryPercent);
  final overallMasteryPercent =
      _int(diagnosis['overall_mastery_percent']) ??
      (analysis is Map ? _int(analysis['overall_mastery_percent']) : null);
  return KnowledgeState(
    skill: targetTitle.isNotEmpty ? targetTitle : copy.adaptiveDiagnosisLabel,
    gapLabel: target is Map ? _string(target['status']).toUpperCase() : 'DONE',
    message: _string(diagnosis['summary']),
    pathTitle: copy.personalizedPathGeneratedLabel,
    pathMeta: _scoreMeta(
      copy,
      scorePercent: scorePercent,
      correctCount: correctCount,
      answeredCount: answeredCount,
    ),
    pathDescription: copy.pathDescriptionLabel(recommendedPath),
    recommendedPath: recommendedPath.isEmpty
        ? 'target_from_basics'
        : recommendedPath,
    pathOptions: pathOptions is List
        ? pathOptions
              .map((item) => _string(item))
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const [],
    masteryScore: masteryScore,
    overallMasteryPercent: overallMasteryPercent,
    correctCount: correctCount,
    answeredCount: answeredCount,
    strengths: strengths,
    gaps: gaps,
    evidenceNotes: evidenceNotes,
    recommendedFocus: recommendedFocus,
    nodeReports: _nodeReports(diagnosis['nodes']),
  );
}

String _string(Object? value) => (value ?? '').toString().trim();

double? _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(_string(value));
}

double? _percentToUnit(Object? value) {
  final parsed = _double(value);
  if (parsed == null) {
    return null;
  }
  return parsed > 1 ? parsed / 100 : parsed;
}

int _intFromProgress(Object? value, String key, {required int fallback}) {
  if (value is Map && value[key] is num) {
    return (value[key] as num).toInt();
  }
  return fallback;
}

int? _int(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_string(value));
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => _string(item))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<PretestNodeReport> _nodeReports(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((node) {
        final evidenceSummary = node['evidence_summary'];
        final summary = evidenceSummary is Map ? evidenceSummary : const {};
        return PretestNodeReport(
          title: _string(node['title']).isNotEmpty
              ? _string(node['title'])
              : _string(node['concept_code']),
          role: _string(node['role']),
          status: _string(node['status']),
          difficultyReached: _string(node['difficulty_reached']),
          masteryScore: _double(node['mastery_score']),
          confidence: _double(node['confidence']),
          reasoningQuality: _string(summary['reasoning_quality']).isNotEmpty
              ? _string(summary['reasoning_quality'])
              : 'not_provided',
          avgReasoningScore: _double(summary['avg_reasoning_score']),
          attemptCount: _int(summary['attempt_count']) ?? 0,
          correctCount: _int(summary['correct_count']) ?? 0,
          answerPercent: _double(node['answer_percent']),
          evidencePercent: _double(node['evidence_percent']),
          scorePercent: _double(node['score_percent']),
          confidencePercent: _double(node['confidence_percent']),
          metricSource: _string(node['metric_source']),
          hasEvidence: summary['has_evidence'] == true,
          diagnosticSignals: _stringList(summary['diagnostic_signals']),
          carelessMistakePossible: summary['careless_mistake_possible'] == true,
          misconceptionDetected: summary['misconception_detected'] == true,
        );
      })
      .where((node) => node.status != 'not_tested')
      .toList(growable: false);
}

String _scoreMeta(
  OnboardingCopy copy, {
  required double? scorePercent,
  required int correctCount,
  required int answeredCount,
}) {
  if (scorePercent == null) {
    return copy.adaptivePretestCompleteLabel;
  }
  final parts = <String>[copy.scoreMetaLabel(scorePercent.round())];
  if (answeredCount > 0) {
    parts.add(copy.correctCountMetaLabel(correctCount, answeredCount));
  }
  return parts.join(' • ');
}
