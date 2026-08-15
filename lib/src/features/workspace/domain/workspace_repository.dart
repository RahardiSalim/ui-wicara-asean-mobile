import 'dart:typed_data';

import 'workspace_models.dart';

abstract class WorkspaceRepository {
  Future<WorkspaceSession> createOrResumeWorkspace({
    required String trackId,
    required String moduleId,
    String? workspaceSessionId,
    bool startNewSession = false,
  });

  WorkspaceSessionHistory sessionHistory({
    required String trackId,
    required String moduleId,
  });

  Future<void> setActiveSession({
    required String trackId,
    required String moduleId,
    required String workspaceId,
  });

  Future<List<WorkspaceSessionSummary>> fetchSessionHistory({
    required String trackId,
    required String moduleId,
    int limit,
    int offset,
  });

  Future<void> deleteSession({
    required String trackId,
    required String moduleId,
    required String workspaceId,
  });

  /// Uploads a canvas snapshot and returns the resulting image asset id.
  Future<String> uploadCanvasImage({
    required Uint8List bytes,
    String filename = 'canvas.png',
    String mimeType = 'image/png',
  });

  /// URL for rendering a previously uploaded image asset. The endpoint is
  /// auth-gated, so pair it with [imageAssetHeaders].
  String imageAssetUrl(String imageAssetId);

  /// Headers required to fetch [imageAssetUrl]; without these the request 401s.
  Map<String, String> imageAssetHeaders();

  /// Forgets the cached pointer for one track+module (stale or deleted id).
  Future<void> clearCachedSession({
    required String trackId,
    required String moduleId,
  });

  /// Clears every locally cached workspace pointer (call on sign-out).
  Future<void> clearLocalSessions();

  Future<WorkspaceSession> fetchWorkspace(String workspaceId);

  Future<WorkspaceAppendResult> appendEvent({
    required String workspaceId,
    required String eventType,
    String textPayload = '',
    Map<String, dynamic> metadata = const {},
    String? imageAssetId,
  });

  Future<WorkspaceSession> advancePhase({required String workspaceId});

  Future<WorkspaceSession> startPosttest({required String workspaceId});

  Future<WorkspaceGenerateVideoResult> generateVideo({
    required String workspaceId,
    String generationMode = 'context_auto',
    String? templateId,
    Map<String, dynamic>? specJson,
    String language = 'en',
    String qualityProfile = 'standard',
    String? conceptId,
    Map<String, dynamic> metadata = const {},
  });

  Future<WorkspaceAnimationJobStatus> getAnimationStatus({
    required String jobId,
  });

  Future<void> updateModuleState({
    required String trackId,
    required String moduleId,
    required String status,
  });
}

class WorkspaceException implements Exception {
  const WorkspaceException(this.message);

  final String message;

  @override
  String toString() => message;
}
