import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../application/analytics_controller.dart';
import '../domain/analytics_models.dart';

/// Long-term learning insights: cross-subject mastery, velocity & streaks,
/// multi-period trends, and at-risk concepts.
class InsightsPage extends StatefulWidget {
  const InsightsPage({required this.repository, super.key});

  final AnalyticsRepository repository;

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late final AnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnalyticsController(repository: widget.repository);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _pct(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final copy = WicaraCopyScope.of(context);
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      appBar: AppBar(
        title: Text(copy.insightsLabel),
        backgroundColor: Colors.white,
        foregroundColor: WicaraColors.ink,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.overview == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null && _controller.overview == null) {
            return _errorState(copy, _controller.error!);
          }
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _headline(copy),
                const SizedBox(height: 16),
                _crossSubject(copy),
                const SizedBox(height: 16),
                _velocity(copy),
                const SizedBox(height: 16),
                _trends(copy),
                const SizedBox(height: 16),
                _atRisk(copy),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorState(OnboardingCopy copy, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.show_chart, size: 48, color: WicaraColors.softMuted),
          const SizedBox(height: 12),
          Text(
            copy.insightsUnavailableLabel,
            style: const TextStyle(
              color: WicaraColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WicaraColors.muted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _controller.load(),
            icon: const Icon(Icons.refresh),
            label: Text(copy.retryLabel),
          ),
        ],
      ),
    ),
  );

  Widget _headline(OnboardingCopy copy) {
    final o = _controller.overview;
    final v = _controller.velocity;
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
            copy.overallMasteryLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            o == null ? '—' : _pct(o.overallAvgMastery),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            o == null
                ? ''
                : copy.insightsSummaryLabel(
                    o.subjectsStudied,
                    o.conceptsTracked,
                    o.totalAttempts,
                  ),
            style: const TextStyle(color: Colors.white70),
          ),
          if (v != null) ...[
            const SizedBox(height: 4),
            Text(
              copy.streakSummaryLabel(
                v.currentStreakDays,
                v.longestStreakDays,
                v.activeDays,
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _crossSubject(OnboardingCopy copy) {
    final subjects = _controller.overview?.subjects ?? const <SubjectMastery>[];
    return _card(copy.masteryBySubjectLabel, [
      if (subjects.isEmpty)
        Text(
          copy.noSubjectDataLabel,
          style: const TextStyle(color: WicaraColors.muted),
        )
      else
        ...subjects.map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.subjectLabel(s.subjectName),
                        style: const TextStyle(
                          color: WicaraColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_pct(s.avgMastery)} · ${copy.masteredCountLabel(s.mastered, s.conceptsTracked)}',
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
                    value: s.avgMastery.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: WicaraColors.primarySoft,
                    valueColor: const AlwaysStoppedAnimation(
                      WicaraColors.primaryDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _velocity(OnboardingCopy copy) {
    final v = _controller.velocity;
    if (v == null) return const SizedBox.shrink();
    return Row(
      children: [
        _stat(
          copy.masteredLabel,
          '${v.conceptsMastered}/${v.conceptsTracked}',
          WicaraColors.accentMint,
        ),
        const SizedBox(width: 10),
        _stat(
          copy.currentStreakLabel,
          copy.streakDaysShortLabel(v.currentStreakDays),
          WicaraColors.accentCoral,
        ),
        const SizedBox(width: 10),
        _stat(
          copy.attemptsPerDayLabel,
          v.avgAttemptsPerActiveDay.toStringAsFixed(1),
          WicaraColors.accentAmber,
        ),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _trends(OnboardingCopy copy) {
    final t = _controller.trends;
    final points = t?.points ?? const <TrendPoint>[];
    final maxScore = points.fold<int>(1, (a, p) => p.score > a ? p.score : a);
    return _card(copy.scoreTrendLabel, [
      Row(
        children: [
          Text(
            copy.periodLabel,
            style: const TextStyle(color: WicaraColors.muted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          for (final period in const ['month', 'all'])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(copy.trendPeriodLabel(period)),
                selected: _controller.trendPeriod == period,
                onSelected: (_) => _controller.setTrendPeriod(period),
                selectedColor: WicaraColors.primaryDeep,
                backgroundColor: WicaraColors.primarySoft,
                labelStyle: TextStyle(
                  color: _controller.trendPeriod == period
                      ? Colors.white
                      : WicaraColors.text,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (points.isEmpty)
        Text(
          copy.notEnoughHistoryLabel,
          style: const TextStyle(color: WicaraColors.muted),
        )
      else
        ...points.map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    p.period,
                    style: const TextStyle(
                      color: WicaraColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (p.score / maxScore).clamp(0, 1),
                      minHeight: 12,
                      backgroundColor: WicaraColors.primarySoft,
                      valueColor: const AlwaysStoppedAnimation(
                        WicaraColors.primaryDeep,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${p.score}',
                  style: const TextStyle(color: WicaraColors.ink, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _atRisk(OnboardingCopy copy) {
    final items = _controller.atRisk?.items ?? const <AtRiskItem>[];
    final total = _controller.atRisk?.totalAtRisk ?? 0;
    return _card(copy.needsReviewLabel(total), [
      if (items.isEmpty)
        Text(
          copy.nothingAtRiskLabel,
          style: const TextStyle(color: WicaraColors.muted),
        )
      else
        ...items.map(
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: WicaraColors.accentCoral,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WicaraColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        copy.atRiskDetailLabel(
                          copy.subjectLabel(i.subjectName),
                          _pct(i.mastery),
                          i.overdueDays != null && i.overdueDays! > 0
                              ? copy.overdueSuffixLabel(i.overdueDays!.round())
                              : '',
                        ),
                        style: const TextStyle(
                          color: WicaraColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _card(String title, List<Widget> children) => Container(
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
