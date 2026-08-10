import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wicara_mobile/src/core/network/api_client.dart';
import 'package:wicara_mobile/src/features/review/data/api_review_repository.dart';

void main() {
  test('teacher role is read from the flat current-user response', () async {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/me');
        return http.Response(
          jsonEncode({'id': 'teacher-1', 'role': 'teacher'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = ApiReviewRepository(apiClient: client);

    expect(await repository.isCurrentUserTeacher(), isTrue);
  });
}
