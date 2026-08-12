import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wicara_mobile/src/core/network/api_client.dart';
import 'package:wicara_mobile/src/features/auth/data/auth_session_store.dart';
import 'package:wicara_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:wicara_mobile/src/features/workspace/data/api_workspace_repository.dart';
import 'package:wicara_mobile/src/features/workspace/data/workspace_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'append keeps backend tutor and sends learner metadata unchanged',
    () async {
      late Map<String, dynamic> requestBody;
      final repository = await _repository(
        MockClient((request) async {
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _jsonResponse({
            'event': _eventJson(actorType: 'learner', text: 'My reasoning'),
            'tutor_response': {
              'text': 'Backend tutor response',
              'intent': 'probe_understanding',
              'next_actions': ['buat_visualisasi', 'minta_petunjuk'],
              'next_phase_ready': false,
              'phase_reasoning': 'More evidence is required.',
              'evidence_tags': ['identified_outer_function'],
              'correctness': 'partial',
              'misconception_status': 'still_active',
              'confidence': 0.86,
              'evaluation_outcome': 'continue_explore',
              'scaffold_level': 2,
              'evidence_request': {'type': 'short_answer'},
              'explanation_card': {'title': 'Chain rule'},
              'tool_suggestion': {
                'tool': 'visualization',
                'reason': 'learner_stuck',
                'prompt': 'Show how the inner derivative changes the slope.',
              },
            },
            'mastery_update': null,
            'workspace': _workspaceJson(),
          });
        }),
      );

      final result = await repository.appendEvent(
        workspaceId: 'workspace-1',
        eventType: 'text',
        textPayload: 'My reasoning',
        metadata: const {'input_source': 'typed'},
      );

      expect(requestBody['metadata'], {'input_source': 'typed'});
      final metadata = requestBody['metadata'] as Map<String, dynamic>;
      expect(metadata, isNot(contains('skip_server_tutor')));
      expect(metadata, isNot(contains('client_tutor_override')));
      expect(metadata, isNot(contains('client_5e_state')));
      expect(result.tutorResponse?.text, 'Backend tutor response');
      expect(result.tutorResponse?.nextActions, [
        'buat_visualisasi',
        'minta_petunjuk',
      ]);
      expect(result.tutorResponse?.correctness, 'partial');
      expect(result.tutorResponse?.evidenceRequest, {'type': 'short_answer'});
      expect(result.tutorResponse?.toolSuggestion?.isVisualization, isTrue);
      expect(
        result.tutorResponse?.toolSuggestion?.prompt,
        'Show how the inner derivative changes the slope.',
      );
      expect(
        result.workspace.learningContext.currentModuleConceptId,
        'concept-chain-rule',
      );
      expect(result.workspace.learningContext.moduleRole, 'prerequisite_gap');
      expect(result.workspace.learningContext.diagnosisReason, 'inner omitted');
      expect(result.workspace.phaseEvidence['explore'], hasLength(1));
      expect(result.workspace.hintLevel, 2);
      expect(result.workspace.posttestTrigger?.isReady, isTrue);
    },
  );

  test(
    'context-auto video request contains no client template or spec',
    () async {
      late Map<String, dynamic> requestBody;
      final repository = await _repository(
        MockClient((request) async {
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _jsonResponse({
            'queue': {
              'job_id': 'job-1',
              'artifact_id': 'artifact-1',
              'status': 'queued',
            },
            'event': _eventJson(actorType: 'system', text: ''),
            'workspace': _workspaceJson(),
          });
        }),
      );

      await repository.generateVideo(
        workspaceId: 'workspace-1',
        generationMode: 'context_auto',
        language: 'id',
        conceptId: 'concept-chain-rule',
        metadata: const {'current_phase': 'explore'},
      );

      expect(requestBody['generation_mode'], 'context_auto');
      expect(requestBody['concept_id'], 'concept-chain-rule');
      expect(requestBody['metadata'], {'current_phase': 'explore'});
      expect(requestBody, isNot(contains('template_id')));
      expect(requestBody, isNot(contains('spec_json')));
    },
  );

  test('advance phase sends no obsolete force query parameter', () async {
    late Uri requestedUri;
    final repository = await _repository(
      MockClient((request) async {
        requestedUri = request.url;
        return _jsonResponse(_workspaceJson());
      }),
    );

    await repository.advancePhase(workspaceId: 'workspace-1');

    expect(requestedUri.path, '/api/v1/workspaces/workspace-1/advance-phase');
    expect(requestedUri.queryParameters, isEmpty);
  });

  test('workspace event exposes tutor tool and queued media metadata', () {
    final tutorEvent = workspaceEventFromJson({
      ..._eventJson(actorType: 'tutor', text: 'A visual may help.'),
      'metadata': {
        'tool_suggestion': {
          'tool': 'visualization',
          'reason': 'repeated_misconception',
          'prompt': 'Compare the outer and inner derivative visually.',
        },
      },
    });
    final mediaEvent = workspaceEventFromJson({
      ..._eventJson(actorType: 'system', text: ''),
      'event_type': 'media_generated',
      'metadata': {'job_id': 'job-1', 'queue_status': 'queued'},
    });

    expect(tutorEvent.tutorToolSuggestion?.isVisualization, isTrue);
    expect(mediaEvent.mediaJobId, 'job-1');
    expect(mediaEvent.mediaQueueStatus, 'queued');
  });
}

Future<ApiWorkspaceRepository> _repository(MockClient httpClient) async {
  final sessionStore = AuthSessionStore();
  await sessionStore.save(
    session: const AuthSession(
      userId: 'learner-1',
      displayName: 'Learner',
      role: AuthRole.learner,
      onboardingCompleted: true,
      token: 'token-1',
    ),
    lastProtectedRoute: '/home',
  );
  return ApiWorkspaceRepository(
    apiClient: ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: httpClient,
    ),
    sessionStore: sessionStore,
    workspaceSessionStore: WorkspaceSessionStore(),
  );
}

http.Response _jsonResponse(Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> _eventJson({
  required String actorType,
  required String text,
}) {
  return {
    'id': 'event-1',
    'workspace_id': 'workspace-1',
    'event_index': 1,
    'event_type': 'text',
    'actor_type': actorType,
    'text_payload': text,
    'metadata': <String, dynamic>{},
  };
}

Map<String, dynamic> _workspaceJson() {
  return {
    'id': 'workspace-1',
    'track_id': 'track-1',
    'module_id': 'module-1',
    'current_topic': 'Aturan rantai',
    'current_topic_description': 'Repair the diagnosed prerequisite.',
    'learner_language': 'id',
    'content_mode': 'chat',
    'status': 'completed',
    'events': <Map<String, dynamic>>[],
    'current_phase': 'evaluate',
    'phase_transition_pending': false,
    'posttest_eligible': false,
    'learning_context': {
      'original_target': {
        'concept_id': 'concept-curve-sketch',
        'concept_code': 'curve_sketch',
        'label': 'Sketsa kurva menggunakan turunan',
      },
      'current_module': {
        'concept_id': 'concept-chain-rule',
        'concept_code': 'chain_rule',
        'label': 'Aturan rantai',
        'role': 'prerequisite_gap',
      },
      'diagnosis': {
        'reason': 'inner omitted',
        'evidence': {
          'source_attempt_ids': ['attempt-1'],
        },
      },
      'already_understood': ['turunan polinomial'],
      'route': ['chain_rule', 'curve_sketch'],
      'returns_to_original_target': true,
    },
    'phase_evidence': {
      'explore': [
        {'tag': 'identified_outer_function'},
      ],
    },
    'hint_level': 2,
    'posttest_trigger': {
      'status': 'ready',
      'reason': 'module_completed',
      'posttest_session_id': 'posttest-1',
      'question_count': 3,
    },
  };
}
