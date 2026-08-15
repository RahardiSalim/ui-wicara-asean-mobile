/// Translations for the ASEAN languages beyond English and Indonesian.
///
/// English and Indonesian live inline on `OnboardingCopy`; these maps cover the
/// remaining supported languages. Any key missing here falls back to English,
/// so partial coverage never breaks a screen.
library;

import 'copy_fil.dart';
import 'copy_ms.dart';
import 'copy_th.dart';
import 'copy_vi.dart';

const copyTranslations = <String, Map<String, String>>{
  'ms': copyMs,
  'vi': copyVi,
  'th': copyTh,
  'fil': copyFil,
};
