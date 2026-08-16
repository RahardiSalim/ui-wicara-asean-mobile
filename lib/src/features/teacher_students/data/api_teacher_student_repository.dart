import '../../../core/network/api_client.dart';
import '../domain/teacher_student_models.dart';

class ApiTeacherStudentRepository implements TeacherStudentRepository {
  const ApiTeacherStudentRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<TeacherStudentConnection> inviteStudent(String email) async {
    final json = await _apiClient.postJson(
      '/api/v1/teacher-students/invitations',
      body: {'email': email.trim()},
    );
    return TeacherStudentConnection.fromJson(json);
  }

  @override
  Future<List<TeacherStudentConnection>> fetchTeacherConnections() async {
    final json = await _apiClient.getJson(
      '/api/v1/teacher-students/teacher/connections',
    );
    return _connections(json);
  }

  @override
  Future<List<TeacherStudentConnection>> fetchStudentConnections() async {
    final json = await _apiClient.getJson(
      '/api/v1/teacher-students/student/connections',
    );
    return _connections(json);
  }

  @override
  Future<TeacherStudentConnection> acceptInvitation(String connectionId) async {
    final json = await _apiClient.postJson(
      '/api/v1/teacher-students/invitations/$connectionId/accept',
    );
    return TeacherStudentConnection.fromJson(json);
  }

  @override
  Future<TeacherStudentConnection> rejectInvitation(String connectionId) async {
    final json = await _apiClient.postJson(
      '/api/v1/teacher-students/invitations/$connectionId/reject',
    );
    return TeacherStudentConnection.fromJson(json);
  }

  @override
  Future<void> disconnect(String connectionId) {
    return _apiClient.delete(
      '/api/v1/teacher-students/connections/$connectionId',
    );
  }

  @override
  Future<StudentProgress> fetchStudentProgress(String studentId) async {
    final json = await _apiClient.getJson(
      '/api/v1/teacher-students/teacher/students/$studentId/progress',
    );
    return StudentProgress.fromJson(json);
  }

  List<TeacherStudentConnection> _connections(Map<String, dynamic> json) {
    return (json['items'] as List? ?? const [])
        .map(
          (item) => TeacherStudentConnection.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }
}
