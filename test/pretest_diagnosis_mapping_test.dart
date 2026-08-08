import 'package:flutter_test/flutter_test.dart';
import 'package:wicara_mobile/src/features/pretest/data/api_pretest_repository.dart';

void main() {
  test('keeps answer score separate from adaptive mastery', () {
    final state = knowledgeStateFromDiagnosis({
      'target': {'title': 'Sketsa kurva', 'status': 'fragile'},
      'summary': 'Metode masih perlu diperkuat.',
      'recommended_path': 'target_from_basics',
      'pure_answer_score': 2,
      'pure_answer_total': 2,
      'pure_answer_percent': 100,
      'target_mastery_estimate_percent': 45,
      'adaptive_mastery_estimate_percent': 45,
      'overall_mastery_percent': 45,
      'analysis': <String, dynamic>{},
      'nodes': <Map<String, dynamic>>[],
    });

    expect(state.pathMeta, contains('100%'));
    expect(state.masteryScore, 0.45);
    expect(state.overallMasteryPercent, 45);
  });
}
