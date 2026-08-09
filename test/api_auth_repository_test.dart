import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wicara_mobile/src/core/network/api_client.dart';
import 'package:wicara_mobile/src/features/auth/data/api_auth_repository.dart';
import 'package:wicara_mobile/src/features/auth/data/auth_session_store.dart';
import 'package:wicara_mobile/src/features/auth/domain/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final testCase in <({AuthRole requested, AuthRole returned})>[
    (requested: AuthRole.learner, returned: AuthRole.teacher),
    (requested: AuthRole.teacher, returned: AuthRole.learner),
  ]) {
    test('registration sends ${testCase.requested.name} and trusts backend '
        '${testCase.returned.name} role', () async {
      late http.Request capturedRequest;
      final repository = _repository(
        MockClient((request) async {
          capturedRequest = request;
          return _jsonResponse({
            'user_id': 'new-user-1',
            'display_name': 'New User',
            'role': testCase.returned.name,
            'onboarding_completed': false,
            'token': 'access-token-1',
            'refresh_token': 'refresh-token-1',
          });
        }),
      );

      final session = await repository.register(
        RegisterRequest(
          email: '  new.user@example.com  ',
          password: 'secret-password',
          displayName: '  New User  ',
          role: testCase.requested,
        ),
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/v1/auth/register');
      expect(jsonDecode(capturedRequest.body), {
        'email': 'new.user@example.com',
        'password': 'secret-password',
        'display_name': 'New User',
        'role': testCase.requested.name,
      });
      expect(session.userId, 'new-user-1');
      expect(session.displayName, 'New User');
      expect(session.role, testCase.returned);
      expect(session.onboardingCompleted, isFalse);
      expect(session.token, 'access-token-1');
      expect(session.refreshToken, 'refresh-token-1');
    });
  }

  test(
    'email login sends new account credentials and parses session',
    () async {
      late http.Request capturedRequest;
      final sessionStore = AuthSessionStore();
      final repository = _repository(
        MockClient((request) async {
          capturedRequest = request;
          return _jsonResponse({
            'user_id': 'new-user-1',
            'display_name': 'New User',
            'role': 'teacher',
            'onboarding_completed': true,
            'token': 'access-token-2',
            'refresh_token': 'refresh-token-2',
          });
        }),
        sessionStore: sessionStore,
      );

      final session = await repository.signIn(
        const SignInRequest(
          emailOrPhone: '  new.user@example.com  ',
          password: 'secret-password',
          role: AuthRole.teacher,
        ),
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/v1/auth/sign-in');
      expect(jsonDecode(capturedRequest.body), {
        'email_or_phone': 'new.user@example.com',
        'password': 'secret-password',
        'role': 'teacher',
      });
      expect(session.userId, 'new-user-1');
      expect(session.displayName, 'New User');
      expect(session.role, AuthRole.teacher);
      expect(session.onboardingCompleted, isTrue);
      expect(session.token, 'access-token-2');
      expect(session.refreshToken, 'refresh-token-2');
      expect(sessionStore.currentSession, same(session));
    },
  );

  test('unknown backend role fails closed to student', () async {
    final repository = _repository(
      MockClient(
        (request) async => _jsonResponse({
          'user_id': 'new-user-1',
          'display_name': 'New User',
          'role': 'unexpected-role',
          'onboarding_completed': false,
          'token': 'access-token',
          'refresh_token': 'refresh-token',
        }),
      ),
    );

    final session = await repository.signIn(
      const SignInRequest(
        emailOrPhone: 'teacher@example.com',
        password: 'secret-password',
        role: AuthRole.teacher,
      ),
    );

    expect(session.role, AuthRole.learner);
  });

  test('password reset posts a trimmed email', () async {
    late http.Request capturedRequest;
    final repository = _repository(
      MockClient((request) async {
        capturedRequest = request;
        return _jsonResponse({});
      }),
    );

    await repository.requestPasswordReset('  new.user@example.com  ');

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/v1/auth/password-reset');
    expect(jsonDecode(capturedRequest.body), {'email': 'new.user@example.com'});
  });
}

ApiAuthRepository _repository(
  MockClient httpClient, {
  AuthSessionStore? sessionStore,
}) {
  return ApiAuthRepository(
    apiClient: ApiClient(baseUrl: 'https://api.test', httpClient: httpClient),
    sessionStore: sessionStore ?? AuthSessionStore(),
    googleWebClientId: '',
  );
}

http.Response _jsonResponse(Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
