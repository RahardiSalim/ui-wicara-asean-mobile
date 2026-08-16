import 'package:flutter/material.dart';

import '../../../core/theme/wicara_colors.dart';
import '../../analytics/domain/analytics_models.dart';
import '../domain/teacher_student_models.dart';

class StudentProgressPage extends StatefulWidget {
  const StudentProgressPage({
    required this.repository,
    required this.studentId,
    super.key,
  });

  final TeacherStudentRepository repository;
  final String studentId;

  @override
  State<StudentProgressPage> createState() => _StudentProgressPageState();
}

class _StudentProgressPageState extends State<StudentProgressPage> {
  StudentProgress? _progress;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final progress = await widget.repository.fetchStudentProgress(
        widget.studentId,
      );
      if (!mounted) return;
      setState(() => _progress = progress);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _percent(double value) => '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      appBar: AppBar(
        title: Text(_progress?.studentName ?? 'Student progress'),
        backgroundColor: Colors.white,
        foregroundColor: WicaraColors.ink,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading && _progress == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _progress == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: WicaraColors.softMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'Progress is unavailable',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: WicaraColors.muted),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final progress = _progress!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _headline(progress),
          const SizedBox(height: 14),
          _stats(progress),
          const SizedBox(height: 14),
          _subjects(progress.overview.subjects),
          const SizedBox(height: 14),
          _trends(progress.trends.points),
          const SizedBox(height: 14),
          _atRisk(progress.atRisk),
        ],
      ),
    );
  }

  Widget _headline(StudentProgress progress) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [WicaraColors.primaryDeep, WicaraColors.secondaryDeep],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progress.studentName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (progress.studentEmail != null)
          Text(
            progress.studentEmail!,
            style: const TextStyle(color: Colors.white70),
          ),
        const SizedBox(height: 18),
        const Text('Overall mastery', style: TextStyle(color: Colors.white70)),
        Text(
          _percent(progress.overview.overallAvgMastery),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _stats(StudentProgress progress) => Row(
    children: [
      _stat('Attempts', '${progress.overview.totalAttempts}'),
      const SizedBox(width: 8),
      _stat('Active days', '${progress.overview.activeDays}'),
      const SizedBox(width: 8),
      _stat('Streak', '${progress.velocity.currentStreakDays}d'),
    ],
  );

  Widget _stat(String label, String value) => Expanded(
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
            style: const TextStyle(color: WicaraColors.muted, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: WicaraColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _subjects(List<SubjectMastery> subjects) => _card(
    'Mastery by subject',
    subjects.isEmpty
        ? const [
            Text(
              'No learning evidence yet.',
              style: TextStyle(color: WicaraColors.muted),
            ),
          ]
        : subjects
              .map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subject.subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(_percent(subject.avgMastery)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: subject.avgMastery.clamp(0, 1),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.mastered} mastered · ${subject.gaps} gaps',
                        style: const TextStyle(
                          color: WicaraColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
  );

  Widget _trends(List<TrendPoint> points) => _card(
    'Monthly score trend',
    points.isEmpty
        ? const [
            Text(
              'Not enough history yet.',
              style: TextStyle(color: WicaraColors.muted),
            ),
          ]
        : points
              .map(
                (point) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(point.period),
                  subtitle: Text(
                    '${point.attempts} attempts · ${point.fixedGaps} gaps fixed',
                  ),
                  trailing: Text(
                    '${point.score}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
  );

  Widget _atRisk(AnalyticsAtRisk atRisk) => _card(
    'Needs review (${atRisk.totalAtRisk})',
    atRisk.items.isEmpty
        ? const [
            Text(
              'No concepts currently need attention.',
              style: TextStyle(color: WicaraColors.muted),
            ),
          ]
        : atRisk.items
              .map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: WicaraColors.accentCoral,
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.subjectName} · mastery ${_percent(item.mastery)}',
                  ),
                ),
              )
              .toList(),
  );

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
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
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}
