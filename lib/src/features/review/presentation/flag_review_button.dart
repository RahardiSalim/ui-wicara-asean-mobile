import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';
import '../domain/review_models.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// True when a learner flag can target this artifact: we have a repository and
/// the id is a real backend UUID (offline-generated items have no server-side
/// artifact to review).
bool canFlagArtifact(ReviewRepository? repository, String artifactId) =>
    repository != null && _uuidPattern.hasMatch(artifactId.trim());

/// Shows the reason dialog and sends a manual flag to the teacher review queue.
/// Returns true on success. Non-blocking: the learner keeps going regardless.
Future<bool> promptAndFlag({
  required BuildContext context,
  required ReviewRepository repository,
  required String artifactType,
  required String artifactId,
}) async {
  final copy = WicaraCopyScope.read(context);
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text(copy.flagForTeacherLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              copy.flagForTeacherDescription,
              style: const TextStyle(color: WicaraColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(hintText: copy.flagReasonHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(copy.cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(dialogContext).pop(text);
            },
            child: Text(copy.sendLabel),
          ),
        ],
      );
    },
  );
  if (reason == null) return false;

  try {
    await repository.flag(
      artifactType: artifactType,
      artifactId: artifactId,
      reason: reason,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(copy.flagSentLabel)));
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(copy.flagFailedLabel)));
    }
    return false;
  }
}

/// A small learner-facing "this looks wrong" affordance that sends a manual
/// flag to the teacher review queue. Renders nothing unless [canFlagArtifact].
class FlagReviewButton extends StatefulWidget {
  const FlagReviewButton({
    required this.repository,
    required this.artifactType,
    required this.artifactId,
    this.compact = false,
    super.key,
  });

  final ReviewRepository? repository;
  final String artifactType;
  final String artifactId;
  final bool compact;

  static bool canFlag(ReviewRepository? repository, String artifactId) =>
      canFlagArtifact(repository, artifactId);

  @override
  State<FlagReviewButton> createState() => _FlagReviewButtonState();
}

class _FlagReviewButtonState extends State<FlagReviewButton> {
  bool _sending = false;
  bool _flagged = false;

  Future<void> _flag() async {
    final repository = widget.repository;
    if (repository == null || _sending || _flagged) return;
    setState(() => _sending = true);
    final ok = await promptAndFlag(
      context: context,
      repository: repository,
      artifactType: widget.artifactType,
      artifactId: widget.artifactId,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _flagged = ok || _flagged;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FlagReviewButton.canFlag(widget.repository, widget.artifactId)) {
      return const SizedBox.shrink();
    }
    final copy = WicaraCopyScope.of(context);
    final icon = _flagged ? Icons.flag : Icons.outlined_flag;
    final color = _flagged ? WicaraColors.accentMint : WicaraColors.muted;
    final label = _flagged ? copy.flaggedLabel : copy.looksWrongLabel;

    if (widget.compact) {
      return IconButton(
        tooltip: label,
        onPressed: _flagged || _sending ? null : _flag,
        icon: _sending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18, color: color),
      );
    }

    return TextButton.icon(
      onPressed: _flagged || _sending ? null : _flag,
      style: TextButton.styleFrom(foregroundColor: color),
      icon: _sending
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
