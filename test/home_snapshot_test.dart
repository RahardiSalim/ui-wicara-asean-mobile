import 'package:flutter_test/flutter_test.dart';
import 'package:wicara_mobile/src/features/home/domain/home_snapshot.dart';

void main() {
  test('workspace target is absent when backend returns no queue or track', () {
    expect(_snapshot().firstWorkspaceTarget, isNull);
  });

  test('workspace target comes from a backend-ready module', () {
    final snapshot = _snapshot(
      activeTracks: const [
        LearningTrackSummary(
          id: 'track-backend',
          subjectCode: 'matematika',
          subjectName: 'Matematika',
          title: 'Turunan',
          status: 'active',
          progressPercent: 25,
          modules: [
            LearningTrackModuleSummary(
              id: 'module-chain-rule',
              title: 'Aturan rantai',
              description: 'Repair prerequisite gap',
              status: 'ready',
              estimatedMinutes: 14,
            ),
          ],
        ),
      ],
    );

    expect(snapshot.firstWorkspaceTarget?.trackId, 'track-backend');
    expect(snapshot.firstWorkspaceTarget?.moduleId, 'module-chain-rule');
  });
}

HomeSnapshot _snapshot({List<LearningTrackSummary> activeTracks = const []}) {
  return HomeSnapshot(
    displayName: 'Learner',
    streakDays: 0,
    country: 'Indonesia',
    educationLevel: 'senior_high',
    gradeLevel: '11',
    preferredLanguage: 'Indonesian',
    studyGoal: '',
    dailyStudyTime: '',
    selectedSubjects: const ['Matematika'],
    availableSubjects: const ['Matematika'],
    onboardingCompleted: true,
    activeTracks: activeTracks,
  );
}
