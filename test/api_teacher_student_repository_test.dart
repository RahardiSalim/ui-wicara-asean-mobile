import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wicara_mobile/src/core/network/api_client.dart';
import 'package:wicara_mobile/src/features/teacher_students/data/api_teacher_student_repository.dart';

void main() {
  test('invite and consent methods use the expected API routes', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response(
          jsonEncode(_connectionJson(status: 'pending')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = ApiTeacherStudentRepository(apiClient: client);

    final invited = await repository.inviteStudent(' student@example.com ');
    await repository.acceptInvitation('connection-1');
    await repository.rejectInvitation('connection-1');
    await repository.disconnect('connection-1');

    expect(invited.studentName, 'Student One');
    expect(jsonDecode(requests[0].body), {'email': 'student@example.com'});
    expect(requests.map((request) => request.url.path), [
      '/api/v1/teacher-students/invitations',
      '/api/v1/teacher-students/invitations/connection-1/accept',
      '/api/v1/teacher-students/invitations/connection-1/reject',
      '/api/v1/teacher-students/connections/connection-1',
    ]);
  });

  test('teacher connections and student progress are parsed', () async {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/progress')) {
          return http.Response(
            jsonEncode(_progressJson()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'items': [_connectionJson(status: 'accepted')],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = ApiTeacherStudentRepository(apiClient: client);

    final connections = await repository.fetchTeacherConnections();
    final progress = await repository.fetchStudentProgress('student-1');

    expect(connections, hasLength(1));
    expect(connections.single.isAccepted, isTrue);
    expect(progress.studentName, 'Student One');
    expect(progress.overview.overallAvgMastery, 0.75);
    expect(progress.overview.subjects.single.subjectName, 'Mathematics');
    expect(progress.velocity.currentStreakDays, 3);
    expect(progress.atRisk.totalAtRisk, 1);
    expect(progress.trends.points.single.score, 80);
  });
}

Map<String, dynamic> _connectionJson({required String status}) => {
  'id': 'connection-1',
  'status': status,
  'teacher_id': 'teacher-1',
  'teacher_name': 'Teacher One',
  'teacher_email': 'teacher@example.com',
  'student_id': 'student-1',
  'student_name': 'Student One',
  'student_email': 'student@example.com',
  'requested_at': '2026-08-10T10:00:00Z',
  'responded_at': status == 'accepted' ? '2026-08-10T11:00:00Z' : null,
};

Map<String, dynamic> _progressJson() => {
  'student_id': 'student-1',
  'student_name': 'Student One',
  'student_email': 'student@example.com',
  'overview': {
    'subjects': [
      {
        'subject_code': 'math',
        'subject_name': 'Mathematics',
        'concepts_tracked': 4,
        'mastered': 3,
        'gaps': 1,
        'avg_mastery': 0.75,
      },
    ],
    'subjects_studied': 1,
    'concepts_tracked': 4,
    'overall_avg_mastery': 0.75,
    'total_attempts': 12,
    'active_days': 4,
  },
  'trends': {
    'period': 'month',
    'points': [
      {
        'period': '2026-08',
        'score': 80,
        'attempts': 12,
        'fixed_gaps': 2,
        'remaining_gaps': 1,
      },
    ],
  },
  'velocity': {
    'total_attempts': 12,
    'active_days': 4,
    'current_streak_days': 3,
    'longest_streak_days': 3,
    'concepts_mastered': 3,
    'concepts_tracked': 4,
    'avg_attempts_per_active_day': 3.0,
    'first_active': '2026-08-01',
    'last_active': '2026-08-10',
  },
  'at_risk': {
    'items': [
      {
        'concept_id': 'concept-1',
        'title': 'Fractions',
        'subject_code': 'math',
        'subject_name': 'Mathematics',
        'mastery': 0.4,
        'confidence': 0.3,
        'overdue_days': 2,
        'retention_estimate': 0.5,
        'risk_score': 5.5,
      },
    ],
    'total_at_risk': 1,
  },
};
