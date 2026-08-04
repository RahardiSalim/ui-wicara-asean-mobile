import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/accessibility/speech_accessibility_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../../core/widgets/speech_controls.dart';
import '../../home/domain/home_repository.dart';
import '../../home/domain/home_snapshot.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../../pretest/presentation/widgets/rich_math_text.dart';
import '../../pretest/presentation/widgets/fishbone_canvas.dart';
import '../domain/workspace_models.dart';
import '../domain/workspace_repository.dart';

enum _WorkspaceContentMode {
  choosing,
  videoProcessing,
  videoReady,
  videoFailed,
}

class WorkspaceModulesPage extends StatefulWidget {
  const WorkspaceModulesPage({
    required this.onboardingController,
    required this.workspaceRepository,
    this.homeRepository,
    this.routeArguments,
    super.key,
  });

  final OnboardingController onboardingController;
  final WorkspaceRepository workspaceRepository;

  /// Optional: when provided the latest weekly report is fetched and shown
  /// as a summary card at the top of the chat history.
  final HomeRepository? homeRepository;
  final WorkspaceRouteArguments? routeArguments;

  @override
  State<WorkspaceModulesPage> createState() => _WorkspaceModulesPageState();
}

class _WorkspaceModulesPageState extends State<WorkspaceModulesPage> {
  static const _videoPollingInterval = Duration(seconds: 3);
  static const _videoPollingTimeout = Duration(minutes: 5);

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_WorkspaceChatEntry> _chatEntries = [];
  final List<CanvasWorkSnapshot> _canvasSnapshots = [];

  _WorkspaceContentMode _contentMode = _WorkspaceContentMode.choosing;
  WorkspaceSession? _workspace;
  bool _isLoadingWorkspace = true;
  bool _isAppendingEvent = false;
  bool _isPhaseSubmitting = false;
  String? _workspaceError;
  bool _isVideoGenerating = false;
  bool _stopVideoPolling = false;
  WorkspaceAnimationJobStatus? _latestVideoStatus;
  WorkspaceMediaArtifact? _latestVideoArtifact;
  String? _videoStatusMessage;
  String? _videoErrorMessage;
  bool _isWorkspaceHeaderExpanded = false;
  List<WorkspaceSessionSummary> _sessionHistory = const [];
  String? _activeSessionId;
  int _workspaceRequestSerial = 0;

  /// Latest weekly report fetched from HomeRepository. Null while loading or
  /// if no HomeRepository was provided.
  WeeklyLearningReport? _weeklyReport;
  bool _reportCardDismissed = false;

  _LocalizedWorkspaceMaterial get _workspaceMaterial {
    return _LocalizedWorkspaceMaterial.forLanguage(_normalizedLanguageCode());
  }

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
    _loadWeeklyReport();
  }

  Future<void> _loadWeeklyReport() async {
    final repo = widget.homeRepository;
    if (repo == null) return;
    try {
      final report = await repo.fetchWeeklyLearningReport();
      if (!mounted) return;
      setState(() => _weeklyReport = report);
    } catch (_) {
      // Best-effort: silently ignore report fetch failures.
    }
  }

  @override
  void dispose() {
    _stopVideoPolling = true;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspace({
    String? workspaceSessionId,
    bool startNewSession = false,
  }) async {
    final requestSerial = ++_workspaceRequestSerial;
    final arguments = widget.routeArguments;
    if (arguments == null || !arguments.isValid) {
      setState(() {
        _isLoadingWorkspace = false;
        _workspaceError = _workspaceMaterial.openTrackModuleMessage;
      });
      return;
    }

    setState(() {
      _isLoadingWorkspace = true;
      _workspaceError = null;
      if (startNewSession || workspaceSessionId != null) {
        _resetCurrentChatState(nextActiveSessionId: workspaceSessionId);
      }
    });
    try {
      final storedHistory = widget.workspaceRepository.sessionHistory(
        trackId: arguments.trackId,
        moduleId: arguments.moduleId,
      );
      final resolvedWorkspaceSessionId =
          workspaceSessionId ??
          (startNewSession ? null : storedHistory.activeWorkspaceId);
      final workspace = await widget.workspaceRepository
          .createOrResumeWorkspace(
            trackId: arguments.trackId,
            moduleId: arguments.moduleId,
            workspaceSessionId: resolvedWorkspaceSessionId,
            startNewSession: startNewSession,
          );
      await widget.workspaceRepository.updateModuleState(
        trackId: arguments.trackId,
        moduleId: arguments.moduleId,
        status: 'active',
      );
      var history = _sessionHistory;
      try {
        history = await widget.workspaceRepository.fetchSessionHistory(
          trackId: arguments.trackId,
          moduleId: arguments.moduleId,
        );
      } on WorkspaceException {
        history = _sessionHistory;
      }
      if (!mounted || requestSerial != _workspaceRequestSerial) return;
      setState(() {
        _workspace = workspace;
        _activeSessionId = workspace.id;
        _chatEntries
          ..clear()
          ..addAll(_entriesFromEvents(workspace.events));
        _latestVideoArtifact = _withResolvedArtifactUrls(workspace.latestMedia);
        _sessionHistory = history;
        _isLoadingWorkspace = false;
      });
      _scrollToBottom();
    } on WorkspaceException catch (error) {
      if (!mounted || requestSerial != _workspaceRequestSerial) return;
      setState(() {
        _isLoadingWorkspace = false;
        _workspaceError = error.message;
      });
    }
  }

  Future<void> _startNewChatSession() async {
    await _loadWorkspace(startNewSession: true);
  }

  Future<void> _switchToSession(String workspaceId) async {
    final requestSerial = ++_workspaceRequestSerial;
    final arguments = widget.routeArguments;
    if (arguments == null || !arguments.isValid) {
      return;
    }
    if (workspaceId == (_workspace?.id ?? '')) {
      return;
    }
    setState(() {
      _isLoadingWorkspace = true;
      _workspaceError = null;
      _resetCurrentChatState(nextActiveSessionId: workspaceId);
    });
    try {
      final workspace = await widget.workspaceRepository.fetchWorkspace(
        workspaceId,
      );
      await widget.workspaceRepository.setActiveSession(
        trackId: arguments.trackId,
        moduleId: arguments.moduleId,
        workspaceId: workspaceId,
      );
      var history = _sessionHistory;
      try {
        history = await widget.workspaceRepository.fetchSessionHistory(
          trackId: arguments.trackId,
          moduleId: arguments.moduleId,
        );
      } on WorkspaceException {
        history = _sessionHistory;
      }
      if (!mounted || requestSerial != _workspaceRequestSerial) {
        return;
      }
      setState(() {
        _workspace = workspace;
        _activeSessionId = workspace.id;
        _chatEntries
          ..clear()
          ..addAll(_entriesFromEvents(workspace.events));
        _latestVideoArtifact = _withResolvedArtifactUrls(workspace.latestMedia);
        _sessionHistory = history;
        _isLoadingWorkspace = false;
      });
      _scrollToBottom();
    } on WorkspaceException catch (error) {
      if (!mounted || requestSerial != _workspaceRequestSerial) {
        return;
      }
      setState(() {
        _isLoadingWorkspace = false;
        _workspaceError = error.message;
      });
    }
  }

  void _resetCurrentChatState({String? nextActiveSessionId}) {
    _workspace = null;
    _activeSessionId = nextActiveSessionId;
    _isAppendingEvent = false;
    _isPhaseSubmitting = false;
    _isVideoGenerating = false;
    _stopVideoPolling = true;
    _chatEntries.clear();
    _canvasSnapshots.clear();
    _contentMode = _WorkspaceContentMode.choosing;
    _latestVideoStatus = null;
    _latestVideoArtifact = null;
    _videoStatusMessage = null;
    _videoErrorMessage = null;
  }

  Future<void> _openSessionHistorySheet() async {
    final arguments = widget.routeArguments;
    if (arguments == null || !arguments.isValid) {
      return;
    }
    List<WorkspaceSessionSummary> sessions = _sessionHistory;
    try {
      sessions = await widget.workspaceRepository.fetchSessionHistory(
        trackId: arguments.trackId,
        moduleId: arguments.moduleId,
      );
      if (mounted) {
        setState(() => _sessionHistory = sessions);
      }
    } on WorkspaceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _workspaceError = error.message);
      return;
    }
    if (!mounted || sessions.isEmpty) {
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _WorkspaceHistorySheet(
          sessions: sessions,
          activeSessionId: _activeSessionId,
          material: _workspaceMaterial,
        );
      },
    );
    if (selected != null) {
      await _switchToSession(selected);
    }
  }

  Future<void> _generateVideo() async {
    if (_isVideoGenerating) {
      return;
    }
    final workspace = _workspace;
    if (workspace == null) {
      setState(() {
        _workspaceError = _workspaceMaterial.workspaceNotReadyMessage;
      });
      return;
    }

    final language = _normalizedLanguageCode();
    final chatTurnCount = _chatEntries
        .where(
          (entry) =>
              !entry.isCanvas && (entry.text?.trim().isNotEmpty ?? false),
        )
        .length;
    _stopVideoPolling = true;
    setState(() {
      _isVideoGenerating = true;
      _contentMode = _WorkspaceContentMode.videoProcessing;
      _latestVideoStatus = null;
      _videoStatusMessage = _workspaceMaterial.queueingVideoMessage;
      _videoErrorMessage = null;
      _workspaceError = null;
    });
    _scrollToBottom();

    try {
      debugPrint(
        '[video-generate] workspace_id=${workspace.id} generation_mode=context_auto language=$language',
      );
      final result = await widget.workspaceRepository.generateVideo(
        workspaceId: workspace.id,
        generationMode: 'context_auto',
        language: language,
        qualityProfile: 'standard',
        conceptId: workspace.learningContext.currentModuleConceptId,
        metadata: {
          'triggered_by': 'workspace_mid_chat_button',
          'chat_turn_count': chatTurnCount,
          'workspace_content_mode': _contentMode.name,
          'current_phase': workspace.currentPhase,
        },
      );

      if (!mounted) return;
      setState(() {
        _workspace = result.workspace;
        _latestVideoArtifact =
            _withResolvedArtifactUrls(result.workspace.latestMedia) ??
            _latestVideoArtifact;
        _videoStatusMessage = _workspaceMaterial.videoQueuedMessage;
      });

      await _pollVideoStatus(jobId: result.queue.jobId);
    } on WorkspaceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isVideoGenerating = false;
        _contentMode = _WorkspaceContentMode.videoFailed;
        _videoErrorMessage = error.message;
      });
      _scrollToBottom();
    }
  }

  Future<void> _pollVideoStatus({required String jobId}) async {
    _stopVideoPolling = false;
    final startedAt = DateTime.now();

    while (mounted && !_stopVideoPolling) {
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed >= _videoPollingTimeout) {
        if (!mounted) return;
        setState(() {
          _isVideoGenerating = false;
          _contentMode = _WorkspaceContentMode.videoFailed;
          _videoErrorMessage = _workspaceMaterial.videoTimedOutMessage(
            _videoPollingTimeout.inMinutes,
          );
          _videoStatusMessage = _workspaceMaterial.generationTimeoutMessage;
        });
        _scrollToBottom();
        return;
      }

      try {
        final status = await widget.workspaceRepository.getAnimationStatus(
          jobId: jobId,
        );
        if (!mounted || _stopVideoPolling) return;

        setState(() {
          _latestVideoStatus = status;
          _videoStatusMessage = status.message;
          if (status.isReady) {
            _isVideoGenerating = false;
            _contentMode = _WorkspaceContentMode.videoReady;
            _videoErrorMessage = null;
            _latestVideoArtifact = _latestVideoArtifactFromStatus(
              status,
              fallback: _workspace,
            );
          } else if (status.isFailed) {
            _isVideoGenerating = false;
            _contentMode = _WorkspaceContentMode.videoFailed;
            _videoErrorMessage = status.error ?? status.message;
          } else {
            _contentMode = _WorkspaceContentMode.videoProcessing;
          }
        });
        _scrollToBottomIfNearBottom();

        if (status.isFinal) {
          if (status.isReady) {
            await _refreshWorkspaceAfterReady();
          }
          _scrollToBottom();
          return;
        }
      } on WorkspaceException catch (error) {
        if (!mounted || _stopVideoPolling) return;
        setState(() {
          _isVideoGenerating = false;
          _contentMode = _WorkspaceContentMode.videoFailed;
          _videoErrorMessage = error.message;
        });
        _scrollToBottom();
        return;
      }

      await Future<void>.delayed(_videoPollingInterval);
    }
  }

  Future<void> _refreshWorkspaceAfterReady() async {
    final workspace = _workspace;
    if (workspace == null) {
      return;
    }
    try {
      final refreshed = await widget.workspaceRepository.fetchWorkspace(
        workspace.id,
      );
      if (!mounted) return;
      setState(() {
        _workspace = refreshed;
        _chatEntries
          ..clear()
          ..addAll(_entriesFromEvents(refreshed.events));
        _latestVideoArtifact =
            _withResolvedArtifactUrls(refreshed.latestMedia) ??
            _latestVideoArtifact;
      });
    } on WorkspaceException {
      // Best effort refresh; preserve ready state and fallback artifact.
    }
  }

  bool _canGenerateVideoForCurrentTopic() => _workspace != null;

  String _normalizedLanguageCode() {
    final workspaceLanguage = _workspace?.learnerLanguage
        .toLowerCase()
        .trim()
        .replaceAll('_', '-');
    final preferredLanguage = (workspaceLanguage?.isNotEmpty ?? false)
        ? workspaceLanguage!
        : widget.onboardingController.profile.preferredLanguage
              .toLowerCase()
              .trim()
              .replaceAll('_', '-');
    return switch (preferredLanguage) {
      'indonesian' ||
      'ind' ||
      'indo' ||
      'bahasa' ||
      'bahasa indonesia' ||
      'id' ||
      'id-id' => 'id',
      'english' || 'eng' || 'en' || 'en-us' || 'en-gb' => 'en',
      _ => 'en',
    };
  }

  WorkspaceMediaArtifact _latestVideoArtifactFromStatus(
    WorkspaceAnimationJobStatus status, {
    WorkspaceSession? fallback,
  }) {
    final existing = _workspace?.latestMedia;
    if (existing != null && existing.id == status.artifactId) {
      return existing;
    }
    final material = _workspaceMaterial;
    return WorkspaceMediaArtifact(
      id: status.artifactId,
      title: fallback?.currentTopic ?? material.generatedVideoFallbackTitle,
      subtitle: material.generatedVideoSubtitle,
      status: status.status,
      durationSeconds: 0,
      durationLabel: '--:--',
      transcript: '',
      notes: const [],
      thumbnailUrl: _resolveMediaUrl(status.thumbnailUrl),
      videoUrl: _resolveMediaUrl(status.videoUrl),
      playbackUrl: _resolveMediaUrl(status.videoUrl),
    );
  }

  String? _resolveMediaUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(rawUrl);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
      return rawUrl;
    }
    final baseUri = Uri.parse(ApiClient.defaultBaseUrl);
    if (rawUrl.startsWith('/')) {
      return baseUri.resolve(rawUrl).toString();
    }
    return baseUri.resolve('/$rawUrl').toString();
  }

  WorkspaceMediaArtifact? _withResolvedArtifactUrls(
    WorkspaceMediaArtifact? artifact,
  ) {
    if (artifact == null) {
      return null;
    }
    return WorkspaceMediaArtifact(
      id: artifact.id,
      title: artifact.title,
      subtitle: artifact.subtitle,
      status: artifact.status,
      durationSeconds: artifact.durationSeconds,
      durationLabel: artifact.durationLabel,
      transcript: artifact.transcript,
      notes: artifact.notes,
      thumbnailUrl: _resolveMediaUrl(artifact.thumbnailUrl),
      videoUrl: _resolveMediaUrl(artifact.videoUrl),
      playbackUrl: _resolveMediaUrl(artifact.playbackUrl),
      createdAt: artifact.createdAt,
    );
  }

  Future<void> _advancePhase() async {
    final workspace = _workspace;
    if (workspace == null || _isLoadingWorkspace || _isPhaseSubmitting) {
      return;
    }
    setState(() {
      _isPhaseSubmitting = true;
      _workspaceError = null;
    });
    try {
      final updated = await widget.workspaceRepository.advancePhase(
        workspaceId: workspace.id,
      );
      if (!mounted || _workspace?.id != workspace.id) {
        return;
      }
      final arguments = widget.routeArguments;
      var history = _sessionHistory;
      if (arguments != null && arguments.isValid) {
        try {
          history = await widget.workspaceRepository.fetchSessionHistory(
            trackId: arguments.trackId,
            moduleId: arguments.moduleId,
          );
        } on WorkspaceException {
          history = _sessionHistory;
        }
      }
      if (!mounted || _workspace?.id != workspace.id) {
        return;
      }
      setState(() {
        _workspace = updated;
        _sessionHistory = history;
        _isPhaseSubmitting = false;
      });
    } on WorkspaceException catch (error) {
      if (!mounted || _workspace?.id != workspace.id) {
        return;
      }
      setState(() {
        _isPhaseSubmitting = false;
        _workspaceError = error.message;
      });
    }
  }

  Future<void> _startPosttestFromWorkspace() async {
    final workspace = _workspace;
    if (workspace == null || _isLoadingWorkspace || _isPhaseSubmitting) {
      return;
    }
    final trigger = workspace.posttestTrigger;
    if (trigger?.isReady == true) {
      _openPosttestFromWorkspace();
      return;
    }
    if (!workspace.posttestEligible) {
      return;
    }
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) {
        final material = _workspaceMaterial;
        return AlertDialog(
          title: Text(material.startPosttestButtonLabel),
          content: Text(material.posttestReadyBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(material.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(material.startPosttestDialogLabel),
            ),
          ],
        );
      },
    );
    if (shouldStart != true) {
      return;
    }
    setState(() {
      _isPhaseSubmitting = true;
      _workspaceError = null;
    });
    try {
      final updated = await widget.workspaceRepository.startPosttest(
        workspaceId: workspace.id,
      );
      if (!mounted || _workspace?.id != workspace.id) {
        return;
      }
      setState(() {
        _workspace = updated;
        _isPhaseSubmitting = false;
      });
      if (updated.posttestTrigger?.isReady == true) {
        _openPosttestFromWorkspace();
      } else {
        setState(() {
          _workspaceError =
              updated.posttestTrigger?.error ??
              _workspaceMaterial.posttestUnavailableMessage;
        });
      }
    } on WorkspaceException catch (error) {
      if (!mounted || _workspace?.id != workspace.id) {
        return;
      }
      setState(() {
        _isPhaseSubmitting = false;
        _workspaceError = error.message;
      });
    }
  }

  void _openPosttestFromWorkspace() {
    final arguments = widget.routeArguments;
    final workspaceTitle = _workspace?.currentTopic.trim() ?? '';
    Navigator.of(context).pop(
      WorkspaceCompletionResult(
        trackId: arguments?.trackId ?? _workspace?.trackId ?? '',
        moduleId: arguments?.moduleId ?? _workspace?.moduleId ?? '',
        moduleTitle: workspaceTitle.isNotEmpty
            ? workspaceTitle
            : _workspaceMaterial.topicTitle,
        moduleCompleted: _workspace?.status == 'completed',
        requestedEarlyPosttest: false,
        workspaceSessionId: _workspace?.id,
      ),
    );
  }

  Future<void> _handleCanvasSentToChat(CanvasWorkSnapshot snapshot) async {
    setState(() {
      _canvasSnapshots.add(snapshot);
      _chatEntries.add(_WorkspaceChatEntry.canvas(snapshot));
    });
    await _appendWorkspaceEvent(
      eventType: 'canvas_sent',
      metadata: {
        'version': snapshot.version,
        'element_count': snapshot.elementCount,
        'has_attachment': snapshot.hasAttachment,
        'show_grid': snapshot.showGrid,
        'canvas_width': snapshot.canvasSize.width,
        'canvas_height': snapshot.canvasSize.height,
      },
    );
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    if (_isLoadingWorkspace || _workspace == null) {
      setState(() {
        _workspaceError = _workspaceMaterial.chatLoadingMessage;
      });
      return;
    }

    _messageController.clear();
    setState(() {
      _chatEntries.add(_WorkspaceChatEntry.text(text: message, isUser: true));
    });
    await _appendWorkspaceEvent(eventType: 'text', textPayload: message);
    _scrollToBottom();
  }

  Future<void> _startLearningChat() async {
    if (_chatEntries.isNotEmpty) {
      return;
    }
    if (_isLoadingWorkspace || _workspace == null) {
      setState(() {
        _workspaceError = _workspaceMaterial.chatLoadingMessage;
      });
      return;
    }

    final workspaceTitle = _workspace?.currentTopic.trim() ?? '';
    final topic = workspaceTitle.isNotEmpty
        ? workspaceTitle
        : _workspaceMaterial.topicTitle;
    final message = _normalizedLanguageCode() == 'id'
        ? 'Saya siap mulai belajar $topic.'
        : "I'm ready to start learning $topic.";
    setState(() {
      _chatEntries.add(_WorkspaceChatEntry.text(text: message, isUser: true));
    });
    await _appendWorkspaceEvent(
      eventType: 'text',
      textPayload: message,
      metadata: const {'triggered_by': 'workspace_start_chat_button'},
    );
    _scrollToBottom();
  }

  Future<void> _appendWorkspaceEvent({
    required String eventType,
    String textPayload = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    final workspace = _workspace;
    if (workspace == null) {
      setState(() {
        _workspaceError = _workspaceMaterial.workspaceNotReadyMessage;
      });
      return;
    }
    setState(() {
      _isAppendingEvent = true;
      _workspaceError = null;
    });
    try {
      final result = await widget.workspaceRepository.appendEvent(
        workspaceId: workspace.id,
        eventType: eventType,
        textPayload: textPayload,
        metadata: metadata,
      );
      if (!mounted || _workspace?.id != workspace.id) return;
      final arguments = widget.routeArguments;
      var history = _sessionHistory;
      if (arguments != null && arguments.isValid) {
        try {
          history = await widget.workspaceRepository.fetchSessionHistory(
            trackId: arguments.trackId,
            moduleId: arguments.moduleId,
          );
        } on WorkspaceException {
          history = _sessionHistory;
        }
      }
      if (!mounted || _workspace?.id != workspace.id) return;
      setState(() {
        _workspace = result.workspace;
        _sessionHistory = history;
        _chatEntries
          ..clear()
          ..addAll(_entriesFromEvents(result.workspace.events));
        _isAppendingEvent = false;
      });
    } on WorkspaceException catch (error) {
      if (!mounted || _workspace?.id != workspace.id) return;
      setState(() {
        _isAppendingEvent = false;
        _workspaceError = error.message;
        _chatEntries.add(
          _WorkspaceChatEntry.text(
            text: _workspaceMaterial.workspaceSyncFailedMessage(error.message),
            isUser: false,
          ),
        );
      });
    }
  }

  List<_WorkspaceChatEntry> _entriesFromEvents(List<WorkspaceEvent> events) {
    return events
        .map((event) {
          if (event.eventType == 'canvas_sent') {
            final count = event.metadata['element_count'];
            return _WorkspaceChatEntry.text(
              text: _workspaceMaterial.canvasSnapshotSentLabel(count),
              isUser: true,
            );
          }
          if (event.textPayload.trim().isEmpty) {
            return null;
          }
          return _WorkspaceChatEntry.text(
            text: event.textPayload,
            isUser: event.isLearner,
            nextActions: event.tutorNextActions,
            evidenceRequest: event.tutorEvidenceRequest,
            explanationCard: event.tutorExplanationCard,
          );
        })
        .whereType<_WorkspaceChatEntry>()
        .toList(growable: false);
  }

  void _openCanvas() {
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Canvas workspace',
      barrierDismissible: true,
      barrierColor: WicaraColors.ink.withValues(alpha: 0.14),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _WorkspaceCanvasDialog(
          onCanvasSent: (snapshot) {
            _handleCanvasSentToChat(snapshot);
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  bool _canAdvancePhase(WorkspaceSession? workspace) {
    if (workspace == null) {
      return false;
    }
    if (workspace.currentPhase == 'evaluate') {
      return false;
    }
    if (_isLoadingWorkspace || _isPhaseSubmitting || _isAppendingEvent) {
      return false;
    }
    return workspace.phaseTransitionPending;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _scrollToBottomIfNearBottom() {
    if (!_scrollController.hasClients) {
      _scrollToBottom();
      return;
    }
    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    if (distanceToBottom <= 120) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = OnboardingCopy.forLanguage(
      widget.onboardingController.profile.preferredLanguage,
    );
    final material = _workspaceMaterial;
    final workspace = _workspace;
    final showStartPosttestButton =
        workspace?.posttestEligible == true ||
        workspace?.posttestTrigger?.isReady == true;
    final canAdvancePhase = _canAdvancePhase(workspace);
    final workspaceDescription =
        (_workspace?.currentTopicDescription.trim().isNotEmpty ?? false)
        ? _workspace!.currentTopicDescription.trim()
        : (_workspace == null
              ? material.loadingDescription
              : material.syncedDescription);
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, 430.0);
            final compactViewport = constraints.maxHeight < 780;
            final showHeaderDetails =
                !compactViewport || _isWorkspaceHeaderExpanded;

            return Center(
              child: SizedBox(
                width: pageWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.chevron_left_rounded),
                                iconSize: 33,
                                color: WicaraColors.ink,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 38,
                                  height: 38,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Image.asset(
                                'lib/src/assets/workspaceIcon.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  material.workspaceTitleLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (compactViewport)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isWorkspaceHeaderExpanded =
                                          !_isWorkspaceHeaderExpanded;
                                    });
                                  },
                                  icon: Icon(
                                    showHeaderDetails
                                        ? Icons.unfold_less_rounded
                                        : Icons.unfold_more_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    showHeaderDetails
                                        ? (material.isIndonesian
                                              ? 'Ringkas'
                                              : 'Collapse')
                                        : (material.isIndonesian
                                              ? 'Detail'
                                              : 'Details'),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                            ],
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            crossFadeState: showHeaderDetails
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _WorkspaceTopicCard(
                                    copy: copy,
                                    title:
                                        _workspace?.currentTopic ??
                                        widget.routeArguments?.moduleTitle ??
                                        material.topicTitle,
                                    description: workspaceDescription,
                                  ),
                                  const SizedBox(height: 10),
                                  _PhaseStepperBar(
                                    currentPhase:
                                        workspace?.currentPhase ?? 'engage',
                                    phaseTransitionPending:
                                        workspace?.phaseTransitionPending ??
                                        false,
                                    material: material,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isLoadingWorkspace
                                              ? null
                                              : () {
                                                  unawaited(
                                                    _startNewChatSession(),
                                                  );
                                                },
                                          icon: const Icon(
                                            Icons.add_comment_outlined,
                                          ),
                                          label: Text(material.newChatLabel),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            unawaited(
                                              _openSessionHistorySheet(),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.history_rounded,
                                          ),
                                          label: Text(
                                            material.historyButtonLabel(
                                              _sessionHistory.length,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (showStartPosttestButton) ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed:
                                          _isLoadingWorkspace ||
                                              _isPhaseSubmitting
                                          ? null
                                          : () {
                                              unawaited(
                                                _startPosttestFromWorkspace(),
                                              );
                                            },
                                      icon: const Icon(
                                        Icons.assignment_turned_in_outlined,
                                      ),
                                      label: Text(
                                        material.startPosttestButtonLabel,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _WorkspaceCompactHeaderStatus(
                                phase: workspace?.currentPhase ?? 'engage',
                                phaseTransitionPending:
                                    workspace?.phaseTransitionPending ?? false,
                                material: material,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, viewportConstraints) {
                          return SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: viewportConstraints.maxHeight - 12,
                              ),
                              child: _WorkspaceChatPanel(
                                contentMode: _contentMode,
                                chatEntries: _chatEntries,
                                canvasSnapshots: _canvasSnapshots,
                                material: material,
                                isLoadingWorkspace: _isLoadingWorkspace,
                                isAppendingEvent: _isAppendingEvent,
                                isVideoGenerating: _isVideoGenerating,
                                workspaceError: _workspaceError,
                                latestVideoStatus: _latestVideoStatus,
                                latestVideoArtifact: _latestVideoArtifact,
                                videoStatusMessage: _videoStatusMessage,
                                videoErrorMessage: _videoErrorMessage,
                                canGenerateVideo:
                                    _canGenerateVideoForCurrentTopic(),
                                weeklyReport: _reportCardDismissed
                                    ? null
                                    : _weeklyReport,
                                onDismissReport: () {
                                  setState(() => _reportCardDismissed = true);
                                },
                                onGenerateVideo: () {
                                  unawaited(_generateVideo());
                                },
                                onStartChat: () {
                                  unawaited(_startLearningChat());
                                },
                                onOpenCanvas: _openCanvas,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _WorkspaceFooter(
                      controller: _messageController,
                      onSend: _sendMessage,
                      onAdvancePhase: () {
                        unawaited(_advancePhase());
                      },
                      onGenerateVideo: () {
                        unawaited(_generateVideo());
                      },
                      canAdvancePhase: canAdvancePhase,
                      isPhaseSubmitting: _isPhaseSubmitting,
                      isVideoGenerating: _isVideoGenerating,
                      canGenerateVideo: _canGenerateVideoForCurrentTopic(),
                      copy: copy,
                      material: material,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkspaceChatEntry {
  const _WorkspaceChatEntry.text({
    required this.text,
    required this.isUser,
    this.nextActions = const [],
    this.evidenceRequest,
    this.explanationCard,
  }) : snapshot = null;

  const _WorkspaceChatEntry.canvas(this.snapshot)
    : text = null,
      isUser = true,
      nextActions = const [],
      evidenceRequest = null,
      explanationCard = null;

  final String? text;
  final bool isUser;
  final CanvasWorkSnapshot? snapshot;
  final List<String> nextActions;
  final Map<String, dynamic>? evidenceRequest;
  final Map<String, dynamic>? explanationCard;

  bool get isCanvas => snapshot != null;
  bool get hasStructuredTutorData =>
      nextActions.isNotEmpty ||
      (evidenceRequest?.isNotEmpty ?? false) ||
      (explanationCard?.isNotEmpty ?? false);
}

class _WorkspaceHistorySheet extends StatelessWidget {
  const _WorkspaceHistorySheet({
    required this.sessions,
    required this.activeSessionId,
    required this.material,
  });

  final List<WorkspaceSessionSummary> sessions;
  final String? activeSessionId;
  final _LocalizedWorkspaceMaterial material;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                material.chatHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: WicaraColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isActive = session.id == activeSessionId;
                  return ListTile(
                    leading: Icon(
                      isActive
                          ? Icons.chat_bubble_rounded
                          : Icons.chat_bubble_outline_rounded,
                      color: isActive
                          ? WicaraColors.primary
                          : WicaraColors.muted,
                    ),
                    title: Text(
                      material.historySessionTitle(session.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      _historySubtitle(session),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check_rounded)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(session.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _historySubtitle(WorkspaceSessionSummary session) {
    final parts = <String>[];
    if (session.preview.isNotEmpty) {
      parts.add(session.preview);
    }
    final countLabel = material.historyMessageCountLabel(session.messageCount);
    parts.add(countLabel);
    final timeLabel = _compactDate(session.updatedAt);
    if (timeLabel.isNotEmpty) {
      parts.add(timeLabel);
    }
    return parts.join(' | ');
  }

  String _compactDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '';
    }
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month} $hour:$minute';
  }
}

class _LocalizedWorkspaceMaterial {
  const _LocalizedWorkspaceMaterial({
    required this.isIndonesian,
    required this.topicTitle,
    required this.startChatTitle,
    required this.startChatBody,
    required this.startChatButtonLabel,
    required this.loadingDescription,
    required this.syncedDescription,
  });

  final bool isIndonesian;
  final String topicTitle;
  final String startChatTitle;
  final String startChatBody;
  final String startChatButtonLabel;
  final String loadingDescription;
  final String syncedDescription;

  String get workspaceTitleLabel =>
      isIndonesian ? 'Ruang belajar' : 'Workspace';
  String get newChatLabel => isIndonesian ? 'Chat baru' : 'New chat';
  String get chatHistoryTitle => isIndonesian ? 'Riwayat chat' : 'Chat history';
  String get advancePhaseLabel =>
      isIndonesian ? 'Lanjut fase' : 'Advance phase';
  String get advancingPhaseLabel =>
      isIndonesian ? 'Memindahkan fase...' : 'Advancing phase...';
  String get phaseTransitionHint => isIndonesian
      ? "Tekan 'Lanjut fase' kalau sudah paham."
      : "Tap 'Advance phase' when you are ready.";
  String phaseLabel(String phase) {
    return switch (phase.trim().toLowerCase()) {
      'engage' => isIndonesian ? 'Engage' : 'Engage',
      'explore' => isIndonesian ? 'Explore' : 'Explore',
      'explain' => isIndonesian ? 'Explain' : 'Explain',
      'elaborate' => isIndonesian ? 'Elaborate' : 'Elaborate',
      'evaluate' => isIndonesian ? 'Evaluate' : 'Evaluate',
      _ => isIndonesian ? 'Engage' : 'Engage',
    };
  }

  String get startPosttestButtonLabel =>
      isIndonesian ? 'Mulai Posttest' : 'Start Posttest';
  String get posttestReadyBody => isIndonesian
      ? 'Mulai posttest sekarang? Ini akan menutup modul workspace dan menyiapkan sesi posttest.'
      : 'Start posttest now? This will complete the workspace module and prepare the posttest session.';
  String get cancelLabel => isIndonesian ? 'Batal' : 'Cancel';
  String get startPosttestDialogLabel =>
      isIndonesian ? 'Mulai posttest' : 'Start posttest';
  String get posttestUnavailableMessage => isIndonesian
      ? 'Posttest belum siap. Lanjutkan sesuai arahan tutor.'
      : 'The posttest is not ready yet. Continue with the tutor guidance.';
  String get workspaceNotReadyMessage =>
      isIndonesian ? 'Workspace belum siap.' : 'Workspace is not ready yet.';
  String get openTrackModuleMessage => isIndonesian
      ? 'Buka modul track dari Beranda atau Antrian sebelum memakai workspace.'
      : 'Open a track module from Home or Queue before using workspace.';
  String get chatLoadingMessage => isIndonesian
      ? 'Sesi chat masih dimuat.'
      : 'Chat session is still loading.';
  String get connectingWorkspaceMessage => isIndonesian
      ? 'Menghubungkan ke workspace backend...'
      : 'Connecting to backend workspace...';
  String get savingEvidenceMessage => isIndonesian
      ? 'Menyimpan bukti workspace...'
      : 'Saving workspace evidence...';
  String get queueingVideoMessage => isIndonesian
      ? 'Menyiapkan pembuatan video...'
      : 'Queueing video generation...';
  String get videoQueuedMessage => isIndonesian
      ? 'Video masuk antrean. Menunggu worker...'
      : 'Video queued. Waiting for worker...';
  String videoTimedOutMessage(int minutes) => isIndonesian
      ? 'Pembuatan video melewati batas waktu setelah $minutes menit.'
      : 'Video generation timed out after $minutes minutes.';
  String get generationTimeoutMessage =>
      isIndonesian ? 'Waktu pembuatan habis.' : 'Generation timeout.';
  String get buildingScenesMessage => isIndonesian
      ? 'Membangun scene, narasi, dan rendering...'
      : 'Building scenes, narration, and rendering...';
  String get generatingVideoTitle =>
      isIndonesian ? 'Membuat video' : 'Generating video';
  String get generatedVideoFallbackTitle =>
      isIndonesian ? 'Video yang dibuat' : 'Generated video';
  String get savedGeneratedVideoTitle =>
      isIndonesian ? 'Video tersimpan' : 'Saved generated video';
  String get generatedVideoSubtitle => isIndonesian
      ? 'Rendering video selesai dan siap di workspace.'
      : 'Video rendering finished and is ready in your workspace.';
  String get aiVideoChip => isIndonesian ? 'Video AI' : 'AI video';
  String get readyUrlChip => isIndonesian ? 'URL siap' : 'Ready URL';
  String get playGeneratedVideoLabel =>
      isIndonesian ? 'Putar video' : 'Play generated video';
  String get videoUrlUnavailableLabel =>
      isIndonesian ? 'URL video tidak tersedia' : 'Video URL unavailable';
  String get videoGenerationFailedTitle =>
      isIndonesian ? 'Pembuatan video gagal' : 'Video generation failed';
  String get videoGenerationFailedMessage =>
      isIndonesian ? 'Pembuatan video gagal.' : 'Video generation failed.';
  String get retryGenerateVideoLabel =>
      isIndonesian ? 'Coba buat video lagi' : 'Retry generate video';
  String get generatingVideoButtonLabel =>
      isIndonesian ? 'Membuat video...' : 'Generating video...';
  String get generateVideoFromChatLabel => isIndonesian
      ? 'Buat video dari chat ini'
      : 'Generate video from this chat';
  String get generatingVideoContextMessage => isIndonesian
      ? 'Membuat video dari konteks percakapan terakhirmu...'
      : 'Generating video from your latest conversation context...';
  String get videoReadyMessage => isIndonesian
      ? 'Video siap. Kamu bisa memutarnya dari kartu chat terbaru.'
      : 'Video ready. You can play it from the latest chat card.';
  String get failedToLoadVideoMessage => isIndonesian
      ? 'Gagal memuat video dari URL backend.'
      : 'Failed to load video from backend URL.';
  String get openFullscreenTooltip =>
      isIndonesian ? 'Buka layar penuh' : 'Open fullscreen';
  String durationChipLabel(String durationLabel) =>
      isIndonesian ? 'Durasi $durationLabel' : 'Duration $durationLabel';
  String get canvasAttachedPrompt => isIndonesian
      ? 'Kanvas sudah terlampir. Tambahkan sketsa lain jika perlu.'
      : 'Canvas work is attached. Add another sketch if needed.';
  String get canvasPrompt => isIndonesian
      ? 'Butuh papan tulis? Buka kanvas dan kirim sketsamu di sini.'
      : 'Need a whiteboard? Open canvas and send your sketch here.';
  String get openCanvasLabel => isIndonesian ? 'Buka kanvas' : 'Open canvas';
  String get useCanvasLabel => isIndonesian ? 'Pakai kanvas' : 'Use canvas';
  String get canvasSentLabel =>
      isIndonesian ? 'Kanvas terkirim' : 'Canvas sent';
  String get explanationCardLabel =>
      isIndonesian ? 'Kartu penjelasan' : 'Explanation card';
  String get evidenceRequestLabel =>
      isIndonesian ? 'Bukti yang diminta' : 'Evidence requested';
  String get nextActionsLabel =>
      isIndonesian ? 'Aksi berikutnya' : 'Next actions';
  String canvasSnapshotSentLabel(Object? count) {
    final suffix = count == null
        ? ''
        : isIndonesian
        ? ' ($count tanda)'
        : ' ($count marks)';
    return isIndonesian
        ? 'Snapshot kanvas terkirim$suffix'
        : 'Canvas snapshot sent$suffix';
  }

  String canvasMarksLabel(int count, bool hasAttachment) {
    final markText = isIndonesian ? '$count tanda' : '$count marks';
    if (!hasAttachment) {
      return markText;
    }
    return isIndonesian
        ? '$markText - kertas terlampir'
        : '$markText - paper attached';
  }

  String historyButtonLabel(int count) =>
      isIndonesian ? 'Riwayat ($count)' : 'History ($count)';

  String historySessionTitle(String title) =>
      title.isEmpty ? newChatLabel : title;

  String historyMessageCountLabel(int count) {
    if (isIndonesian) {
      return '$count pesan';
    }
    return count == 1 ? '1 message' : '$count messages';
  }

  String workspaceSyncFailedMessage(String message) => isIndonesian
      ? 'Sinkronisasi workspace gagal: $message'
      : 'Workspace sync failed: $message';

  factory _LocalizedWorkspaceMaterial.forLanguage(String languageCode) {
    if (languageCode == 'id') {
      return const _LocalizedWorkspaceMaterial(
        isIndonesian: true,
        topicTitle: 'Topik pembelajaran',
        startChatTitle: 'Mulai sesi belajar',
        startChatBody:
            'Tutor akan memandu dari diagnosis dan fase belajar yang tersimpan di backend.',
        startChatButtonLabel: 'Mulai chat belajar',
        loadingDescription:
            'Menghubungkan modul dengan konteks belajar dari backend.',
        syncedDescription:
            'Percakapan, kanvas, media, dan status fase disinkronkan dengan backend.',
      );
    }

    return const _LocalizedWorkspaceMaterial(
      isIndonesian: false,
      topicTitle: 'Learning topic',
      startChatTitle: 'Start learning',
      startChatBody:
          'The tutor will guide you from the diagnosis and learning phase stored by the backend.',
      startChatButtonLabel: 'Start learning chat',
      loadingDescription:
          'Connecting this module to the backend learning context.',
      syncedDescription:
          'Conversation, canvas, media, and phase state are synced with the backend.',
    );
  }
}

class _WorkspaceChatPanel extends StatelessWidget {
  const _WorkspaceChatPanel({
    required this.contentMode,
    required this.chatEntries,
    required this.canvasSnapshots,
    required this.material,
    required this.isLoadingWorkspace,
    required this.isAppendingEvent,
    required this.isVideoGenerating,
    required this.workspaceError,
    required this.latestVideoStatus,
    required this.latestVideoArtifact,
    required this.videoStatusMessage,
    required this.videoErrorMessage,
    required this.canGenerateVideo,
    required this.onGenerateVideo,
    required this.onStartChat,
    required this.onOpenCanvas,
    this.weeklyReport,
    this.onDismissReport,
  });

  final _WorkspaceContentMode contentMode;
  final List<_WorkspaceChatEntry> chatEntries;
  final List<CanvasWorkSnapshot> canvasSnapshots;
  final _LocalizedWorkspaceMaterial material;
  final bool isLoadingWorkspace;
  final bool isAppendingEvent;
  final bool isVideoGenerating;
  final String? workspaceError;
  final WorkspaceAnimationJobStatus? latestVideoStatus;
  final WorkspaceMediaArtifact? latestVideoArtifact;
  final String? videoStatusMessage;
  final String? videoErrorMessage;
  final bool canGenerateVideo;
  final VoidCallback onGenerateVideo;
  final VoidCallback onStartChat;
  final VoidCallback onOpenCanvas;
  final WeeklyLearningReport? weeklyReport;
  final VoidCallback? onDismissReport;

  @override
  Widget build(BuildContext context) {
    return _WorkspacePanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpeechStatusBanner(locale: material.isIndonesian ? 'id-ID' : 'en-US'),
          // ── Weekly report card (dismissible, shown at top of chat) ────────
          if (weeklyReport != null) ...[
            _WeeklyReportChatCard(
              report: weeklyReport!,
              onDismiss: onDismissReport,
            ),
            const SizedBox(height: 14),
          ],
          if (isLoadingWorkspace) ...[
            _WorkspaceSyncNotice(
              icon: Icons.cloud_sync_outlined,
              text: material.connectingWorkspaceMessage,
            ),
          ] else if (workspaceError != null) ...[
            const SizedBox(height: 10),
            _WorkspaceSyncNotice(
              icon: Icons.error_outline_rounded,
              text: workspaceError!,
              isError: true,
            ),
          ] else if (isAppendingEvent) ...[
            const SizedBox(height: 10),
            _WorkspaceSyncNotice(
              icon: Icons.sync_rounded,
              text: material.savingEvidenceMessage,
            ),
          ],
          if (!isLoadingWorkspace &&
              workspaceError == null &&
              chatEntries.isEmpty) ...[
            const SizedBox(height: 14),
            _WorkspaceStartChatCard(
              material: material,
              onStartChat: onStartChat,
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _WorkspaceCanvasPromptBubble(
              hasCanvasWork: canvasSnapshots.isNotEmpty,
              material: material,
              onUseCanvas: onOpenCanvas,
            ),
          ),
          for (final entry in chatEntries) ...[
            const SizedBox(height: 9),
            if (entry.isCanvas)
              Align(
                alignment: Alignment.centerRight,
                child: _CanvasSnapshotBubble(
                  snapshot: entry.snapshot!,
                  material: material,
                ),
              )
            else if (entry.isUser)
              _WorkspaceBubble(
                text: entry.text!,
                isUser: true,
                locale: material.isIndonesian ? 'id-ID' : 'en-US',
              )
            else
              _AssistantMessageFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WorkspaceBubble(
                      text: entry.text!,
                      isUser: false,
                      locale: material.isIndonesian ? 'id-ID' : 'en-US',
                    ),
                    if (entry.hasStructuredTutorData) ...[
                      const SizedBox(height: 8),
                      _StructuredTutorData(
                        explanationCard: entry.explanationCard,
                        evidenceRequest: entry.evidenceRequest,
                        nextActions: entry.nextActions,
                        material: material,
                      ),
                    ],
                  ],
                ),
              ),
          ],
          if (contentMode == _WorkspaceContentMode.videoProcessing) ...[
            const SizedBox(height: 14),
            _WorkspaceVideoLoadingCard(
              progress: latestVideoStatus?.progress ?? 0,
              material: material,
              message: videoStatusMessage ?? material.buildingScenesMessage,
            ),
          ] else if (contentMode == _WorkspaceContentMode.videoReady) ...[
            const SizedBox(height: 14),
            _GeneratedWorkspaceVideoCard(
              artifact: latestVideoArtifact,
              status: latestVideoStatus,
              material: material,
            ),
          ] else if (contentMode == _WorkspaceContentMode.videoFailed) ...[
            const SizedBox(height: 14),
            _WorkspaceVideoFailedCard(
              errorMessage:
                  videoErrorMessage ??
                  latestVideoStatus?.error ??
                  material.videoGenerationFailedMessage,
              material: material,
              onRetry: onGenerateVideo,
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceCanvasDialog extends StatelessWidget {
  const _WorkspaceCanvasDialog({required this.onCanvasSent});

  final ValueChanged<CanvasWorkSnapshot> onCanvasSent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: WicaraColors.pageBackground,
      surfaceTintColor: WicaraColors.pageBackground,
      child: SizedBox.expand(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 640
                  ? 28.0
                  : 12.0;
              final verticalPadding = constraints.maxHeight > 700 ? 24.0 : 12.0;
              final canvasWidth = math.min(
                constraints.maxWidth - horizontalPadding * 2,
                860.0,
              );
              final canvasHeight = math.max(
                420.0,
                constraints.maxHeight - verticalPadding * 2,
              );

              return Center(
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: FishboneCanvas(
                    height: canvasHeight,
                    isLargePanel: true,
                    onOpenLargePanel: () => Navigator.of(context).pop(),
                    onSendToChat: onCanvasSent,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WorkspaceSyncNotice extends StatelessWidget {
  const _WorkspaceSyncNotice({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? WicaraColors.accentCoral : WicaraColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF2EF) : WicaraColors.secondarySoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WicaraColors.text,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBubble extends StatelessWidget {
  const _WorkspaceBubble({
    required this.text,
    required this.isUser,
    required this.locale,
  });

  final String text;
  final bool isUser;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? WicaraColors.speechBlue : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isUser ? WicaraColors.primaryLight : WicaraColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: WicaraColors.shadowBlue.withValues(alpha: 0.18),
                blurRadius: 15,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichMathText(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WicaraColors.text,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(height: 8),
                  ReadAloudButton(textToRead: text, locale: locale),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantMessageFrame extends StatelessWidget {
  const _AssistantMessageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AgentAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agent',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: WicaraColors.secondaryDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WicaraColors.secondary, WicaraColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: WicaraColors.secondary.withValues(alpha: 0.26),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          'lib/src/assets/waveIcon.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _WorkspaceTopicCard extends StatelessWidget {
  const _WorkspaceTopicCard({
    required this.copy,
    required this.title,
    required this.description,
  });

  final OnboardingCopy copy;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: WicaraColors.line),
        boxShadow: [
          BoxShadow(
            color: WicaraColors.shadowBlue.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: WicaraColors.secondarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              copy.currentTopicLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: WicaraColors.secondaryDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: WicaraColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCanvasPromptBubble extends StatelessWidget {
  const _WorkspaceCanvasPromptBubble({
    required this.hasCanvasWork,
    required this.material,
    required this.onUseCanvas,
  });

  final bool hasCanvasWork;
  final _LocalizedWorkspaceMaterial material;
  final VoidCallback onUseCanvas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: WicaraColors.line),
            boxShadow: [
              BoxShadow(
                color: WicaraColors.shadowBlue.withValues(alpha: 0.16),
                blurRadius: 15,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Text(
            hasCanvasWork
                ? material.canvasAttachedPrompt
                : material.canvasPrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WicaraColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _WorkspaceCanvasQuickActionButton(
          label: hasCanvasWork
              ? material.openCanvasLabel
              : material.useCanvasLabel,
          onPressed: onUseCanvas,
        ),
      ],
    );
  }
}

class _WorkspaceCanvasQuickActionButton extends StatelessWidget {
  const _WorkspaceCanvasQuickActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: WicaraColors.secondary,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: WicaraColors.secondary.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.draw_outlined, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceVideoLoadingCard extends StatelessWidget {
  const _WorkspaceVideoLoadingCard({
    required this.progress,
    required this.message,
    required this.material,
  });

  final int progress;
  final String message;
  final _LocalizedWorkspaceMaterial material;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = (progress.clamp(0, 100)) / 100;
    return _WorkspaceRichBubble(
      icon: Icons.movie_creation_outlined,
      title: material.generatingVideoTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalizedProgress == 0 ? null : normalizedProgress,
              minHeight: 7,
              color: WicaraColors.primaryDeep,
              backgroundColor: WicaraColors.primarySoft,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            '$progress%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedWorkspaceVideoCard extends StatelessWidget {
  const _GeneratedWorkspaceVideoCard({
    required this.material,
    this.artifact,
    this.status,
  });

  final _LocalizedWorkspaceMaterial material;
  final WorkspaceMediaArtifact? artifact;
  final WorkspaceAnimationJobStatus? status;

  @override
  Widget build(BuildContext context) {
    final title = artifact?.title ?? material.generatedVideoFallbackTitle;
    final subtitle = artifact?.subtitle ?? material.generatedVideoSubtitle;
    final durationLabel = artifact?.durationLabel.isNotEmpty == true
        ? artifact!.durationLabel
        : '--:--';
    final playbackUrl = artifact?.videoUrl ?? status?.videoUrl ?? '';
    final thumbnailUrl = artifact?.thumbnailUrl ?? status?.thumbnailUrl;
    final canPlay = playbackUrl.isNotEmpty;

    return _WorkspaceRichBubble(
      icon: Icons.video_collection_outlined,
      title: material.savedGeneratedVideoTitle,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WicaraColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CustomPaint(
                            painter: _WorkspaceVideoPreviewPainter(),
                          );
                        },
                      )
                    else
                      CustomPaint(painter: _WorkspaceVideoPreviewPainter()),
                    Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: WicaraColors.shadowBlue.withValues(
                                alpha: 0.32,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: WicaraColors.secondary,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: WicaraColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WicaraColors.muted,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _GeneratedVideoChip(durationLabel),
                            _GeneratedVideoChip(material.aiVideoChip),
                            if (playbackUrl.isNotEmpty)
                              _GeneratedVideoChip(material.readyUrlChip),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(
                        Icons.check_circle_rounded,
                        color: WicaraColors.accentMint,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canPlay
                          ? () {
                              unawaited(
                                SpeechAccessibilityScope.maybeOf(
                                  context,
                                )?.stop(),
                              );
                              showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return _WorkspaceVideoPlayerDialog(
                                    title: title,
                                    videoUrl: playbackUrl,
                                    durationLabel: durationLabel,
                                    material: material,
                                  );
                                },
                              );
                            }
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        canPlay
                            ? material.playGeneratedVideoLabel
                            : material.videoUrlUnavailableLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceVideoPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEAF4FF), Color(0xFFDCEEFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final circlePaint = Paint()
      ..color = const Color(0xFFBBD8FF).withValues(alpha: 0.45);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.28),
      size.shortestSide * 0.16,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.76),
      size.shortestSide * 0.2,
      circlePaint,
    );

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF9EC3F8);
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.2,
        size.width * 0.72,
        size.height * 0.6,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(frameRect, framePaint);

    final playPath = Path()
      ..moveTo(size.width * 0.46, size.height * 0.39)
      ..lineTo(size.width * 0.46, size.height * 0.61)
      ..lineTo(size.width * 0.62, size.height * 0.5)
      ..close();
    final playPaint = Paint()..color = const Color(0xFF6FA3EA);
    canvas.drawPath(playPath, playPaint);
  }

  @override
  bool shouldRepaint(covariant _WorkspaceVideoPreviewPainter oldDelegate) =>
      false;
}

class _WorkspaceVideoFailedCard extends StatelessWidget {
  const _WorkspaceVideoFailedCard({
    required this.errorMessage,
    required this.material,
    required this.onRetry,
  });

  final String errorMessage;
  final _LocalizedWorkspaceMaterial material;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _WorkspaceRichBubble(
      icon: Icons.error_outline_rounded,
      title: material.videoGenerationFailedTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.accentCoral,
              fontWeight: FontWeight.w700,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(material.retryGenerateVideoLabel),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceVideoPlayerDialog extends StatefulWidget {
  const _WorkspaceVideoPlayerDialog({
    required this.title,
    required this.videoUrl,
    required this.material,
    this.durationLabel,
    this.isFullscreen = false,
    this.initialPosition,
  });

  final String title;
  final String videoUrl;
  final _LocalizedWorkspaceMaterial material;
  final String? durationLabel;
  final bool isFullscreen;
  final Duration? initialPosition;

  @override
  State<_WorkspaceVideoPlayerDialog> createState() =>
      _WorkspaceVideoPlayerDialogState();
}

class _WorkspaceVideoPlayerDialogState
    extends State<_WorkspaceVideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  double _zoomScale = 1.0;
  double? _timelineHoverFraction;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      final requestedPosition = widget.initialPosition;
      if (requestedPosition != null && requestedPosition > Duration.zero) {
        final maxPosition = controller.value.duration;
        final clampedPosition = requestedPosition > maxPosition
            ? maxPosition
            : requestedPosition;
        await controller.seekTo(clampedPosition);
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
      await controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = widget.material.failedToLoadVideoMessage;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _setZoomScale(double value) {
    setState(() {
      _zoomScale = value.clamp(1.0, 3.0);
    });
  }

  Future<void> _openFullscreenPlayer(VideoPlayerController controller) async {
    final currentPosition = controller.value.position;
    final wasPlaying = controller.value.isPlaying;
    await controller.pause();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) {
        return _WorkspaceVideoPlayerDialog(
          title: widget.title,
          videoUrl: widget.videoUrl,
          material: widget.material,
          durationLabel: widget.durationLabel,
          isFullscreen: true,
          initialPosition: currentPosition,
        );
      },
    );

    if (!mounted || !wasPlaying) return;
    await controller.play();
  }

  void _updateTimelineHover({
    required double localDx,
    required double trackWidth,
  }) {
    if (trackWidth <= 0) return;
    final fraction = (localDx / trackWidth).clamp(0.0, 1.0);
    if (_timelineHoverFraction == fraction) return;
    setState(() {
      _timelineHoverFraction = fraction;
    });
  }

  void _clearTimelineHover() {
    if (_timelineHoverFraction == null) return;
    setState(() {
      _timelineHoverFraction = null;
    });
  }

  String _formatTimelineTime(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isFullscreen = widget.isFullscreen;
    final foreground = isFullscreen ? Colors.white : WicaraColors.text;
    final card = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isFullscreen &&
                  !_isLoading &&
                  _errorMessage == null &&
                  controller != null)
                IconButton(
                  onPressed: () => _openFullscreenPlayer(controller),
                  icon: const Icon(Icons.open_in_full_rounded),
                  color: foreground,
                  tooltip: widget.material.openFullscreenTooltip,
                ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.close_rounded,
                ),
                color: foreground,
              ),
            ],
          ),
          if ((widget.durationLabel ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: _GeneratedVideoChip(
                widget.material.durationChipLabel(widget.durationLabel!),
              ),
            ),
          ],
          const SizedBox(height: 6),
          AspectRatio(
            aspectRatio: controller?.value.isInitialized == true
                ? controller!.value.aspectRatio
                : 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.black,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 3,
                        panEnabled: true,
                        scaleEnabled: true,
                        child: Center(
                          child: Transform.scale(
                            scale: _zoomScale,
                            child: VideoPlayer(controller!),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!_isLoading && _errorMessage == null && controller != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final totalDuration = value.duration > Duration.zero
                    ? value.duration
                    : const Duration(seconds: 1);
                final maxMs = totalDuration.inMilliseconds;
                final positionMs = value.position.inMilliseconds
                    .clamp(0, maxMs)
                    .toInt();
                final sliderValue = maxMs <= 0 ? 0.0 : positionMs / maxMs;
                final currentLabel = _formatTimelineTime(
                  Duration(milliseconds: positionMs),
                );
                final totalLabel = _formatTimelineTime(totalDuration);

                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (value.isPlaying) {
                                controller.pause();
                              } else {
                                controller.play();
                              }
                            });
                          },
                          icon: Icon(
                            value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          color: foreground,
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final trackWidth = constraints.maxWidth;
                              final hoverFraction = _timelineHoverFraction;
                              final showHover =
                                  hoverFraction != null && trackWidth > 0;
                              final safeHoverFraction = hoverFraction ?? 0.0;
                              final hoverMs = showHover
                                  ? (maxMs * safeHoverFraction).round()
                                  : 0;
                              final hoverLabel = showHover
                                  ? _formatTimelineTime(
                                      Duration(milliseconds: hoverMs),
                                    )
                                  : '';
                              final bubbleWidth = 64.0;
                              final hoverLeft = showHover
                                  ? ((trackWidth * safeHoverFraction) -
                                            (bubbleWidth / 2))
                                        .clamp(
                                          0.0,
                                          math.max(
                                            0.0,
                                            trackWidth - bubbleWidth,
                                          ),
                                        )
                                        .toDouble()
                                  : 0.0;

                              return MouseRegion(
                                onHover: (event) {
                                  _updateTimelineHover(
                                    localDx: event.localPosition.dx,
                                    trackWidth: trackWidth,
                                  );
                                },
                                onExit: (_) => _clearTimelineHover(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: showHover ? 22 : 0,
                                      child: showHover
                                          ? Stack(
                                              children: [
                                                Positioned(
                                                  left: hoverLeft,
                                                  width: bubbleWidth,
                                                  child: Container(
                                                    height: 20,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black87,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      hoverLabel,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 5,
                                        ),
                                        overlayShape:
                                            SliderComponentShape.noOverlay,
                                        activeTrackColor:
                                            WicaraColors.secondary,
                                        inactiveTrackColor: WicaraColors.line,
                                        thumbColor: WicaraColors.secondary,
                                      ),
                                      child: Slider(
                                        value: sliderValue.clamp(0.0, 1.0),
                                        min: 0,
                                        max: 1,
                                        onChanged: (nextValue) {
                                          final target = Duration(
                                            milliseconds: (maxMs * nextValue)
                                                .round(),
                                          );
                                          controller.seekTo(target);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => _setZoomScale(_zoomScale - 0.25),
                          icon: const Icon(Icons.zoom_out_rounded),
                          color: foreground,
                        ),
                        IconButton(
                          onPressed: () => _setZoomScale(1.0),
                          icon: const Icon(Icons.filter_center_focus_rounded),
                          color: foreground,
                        ),
                        IconButton(
                          onPressed: () => _setZoomScale(_zoomScale + 0.25),
                          icon: const Icon(Icons.zoom_in_rounded),
                          color: foreground,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          currentLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: foreground.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          totalLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: foreground.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );

    if (isFullscreen) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: ColoredBox(color: Colors.black, child: card),
        ),
      );
    }

    return Dialog(insetPadding: const EdgeInsets.all(16), child: card);
  }
}

class _GeneratedVideoChip extends StatelessWidget {
  const _GeneratedVideoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: WicaraColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: WicaraColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkspaceStartChatCard extends StatelessWidget {
  const _WorkspaceStartChatCard({
    required this.material,
    required this.onStartChat,
  });

  final _LocalizedWorkspaceMaterial material;
  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return _WorkspaceRichBubble(
      icon: Icons.auto_awesome_rounded,
      title: material.startChatTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            material.startChatBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.text,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onStartChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(material.startChatButtonLabel),
          ),
        ],
      ),
    );
  }
}

class _CanvasSnapshotBubble extends StatelessWidget {
  const _CanvasSnapshotBubble({required this.snapshot, required this.material});

  final CanvasWorkSnapshot snapshot;
  final _LocalizedWorkspaceMaterial material;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WicaraColors.speechBlue,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: WicaraColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: WicaraColors.shadowBlue.withValues(alpha: 0.18),
            blurRadius: 15,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.draw_outlined,
                color: WicaraColors.primaryDeep,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  material.canvasSentLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: WicaraColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CanvasWorkPreview(snapshot: snapshot),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            material.canvasMarksLabel(
              snapshot.elementCount,
              snapshot.hasAttachment,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseStepperBar extends StatelessWidget {
  const _PhaseStepperBar({
    required this.currentPhase,
    required this.phaseTransitionPending,
    required this.material,
  });

  final String currentPhase;
  final bool phaseTransitionPending;
  final _LocalizedWorkspaceMaterial material;

  static const _phaseOrder = [
    'engage',
    'explore',
    'explain',
    'elaborate',
    'evaluate',
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = currentPhase.trim().toLowerCase();
    final rawIndex = _phaseOrder.indexOf(normalized);
    final currentIndex = rawIndex < 0 ? 0 : rawIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(_phaseOrder.length, (index) {
            final phase = _phaseOrder[index];
            final done = index < currentIndex;
            final active = index == currentIndex;
            final fillColor = done
                ? WicaraColors.accentMint.withValues(alpha: 0.24)
                : active
                ? WicaraColors.primary.withValues(alpha: 0.2)
                : WicaraColors.fieldFill;
            final borderColor = done
                ? WicaraColors.accentMint
                : active
                ? WicaraColors.primary
                : WicaraColors.line;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == _phaseOrder.length - 1 ? 0 : 6,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: active ? 1.3 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (done) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: WicaraColors.accentMint,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        material.phaseLabel(phase),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: WicaraColors.ink,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        if (phaseTransitionPending) ...[
          const SizedBox(height: 7),
          Text(
            material.phaseTransitionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _WorkspaceCompactHeaderStatus extends StatelessWidget {
  const _WorkspaceCompactHeaderStatus({
    required this.phase,
    required this.phaseTransitionPending,
    required this.material,
  });

  final String phase;
  final bool phaseTransitionPending;
  final _LocalizedWorkspaceMaterial material;

  @override
  Widget build(BuildContext context) {
    const phases = {'engage', 'explore', 'explain', 'elaborate', 'evaluate'};
    final normalizedPhase = phase.trim().toLowerCase();
    final currentPhase = phases.contains(normalizedPhase)
        ? normalizedPhase
        : 'engage';
    final chipColor = phaseTransitionPending
        ? WicaraColors.secondarySoft
        : WicaraColors.fieldFill;
    final chipBorder = phaseTransitionPending
        ? WicaraColors.secondaryLight
        : WicaraColors.line;
    final statusText = phaseTransitionPending
        ? (material.isIndonesian
              ? 'Siap transisi fase'
              : 'Phase transition ready')
        : (material.isIndonesian
              ? 'Belajar di fase ini'
              : 'Continue this phase');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WicaraColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: chipBorder),
            ),
            child: Text(
              material.phaseLabel(currentPhase),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: WicaraColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WicaraColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceFooter extends StatelessWidget {
  const _WorkspaceFooter({
    required this.controller,
    required this.onSend,
    required this.onAdvancePhase,
    required this.onGenerateVideo,
    required this.canAdvancePhase,
    required this.isPhaseSubmitting,
    required this.isVideoGenerating,
    required this.canGenerateVideo,
    required this.copy,
    required this.material,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAdvancePhase;
  final VoidCallback onGenerateVideo;
  final bool canAdvancePhase;
  final bool isPhaseSubmitting;
  final bool isVideoGenerating;
  final bool canGenerateVideo;
  final OnboardingCopy copy;
  final _LocalizedWorkspaceMaterial material;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WicaraColors.pageBackground.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: WicaraColors.line)),
        boxShadow: [
          BoxShadow(
            color: WicaraColors.shadowBlue.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canAdvancePhase && !isPhaseSubmitting
                        ? onAdvancePhase
                        : null,
                    icon: Icon(
                      isPhaseSubmitting
                          ? Icons.hourglass_bottom_rounded
                          : Icons.skip_next_rounded,
                    ),
                    label: Text(
                      isPhaseSubmitting
                          ? material.advancingPhaseLabel
                          : material.advancePhaseLabel,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !isVideoGenerating && canGenerateVideo
                        ? onGenerateVideo
                        : null,
                    icon: Icon(
                      isVideoGenerating
                          ? Icons.hourglass_bottom_rounded
                          : Icons.smart_display_rounded,
                    ),
                    label: Text(
                      isVideoGenerating
                          ? material.generatingVideoButtonLabel
                          : material.generateVideoFromChatLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _WorkspaceComposerInput(
              controller: controller,
              onSend: onSend,
              copy: copy,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceComposerInput extends StatelessWidget {
  const _WorkspaceComposerInput({
    required this.controller,
    required this.onSend,
    required this.copy,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final OnboardingCopy copy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: copy.askOrReflectHereHint,
                  filled: true,
                  fillColor: WicaraColors.fieldFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: WicaraColors.secondaryLight,
                      width: 1.4,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: WicaraColors.secondary,
                      width: 1.7,
                    ),
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WicaraColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: WicaraColors.secondary,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: WicaraColors.secondary.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.arrow_upward_rounded),
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: MicrophoneToggle(
            locale: copy.isIndonesian ? 'id-ID' : 'en-US',
            onTranscript: _insertTranscript,
          ),
        ),
      ],
    );
  }

  void _insertTranscript(String transcript) {
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : start;
    final before = controller.text.substring(0, start);
    final after = controller.text.substring(end);
    final separator = before.isNotEmpty && !before.endsWith(' ') ? ' ' : '';
    final inserted = '$separator${transcript.trim()}';
    controller.value = TextEditingValue(
      text: '$before$inserted$after',
      selection: TextSelection.collapsed(
        offset: before.length + inserted.length,
      ),
    );
  }
}

class _WorkspaceRichBubble extends StatelessWidget {
  const _WorkspaceRichBubble({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WicaraColors.line, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: WicaraColors.secondary, size: 19),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WicaraColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            child,
          ],
        ),
      ),
    );
  }
}

class _WorkspacePanel extends StatelessWidget {
  const _WorkspacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: WicaraColors.line, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: WicaraColors.shadowBlue.withValues(alpha: 0.12),
            blurRadius: 17,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Weekly Report Chat Card
// ────────────────────────────────────────────────────────────────────────────

/// A compact, dismissible summary card shown at the top of the workspace
/// chatbot whenever the HomeRepository is configured. It displays the user's
/// latest weekly learning progress so they can pick up where they left off.
class _WeeklyReportChatCard extends StatelessWidget {
  const _WeeklyReportChatCard({required this.report, this.onDismiss});

  final WeeklyLearningReport report;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final score = report.score;
    final fixed = report.fixedGaps;
    final remaining = report.remainingGaps;
    final minutes = report.retentionMinutes;
    final notes = report.summaryNotes.take(3).toList();
    final consistency = report.consistencySummary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WicaraColors.primary.withValues(alpha: 0.10),
            WicaraColors.primaryDeep.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: WicaraColors.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: WicaraColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: WicaraColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Report',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: WicaraColors.primary,
                        height: 1.1,
                      ),
                    ),
                    if (report.rangeLabel.isNotEmpty)
                      Text(
                        report.rangeLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: WicaraColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: WicaraColors.muted,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Stat row ────────────────────────────────────────────────────
          Row(
            children: [
              _ReportStat(
                value: score > 0 ? '$score%' : '--',
                label: 'Score',
                color: WicaraColors.primary,
              ),
              const SizedBox(width: 8),
              _ReportStat(
                value: '+$fixed',
                label: 'Fixed gaps',
                color: WicaraColors.accentMint,
              ),
              const SizedBox(width: 8),
              _ReportStat(
                value: '$remaining',
                label: 'Remaining',
                color: remaining > 0
                    ? const Color(0xFFF4A44E)
                    : WicaraColors.accentMint,
              ),
              const SizedBox(width: 8),
              _ReportStat(
                value: '${minutes}m',
                label: 'Retention',
                color: WicaraColors.primaryDeep,
              ),
            ],
          ),

          // ── Summary notes ───────────────────────────────────────────────
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WicaraColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: WicaraColors.text,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Consistency summary ─────────────────────────────────────────
          if (consistency.narrative.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              decoration: BoxDecoration(
                color: WicaraColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                consistency.narrative,
                style: TextStyle(
                  fontSize: 11,
                  color: WicaraColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: WicaraColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
