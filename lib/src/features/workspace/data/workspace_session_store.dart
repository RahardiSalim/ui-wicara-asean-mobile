import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/workspace_models.dart';

class WorkspaceSessionStore {
  static const _legacyTrackIdKey = 'workspace.track_id';
  static const _legacyModuleIdKey = 'workspace.module_id';
  static const _legacyWorkspaceIdKey = 'workspace.workspace_id';
  static const _legacySessionsMapKey = 'workspace.sessions_map';
  static const _legacySessionsStateKey = 'workspace.sessions_state_v2';
  static const _activeSessionsKey = 'workspace.active_sessions_v3';

  final Map<String, String> _activeWorkspaceIds = {};

  Future<void> read() async {
    final preferences = await SharedPreferences.getInstance();

    final legacyTrack = preferences.getString(_legacyTrackIdKey)?.trim();
    final legacyModule = preferences.getString(_legacyModuleIdKey)?.trim();
    final legacyWorkspace = preferences.getString(_legacyWorkspaceIdKey)?.trim();
    if (legacyTrack != null &&
        legacyTrack.isNotEmpty &&
        legacyModule != null &&
        legacyModule.isNotEmpty &&
        legacyWorkspace != null &&
        legacyWorkspace.isNotEmpty) {
      _activeWorkspaceIds[_key(legacyTrack, legacyModule)] = legacyWorkspace;
      await preferences.remove(_legacyTrackIdKey);
      await preferences.remove(_legacyModuleIdKey);
      await preferences.remove(_legacyWorkspaceIdKey);
    }

    _migrateLegacyMap(
      preferences.getString(_legacySessionsMapKey),
      readId: (value) => (value ?? '').toString().trim(),
    );
    await preferences.remove(_legacySessionsMapKey);

    _migrateLegacyMap(
      preferences.getString(_legacySessionsStateKey),
      readId: (value) => value is Map<String, dynamic>
          ? (value['active_workspace_id'] ?? '').toString().trim()
          : '',
    );
    await preferences.remove(_legacySessionsStateKey);

    final raw = preferences.getString(_activeSessionsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final id = (entry.value ?? '').toString().trim();
          if (id.isNotEmpty) {
            _activeWorkspaceIds[entry.key] = id;
          }
        }
      } catch (_) {
        // Ignore corrupt payload and continue with migrated in-memory state.
      }
    }

    await _persist();
  }

  void _migrateLegacyMap(
    String? raw, {
    required String Function(Object? value) readId,
  }) {
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final id = readId(entry.value);
        if (id.isNotEmpty) {
          _activeWorkspaceIds.putIfAbsent(entry.key, () => id);
        }
      }
    } catch (_) {
      // Ignore invalid legacy data.
    }
  }

  String? workspaceIdFor({required String trackId, required String moduleId}) {
    final id = _activeWorkspaceIds[_key(trackId, moduleId)];
    return (id == null || id.isEmpty) ? null : id;
  }

  WorkspaceSessionHistory sessionHistoryFor({
    required String trackId,
    required String moduleId,
  }) {
    return WorkspaceSessionHistory(
      activeWorkspaceId: workspaceIdFor(trackId: trackId, moduleId: moduleId),
    );
  }

  Future<void> saveAndSetActive({
    required String trackId,
    required String moduleId,
    required String workspaceId,
  }) {
    return setActiveWorkspaceId(
      trackId: trackId,
      moduleId: moduleId,
      workspaceId: workspaceId,
    );
  }

  Future<void> setActiveWorkspaceId({
    required String trackId,
    required String moduleId,
    required String workspaceId,
  }) async {
    final normalized = workspaceId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _activeWorkspaceIds[_key(trackId, moduleId)] = normalized;
    await _persist();
  }

  Future<void> clearSession({
    required String trackId,
    required String moduleId,
  }) async {
    _activeWorkspaceIds.remove(_key(trackId, moduleId));
    await _persist();
  }

  /// Forgets every cached pointer. Must be called on sign-out, otherwise the
  /// next account inherits ids it does not own and every open 404s.
  Future<void> clearAll() async {
    _activeWorkspaceIds.clear();
    await _persist();
  }

  static String _key(String trackId, String moduleId) =>
      '${trackId}__$moduleId';

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _activeSessionsKey,
      jsonEncode(_activeWorkspaceIds),
    );
  }
}

final workspaceSessionStore = WorkspaceSessionStore();
