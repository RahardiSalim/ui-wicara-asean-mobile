import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';

/// Localizes a snake_case enum value (trigger / status / type) for display,
/// falling back to a humanized version of the raw value.
String reviewLabel(BuildContext context, String raw) =>
    WicaraCopyScope.of(context).reviewArtifactLabel(raw);

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ArtifactTypeBadge extends StatelessWidget {
  const ArtifactTypeBadge({required this.type, super.key});

  final String type;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (type) {
      'question' => (
        Icons.help_outline,
        WicaraColors.primarySoft,
        WicaraColors.primaryDeep,
      ),
      'diagnosis' => (
        Icons.troubleshoot,
        WicaraColors.secondarySoft,
        WicaraColors.secondaryDeep,
      ),
      'evaluation' => (
        Icons.fact_check_outlined,
        WicaraColors.mint,
        WicaraColors.accentMint,
      ),
      _ => (Icons.category_outlined, WicaraColors.line, WicaraColors.text),
    };
    return _Pill(
      text: reviewLabel(context, type),
      background: bg,
      foreground: fg,
      icon: icon,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'open' => (WicaraColors.glowLemon, WicaraColors.accentAmber),
      'approved' => (WicaraColors.glowMint, WicaraColors.accentMint),
      'corrected' => (WicaraColors.primarySoft, WicaraColors.primaryDeep),
      'rejected' => (WicaraColors.glowPeach, WicaraColors.accentCoral),
      _ => (WicaraColors.line, WicaraColors.text),
    };
    return _Pill(
      text: reviewLabel(context, status),
      background: bg,
      foreground: fg,
    );
  }
}

class TriggerBadge extends StatelessWidget {
  const TriggerBadge({required this.trigger, super.key});

  final String trigger;

  @override
  Widget build(BuildContext context) {
    final (icon, fg) = switch (trigger) {
      'low_confidence' => (Icons.trending_down, WicaraColors.accentAmber),
      'risk_signal' => (Icons.warning_amber_rounded, WicaraColors.accentCoral),
      'sampled' => (Icons.casino_outlined, WicaraColors.secondaryDeep),
      'learner_flag' => (Icons.flag_outlined, WicaraColors.primaryDeep),
      _ => (Icons.label_outline, WicaraColors.text),
    };
    return _Pill(
      text: reviewLabel(context, trigger),
      background: WicaraColors.fieldFill,
      foreground: fg,
      icon: icon,
    );
  }
}

class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({required this.confidence, super.key});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final fg = confidence < 0.55
        ? WicaraColors.accentCoral
        : WicaraColors.accentMint;
    return _Pill(
      text: 'conf ${confidence.toStringAsFixed(2)}',
      background: WicaraColors.fieldFill,
      foreground: fg,
      icon: Icons.speed,
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({required this.priority, super.key});

  final int priority;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      text: 'P$priority',
      background: WicaraColors.fieldFill,
      foreground: WicaraColors.muted,
    );
  }
}
