import '../../../core/network/api_client.dart';
import '../domain/review_models.dart';

/// Talks to the backend `/api/v1/review/*` endpoints. The bearer token is
/// injected by [ApiClient] (set by AuthController on sign-in), so no explicit
/// Authorization header is needed here.
class ApiReviewRepository implements ReviewRepository {
  const ApiReviewRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<ReviewQueue> fetchQueue({
    String? status,
    String? artifactType,
    String? trigger,
    String? subject,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (status != null && status.isNotEmpty) 'status': status,
      if (artifactType != null && artifactType.isNotEmpty)
        'artifact_type': artifactType,
      if (trigger != null && trigger.isNotEmpty) 'trigger': trigger,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
    };
    final json = await _apiClient.getJson(
      '/api/v1/review/queue',
      queryParameters: query,
    );
    return ReviewQueue.fromJson(json);
  }

  @override
  Future<ReviewItemDetail> fetchItem(String id) async {
    final json = await _apiClient.getJson('/api/v1/review/items/$id');
    return ReviewItemDetail.fromJson(json);
  }

  @override
  Future<ReviewItem> approve(String id, {String notes = ''}) async {
    final json = await _apiClient.postJson(
      '/api/v1/review/items/$id/approve',
      body: {'notes': notes},
    );
    return ReviewItem.fromJson(json);
  }

  @override
  Future<ReviewItem> reject(String id, {required String reason}) async {
    final json = await _apiClient.postJson(
      '/api/v1/review/items/$id/reject',
      body: {'reason': reason},
    );
    return ReviewItem.fromJson(json);
  }

  @override
  Future<ReviewItemDetail> correct(
    String id, {
    required Map<String, dynamic> fields,
    String notes = '',
  }) async {
    final json = await _apiClient.postJson(
      '/api/v1/review/items/$id/correct',
      body: {'fields': fields, 'notes': notes},
    );
    return ReviewItemDetail.fromJson(json);
  }

  @override
  Future<ReviewMetrics> fetchMetrics() async {
    final json = await _apiClient.getJson('/api/v1/review/metrics');
    return ReviewMetrics.fromJson(json);
  }

  @override
  Future<ReviewItem> flag({
    required String artifactType,
    required String artifactId,
    required String reason,
  }) async {
    final json = await _apiClient.postJson(
      '/api/v1/review/flag',
      body: {
        'artifact_type': artifactType,
        'artifact_id': artifactId,
        'reason': reason,
      },
    );
    return ReviewItem.fromJson(json);
  }

  @override
  Future<bool> isCurrentUserTeacher() async {
    try {
      final json = await _apiClient.getJson('/api/v1/me');
      return (json['role']?.toString() ?? '') == 'teacher';
    } catch (_) {
      return false;
    }
  }
}
