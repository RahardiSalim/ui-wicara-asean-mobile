import 'package:flutter_test/flutter_test.dart';
import 'package:wicara_mobile/src/features/offline_pretest/domain/local_pretest_decision_engine.dart';

const target = 'baseline';
const prerequisite1 = 'prerequisite.1';
const prerequisite2 = 'prerequisite.2';

void main() {
  group('LocalPretestDecisionEngine', () {
    test('baseline medium correct asks hard', () {
      final result = _decide(
        _state(),
        conceptCode: target,
        difficulty: 'medium',
        isCorrect: true,
      );

      expect(result.action, {
        'type': 'next_question',
        'concept_code': target,
        'difficulty': 'hard',
        'reason': 'target_medium_correct',
      });
    });

    for (final hardIsCorrect in [true, false]) {
      test('baseline hard finalizes when correct is $hardIsCorrect', () {
        final result = _decide(
          _state(),
          conceptCode: target,
          difficulty: 'hard',
          isCorrect: hardIsCorrect,
        );

        expect(result.action['type'], 'finalize');
        expect(
          result.action['reason'],
          hardIsCorrect ? 'target_ready' : 'target_reinforcement',
        );
      });
    }

    for (final easyIsCorrect in [true, false]) {
      test(
        'baseline medium wrong then easy=$easyIsCorrect enters prerequisite',
        () {
          final state = _state();
          final mediumResult = _decide(
            state,
            conceptCode: target,
            difficulty: 'medium',
            isCorrect: false,
          );
          state['node_results'] = {
            target: {
              'medium': 'wrong',
              'easy': easyIsCorrect ? 'correct' : 'wrong',
            },
          };

          final easyResult = _decide(
            state,
            conceptCode: target,
            difficulty: 'easy',
            isCorrect: easyIsCorrect,
          );

          expect(mediumResult.action['difficulty'], 'easy');
          expect(easyResult.action, {
            'type': 'next_question',
            'concept_code': prerequisite1,
            'difficulty': 'medium',
            'reason': 'enter_prerequisite_node',
          });
        },
      );
    }

    for (final easyIsCorrect in [true, false]) {
      test(
        'prerequisite medium wrong then easy=$easyIsCorrect enters next prerequisite',
        () {
          final state = _state()
            ..['current_concept_code'] = prerequisite1
            ..['probe_queue'] = [_probe(prerequisite2, depth: 2, priority: 0.4)]
            ..['node_results'] = {
              target: {'medium': 'wrong', 'easy': 'wrong'},
              prerequisite1: {
                'medium': 'wrong',
                'easy': easyIsCorrect ? 'correct' : 'wrong',
              },
            };

          final mediumResult = _decide(
            state,
            conceptCode: prerequisite1,
            difficulty: 'medium',
            isCorrect: false,
          );
          final easyResult = _decide(
            state,
            conceptCode: prerequisite1,
            difficulty: 'easy',
            isCorrect: easyIsCorrect,
          );

          expect(mediumResult.action['difficulty'], 'easy');
          expect(easyResult.action['concept_code'], prerequisite2);
          expect(easyResult.action['difficulty'], 'medium');
        },
      );
    }

    for (final hardIsCorrect in [true, false]) {
      test(
        'prerequisite medium correct then hard=$hardIsCorrect finalizes',
        () {
          final state = _state()..['current_concept_code'] = prerequisite1;

          final mediumResult = _decide(
            state,
            conceptCode: prerequisite1,
            difficulty: 'medium',
            isCorrect: true,
          );
          final hardResult = _decide(
            state,
            conceptCode: prerequisite1,
            difficulty: 'hard',
            isCorrect: hardIsCorrect,
          );

          expect(mediumResult.action['difficulty'], 'hard');
          expect(hardResult.action, {
            'type': 'finalize',
            'reason': 'prerequisite_strength_checked',
          });
        },
      );
    }

    test('question cap stops before an eleventh question', () {
      final state = _state()..['question_count'] = 10;

      final result = _decide(
        state,
        conceptCode: prerequisite1,
        difficulty: 'easy',
        isCorrect: false,
      );

      expect(result.action, {
        'type': 'finalize',
        'reason': 'max_questions_reached',
      });
    });

    test('high confidence does not interrupt prerequisite cycle', () {
      final state = _state()
        ..['current_concept_code'] = prerequisite1
        ..['confidence'] = 0.99;

      final result = _decide(
        state,
        conceptCode: prerequisite1,
        difficulty: 'medium',
        isCorrect: false,
      );

      expect(result.action['type'], 'next_question');
      expect(result.action['difficulty'], 'easy');
    });
  });
}

({Map<String, dynamic> state, Map<String, dynamic> action}) _decide(
  Map<String, dynamic> state, {
  required String conceptCode,
  required String difficulty,
  required bool isCorrect,
}) {
  return LocalPretestDecisionEngine().decide(
    state,
    lastConceptCode: conceptCode,
    lastDifficulty: difficulty,
    lastIsCorrect: isCorrect,
    graphScope: _graphScope(),
  );
}

Map<String, dynamic> _state() {
  return {
    'target_concept_code': target,
    'current_concept_code': target,
    'current_difficulty': 'medium',
    'question_count': 1,
    'max_questions': 10,
    'max_nodes_visited': 5,
    'confidence': 0.0,
    'confidence_threshold': 0.95,
    'probe_queue': [
      _probe(prerequisite1, depth: 1, priority: 0.7),
      _probe(prerequisite2, depth: 2, priority: 0.4),
    ],
    'node_results': <String, dynamic>{},
  };
}

Map<String, dynamic> _graphScope() {
  return {
    'nodes': [
      {
        'concept_code': target,
        'concept_id': 'target-id',
        'role': 'target',
        'depth': 0,
        'parent': null,
      },
      {
        'concept_code': prerequisite1,
        'concept_id': 'p1-id',
        'role': 'prerequisite',
        'depth': 1,
        'parent': target,
      },
      {
        'concept_code': prerequisite2,
        'concept_id': 'p2-id',
        'role': 'prerequisite',
        'depth': 2,
        'parent': prerequisite1,
      },
    ],
    'edges': [
      {'from': target, 'to': prerequisite1, 'weight': 0.9},
      {'from': prerequisite1, 'to': prerequisite2, 'weight': 0.8},
    ],
  };
}

Map<String, dynamic> _probe(
  String conceptCode, {
  required int depth,
  required double priority,
}) {
  return {'concept_code': conceptCode, 'depth': depth, 'priority': priority};
}
