import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wicara_mobile/src/features/analytics/domain/analytics_models.dart';
import 'package:wicara_mobile/src/features/teacher_students/domain/teacher_student_models.dart';
import 'package:wicara_mobile/src/features/teacher_students/presentation/student_teacher_connections_page.dart';
import 'package:wicara_mobile/src/features/teacher_students/presentation/teacher_dashboard_page.dart';

void main() {
  testWidgets('student can accept a pending teacher request', (tester) async {
    final repository = _FakeTeacherStudentRepository(
      connections: [_connection(status: 'pending')],
    );

    await tester.pumpWidget(
      MaterialApp(home: StudentTeacherConnectionsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Teacher One'), findsOneWidget);
    expect(
      find.textContaining('only see your learning progress after you accept'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();

    expect(repository.acceptedId, 'connection-1');
    expect(find.text('No connected teachers'), findsOneWidget);
  });

  testWidgets('teacher opens an accepted student progress dashboard', (
    tester,
  ) async {
    final repository = _FakeTeacherStudentRepository(
      connections: [_connection(status: 'accepted')],
    );

    await tester.pumpWidget(
      MaterialApp(home: TeacherDashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Teacher dashboard'), findsOneWidget);
    expect(find.text('Student One'), findsOneWidget);
    expect(find.text('Connected'), findsWidgets);

    await tester.tap(find.text('Student One'));
    await tester.pumpAndSettle();

    expect(find.text('Overall mastery'), findsOneWidget);
    expect(find.text('75%'), findsWidgets);
    expect(find.text('Mathematics'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Needs review (1)'),
      find.byType(Scrollable).last,
      const Offset(0, -300),
    );
    expect(find.text('Needs review (1)'), findsOneWidget);
  });

  testWidgets('teacher dashboard exposes sign out', (tester) async {
    var signedOut = false;
    final repository = _FakeTeacherStudentRepository(connections: const []);

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardPage(
          repository: repository,
          onSignOut: () async => signedOut = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();

    expect(signedOut, isTrue);
  });
}

TeacherStudentConnection _connection({required String status}) {
  return TeacherStudentConnection(
    id: 'connection-1',
    status: status,
    teacherId: 'teacher-1',
    teacherName: 'Teacher One',
    teacherEmail: 'teacher@example.com',
    studentId: 'student-1',
    studentName: 'Student One',
    studentEmail: 'student@example.com',
    requestedAt: DateTime.utc(2026, 8, 10),
    respondedAt: status == 'accepted' ? DateTime.utc(2026, 8, 10, 1) : null,
  );
}

class _FakeTeacherStudentRepository implements TeacherStudentRepository {
  _FakeTeacherStudentRepository({required this.connections});

  List<TeacherStudentConnection> connections;
  String? acceptedId;

  @override
  Future<TeacherStudentConnection> acceptInvitation(String connectionId) async {
    acceptedId = connectionId;
    connections = const [];
    return _connection(status: 'accepted');
  }

  @override
  Future<void> disconnect(String connectionId) async {
    connections = const [];
  }

  @override
  Future<List<TeacherStudentConnection>> fetchStudentConnections() async {
    return connections;
  }

  @override
  Future<List<TeacherStudentConnection>> fetchTeacherConnections() async {
    return connections;
  }

  @override
  Future<StudentProgress> fetchStudentProgress(String studentId) async {
    return StudentProgress(
      studentId: studentId,
      studentName: 'Student One',
      studentEmail: 'student@example.com',
      overview: const AnalyticsOverview(
        subjects: [
          SubjectMastery(
            subjectCode: 'math',
            subjectName: 'Mathematics',
            conceptsTracked: 4,
            mastered: 3,
            gaps: 1,
            avgMastery: 0.75,
          ),
        ],
        subjectsStudied: 1,
        conceptsTracked: 4,
        overallAvgMastery: 0.75,
        totalAttempts: 12,
        activeDays: 4,
      ),
      trends: const AnalyticsTrends(period: 'month', points: []),
      velocity: const AnalyticsVelocity(
        totalAttempts: 12,
        activeDays: 4,
        currentStreakDays: 3,
        longestStreakDays: 3,
        conceptsMastered: 3,
        conceptsTracked: 4,
        avgAttemptsPerActiveDay: 3,
        firstActive: '2026-08-01',
        lastActive: '2026-08-10',
      ),
      atRisk: const AnalyticsAtRisk(
        items: [
          AtRiskItem(
            conceptId: 'concept-1',
            title: 'Fractions',
            subjectCode: 'math',
            subjectName: 'Mathematics',
            mastery: 0.4,
            confidence: 0.3,
            overdueDays: 2,
            retentionEstimate: 0.5,
            riskScore: 5.5,
          ),
        ],
        totalAtRisk: 1,
      ),
    );
  }

  @override
  Future<TeacherStudentConnection> inviteStudent(String email) async {
    final connection = _connection(status: 'pending');
    connections = [connection];
    return connection;
  }

  @override
  Future<TeacherStudentConnection> rejectInvitation(String connectionId) async {
    connections = const [];
    return _connection(status: 'rejected');
  }
}
