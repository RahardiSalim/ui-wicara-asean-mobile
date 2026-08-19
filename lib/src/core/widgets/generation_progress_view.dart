import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wicara_colors.dart';

/// One labelled step in a [GenerationProgressView].
class GenerationStage {
  const GenerationStage({
    required this.label,
    required this.icon,
    required this.weight,
  });

  final String label;
  final IconData icon;

  /// Relative share of the expected wait this stage occupies. Weights are
  /// normalised, so they only need to be sensible against each other.
  final double weight;
}

/// Full-bleed progress surface for operations that take minutes rather than
/// milliseconds, such as generating an adaptive pretest.
///
/// The backend exposes no incremental progress for these calls, so the bar is
/// driven by elapsed time against [expectedDuration] on a decaying curve: it
/// advances quickly at first and keeps creeping afterwards, but never reaches
/// the end on its own. Only the caller completing the work fills it. That way
/// a slow run looks slow instead of looking finished and stuck.
class GenerationProgressView extends StatefulWidget {
  const GenerationProgressView({
    required this.title,
    required this.subtitle,
    required this.stages,
    required this.expectedDuration,
    this.heroAsset,
    this.footnote,
    this.tips = const <String>[],
    super.key,
  });

  final String title;
  final String subtitle;
  final List<GenerationStage> stages;
  final Duration expectedDuration;
  final String? heroAsset;
  final String? footnote;
  final List<String> tips;

  @override
  State<GenerationProgressView> createState() => _GenerationProgressViewState();
}

class _GenerationProgressViewState extends State<GenerationProgressView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Stopwatch _elapsed = Stopwatch();

  @override
  void initState() {
    super.initState();
    _elapsed.start();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.stop();
    super.dispose();
  }

  /// Approaches 1 asymptotically, so the bar never claims to be done.
  double get _progress {
    final expected = widget.expectedDuration.inMilliseconds;
    if (expected <= 0) {
      return 0;
    }
    final ratio = _elapsed.elapsedMilliseconds / expected;
    return 1 - math.exp(-1.9 * ratio);
  }

  int get _activeStageIndex {
    final stages = widget.stages;
    if (stages.isEmpty) {
      return 0;
    }
    final total = stages.fold<double>(0, (sum, stage) => sum + stage.weight);
    if (total <= 0) {
      return 0;
    }
    final reached = _progress * total;
    var running = 0.0;
    for (var i = 0; i < stages.length; i++) {
      running += stages[i].weight;
      if (reached < running) {
        return i;
      }
    }
    return stages.length - 1;
  }

  String get _elapsedLabel {
    final seconds = _elapsed.elapsed.inSeconds;
    final minutes = seconds ~/ 60;
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, _) {
        final progress = _progress;
        final activeIndex = _activeStageIndex;
        return Container(
          color: WicaraColors.pageBackground,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Hero(asset: widget.heroAsset, pulse: _ticker.value),
                      const SizedBox(height: 26),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: WicaraColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WicaraColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _ProgressBar(value: progress),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).clamp(0, 99).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: WicaraColors.primaryDeep,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            _elapsedLabel,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: WicaraColors.softMuted,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      for (var i = 0; i < widget.stages.length; i++) ...[
                        _StageRow(
                          stage: widget.stages[i],
                          state: i < activeIndex
                              ? _StageState.done
                              : i == activeIndex
                              ? _StageState.active
                              : _StageState.pending,
                          spin: _ticker.value,
                        ),
                        if (i != widget.stages.length - 1)
                          const SizedBox(height: 4),
                      ],
                      if (widget.tips.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _TipCard(
                          tip: widget
                              .tips[(_elapsed.elapsed.inSeconds ~/ 8) %
                                  widget.tips.length],
                        ),
                      ],
                      if (widget.footnote != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          widget.footnote!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: WicaraColors.softMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.asset, required this.pulse});

  final String? asset;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final breathe = math.sin(pulse * 2 * math.pi);
    return SizedBox(
      height: 148,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + breathe * 0.05,
              child: Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WicaraColors.primarySoft,
                      WicaraColors.secondarySoft,
                    ],
                  ),
                ),
              ),
            ),
            Transform.rotate(
              angle: pulse * 2 * math.pi,
              child: CustomPaint(
                size: const Size(148, 148),
                painter: _OrbitPainter(),
              ),
            ),
            Transform.translate(
              offset: Offset(0, breathe * 4),
              child: asset == null
                  ? const Icon(
                      Icons.auto_awesome_rounded,
                      size: 54,
                      color: WicaraColors.primaryDeep,
                    )
                  : Image.asset(
                      asset!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          WicaraColors.primary,
          WicaraColors.secondary,
          WicaraColors.primary,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 0.6,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * 0.35,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 10, color: WicaraColors.primarySoft),
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                height: 10,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WicaraColors.primary,
                      WicaraColors.secondary,
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _StageState { done, active, pending }

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.state,
    required this.spin,
  });

  final GenerationStage stage;
  final _StageState state;
  final double spin;

  @override
  Widget build(BuildContext context) {
    final isDone = state == _StageState.done;
    final isActive = state == _StageState.active;
    final foreground = isDone
        ? WicaraColors.accentMint
        : isActive
        ? WicaraColors.primaryDeep
        : WicaraColors.softMuted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: state == _StageState.pending ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isActive)
                    Transform.rotate(
                      angle: spin * 2 * math.pi,
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            WicaraColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? WicaraColors.mint
                          : isActive
                          ? WicaraColors.primarySoft
                          : WicaraColors.line,
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : stage.icon,
                      size: 15,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stage.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isActive ? WicaraColors.ink : WicaraColors.text,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: Container(
        key: ValueKey(tip),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: WicaraColors.glowLemon.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: WicaraColors.accentAmber,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tip,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WicaraColors.text,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
