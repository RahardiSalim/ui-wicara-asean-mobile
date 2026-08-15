import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../data/litert_gemma_runtime.dart';
import '../domain/edge_ai_models.dart';
import '../domain/edge_ai_runtime.dart';

class EdgeAiSettingsPage extends StatefulWidget {
  const EdgeAiSettingsPage({
    this.runtime = defaultEdgeAiRuntime,
    this.testPrompt,
    this.initialModelUrl = _defaultModelUrl,
    super.key,
  });

  static const _defaultModelUrl = String.fromEnvironment(
    'WICARA_EDGE_MODEL_URL',
    defaultValue:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
  );

  final EdgeAiRuntime runtime;

  /// Overrides the diagnostic prompt sent to the local model. When null the
  /// prompt follows the learner's language so the output is readable.
  final String? testPrompt;
  final String initialModelUrl;

  @override
  State<EdgeAiSettingsPage> createState() => _EdgeAiSettingsPageState();
}

class _EdgeAiSettingsPageState extends State<EdgeAiSettingsPage> {
  late final TextEditingController _modelUrlController;
  Timer? _installProgressPoller;
  bool _installPollInFlight = false;

  EdgeRuntimeStatus? _status;
  String? _lastOutput;
  String? _errorText;
  String? _installSummary;
  bool _isLoading = true;
  bool _isInstalling = false;
  bool _isInitializing = false;
  bool _isGenerating = false;
  bool _showAdvancedModelUrl = false;

  @override
  void initState() {
    super.initState();
    _modelUrlController = TextEditingController(text: widget.initialModelUrl);
    _refreshStatus();
  }

  @override
  void dispose() {
    _installProgressPoller?.cancel();
    _modelUrlController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });
    }
    try {
      final status = await widget.runtime.getStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = status;
        if (showLoading) {
          _isLoading = false;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (showLoading) {
          _isLoading = false;
        }
        _errorText = _copy.edgeAiStatusReadFailedLabel(error);
      });
    }
  }

  void _startInstallProgressPolling() {
    _installProgressPoller?.cancel();
    _installProgressPoller = Timer.periodic(const Duration(milliseconds: 700), (
      _,
    ) async {
      if (_installPollInFlight || !mounted) {
        return;
      }
      _installPollInFlight = true;
      try {
        await _refreshStatus(showLoading: false);
      } finally {
        _installPollInFlight = false;
      }
    });
  }

  void _stopInstallProgressPolling() {
    _installProgressPoller?.cancel();
    _installProgressPoller = null;
    _installPollInFlight = false;
  }

  OnboardingCopy get _copy => WicaraCopyScope.read(context);

  Future<void> _installModel({bool overwrite = false}) async {
    final copy = _copy;
    final url = _modelUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorText = copy.edgeAiEnterModelUrlLabel;
      });
      return;
    }

    setState(() {
      _isInstalling = true;
      _errorText = null;
      _installSummary = null;
    });
    _startInstallProgressPolling();
    try {
      final installed = await widget.runtime.installModel(
        url: url,
        overwrite: overwrite,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isInstalling = false;
        _installSummary = installed.skipped && !overwrite
            ? copy.edgeAiModelAlreadyPresentLabel(installed.modelPath)
            : overwrite
            ? copy.edgeAiModelReinstalledLabel(
                _formatBytes(installed.bytesDownloaded),
                installed.downloadMs ?? 0,
              )
            : copy.edgeAiModelInstalledLabel(
                _formatBytes(installed.bytesDownloaded),
                installed.downloadMs ?? 0,
              );
      });
      _stopInstallProgressPolling();
      await _refreshStatus(showLoading: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInstalling = false;
        _errorText = copy.edgeAiInstallFailedLabel(error);
      });
      _stopInstallProgressPolling();
      await _refreshStatus(showLoading: false);
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _errorText = null;
    });
    try {
      final status = await widget.runtime.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = status;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorText = _friendlyInitializeError(_copy, error.toString());
      });
    }
  }

  Future<void> _unloadModel() async {
    setState(() {
      _errorText = null;
    });
    try {
      await widget.runtime.unload();
      if (!mounted) {
        return;
      }
      setState(() {
        _installSummary = _copy.edgeAiUnloadedLabel;
      });
      await _refreshStatus(showLoading: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = _copy.edgeAiUnloadFailedLabel(error);
      });
    }
  }

  String _friendlyInitializeError(OnboardingCopy copy, String raw) {
    if (raw.contains('INITIALIZE_FAILED')) {
      return copy.edgeAiInitializeCorruptLabel;
    }
    return copy.edgeAiInitializeFailedLabel(raw);
  }

  Future<void> _runTestPrompt() async {
    setState(() {
      _isGenerating = true;
      _errorText = null;
      _lastOutput = null;
    });

    try {
      final request = EdgeGenerationRequest(
        requestId: 'litert_test_${DateTime.now().millisecondsSinceEpoch}',
        prompt: widget.testPrompt ?? _copy.edgeAiTestPrompt,
        temperature: 0.3,
        maxTokens: 180,
      );
      final result = await widget.runtime.generate(request);
      if (!mounted) {
        return;
      }
      setState(() {
        _isGenerating = false;
        _lastOutput =
            '${result.text}\n\n(totalMs=${result.metrics.totalMs}, execution=${result.executionLocation}, fallback=${result.fallbackUsed})';
      });
      await _refreshStatus(showLoading: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isGenerating = false;
        _errorText = _copy.edgeAiGenerationFailedLabel(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = WicaraCopyScope.of(context);
    final status = _status;
    final statusKey = _isLoading
        ? 'checking'
        : status == null
        ? 'unknown'
        : status.isReady
        ? 'ready'
        : status.available
        ? (status.defaultModelExists ? 'needs-init' : 'needs-install')
        : 'unavailable';
    final statusLabel = switch (statusKey) {
      'checking' => copy.edgeAiStatusChecking,
      'ready' => copy.edgeAiStatusReady,
      'needs-init' => copy.edgeAiStatusNeedsInit,
      'needs-install' => copy.edgeAiStatusNeedsInstall,
      'unavailable' => copy.edgeAiStatusUnavailable,
      _ => copy.edgeAiStatusUnknown,
    };
    final badgeColor = switch (statusKey) {
      'ready' => WicaraColors.accentMint,
      'needs-install' || 'needs-init' => const Color(0xFFF4A44E),
      'unavailable' => WicaraColors.accentCoral,
      _ => WicaraColors.secondary,
    };
    final download = status?.download ?? const EdgeModelDownloadStatus();
    final showProgress = _isInstalling || download.inProgress;
    final progressValue = download.progressValue;

    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 32,
                    color: WicaraColors.ink,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 38,
                      height: 38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      copy.edgeAiSettingsTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: WicaraColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                copy.edgeAiSettingsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WicaraColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WicaraColors.line, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.memory_rounded,
                          size: 18,
                          color: WicaraColors.primaryDeep,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            copy.edgeAiSectionLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: WicaraColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: badgeColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (status != null) ...[
                      Text(
                        'runtime=${status.runtime}  backend=${status.backend}  execution=${status.executionLocation}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WicaraColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'model=${status.modelPath ?? status.defaultModelPath ?? '-'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WicaraColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _showAdvancedModelUrl = !_showAdvancedModelUrl;
                      }),
                      icon: Icon(
                        _showAdvancedModelUrl
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                      label: Text(
                        _showAdvancedModelUrl
                            ? copy.edgeAiHideModelUrlLabel
                            : copy.edgeAiShowModelUrlLabel,
                      ),
                    ),
                    if (_showAdvancedModelUrl) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _modelUrlController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: copy.edgeAiModelUrlLabel,
                          hintText: 'https://...',
                          filled: true,
                          fillColor: WicaraColors.fieldFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: WicaraColors.line,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: WicaraColors.line,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: WicaraColors.secondary,
                            ),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WicaraColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _isInstalling
                              ? null
                              : () => _installModel(overwrite: false),
                          child: Text(
                            _isInstalling
                                ? copy.edgeAiInstallingLabel
                                : copy.edgeAiInstallModelLabel,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _isInstalling
                              ? null
                              : () => _installModel(overwrite: true),
                          child: Text(copy.edgeAiReinstallLabel),
                        ),
                        FilledButton(
                          onPressed: _isInitializing ? null : _initialize,
                          child: Text(
                            _isInitializing
                                ? copy.edgeAiInitializingLabel
                                : copy.edgeAiInitializeLabel,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _refreshStatus,
                          child: Text(copy.refreshLabel),
                        ),
                        OutlinedButton(
                          onPressed: _unloadModel,
                          child: Text(copy.edgeAiUnloadLabel),
                        ),
                        FilledButton.tonal(
                          onPressed: _isGenerating ? null : _runTestPrompt,
                          child: Text(
                            _isGenerating
                                ? copy.edgeAiRunningLabel
                                : copy.edgeAiRunTestPromptLabel,
                          ),
                        ),
                      ],
                    ),
                    if (showProgress) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: WicaraColors.fieldFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: WicaraColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              copy.edgeAiDownloadLabel(download.status),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: WicaraColors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: progressValue),
                            const SizedBox(height: 8),
                            Text(
                              download.hasKnownTotal
                                  ? '${_formatBytes(download.receivedBytes)} / ${_formatBytes(download.totalBytes ?? 0)}${progressValue == null ? '' : ' (${(progressValue * 100).toStringAsFixed(1)}%)'}'
                                  : copy.edgeAiDownloadedLabel(
                                      _formatBytes(download.receivedBytes),
                                    ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: WicaraColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_installSummary != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _installSummary!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WicaraColors.secondaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WicaraColors.accentCoral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (_lastOutput != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: WicaraColors.fieldFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: WicaraColors.line),
                        ),
                        child: SelectableText(
                          _lastOutput!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: WicaraColors.text,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
