/// Language handling shared by every copy surface in the app.
///
/// Mirrors `app/core/language.py` on the backend so a code chosen here always
/// round-trips: the backend localizes *content* for the same six languages.
library;

/// Supported ASEAN languages. English is the universal fallback.
const supportedLanguageCodes = <String>['en', 'id', 'ms', 'vi', 'th', 'fil'];

const _aliases = <String, String>{
  'en': 'en', 'en-us': 'en', 'en-gb': 'en', 'eng': 'en', 'english': 'en',
  'id': 'id', 'id-id': 'id', 'ind': 'id', 'indo': 'id', 'indonesian': 'id',
  'bahasa': 'id', 'bahasa indonesia': 'id',
  'ms': 'ms', 'ms-my': 'ms', 'msa': 'ms', 'may': 'ms', 'malay': 'ms',
  'melayu': 'ms', 'bahasa melayu': 'ms',
  'vi': 'vi', 'vi-vn': 'vi', 'vie': 'vi', 'vietnamese': 'vi',
  'tieng viet': 'vi', 'tiếng việt': 'vi',
  'th': 'th', 'th-th': 'th', 'tha': 'th', 'thai': 'th', 'ภาษาไทย': 'th',
  'fil': 'fil', 'fil-ph': 'fil', 'tl': 'fil', 'tl-ph': 'fil', 'tgl': 'fil',
  'filipino': 'fil', 'tagalog': 'fil',
};

/// Normalizes any language label or code to one of [supportedLanguageCodes].
String normalizeLanguageCode(String? language, {String fallback = 'en'}) {
  final normalized = (language ?? '').trim().toLowerCase().replaceAll('_', '-');
  if (normalized.isEmpty) {
    return supportedLanguageCodes.contains(fallback) ? fallback : 'en';
  }
  final direct = _aliases[normalized];
  if (direct != null) {
    return direct;
  }
  final base = normalized.split('-').first;
  final byBase = _aliases[base];
  if (byBase != null) {
    return byBase;
  }
  if (normalized.contains('indo')) {
    return 'id';
  }
  return supportedLanguageCodes.contains(fallback) ? fallback : 'en';
}

/// Native name of a language, for display in the picker and profile.
String languageEndonym(String code) => switch (normalizeLanguageCode(code)) {
  'id' => 'Bahasa Indonesia',
  'ms' => 'Bahasa Melayu',
  'vi' => 'Tiếng Việt',
  'th' => 'ภาษาไทย',
  'fil' => 'Filipino',
  _ => 'English',
};
