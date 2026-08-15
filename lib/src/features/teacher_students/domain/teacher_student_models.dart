import '../../analytics/domain/analytics_models.dart';

class TeacherStudentConnection {
  const TeacherStudentConnection({
    required this.id,
    required this.status,
    required this.teacherId,
    required this.teacherName,
    required this.teacherEmail,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.requestedAt,
    required this.respondedAt,
  });

  final String id;
  final String status;
  final String teacherId;
  final String teacherName;
  final String? teacherEmail;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final DateTime? requestedAt;
  final DateTime? respondedAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory TeacherStudentConnection.fromJson(Map<String, dynamic> json) {
    return TeacherStudentConnection(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? 'Teacher',
      teacherEmail: json['teacher_email']?.toString(),
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? 'Student',
      studentEmail: json['student_email']?.toString(),
      requestedAt: DateTime.tryParse(json['requested_at']?.toString() ?? ''),
      respondedAt: DateTime.tryParse(json['responded_at']?.toString() ?? ''),
    );
  }
}

class StudentProgress {
  const StudentProgress({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.overview,
    required this.trends,
    required this.velocity,
    required this.atRisk,
  });

  final String studentId;
  final String studentName;
  final String? studentEmail;
  final AnalyticsOverview overview;
  final AnalyticsTrends trends;
  final AnalyticsVelocity velocity;
  final AnalyticsAtRisk atRisk;

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? 'Student',
      studentEmail: json['student_email']?.toString(),
      overview: AnalyticsOverview.fromJson(
        Map<String, dynamic>.from(json['overview'] as Map? ?? const {}),
      ),
      trends: AnalyticsTrends.fromJson(
        Map<String, dynamic>.from(json['trends'] as Map? ?? const {}),
      ),
      velocity: AnalyticsVelocity.fromJson(
        Map<String, dynamic>.from(json['velocity'] as Map? ?? const {}),
      ),
      atRisk: AnalyticsAtRisk.fromJson(
        Map<String, dynamic>.from(json['at_risk'] as Map? ?? const {}),
      ),
    );
  }
}

abstract class TeacherStudentRepository {
  Future<TeacherStudentConnection> inviteStudent(String email);
  Future<List<TeacherStudentConnection>> fetchTeacherConnections();
  Future<List<TeacherStudentConnection>> fetchStudentConnections();
  Future<TeacherStudentConnection> acceptInvitation(String connectionId);
  Future<TeacherStudentConnection> rejectInvitation(String connectionId);
  Future<void> disconnect(String connectionId);
  Future<StudentProgress> fetchStudentProgress(String studentId);
}
