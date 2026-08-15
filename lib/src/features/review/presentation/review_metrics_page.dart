import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../application/review_controller.dart';
import '../domain/review_models.dart';
import 'review_widgets.dart';

/// "How often is human correction needed" dashboard.
class ReviewMetricsPage extends StatefulWidget {
  const ReviewMetricsPage({required this.repository, super.key});

  final ReviewRepository repository;

  @override
  State<ReviewMetricsPage> createState() => _ReviewMetricsPageState();
}

class _ReviewMetricsPageState extends State<ReviewMetricsPage> {
  late final ReviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReviewController(repository: widget.repository);
    _controller.loadMetrics();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _pct(double value) => '${(value * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final copy = WicaraCopyScope.of(context);
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      appBar: AppBar(
        title: Text(copy.correctionMetricsLabel),
        backgroundColor: Colors.white,
        foregroundColor: WicaraColors.ink,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoadingMetrics && _controller.metrics == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final metrics = _controller.metrics;
          if (metrics == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _controller.metricsError ?? copy.noMetricsYetLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WicaraColors.muted),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _controller.loadMetrics,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _headline(copy, metrics),
                const SizedBox(height: 12),
                _smallStats(copy, metrics),
                const SizedBox(height: 16),
                _byTypeSection(copy, metrics),
                const SizedBox(height: 16),
                _triggerSection(copy, metrics),
                const SizedBox(height: 16),
                _timeSeriesSection(copy, metrics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headline(OnboardingCopy copy, ReviewMetrics m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WicaraColors.primaryDeep, WicaraColors.secondaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.humanCorrectionRateLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _pct(m.correctionRate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            copy.correctedOfReviewedLabel(m.correctedTotal, m.reviewedTotal),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _smallStats(OnboardingCopy copy, ReviewMetrics m) {
    return Row(
      children: [
        _statCard(
          copy.approvedLabel,
          _pct(m.approvalRate),
          WicaraColors.accentMint,
        ),
        const SizedBox(width: 10),
        _statCard(
          copy.rejectedLabel,
          _pct(m.rejectionRate),
          WicaraColors.accentCoral,
        ),
        const SizedBox(width: 10),
        _statCard(
          copy.backlogLabel,
          '${m.backlogOpen}',
          WicaraColors.accentAmber,
          subtitle: m.backlogOldestAgeDays != null
              ? copy.oldestBacklogLabel(
                  m.backlogOldestAgeDays!.toStringAsFixed(1),
                )
              : copy.noneOpenLabel,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color, {
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WicaraColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: WicaraColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  color: WicaraColors.softMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _byTypeSection(OnboardingCopy copy, ReviewMetrics m) {
    return _card(copy.correctionRateByTypeLabel, [
      if (m.byType.isEmpty)
        Text(
          copy.noReviewedItemsLabel,
          style: const TextStyle(color: WicaraColors.muted),
        )
      else
        ...m.byType.map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.reviewArtifactLabel(t.artifactType),
                        style: const TextStyle(
                          color: WicaraColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_pct(t.correctionRate)} · ${copy.reviewedCountLabel(t.reviewed)}',
                      style: const TextStyle(
                        color: WicaraColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: t.correctionRate.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: WicaraColors.primarySoft,
                    valueColor: const AlwaysStoppedAnimation(
                      WicaraColors.primaryDeep,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
    ]);
  }

  Widget _triggerSection(OnboardingCopy copy, ReviewMetrics m) {
    return _card(copy.triggerPrecisionLabel, [
      Text(
        copy.triggerPrecisionDescription,
        style: const TextStyle(color: WicaraColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 8),
      if (m.triggerPrecision.isEmpty)
        Text(
          copy.noResolvedItemsLabel,
          style: const TextStyle(color: WicaraColors.muted),
        )
      else
        ...m.triggerPrecision.map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                TriggerBadge(trigger: t.trigger),
                const Spacer(),
                Text(
                  '${_pct(t.precision)}  (${t.caughtProblem}/${t.totalResolved})',
                  style: const TextStyle(
                    color: WicaraColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
    ]);
  }

  Widget _timeSeriesSection(OnboardingCopy copy, ReviewMetrics m) {
    final maxReviewed = m.timeSeries.fold<int>(
      1,
      (acc, p) => p.reviewed > acc ? p.reviewed : acc,
    );
    return _card(copy.lastFourteenDaysLabel, [
      if (m.timeSeries.isEmpty)
        Text(
          copy.noActivityFourteenDaysLabel,
          style: const TextStyle(color: WicaraColors.muted),
        )
      else
        ...m.timeSeries.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    p.date,
                    style: const TextStyle(
                      color: WicaraColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 14, color: WicaraColors.primarySoft),
                        FractionallySizedBox(
                          widthFactor: (p.reviewed / maxReviewed).clamp(0, 1),
                          child: Container(
                            height: 14,
                            color: WicaraColors.primaryLight,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: (p.corrected / maxReviewed).clamp(0, 1),
                          child: Container(
                            height: 14,
                            color: WicaraColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${p.corrected}/${p.reviewed}',
                  style: const TextStyle(
                    color: WicaraColors.text,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }),
      const SizedBox(height: 6),
      Text(
        copy.darkCorrectedLightReviewedLabel,
        style: const TextStyle(color: WicaraColors.softMuted, fontSize: 11),
      ),
    ]);
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
