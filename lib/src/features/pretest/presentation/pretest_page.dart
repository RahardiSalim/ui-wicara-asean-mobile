import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/speech_controls.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../../review/domain/review_models.dart';
import '../../review/presentation/flag_review_button.dart';
import '../domain/pretest_models.dart';
import '../domain/pretest_repository.dart';
import 'widgets/assessment_option_tile.dart';
import 'widgets/knowledge_state_card.dart';
import 'widgets/rich_math_text.dart';

enum _PretestStage { question, result }

String _imageMimeType(String? extension) {
  return switch ((extension ?? '').trim().toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'image/png',
  };
}

class PretestPage extends StatefulWidget {
  const PretestPage({
    required this.pretestRepository,
    required this.onboardingController,
    this.reviewRepository,
    super.key,
  });

  final PretestRepository pretestRepository;
  final OnboardingController onboardingController;
  final ReviewRepository? reviewRepository;

  @override
  State<PretestPage> createState() => _PretestPageState();
}

class _PretestPageState extends State<PretestPage> {
  final _reasoningController = TextEditingController(text: '');

  _PretestStage _stage = _PretestStage.question;
  PretestQuestion? _question;
  String _selectedOptionId = '';
  bool _isSubmitting = false;
  bool _isUploadingEvidence = false;
  bool _isLoadingQuestion = true;
  String? _questionError;
  KnowledgeState? _knowledgeState;
  bool _showInlineEvidence = false;
  Uint8List? _evidenceImageBytes;
  String? _evidenceImageName;
  String? _evidenceImageMimeType;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _reasoningController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _stage = _PretestStage.question;
      _questionError = null;
      _question = null;
      _selectedOptionId = '';
      _knowledgeState = null;
      _showInlineEvidence = false;
      _evidenceImageBytes = null;
      _evidenceImageName = null;
      _evidenceImageMimeType = null;
      _reasoningController.clear();
      _isLoadingQuestion = true;
    });
    try {
      final question = await widget.pretestRepository.fetchCurrentQuestion();
      if (!mounted) {
        return;
      }
      setState(() {
        _question = question;
        _isLoadingQuestion = false;
      });
    } on PretestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _questionError = error.message;
        _isLoadingQuestion = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_isSubmitting) {
      return;
    }
    if (_selectedOptionId.isEmpty) {
      _showMessage('Pilih jawaban sebelum lanjut.');
      return;
    }

    await _submitCurrentAnswer(typedReasoning: '', usedCanvas: false);
  }

  void _openReasoning() {
    if (_selectedOptionId.isEmpty) {
      _showMessage('Pilih jawaban sebelum tambah cara.');
      return;
    }
    setState(() => _showInlineEvidence = !_showInlineEvidence);
  }

  Future<void> _pickEvidenceImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage('File gambar tidak dapat dibaca.');
      return;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      _showMessage('Ukuran gambar maksimal 10 MB.');
      return;
    }
    setState(() {
      _evidenceImageBytes = bytes;
      _evidenceImageName = file.name;
      _evidenceImageMimeType = _imageMimeType(file.extension);
      _showInlineEvidence = true;
    });
  }

  void _removeEvidenceImage() {
    setState(() {
      _evidenceImageBytes = null;
      _evidenceImageName = null;
      _evidenceImageMimeType = null;
    });
  }

  Future<void> _submitReasoning() async {
    if (_isSubmitting || _isUploadingEvidence) {
      return;
    }
    String? imageAssetId;
    final imageBytes = _evidenceImageBytes;
    if (imageBytes != null) {
      setState(() => _isUploadingEvidence = true);
      try {
        imageAssetId = await widget.pretestRepository.uploadEvidenceImage(
          bytes: imageBytes,
          filename: _evidenceImageName ?? 'work.png',
          mimeType: _evidenceImageMimeType ?? 'image/png',
        );
      } on PretestException catch (error) {
        if (mounted) {
          setState(() => _isUploadingEvidence = false);
        }
        _showMessage(error.message);
        return;
      }
      if (mounted) {
        setState(() => _isUploadingEvidence = false);
      }
    }
    await _submitCurrentAnswer(
      typedReasoning: _reasoningController.text,
      usedCanvas: imageAssetId != null,
      canvasAssetId: imageAssetId,
    );
  }

  Future<void> _submitCurrentAnswer({
    required String typedReasoning,
    required bool usedCanvas,
    String? canvasAssetId,
  }) async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await widget.pretestRepository.submitAnswer(
        PretestAnswer(
          questionId: _question?.id ?? '',
          optionId: _selectedOptionId,
          confidence: 0,
          typedReasoning: typedReasoning,
          canvasAssetId: canvasAssetId,
          usedCanvas: usedCanvas,
        ),
      );
      if (!mounted) {
        return;
      }
      if (result.completed) {
        setState(() {
          _knowledgeState = result.diagnosis;
          _question = null;
          _selectedOptionId = '';
          _reasoningController.clear();
          _showInlineEvidence = false;
          _evidenceImageBytes = null;
          _evidenceImageName = null;
          _evidenceImageMimeType = null;
          _stage = _PretestStage.result;
        });
      } else if (result.nextQuestion != null) {
        setState(() {
          _question = result.nextQuestion;
          _selectedOptionId = '';
          _reasoningController.clear();
          _showInlineEvidence = false;
          _evidenceImageBytes = null;
          _evidenceImageName = null;
          _evidenceImageMimeType = null;
          _stage = _PretestStage.question;
        });
      }
    } on PretestException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _selectPathAndGoHome() async {
    final state = _knowledgeState;
    if (state == null) {
      _goHome();
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.pretestRepository.selectPath(state.recommendedPath);
      if (!mounted) {
        return;
      }
      _goHome();
    } on PretestException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
      arguments: const {'auto_open_workspace': true},
    );
  }

  void _leavePretest() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final copy = OnboardingCopy.forLanguage(
      widget.onboardingController.profile.preferredLanguage,
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, 430.0);

            return Center(
              child: SizedBox(
                width: pageWidth,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(_stage),
                    child: _stageView(constraints, copy),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _stageView(BoxConstraints constraints, OnboardingCopy copy) {
    if (_stage == _PretestStage.result) {
      return _ResultStage(
        constraints: constraints,
        copy: copy,
        result: _knowledgeState,
        onContinue: _isSubmitting ? () {} : _selectPathAndGoHome,
      );
    }
    if (_isLoadingQuestion) {
      return _PretestStateView(
        constraints: constraints,
        title: 'Loading pretest',
        message: 'Preparing adaptive questions...',
      );
    }
    if (_questionError != null || _question == null) {
      return _PretestStateView(
        constraints: constraints,
        title: 'Pretest unavailable',
        message:
            _questionError ?? 'Local pretest generator returned no question.',
        actionLabel: 'Try again',
        onAction: _loadQuestion,
      );
    }
    final question = _question!;

    return switch (_stage) {
      _PretestStage.question => _QuestionStage(
        key: ValueKey(question.id),
        constraints: constraints,
        copy: copy,
        question: question,
        reviewRepository: widget.reviewRepository,
        progressValue: (question.progressCurrent / question.progressMax)
            .clamp(0.0, 1.0)
            .toDouble(),
        selectedOptionId: _selectedOptionId,
        isSubmitting: _isSubmitting || _isUploadingEvidence,
        submissionMessage: _isUploadingEvidence
            ? (copy.isIndonesian
                  ? 'Mengupload foto pekerjaan...'
                  : 'Uploading your work image...')
            : (copy.isIndonesian
                  ? 'Jawaban dikirim. Menilai langkah dan menyiapkan soal berikutnya...'
                  : 'Answer sent. Evaluating your work and preparing the next question...'),
        showEvidence: _showInlineEvidence,
        reasoningController: _reasoningController,
        evidenceImageBytes: _evidenceImageBytes,
        evidenceImageName: _evidenceImageName,
        onClose: _leavePretest,
        onSelected: (id) => setState(() => _selectedOptionId = id),
        submitLabel: copy.isIndonesian ? 'Kirim jawaban' : 'Submit answer',
        addEvidenceLabel: copy.isIndonesian
            ? 'Tambah cara / coretan'
            : 'Add reasoning / sketch',
        onSubmit: _submitAnswer,
        onAddEvidence: _openReasoning,
        onPickImage: _pickEvidenceImage,
        onRemoveImage: _removeEvidenceImage,
        onSubmitEvidence: _submitReasoning,
      ),
      _PretestStage.result => const SizedBox.shrink(),
    };
  }
}

class _PretestStateView extends StatelessWidget {
  const _PretestStateView({
    required this.constraints,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final BoxConstraints constraints;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 30),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(0.0, constraints.maxHeight - 48),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'lib/src/assets/pretestIcon.png',
                width: 84,
                height: 84,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 24, height: 1.12),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: WicaraColors.muted,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              GradientButton(label: actionLabel!, onPressed: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionStage extends StatelessWidget {
  const _QuestionStage({
    super.key,
    required this.constraints,
    required this.copy,
    required this.question,
    required this.progressValue,
    required this.selectedOptionId,
    required this.isSubmitting,
    required this.submissionMessage,
    required this.showEvidence,
    required this.reasoningController,
    required this.evidenceImageBytes,
    required this.evidenceImageName,
    required this.onClose,
    required this.onSelected,
    required this.submitLabel,
    required this.addEvidenceLabel,
    required this.onSubmit,
    required this.onAddEvidence,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onSubmitEvidence,
    this.reviewRepository,
  });

  final BoxConstraints constraints;
  final OnboardingCopy copy;
  final PretestQuestion question;
  final ReviewRepository? reviewRepository;
  final double progressValue;
  final String selectedOptionId;
  final bool isSubmitting;
  final String submissionMessage;
  final bool showEvidence;
  final TextEditingController reasoningController;
  final Uint8List? evidenceImageBytes;
  final String? evidenceImageName;
  final VoidCallback onClose;
  final ValueChanged<String> onSelected;
  final String submitLabel;
  final String addEvidenceLabel;
  final VoidCallback onSubmit;
  final VoidCallback onAddEvidence;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onSubmitEvidence;

  @override
  Widget build(BuildContext context) {
    final compact = constraints.maxHeight < 700;
    final horizontalPadding = constraints.maxWidth < 360 ? 18.0 : 28.0;
    final locale = copy.isIndonesian ? 'id-ID' : 'en-US';
    final speechText = [
      question.topic,
      question.prompt,
      question.helper,
      for (final option in question.options) '${option.label}. ${option.text}',
    ].where((part) => part.trim().isNotEmpty).join('. ');
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 10 : 14,
        horizontalPadding,
        22,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(0.0, constraints.maxHeight - 36),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AssessmentHeader(
              leading: Icons.close_rounded,
              onLeadingPressed: onClose,
            ),
            SizedBox(height: compact ? 22 : 54),
            Text(
              'Pretest',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 25, height: 1.12),
            ),
            const SizedBox(height: 12),
            Text(
              question.stepLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: WicaraColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _SlimProgress(value: progressValue),
            SizedBox(height: compact ? 20 : 31),
            Container(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 24,
                compact ? 18 : 24,
                compact ? 18 : 24,
                21,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: WicaraColors.line, width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: WicaraColors.shadowBlue.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: WicaraColors.speechBlue,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: WicaraColors.line),
                      ),
                      child: Text(
                        question.topic,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WicaraColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ReadAloudButton(
                      textToRead: speechText,
                      locale: locale,
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 26),
                  RichMathText(
                    question.prompt,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      height: 1.22,
                    ),
                  ),
                  if (FlagReviewButton.canFlag(reviewRepository, question.id))
                    Align(
                      alignment: Alignment.centerRight,
                      child: FlagReviewButton(
                        repository: reviewRepository,
                        artifactType: 'question',
                        artifactId: question.id,
                      ),
                    ),
                  SizedBox(height: compact ? 18 : 25),
                  RichMathText(
                    question.helper,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WicaraColors.muted,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 26),
                  for (
                    var index = 0;
                    index < question.options.length;
                    index++
                  ) ...[
                    AssessmentOptionTile(
                      option: question.options[index],
                      isSelected:
                          question.options[index].id == selectedOptionId,
                      onTap: () => onSelected(question.options[index].id),
                    ),
                    if (index < question.options.length - 1)
                      const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 19),
                  GradientButton(
                    label: submitLabel,
                    onPressed: selectedOptionId.isEmpty ? null : onSubmit,
                    isLoading: isSubmitting,
                  ),
                  if (isSubmitting) ...[
                    const SizedBox(height: 9),
                    Text(
                      submissionMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WicaraColors.muted,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: selectedOptionId.isEmpty || isSubmitting
                        ? null
                        : onAddEvidence,
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: Text(
                      showEvidence
                          ? (copy.isIndonesian
                                ? 'Tutup cara pengerjaan'
                                : 'Hide work evidence')
                          : addEvidenceLabel,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WicaraColors.secondaryDeep,
                      side: const BorderSide(
                        color: WicaraColors.secondaryLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                  if (showEvidence) ...[
                    const SizedBox(height: 14),
                    _InlineEvidencePanel(
                      copy: copy,
                      controller: reasoningController,
                      imageBytes: evidenceImageBytes,
                      imageName: evidenceImageName,
                      isSubmitting: isSubmitting,
                      onPickImage: onPickImage,
                      onRemoveImage: onRemoveImage,
                      onSubmit: onSubmitEvidence,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _AssessmentFooter(),
          ],
        ),
      ),
    );
  }
}

class _InlineEvidencePanel extends StatelessWidget {
  const _InlineEvidencePanel({
    required this.copy,
    required this.controller,
    required this.imageBytes,
    required this.imageName,
    required this.isSubmitting,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onSubmit,
  });

  final OnboardingCopy copy;
  final TextEditingController controller;
  final Uint8List? imageBytes;
  final String? imageName;
  final bool isSubmitting;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WicaraColors.pageBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WicaraColors.secondaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy.isIndonesian ? 'Cara pengerjaan' : 'Work evidence',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: WicaraColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            copy.isIndonesian
                ? 'Tulis langkahmu, upload foto pekerjaan, atau gunakan keduanya. Foto akan dibaca AI sebagai langkah pengerjaan.'
                : 'Type your steps, upload a photo of your work, or use both. AI will read the image as solution steps.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !isSubmitting,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: copy.isIndonesian
                  ? 'Tulis langkah pengerjaanmu...'
                  : 'Write your solution steps...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: WicaraColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: WicaraColors.line),
              ),
            ),
          ),
          const SizedBox(height: 11),
          if (imageBytes == null)
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : onPickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                copy.isIndonesian
                    ? 'Upload foto pekerjaan'
                    : 'Upload work image',
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WicaraColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.memory(
                      imageBytes!,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: WicaraColors.secondary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          imageName ?? 'work-image',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: copy.isIndonesian
                            ? 'Hapus foto'
                            : 'Remove image',
                        onPressed: isSubmitting ? null : onRemoveImage,
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 13),
          GradientButton(
            label: copy.isIndonesian
                ? 'Kirim jawaban dengan bukti'
                : 'Submit answer with evidence',
            onPressed: isSubmitting ? null : onSubmit,
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }
}

class _ResultStage extends StatelessWidget {
  const _ResultStage({
    required this.constraints,
    required this.copy,
    required this.result,
    required this.onContinue,
  });

  final BoxConstraints constraints;
  final OnboardingCopy copy;
  final KnowledgeState? result;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final state =
        result ??
        KnowledgeState(
          skill: 'Missing prerequisite: causal drivers',
          gapLabel: 'GAP',
          message:
              'The gap looks like choosing a tool before naming the defect driver, evidence, and likely cause chain.',
          pathTitle: copy.personalizedPathGeneratedLabel,
          pathMeta: '12-15 min   •   3 skills',
          pathDescription: copy.personalizedPathDescription,
        );
    final localizedPathMeta = copy.isIndonesian
        ? state.pathMeta.replaceAll('skills', 'skill')
        : state.pathMeta;
    final locale = copy.isIndonesian ? 'id-ID' : 'en-US';
    final resultSpeechText = [
      copy.yourKnowledgeStateLabel,
      if (state.masteryScore != null)
        '${copy.scoreLabel} ${((state.masteryScore ?? 0) * 100).round()} percent',
      state.message,
      ...state.strengths,
      ...state.gaps,
      ...state.evidenceNotes,
      ...state.nodeReports.map((node) => '${node.title}: ${node.status}'),
      ...state.recommendedFocus,
      state.pathDescription,
    ].where((part) => part.trim().isNotEmpty).join('. ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 22),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(0.0, constraints.maxHeight - 36),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 78),
            Text(
              copy.yourKnowledgeStateLabel,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 25, height: 1.12),
            ),
            const SizedBox(height: 10),
            Text(
              copy.basedOnYourResponsesLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: WicaraColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ReadAloudButton(
                textToRead: resultSpeechText,
                locale: locale,
              ),
            ),
            if (state.masteryScore != null) ...[
              const SizedBox(height: 22),
              _ScoreSummaryCard(
                score: state.masteryScore,
                overallMasteryPercent: state.overallMasteryPercent,
                correctCount: state.correctCount,
                answeredCount: state.answeredCount,
                copy: copy,
              ),
            ],
            const SizedBox(height: 28),
            _KnowledgeGapDiagnosisCard(
              gapLabel: state.gapLabel,
              message: state.message,
              strengths: state.strengths,
              gaps: state.gaps,
              evidenceNotes: state.evidenceNotes,
              copy: copy,
            ),
            if (state.nodeReports.isNotEmpty) ...[
              const SizedBox(height: 18),
              _NodeBreakdownCard(nodes: state.nodeReports, copy: copy),
            ],
            if (state.recommendedFocus.isNotEmpty) ...[
              const SizedBox(height: 18),
              _RecommendedFocusCard(items: state.recommendedFocus, copy: copy),
            ],
            const SizedBox(height: 34),
            Text(
              copy.whatsNextLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            KnowledgeStateCard(
              title: copy.personalizedPathGeneratedLabel,
              message:
                  '$localizedPathMeta\n${copy.isIndonesian ? copy.personalizedPathDescription : state.pathDescription}',
              badge: '',
              icon: Icons.center_focus_strong_outlined,
              iconColor: WicaraColors.secondaryDeep,
              iconBackgroundColor: WicaraColors.secondarySoft,
              height: 116,
              showChevron: false,
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: copy.continueToMyPathLabel,
              onPressed: onContinue,
            ),
            const SizedBox(height: 20),
            Text(
              copy.retakePretestAnytimeLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WicaraColors.softMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSummaryCard extends StatelessWidget {
  const _ScoreSummaryCard({
    required this.score,
    required this.overallMasteryPercent,
    required this.correctCount,
    required this.answeredCount,
    required this.copy,
  });

  final double? score;
  final int? overallMasteryPercent;
  final int correctCount;
  final int answeredCount;
  final OnboardingCopy copy;

  @override
  Widget build(BuildContext context) {
    final scorePercent = ((score ?? 0).clamp(0.0, 1.0) * 100).round();
    final correctText = answeredCount > 0
        ? '$correctCount/$answeredCount ${copy.isIndonesian ? 'benar' : 'correct'}'
        : (copy.isIndonesian ? 'Belum ada jawaban' : 'No answers');
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: WicaraColors.line, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: WicaraColors.shadowBlue.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WicaraColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$scorePercent%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: WicaraColors.primaryDeep,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.scoreLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: WicaraColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    copy.isIndonesian ? 'Skor MCQ resmi' : 'Official MCQ score',
                    correctText,
                    if (overallMasteryPercent != null &&
                        overallMasteryPercent != scorePercent)
                      '${copy.isIndonesian ? 'Laporan' : 'Report'} $overallMasteryPercent%',
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WicaraColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeGapDiagnosisCard extends StatelessWidget {
  const _KnowledgeGapDiagnosisCard({
    required this.gapLabel,
    required this.message,
    required this.strengths,
    required this.gaps,
    required this.evidenceNotes,
    required this.copy,
  });

  final String gapLabel;
  final String message;
  final List<String> strengths;
  final List<String> gaps;
  final List<String> evidenceNotes;
  final OnboardingCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WicaraColors.line, width: 1.25),
        boxShadow: [
          BoxShadow(
            color: WicaraColors.shadowBlue.withValues(alpha: 0.13),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: WicaraColors.glowPeach,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: WicaraColors.accentCoral,
                  size: 25,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        copy.missingPrerequisiteGapsLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6E6),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        gapLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFC28A35),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ReportInsightList(
              title: copy.isIndonesian
                  ? 'Yang sudah kuat'
                  : 'What looks strong',
              icon: Icons.check_circle_outline_rounded,
              color: WicaraColors.secondary,
              items: strengths,
            ),
          ],
          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReportInsightList(
              title: copy.isIndonesian
                  ? 'Yang perlu diperbaiki'
                  : 'What needs work',
              icon: Icons.warning_amber_rounded,
              color: WicaraColors.accentCoral,
              items: gaps,
            ),
          ],
          if (evidenceNotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReportInsightList(
              title: copy.isIndonesian ? 'Catatan evidence' : 'Evidence notes',
              icon: Icons.fact_check_outlined,
              color: WicaraColors.primaryDeep,
              items: evidenceNotes,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportInsightList extends StatelessWidget {
  const _ReportInsightList({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: WicaraColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (var i = 0; i < visibleItems.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Text(
              visibleItems[i],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WicaraColors.text,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          if (i != visibleItems.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NodeBreakdownCard extends StatelessWidget {
  const _NodeBreakdownCard({required this.nodes, required this.copy});

  final List<PretestNodeReport> nodes;
  final OnboardingCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WicaraColors.line, width: 1.25),
        boxShadow: [
          BoxShadow(
            color: WicaraColors.shadowBlue.withValues(alpha: 0.11),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy.isIndonesian ? 'Node yang dicek' : 'Checked nodes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: WicaraColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < nodes.length; i++) ...[
            _NodeBreakdownRow(node: nodes[i], copy: copy),
            if (i != nodes.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _NodeBreakdownRow extends StatelessWidget {
  const _NodeBreakdownRow({required this.node, required this.copy});

  final PretestNodeReport node;
  final OnboardingCopy copy;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(node.status);
    final reasoningText = _reasoningText(node, copy);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: WicaraColors.fieldFill,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: WicaraColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WicaraColors.text,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _TinyBadge(label: node.status.toUpperCase(), color: statusColor),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                label: copy.isIndonesian ? 'Benar' : 'Correct',
                value: node.answerPercent == null
                    ? '${node.correctCount}/${node.attemptCount}'
                    : _percentMetricText(node.answerPercent),
              ),
              if (node.difficultyReached.isNotEmpty)
                _MetricPill(
                  label: copy.isIndonesian ? 'Level' : 'Level',
                  value: node.difficultyReached,
                ),
            ],
          ),
          if (reasoningText.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              reasoningText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WicaraColors.muted,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendedFocusCard extends StatelessWidget {
  const _RecommendedFocusCard({required this.items, required this.copy});

  final List<String> items;
  final OnboardingCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WicaraColors.secondarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WicaraColors.secondaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                color: WicaraColors.secondaryDeep,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  copy.isIndonesian
                      ? 'Fokus path berikutnya'
                      : 'Next path focus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: WicaraColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WicaraColors.secondaryDeep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[i],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WicaraColors.text,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: WicaraColors.line),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: WicaraColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'ready' || 'probably_ready' => WicaraColors.secondary,
    'partial' || 'fragile' => const Color(0xFFC28A35),
    'gap' || 'probably_gap' => WicaraColors.accentCoral,
    _ => WicaraColors.primaryDeep,
  };
}

String _percentMetricText(double? value) {
  if (value == null) {
    return '--';
  }
  final clamped = value.clamp(0.0, 100.0);
  return clamped == clamped.roundToDouble()
      ? '${clamped.round()}%'
      : '${clamped.toStringAsFixed(1)}%';
}

String _reasoningText(PretestNodeReport node, OnboardingCopy copy) {
  if (!node.hasEvidence) {
    return '';
  }
  if (node.misconceptionDetected) {
    return copy.isIndonesian
        ? 'Reasoning menunjukkan miskonsepsi pada node ini.'
        : 'Reasoning suggests a misconception on this node.';
  }
  if (node.carelessMistakePossible) {
    return copy.isIndonesian
        ? 'Ada indikasi salah pilih walau langkah cukup masuk akal.'
        : 'There is a possible careless choice despite reasonable reasoning.';
  }
  if (node.reasoningQuality == 'not_provided') {
    return copy.isIndonesian
        ? 'Evidence tersimpan, tetapi tidak ada langkah tertulis untuk dianalisis.'
        : 'Evidence was stored, but no written steps were available to analyze.';
  }
  final score = node.avgReasoningScore == null
      ? ''
      : ' ${(node.avgReasoningScore!.clamp(0.0, 1.0) * 100).round()}%';
  return copy.isIndonesian
      ? 'Kualitas reasoning: ${node.reasoningQuality}$score.'
      : 'Reasoning quality: ${node.reasoningQuality}$score.';
}

class _AssessmentHeader extends StatelessWidget {
  const _AssessmentHeader({
    required this.leading,
    required this.onLeadingPressed,
  });

  final IconData leading;
  final VoidCallback onLeadingPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onLeadingPressed,
          icon: Icon(leading),
          iconSize: leading == Icons.close_rounded ? 28 : 33,
          color: WicaraColors.ink,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        ),
        const SizedBox(width: 38, height: 38),
      ],
    );
  }
}

class _SlimProgress extends StatelessWidget {
  const _SlimProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 5,
        color: WicaraColors.secondary,
        backgroundColor: WicaraColors.line,
      ),
    );
  }
}

class _AssessmentFooter extends StatelessWidget {
  const _AssessmentFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.insights_rounded,
          color: WicaraColors.secondary,
          size: 19,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Adaptive probing  •  Knowledge Space Theory',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WicaraColors.softMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
