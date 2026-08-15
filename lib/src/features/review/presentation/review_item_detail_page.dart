import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../application/review_controller.dart';
import '../domain/review_models.dart';
import 'review_correction_sheet.dart';
import 'review_widgets.dart';

/// Teacher detail view for one flagged AI output, with approve / reject /
/// correct actions. All actions are asynchronous and never block generation.
class ReviewItemDetailPage extends StatefulWidget {
  const ReviewItemDetailPage({
    required this.repository,
    required this.itemId,
    super.key,
  });

  final ReviewRepository repository;
  final String itemId;

  @override
  State<ReviewItemDetailPage> createState() => _ReviewItemDetailPageState();
}

class _ReviewItemDetailPageState extends State<ReviewItemDetailPage> {
  late final ReviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReviewController(repository: widget.repository);
    _controller.loadDetail(widget.itemId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  OnboardingCopy get _copy => WicaraCopyScope.read(context);

  Future<void> _approve() async {
    final copy = _copy;
    final notes = await _promptText(
      title: copy.approveThisOutputLabel,
      hint: copy.optionalNoteHint,
      confirmLabel: copy.approveLabel,
      required: false,
    );
    if (notes == null) return;
    final ok = await _controller.approve(widget.itemId, notes: notes);
    _afterResolve(ok, copy.approvedLabel);
  }

  Future<void> _reject() async {
    final copy = _copy;
    final reason = await _promptText(
      title: copy.rejectThisOutputLabel,
      hint: copy.whyIsItWrongHint,
      confirmLabel: copy.rejectLabel,
      required: true,
    );
    if (reason == null) return;
    final ok = await _controller.reject(widget.itemId, reason: reason);
    _afterResolve(ok, copy.rejectedLabel);
  }

  Future<void> _correct() async {
    final detail = _controller.detail;
    if (detail == null) return;
    final fields = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewCorrectionSheet(detail: detail),
    );
    if (fields == null || fields.isEmpty) return;
    final notes = fields.remove('_notes')?.toString() ?? '';
    final ok = await _controller.correct(
      widget.itemId,
      fields: fields,
      notes: notes,
    );
    if (!mounted) return;
    if (ok) {
      _snack(_copy.correctionSavedLabel);
    } else {
      _snack(_controller.actionError ?? _copy.correctionFailedLabel);
    }
  }

  void _afterResolve(bool ok, String label) {
    if (!mounted) return;
    if (ok) {
      _snack(_copy.resolveSuccessLabel(label));
      Navigator.of(context).pop(true);
    } else {
      _snack(_controller.actionError ?? _copy.resolveFailureLabel(label));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    required String confirmLabel,
    required bool required,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(WicaraCopyScope.of(dialogContext).cancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (required && text.isEmpty) return;
                Navigator.of(
                  dialogContext,
                ).pop(required ? text : controller.text.trim());
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = WicaraCopyScope.of(context);
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      appBar: AppBar(
        title: Text(copy.reviewItemLabel),
        backgroundColor: Colors.white,
        foregroundColor: WicaraColors.ink,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoadingDetail && _controller.detail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = _controller.detail;
          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _controller.detailError ?? copy.itemNotFoundLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WicaraColors.muted),
                ),
              ),
            );
          }
          return _detailBody(copy, detail);
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.detail == null) return const SizedBox.shrink();
          return _actionBar(copy);
        },
      ),
    );
  }

  Widget _detailBody(OnboardingCopy copy, ReviewItemDetail detail) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ArtifactTypeBadge(type: detail.artifactType),
            StatusBadge(status: detail.status),
            if (detail.confidence != null)
              ConfidenceChip(confidence: detail.confidence!),
            PriorityChip(priority: detail.priority),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final reason in detail.triggerReasons)
              TriggerBadge(trigger: reason),
          ],
        ),
        const SizedBox(height: 8),
        _whyBanner(copy, detail),
        const SizedBox(height: 8),
        _artifactSection(copy, detail),
        const SizedBox(height: 8),
        _historySection(copy, detail),
      ],
    );
  }

  Widget _whyBanner(OnboardingCopy copy, ReviewItemDetail detail) {
    final reasons = detail.triggerReasons
        .map(copy.reviewArtifactLabel)
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WicaraColors.speechBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: WicaraColors.primaryDeep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reasons.isEmpty
                  ? copy.flaggedForReviewLabel
                  : copy.flaggedBecauseLabel(reasons),
              style: const TextStyle(color: WicaraColors.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _artifactSection(OnboardingCopy copy, ReviewItemDetail detail) {
    final artifact = detail.artifact;
    if (artifact == null) {
      return _card(copy.artifactLabel, [
        Text(
          copy.artifactUnavailableLabel,
          style: const TextStyle(color: WicaraColors.muted),
        ),
      ]);
    }
    return switch (detail.artifactType) {
      'question' => _buildQuestion(copy, artifact),
      'diagnosis' => _buildDiagnosis(copy, artifact),
      'evaluation' => _buildEvaluation(copy, artifact),
      _ => _card(copy.artifactLabel, [Text(artifact.toString())]),
    };
  }

  Widget _buildQuestion(OnboardingCopy copy, Map<String, dynamic> q) {
    final options = (q['options'] as List?) ?? const [];
    return _card(copy.generatedQuestionLabel, [
      _kv(copy.promptLabel, q['prompt']?.toString() ?? ''),
      if ((q['helper_text']?.toString() ?? '').isNotEmpty)
        _kv(copy.helperLabel, q['helper_text'].toString()),
      const SizedBox(height: 6),
      Text(copy.optionsLabel, style: _labelStyle),
      const SizedBox(height: 4),
      ...options.map((o) {
        final map = Map<String, dynamic>.from(o as Map);
        final isCorrect = map['is_correct'] == true;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isCorrect
                    ? WicaraColors.accentMint
                    : WicaraColors.softMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${map['label'] ?? map['option_key'] ?? ''}. ${map['text'] ?? ''}',
                  style: TextStyle(
                    color: WicaraColors.text,
                    fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 6),
      if ((q['expected_reasoning']?.toString() ?? '').isNotEmpty)
        _kv(copy.expectedReasoningLabel, q['expected_reasoning'].toString()),
      _kv(copy.generationSourceLabel, q['generation_source']?.toString() ?? ''),
    ]);
  }

  Widget _buildDiagnosis(OnboardingCopy copy, Map<String, dynamic> d) {
    final alternatives = (d['alternatives'] as List?) ?? const [];
    return _card(copy.learningGoalDiagnosisLabel, [
      _kv(copy.learnerAskedLabel, d['raw_query']?.toString() ?? ''),
      _kv(copy.subjectSingularLabel, d['subject_code']?.toString() ?? ''),
      _kv(
        copy.suggestedConceptIdLabel,
        d['suggested_concept_id']?.toString() ?? copy.noneLabel,
      ),
      _kv(
        copy.confidenceLabel,
        (d['confidence'] as num?)?.toStringAsFixed(2) ?? '—',
      ),
      _kv(
        copy.statusLabel,
        copy.reviewArtifactLabel(d['status']?.toString() ?? ''),
      ),
      if (alternatives.isNotEmpty)
        _kv(
          copy.alternativesLabel,
          copy.candidateCountLabel(alternatives.length),
        ),
      _kv(
        copy.modelLabel,
        '${d['llm_provider'] ?? ''} / ${d['llm_model'] ?? ''}',
      ),
    ]);
  }

  Widget _buildEvaluation(OnboardingCopy copy, Map<String, dynamic> e) {
    return _card(copy.reasoningEvaluationLabel, [
      _kv(
        copy.learnerReasoningLabel,
        e['typed_reasoning']?.toString() ?? copy.noneLabel,
      ),
      _kv(
        copy.isCorrectLabel,
        e['is_correct'] == true ? copy.yesLabel : copy.noLabel,
      ),
      _kv(
        copy.answerScoreLabel,
        (e['answer_score'] as num?)?.toStringAsFixed(2) ?? '—',
      ),
      _kv(
        copy.reasoningScoreLabel,
        (e['reasoning_score'] as num?)?.toStringAsFixed(2) ?? '—',
      ),
      _kv(
        copy.evidenceScoreLabel,
        (e['evidence_score'] as num?)?.toStringAsFixed(2) ?? '—',
      ),
      _kv(copy.diagnosticSignalLabel, e['diagnostic_signal']?.toString() ?? ''),
    ]);
  }

  Widget _historySection(OnboardingCopy copy, ReviewItemDetail detail) {
    if (detail.actions.isEmpty) {
      return const SizedBox.shrink();
    }
    return _card(copy.historyLabel, [
      ...detail.actions.map((a) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.history,
                size: 16,
                color: WicaraColors.softMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${copy.reviewArtifactLabel(a.action)}'
                  '${a.notes.isNotEmpty ? ' — ${a.notes}' : ''}',
                  style: const TextStyle(
                    color: WicaraColors.text,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _actionBar(OnboardingCopy copy) {
    final acting = _controller.isActing;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: WicaraColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: acting ? null : _reject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: WicaraColors.accentCoral,
                  side: const BorderSide(color: WicaraColors.accentCoral),
                ),
                icon: const Icon(Icons.block, size: 18),
                label: Text(copy.rejectLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: acting ? null : _correct,
                style: OutlinedButton.styleFrom(
                  foregroundColor: WicaraColors.primaryDeep,
                  side: const BorderSide(color: WicaraColors.primaryDeep),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(copy.correctLabelAction),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: acting ? null : _approve,
                style: FilledButton.styleFrom(
                  backgroundColor: WicaraColors.accentMint,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(copy.approveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _labelStyle = TextStyle(
    color: WicaraColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(color: WicaraColors.ink, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WicaraColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: WicaraColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
