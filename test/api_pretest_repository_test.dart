import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wicara_mobile/src/core/network/api_client.dart';
import 'package:wicara_mobile/src/features/auth/data/auth_session_store.dart';
import 'package:wicara_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:wicara_mobile/src/features/pretest/data/api_pretest_repository.dart';
import 'package:wicara_mobile/src/features/pretest/data/pretest_session_store.dart';
import 'package:wicara_mobile/src/features/pretest/domain/pretest_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'already answered response reloads the backend current question',
    () async {
      SharedPreferences.setMockInitialValues({});
      final authStore = AuthSessionStore();
      await authStore.save(
        session: const AuthSession(
          userId: 'learner-1',
          displayName: 'Learner',
          role: AuthRole.learner,
          onboardingCompleted: true,
          token: 'token-1',
        ),
        lastProtectedRoute: '/pretest',
      );
      final pretestStore = PretestSessionStore()
        ..saveBootstrap(
          learningGoalId: 'goal-1',
          pretestSessionId: 'session-1',
        );
      final requestedPaths = <String>[];
      final apiClient = ApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path.endsWith('/answers')) {
            return http.Response(
              jsonEncode({
                'detail': {
                  'error': 'QUESTION_ALREADY_ANSWERED',
                  'message': 'This question already has an answer.',
                },
              }),
              409,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'session_id': 'session-1',
              'current_question': {
                'id': 'question-2',
                'pack_id': '',
                'step_label': 'Question 2 - Up to 10 questions',
                'concept_title': 'Chain rule',
                'prompt': r'Differentiate $\sin(x^2)$.',
                'helper': '',
                'progress': {'current': 2, 'max': 10},
                'options': [
                  {'id': 'option-a', 'label': 'A', 'text': r'$2x\cos(x^2)$'},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = ApiPretestRepository(
        apiClient: apiClient,
        sessionStore: authStore,
        pretestSessionStore: pretestStore,
      );

      final result = await repository.submitAnswer(
        const PretestAnswer(
          questionId: 'question-1',
          optionId: 'option-a',
          confidence: 0,
        ),
      );

      expect(result.completed, isFalse);
      expect(result.nextQuestion?.id, 'question-2');
      expect(requestedPaths, [
        '/api/v1/pretests/session-1/answers',
        '/api/v1/pretests/start',
      ]);
    },
  );
}
