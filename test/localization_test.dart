import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wicara_mobile/src/core/localization/app_language.dart';
import 'package:wicara_mobile/src/core/localization/wicara_copy_scope.dart';
import 'package:wicara_mobile/src/features/onboarding/domain/onboarding_copy.dart';
import 'package:wicara_mobile/src/features/onboarding/domain/copy_translations.dart';
import 'package:wicara_mobile/src/features/onboarding/domain/language_codes.dart';
import 'package:wicara_mobile/src/features/onboarding/domain/onboarding_options.dart';

void main() {
  group('OnboardingCopy.forLanguage', () {
    test('recognizes every spelling of Indonesian the app produces', () {
      for (final value in const [
        'id',
        'id-ID',
        'ind',
        'indonesian',
        'bahasa',
        'Bahasa Indonesia',
      ]) {
        expect(
          OnboardingCopy.forLanguage(value).isIndonesian,
          isTrue,
          reason: '"$value" should resolve to Indonesian',
        );
      }
    });

    test('treats the other picker options as non-Indonesian', () {
      for (final option in onboardingLanguageOptions) {
        final copy = OnboardingCopy.forLanguage(option);
        expect(copy.isIndonesian, option == 'Bahasa Indonesia');
      }
    });

    test('every picker option maps to a distinct supported code', () {
      final codes = onboardingLanguageOptions
          .map(normalizeLanguageCode)
          .toList();
      expect(codes.toSet().length, onboardingLanguageOptions.length);
      for (final code in codes) {
        expect(supportedLanguageCodes, contains(code));
      }
    });

    test('unknown input falls back to English rather than leaking the code', () {
      final copy = OnboardingCopy.forLanguage('klingon');
      expect(copy.languageCode, 'en');
      expect(copy.teacherReviewLabel, 'Teacher review');
    });
  });

  group('translation coverage', () {
    test('every translated language resolves without leaking placeholders', () {
      for (final code in supportedLanguageCodes) {
        final copy = OnboardingCopy.forLanguage(code);
        expect(copy.languageCode, code);
        // Sampled keys must never come back empty or with an unfilled slot.
        for (final value in [
          copy.continueLabel,
          copy.homeLabel,
          copy.signInLabel,
          copy.teacherReviewLabel,
          copy.streakDaysLabel(3),
        ]) {
          expect(value, isNotEmpty, reason: 'empty copy for "$code"');
          expect(
            value.contains('{0}'),
            isFalse,
            reason: 'unfilled placeholder for "$code"',
          );
        }
      }
    });

    test('translated languages use their own words for covered keys', () {
      const covered = 'teacherReviewLabel';
      for (final code in ['ms', 'vi', 'th', 'fil']) {
        expect(
          copyTranslations[code], isNotNull,
          reason: 'missing translation map for "$code"',
        );
        expect(
          copyTranslations[code]![covered],
          isNotNull,
          reason: '"$code" is missing the "$covered" key',
        );
        expect(
          OnboardingCopy.forLanguage(code).teacherReviewLabel,
          copyTranslations[code]![covered],
        );
      }
    });

    test('uncovered keys fall back to English instead of breaking', () {
      // `appTitle` is deliberately untranslated (brand name).
      for (final code in ['ms', 'vi', 'th', 'fil']) {
        expect(OnboardingCopy.forLanguage(code).appTitle, 'Wicara');
      }
    });

    test('every copy key declared in source is translated everywhere', () {
      // Reads the source so a newly added `_t`/`_tf` member fails this test
      // until all four ASEAN languages carry a translation for it.
      final declared = <String>{};
      final sources = <String, String>{
        '': 'lib/src/features/onboarding/domain/onboarding_copy.dart',
        'workspace.':
            'lib/src/features/workspace/presentation/workspace_modules_page.dart',
      };
      final pattern = RegExp(r"_tf?\(\s*'([\w.]+)',\s*\n?\s*en:");
      sources.forEach((prefix, path) {
        final text = File(path).readAsStringSync();
        for (final match in pattern.allMatches(text)) {
          declared.add('$prefix${match.group(1)}');
        }
      });
      expect(declared, isNotEmpty, reason: 'copy sources should declare keys');

      for (final code in const ['ms', 'vi', 'th', 'fil']) {
        final missing = declared.difference(copyTranslations[code]!.keys.toSet());
        expect(
          missing,
          isEmpty,
          reason: '"$code" is missing ${missing.length} translations',
        );
      }
    });

    test('all four languages carry an identical key set', () {
      final reference = copyTranslations['ms']!.keys.toSet();
      for (final code in const ['vi', 'th', 'fil']) {
        expect(
          copyTranslations[code]!.keys.toSet(),
          reference,
          reason: '"$code" key set diverged from "ms"',
        );
      }
    });

    test('reports coverage per language', () {
      final total = copyTranslations['ms']!.length;
      for (final code in ['ms', 'vi', 'th', 'fil']) {
        final n = copyTranslations[code]!.length;
        // ignore: avoid_print
        print('  coverage[$code] = $n keys');
        expect(
          n, total,
          reason: '"$code" is out of sync with the other languages',
        );
      }
    });
  });

  group('copy coverage', () {
    // A representative slice of the surfaces that used to be English-only or
    // Indonesian-only. Each must differ between the two languages.
    final indonesian = OnboardingCopy.forLanguage('Bahasa Indonesia');
    final english = OnboardingCopy.forLanguage('English');

    final samples = <String, String Function(OnboardingCopy copy)>{
      'teacher review': (OnboardingCopy c) => c.teacherReviewLabel,
      'insights': (OnboardingCopy c) => c.insightsLabel,
      'edge AI settings': (OnboardingCopy c) => c.edgeAiSettingsTitle,
      'canvas clear': (OnboardingCopy c) => c.canvasClearTitle,
      'video failed': (OnboardingCopy c) => c.videoFailedToLoadLabel,
      'server timeout': (OnboardingCopy c) => c.serverTimeoutLabel,
      'offline notes': (OnboardingCopy c) => c.offlineWritingNotesLabel,
      'pretest loading': (OnboardingCopy c) => c.loadingPretestLabel,
      'tutor hint': (OnboardingCopy c) => c.tutorHintGenericLabel,
      'flag for teacher': (OnboardingCopy c) => c.flagForTeacherLabel,
    };

    for (final entry in samples.entries) {
      test('${entry.key} differs between languages', () {
        final id = entry.value(indonesian);
        final en = entry.value(english);
        expect(id, isNotEmpty);
        expect(en, isNotEmpty);
        expect(id, isNot(equals(en)));
      });
    }

    test(
      'fallback knowledge graph labels translate, unknown labels pass through',
      () {
        expect(
          indonesian.knowledgeGraphLabel('Derivative Rules'),
          'Aturan Turunan',
        );
        expect(
          english.knowledgeGraphLabel('Derivative Rules'),
          'Derivative Rules',
        );
        expect(
          indonesian.knowledgeGraphLabel('Backend Provided Title'),
          'Backend Provided Title',
        );
      },
    );

    test('review enum labels translate and unknown values are humanized', () {
      expect(
        indonesian.reviewArtifactLabel('low_confidence'),
        'Keyakinan rendah',
      );
      expect(english.reviewArtifactLabel('low_confidence'), 'Low confidence');
      expect(
        indonesian.reviewArtifactLabel('some_new_state'),
        'Some new state',
      );
    });
  });

  group('AppLanguage', () {
    tearDown(() => AppLanguage.preferred = 'English');

    test('exposes copy for the current language and refreshes on change', () {
      AppLanguage.preferred = 'English';
      expect(AppLanguage.copy.isIndonesian, isFalse);

      AppLanguage.preferred = 'Bahasa Indonesia';
      expect(AppLanguage.copy.isIndonesian, isTrue);
      expect(AppLanguage.copy.serverTimeoutLabel, contains('Server WICARA'));
    });

    test('ignores blank updates', () {
      AppLanguage.preferred = 'Bahasa Indonesia';
      AppLanguage.preferred = '   ';
      expect(AppLanguage.copy.isIndonesian, isTrue);
    });
  });

  group('WicaraCopyScope', () {
    testWidgets('serves the installed copy to descendants', (tester) async {
      await tester.pumpWidget(
        WicaraCopyScope(
          copy: OnboardingCopy.forLanguage('Bahasa Indonesia'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) =>
                  Text(WicaraCopyScope.of(context).teacherReviewLabel),
            ),
          ),
        ),
      );

      expect(find.text('Tinjauan guru'), findsOneWidget);
    });

    testWidgets('falls back to English when no scope is installed', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) =>
                Text(WicaraCopyScope.of(context).teacherReviewLabel),
          ),
        ),
      );

      expect(find.text('Teacher review'), findsOneWidget);
    });
  });
}
