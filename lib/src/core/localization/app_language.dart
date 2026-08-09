import '../../features/onboarding/domain/onboarding_copy.dart';

/// App-wide mirror of the learner's preferred language.
///
/// Widgets should read copy from `WicaraCopyScope`. This holder exists for the
/// layers that run outside the widget tree — the HTTP client, repositories, and
/// the offline pretest engine — which still produce learner-facing text.
///
/// `WicaraApp` keeps it in sync with the onboarding profile.
class AppLanguage {
  AppLanguage._();

  static String _preferred = 'English';

  static String get preferred => _preferred;

  static set preferred(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _preferred) {
      return;
    }
    _preferred = trimmed;
    _copy = null;
  }

  static OnboardingCopy? _copy;

  /// Copy for the current language, rebuilt only when the language changes.
  static OnboardingCopy get copy =>
      _copy ??= OnboardingCopy.forLanguage(_preferred);
}
