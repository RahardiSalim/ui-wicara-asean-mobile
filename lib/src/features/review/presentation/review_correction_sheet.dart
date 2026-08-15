import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../domain/review_models.dart';

/// Bottom sheet that collects a teacher's correction for an artifact and returns
/// a `fields` map (plus an optional `_notes` key) via Navigator.pop.
class ReviewCorrectionSheet extends StatefulWidget {
  const ReviewCorrectionSheet({required this.detail, super.key});

  final ReviewItemDetail detail;

  @override
  State<ReviewCorrectionSheet> createState() => _ReviewCorrectionSheetState();
}

class _ReviewCorrectionSheetState extends State<ReviewCorrectionSheet> {
  final _notesController = TextEditingController();

  // Question fields.
  final _promptController = TextEditingController();
  final _expectedController = TextEditingController();
  final _optionControllers = <TextEditingController>[];
  final _optionIds = <String>[];
  int _correctIndex = -1;

  // Diagnosis fields.
  final _conceptIdController = TextEditingController();

  // Evaluation fields.
  double _reasoningScore = 0;
  final _feedbackController = TextEditingController();
  final _signalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final a = widget.detail.artifact ?? const {};
    switch (widget.detail.artifactType) {
      case 'question':
        _promptController.text = a['prompt']?.toString() ?? '';
        _expectedController.text = a['expected_reasoning']?.toString() ?? '';
        final options = (a['options'] as List?) ?? const [];
        for (var i = 0; i < options.length; i++) {
          final map = Map<String, dynamic>.from(options[i] as Map);
          _optionIds.add(map['id']?.toString() ?? '');
          _optionControllers.add(
            TextEditingController(text: map['text']?.toString() ?? ''),
          );
          if (map['is_correct'] == true) _correctIndex = i;
        }
        break;
      case 'diagnosis':
        _conceptIdController.text = a['suggested_concept_id']?.toString() ?? '';
        break;
      case 'evaluation':
        _reasoningScore = ((a['reasoning_score'] as num?)?.toDouble() ?? 0)
            .clamp(0, 1)
            .toDouble();
        _signalController.text = a['diagnostic_signal']?.toString() ?? '';
        break;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _promptController.dispose();
    _expectedController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _conceptIdController.dispose();
    _feedbackController.dispose();
    _signalController.dispose();
    super.dispose();
  }

  void _submit() {
    final fields = <String, dynamic>{};
    switch (widget.detail.artifactType) {
      case 'question':
        fields['prompt'] = _promptController.text.trim();
        fields['expected_reasoning'] = _expectedController.text.trim();
        fields['options'] = [
          for (var i = 0; i < _optionControllers.length; i++)
            {
              'id': _optionIds[i],
              'text': _optionControllers[i].text.trim(),
              'is_correct': i == _correctIndex,
            },
        ];
        break;
      case 'diagnosis':
        final id = _conceptIdController.text.trim();
        if (id.isNotEmpty) fields['suggested_concept_id'] = id;
        break;
      case 'evaluation':
        fields['reasoning_score'] = _reasoningScore;
        if (_feedbackController.text.trim().isNotEmpty) {
          fields['teacher_feedback'] = _feedbackController.text.trim();
        }
        if (_signalController.text.trim().isNotEmpty) {
          fields['diagnostic_signal'] = _signalController.text.trim();
        }
        break;
    }
    if (_notesController.text.trim().isNotEmpty) {
      fields['_notes'] = _notesController.text.trim();
    }
    Navigator.of(context).pop(fields);
  }

  @override
  Widget build(BuildContext context) {
    final copy = WicaraCopyScope.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: WicaraColors.pageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WicaraColors.softMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: WicaraColors.primaryDeep),
                  const SizedBox(width: 8),
                  Text(
                    copy.correctArtifactTitle(widget.detail.artifactType),
                    style: const TextStyle(
                      color: WicaraColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _form(copy),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: WicaraColors.primaryDeep,
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(copy.saveCorrectionLabel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(OnboardingCopy copy) {
    return switch (widget.detail.artifactType) {
      'question' => _questionForm(copy),
      'diagnosis' => _diagnosisForm(copy),
      'evaluation' => _evaluationForm(copy),
      _ => Text(copy.artifactNotCorrectableLabel),
    };
  }

  Widget _questionForm(OnboardingCopy copy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(copy.promptLabel, _promptController, maxLines: 3),
        const SizedBox(height: 12),
        Text(copy.optionsTapCorrectLabel, style: _labelStyle),
        const SizedBox(height: 6),
        for (var i = 0; i < _optionControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    i == _correctIndex
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: i == _correctIndex
                        ? WicaraColors.accentMint
                        : WicaraColors.softMuted,
                  ),
                  onPressed: () => setState(() => _correctIndex = i),
                ),
                Expanded(
                  child: TextField(
                    controller: _optionControllers[i],
                    decoration: _decoration(copy.optionNumberLabel(i + 1)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        _field(copy.expectedReasoningLabel, _expectedController, maxLines: 3),
        const SizedBox(height: 12),
        _notesField(copy),
      ],
    );
  }

  Widget _diagnosisForm(OnboardingCopy copy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.overrideConceptIdLabel,
          style: const TextStyle(color: WicaraColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        _field(copy.suggestedConceptIdLabel, _conceptIdController),
        const SizedBox(height: 12),
        _notesField(copy),
      ],
    );
  }

  Widget _evaluationForm(OnboardingCopy copy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.reasoningScoreLabel, style: _labelStyle),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _reasoningScore,
                onChanged: (v) => setState(() => _reasoningScore = v),
                activeColor: WicaraColors.primaryDeep,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                _reasoningScore.toStringAsFixed(2),
                style: const TextStyle(
                  color: WicaraColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _field(copy.diagnosticSignalLabel, _signalController),
        const SizedBox(height: 12),
        _field(copy.teacherFeedbackLabel, _feedbackController, maxLines: 3),
        const SizedBox(height: 12),
        _notesField(copy),
      ],
    );
  }

  Widget _notesField(OnboardingCopy copy) =>
      _field(copy.auditNoteLabel, _notesController, maxLines: 2);

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _decoration(label),
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: WicaraColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: WicaraColors.line),
    ),
  );

  static const _labelStyle = TextStyle(
    color: WicaraColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}
