import 'copy_translations.dart';
import 'language_codes.dart';
import 'onboarding_options.dart';

/// Learner-facing copy for one language.
///
/// English and Indonesian are written inline at every call site. The other
/// supported ASEAN languages come from [copyTranslations]; anything not yet
/// translated falls back to English, so the app is always fully readable.
class OnboardingCopy {
  const OnboardingCopy._(this.languageCode);

  factory OnboardingCopy.forLanguage(String preferredLanguage) =>
      OnboardingCopy._(normalizeLanguageCode(preferredLanguage));

  /// One of [supportedLanguageCodes].
  final String languageCode;

  bool get isIndonesian => languageCode == 'id';

  /// BCP 47 tag for speech synthesis and recognition, which need a region.
  String get speechLocale => switch (languageCode) {
    'id' => 'id-ID',
    'ms' => 'ms-MY',
    'vi' => 'vi-VN',
    'th' => 'th-TH',
    'fil' => 'fil-PH',
    _ => 'en-US',
  };

  /// Resolves a plain string for the active language.
  String _t(String key, {required String en, required String id}) {
    switch (languageCode) {
      case 'en':
        return en;
      case 'id':
        return id;
      default:
        return copyTranslations[languageCode]?[key] ?? en;
    }
  }

  /// Resolves a list of strings; translations are joined with `|`.
  List<String> _tl(
    String key, {
    required List<String> en,
    required List<String> id,
  }) {
    switch (languageCode) {
      case 'en':
        return en;
      case 'id':
        return id;
      default:
        final joined = copyTranslations[languageCode]?[key];
        return joined == null ? en : joined.split('|');
    }
  }

  /// Resolves a templated string. Translations use `{0}`, `{1}` … placeholders
  /// matching [args]; [en]/[id] are already interpolated by the caller.
  String _tf(
    String key, {
    required String en,
    required String id,
    required List<Object?> args,
  }) {
    switch (languageCode) {
      case 'en':
        return en;
      case 'id':
        return id;
      default:
        final template = copyTranslations[languageCode]?[key];
        if (template == null) {
          return en;
        }
        var result = template;
        for (var i = 0; i < args.length; i++) {
          result = result.replaceAll('{$i}', '${args[i]}');
        }
        return result;
    }
  }

  String get letsSetYouUpTitle =>
      _t('letsSetYouUpTitle', en: "Let's set you up", id: 'Mari kita siapkan akunmu');
  String get letsSetYouUpSubtitle =>
      _t('letsSetYouUpSubtitle', en: 'Tell us a bit about yourself to personalize\nyour learning.', id: 'Ceritakan sedikit tentang dirimu agar\npengalaman belajarmu lebih personal.');
  String get fullNameLabel =>
      _t('fullNameLabel', en: 'Full name', id: 'Nama lengkap');
  String get countryLabel =>
      _t('countryLabel', en: 'Country', id: 'Negara');
  String get gradeLevelLabel =>
      _t('gradeLevelLabel', en: 'Grade level', id: 'Tingkat kelas');
  String get preferredLanguageLabel =>
      _t('preferredLanguageLabel', en: 'Preferred language', id: 'Bahasa pilihan');
  String get continueLabel =>
      _t('continueLabel', en: 'Continue', id: 'Lanjutkan');
  String get improveExperienceNote =>
      _t('improveExperienceNote', en: "We'll keep improving this experience\njust for you.", id: 'Kami akan terus meningkatkan pengalaman ini\nkhusus untukmu.');
  String get chooseSubjectsTitle =>
      _t('chooseSubjectsTitle', en: 'Choose your subjects', id: 'Pilih mata pelajaranmu');
  String get chooseSubjectsSubtitle =>
      _t('chooseSubjectsSubtitle', en: 'Select the subjects you want to learn.\nYou can adjust these anytime.', id: 'Pilih mata pelajaran yang ingin kamu pelajari.\nKamu bisa mengubahnya kapan saja.');
  String get customizeLaterNote =>
      _t('customizeLaterNote', en: 'You can customize more later.', id: 'Kamu bisa mengatur lebih banyak nanti.');
  String get preferencesTitle =>
      _t('preferencesTitle', en: 'How would you like to learn?', id: 'Bagaimana kamu ingin belajar?');
  String get preferencesSubtitle =>
      _t('preferencesSubtitle', en: 'Pick your preferences. You can change\nthem anytime.', id: 'Pilih preferensimu. Kamu bisa mengubahnya\nkapan saja.');
  String get studyGoalLabel =>
      _t('studyGoalLabel', en: 'Study goal', id: 'Tujuan belajar');
  String get studyGoalOptionalLabel =>
      _t('studyGoalOptionalLabel', en: 'Study goal (optional)', id: 'Tujuan belajar (opsional)');
  String get dailyStudyTimeLabel =>
      _t('dailyStudyTimeLabel', en: 'Daily study time', id: 'Waktu belajar harian');
  String get dailyStudyTimeOptionalLabel =>
      _t('dailyStudyTimeOptionalLabel', en: 'Daily study time (optional)', id: 'Waktu belajar harian (opsional)');
  String get adaptivePretestLabel =>
      _t('adaptivePretestLabel', en: 'Continue to adaptive pretest', id: 'Lanjut ke pretest adaptif');
  String get personalizePathNote =>
      _t('personalizePathNote', en: 'This helps us personalize your learning path.', id: 'Ini membantu kami mempersonalisasi jalur belajarmu.');
  String get preferenceCallout =>
      _t('preferenceCallout', en: 'WICARA adapts to you, your pace, your style,\nand your goals.', id: 'WICARA menyesuaikan denganmu, ritmemu, gayamu,\ndan tujuanmu.');
  String get profileTitle =>
      _t('profileTitle', en: 'Profile', id: 'Profil');
  String get profileSubtitle =>
      _t('profileSubtitle', en: 'Manage your learning preferences and account.', id: 'Kelola preferensi belajar dan akunmu.');
  String get homeLabel =>
      _t('homeLabel', en: 'Home', id: 'Beranda');
  String get learnLabel =>
      _t('learnLabel', en: 'Learn', id: 'Belajar');
  String get progressLabel =>
      _t('progressLabel', en: 'Progress', id: 'Progres');
  String get learningSetupTitle =>
      _t('learningSetupTitle', en: 'Learning setup', id: 'Pengaturan belajar');
  String get preferencesSectionTitle =>
      _t('preferencesSectionTitle', en: 'Preferences', id: 'Preferensi');
  String get subjectsLabel =>
      _t('subjectsLabel', en: 'Subjects', id: 'Mata pelajaran');
  String get logoutLabel =>
      _t('logoutLabel', en: 'Log out', id: 'Keluar');
  String get welcomeBack =>
      _t('welcomeBack', en: 'Welcome back,\n', id: 'Selamat datang,\n');
  String get homeSubtitle =>
      _t('homeSubtitle', en: 'Ready to continue learning and build something great today?', id: 'Siap melanjutkan belajar dan membangun sesuatu yang hebat hari ini?');
  String get learnSubtitleRecommended =>
      _t('learnSubtitleRecommended', en: 'Suggested tracks to help you reach your goals.', id: 'Rekomendasi track untuk membantumu mencapai tujuan belajar.');
  String get learnSubtitleTracks =>
      _t('learnSubtitleTracks', en: 'Explore your learning tracks or create a new one here.', id: 'Jelajahi track belajarmu atau buat track baru di sini.');
  String get learnSubtitleGallery =>
      _t('learnSubtitleGallery', en: 'Review the videos and summaries from your learning journey.', id: 'Tinjau ulang video dan ringkasan dari perjalanan belajarmu.');
  String get recommendedLabel =>
      _t('recommendedLabel', en: 'Recommended', id: 'Rekomendasi');
  String get tracksLabel =>
      _t('tracksLabel', en: 'Tracks', id: 'Track');
  String get galleryLabel =>
      _t('galleryLabel', en: 'Gallery', id: 'Galeri');
  String get todaysLearningQueueLabel =>
      _t('todaysLearningQueueLabel', en: "Today's learning queue", id: 'Antrian belajar hari ini');
  String get viewAllLabel =>
      _t('viewAllLabel', en: 'View all', id: 'Lihat semua');
  String get nextUpLabel =>
      _t('nextUpLabel', en: 'Next up', id: 'Berikutnya');
  String get continueSessionLabel =>
      _t('continueSessionLabel', en: 'Continue session', id: 'Lanjutkan sesi');
  String get wantToLearnSomethingNewLabel =>
      _t('wantToLearnSomethingNewLabel', en: 'Want to learn something new?', id: 'Ingin belajar hal baru?');
  String get exploreTracksDescription =>
      _t('exploreTracksDescription', en: 'Explore tracks you have created or start another one.', id: 'Jelajahi track yang sudah kamu buat atau mulai track lainnya.');
  String get exploreLabel =>
      _t('exploreLabel', en: 'Explore', id: 'Jelajahi');
  String get currentStreakLabel =>
      _t('currentStreakLabel', en: 'Current streak', id: 'Streak saat ini');
  String streakDaysLabel(int days) => _tf(
    'streakDaysLabel',
    en: '$days days',
    id: '$days hari',
    args: [days],
  );
  String get dailyEvaluationLabel =>
      _t('dailyEvaluationLabel', en: 'Daily evaluation', id: 'Evaluasi harian');
  String get todaysTopicLabel =>
      _t('todaysTopicLabel', en: "Today's topic: ", id: 'Topik hari ini: ');
  String get dailyEvaluationPrompt =>
      _t('dailyEvaluationPrompt', en: '. Pick a confidence score if you want, then take your daily check.', id: '. Pilih skor keyakinan jika kamu mau, lalu kerjakan cek harianmu.');
  String get notConfidentLabel =>
      _t('notConfidentLabel', en: 'Not confident', id: 'Belum yakin');
  String get veryConfidentLabel =>
      _t('veryConfidentLabel', en: 'Very confident', id: 'Sangat yakin');
  String get takeDailyEvaluationLabel =>
      _t('takeDailyEvaluationLabel', en: 'Take Daily Evaluation', id: 'Mulai Evaluasi Harian');
  String get dailyEvalsWordmark =>
      _t('dailyEvalsWordmark', en: 'Daily Evals', id: 'Evaluasi Harian');
  String get dailyEvalsQuickCheckin =>
      _t('dailyEvalsQuickCheckin', en: 'Quick check-in for today’s learning path.', id: 'Cek cepat untuk jalur belajar hari ini.');
  String get finishDailyEvalsLabel =>
      _t('finishDailyEvalsLabel', en: 'Finish Daily Evals', id: 'Selesaikan Evaluasi');
  String get nextQuestionLabel =>
      _t('nextQuestionLabel', en: 'Next question', id: 'Soal berikutnya');
  String dailyQuestionProgressLabel(int current, int total) => _tf(
    'dailyQuestionProgressLabel',
    en: '$current of $total',
    id: '$current dari $total',
    args: [current, total],
  );
  String get reviewDueLabel =>
      _t('reviewDueLabel', en: 'Review due', id: 'Review yang jatuh tempo');
  String reviewDueSummaryLabel(int count) => _tf(
    'reviewDueSummaryLabel',
    en: '$count items ready for review',
    id: '$count item siap direview',
    args: [count],
  );
  String get reviewNowLabel =>
      _t('reviewNowLabel', en: 'Review now', id: 'Review sekarang');
  String get retentionForecastLabel =>
      _t('retentionForecastLabel', en: 'Your retention forecast', id: 'Perkiraan retensimu');
  String get retentionForecastBasisLabel =>
      _t('retentionForecastBasisLabel', en: 'Based on the Ebbinghaus forgetting curve MVP.', id: 'Berdasarkan MVP kurva lupa Ebbinghaus.');
  String get retentionCoachingLabel =>
      _t('retentionCoachingLabel', en: 'Keep reviewing to move the curve up and improve long-term retention.', id: 'Terus review untuk menaikkan kurva dan memperkuat retensi jangka panjang.');
  String get highImpactLabel =>
      _t('highImpactLabel', en: 'High impact', id: 'Dampak tinggi');
  String get maintainedLabel =>
      _t('maintainedLabel', en: 'Maintained', id: 'Terjaga');
  String get evaluationCompleteLabel =>
      _t('evaluationCompleteLabel', en: 'Evaluation Complete 🎉', id: 'Evaluasi Selesai 🎉');
  String get evaluationCompleteSubtitle =>
      _t('evaluationCompleteSubtitle', en: "Great work! You're building lasting knowledge.", id: 'Kerja bagus! Kamu sedang membangun pemahaman yang bertahan lama.');
  String get reviewedLabel =>
      _t('reviewedLabel', en: 'Reviewed', id: 'Ditinjau');
  String get correctLabel =>
      _t('correctLabel', en: 'Correct', id: 'Benar');
  String get toReviewAgainLabel =>
      _t('toReviewAgainLabel', en: 'To review again', id: 'Ulangi lagi');
  String get scoreLabel =>
      _t('scoreLabel', en: 'Score', id: 'Skor');
  String get reviewedConceptsLabel =>
      _t('reviewedConceptsLabel', en: 'Reviewed concepts', id: 'Konsep yang ditinjau');
  String get noReviewedConceptsLabel =>
      _t('noReviewedConceptsLabel', en: 'No concepts reviewed yet', id: 'Belum ada konsep yang ditinjau');
  String get pendingLabel =>
      _t('pendingLabel', en: 'Pending', id: 'Menunggu');
  String get recommendedNextActionsLabel =>
      _t('recommendedNextActionsLabel', en: 'Recommended next actions', id: 'Rekomendasi langkah berikutnya');
  String get continueLearningReason =>
      _t('continueLearningReason', en: 'Go to your learning path.', id: 'Lanjutkan ke jalur belajarmu.');
  String get statusGoodLabel =>
      _t('statusGoodLabel', en: 'Good', id: 'Bagus');
  String get statusStrongLabel =>
      _t('statusStrongLabel', en: 'Strong', id: 'Kuat');
  String get statusReviewLabel =>
      _t('statusReviewLabel', en: 'Review', id: 'Tinjau');
  String get spacedRepetitionImpactLabel =>
      _t('spacedRepetitionImpactLabel', en: 'Spaced repetition impact', id: 'Dampak pengulangan berspasi');
  String get memoryStrengthenedLabel =>
      _t('memoryStrengthenedLabel', en: "You've strengthened your memory.", id: 'Memorimu makin kuat.');
  String get retentionLiftLabel =>
      _t('retentionLiftLabel', en: 'Retention Lift', id: 'Peningkatan Retensi');
  String get daysUntilNextReviewLabel =>
      _t('daysUntilNextReviewLabel', en: 'Days Until Next Review', id: 'Hari Hingga Tinjauan Berikutnya');
  String get backToHomeLabel =>
      _t('backToHomeLabel', en: 'Back to Home', id: 'Kembali ke Beranda');
  String get continueLearningLabel =>
      _t('continueLearningLabel', en: 'Continue Learning', id: 'Lanjutkan Belajar');
  String get learnSomethingNewLabel =>
      _t('learnSomethingNewLabel', en: 'Learn something new', id: 'Pelajari hal baru');
  String get newTrackDescription =>
      _t('newTrackDescription', en: 'Create a new track outside your current list.', id: 'Buat track baru di luar daftar yang sedang kamu jalani.');
  String get newTrackLabel =>
      _t('newTrackLabel', en: 'New track', id: 'Track baru');
  String get contentGalleryLabel =>
      _t('contentGalleryLabel', en: 'Content Gallery', id: 'Galeri Konten');
  String get contentGalleryDescription =>
      _t('contentGalleryDescription', en: 'All videos generated before are here, ready to replay with the notes that WICARA compiled for you.', id: 'Semua video yang pernah dibuat ada di sini, siap diputar ulang bersama catatan yang WICARA susun untukmu.');
  String get notesLabel =>
      _t('notesLabel', en: 'Notes', id: 'Catatan');
  String get cheatsheetSummaryLabel =>
      _t('cheatsheetSummaryLabel', en: 'Cheatsheet summary', id: 'Ringkasan catatan');
  String get recommendedForCurrentReadinessLabel =>
      _t('recommendedForCurrentReadinessLabel', en: 'Recommended for Calculus I based on\nyour current gaps and readiness.', id: 'Direkomendasikan untuk Calculus I berdasarkan\ngap dan kesiapanmu saat ini.');
  String get progressSubtitle =>
      _t('progressSubtitle', en: 'Start with your learning report, then explore the knowledge map.', id: 'Mulai dari laporan belajar, lalu jelajahi peta pengetahuan.');
  String get learningReportLabel =>
      _t('learningReportLabel', en: 'Learning Report', id: 'Laporan Belajar');
  String get learningReportDescription =>
      _t('learningReportDescription', en: 'Weekly performance, fixed gaps, unlocked concepts.', id: 'Performa mingguan, gap yang tertutup, dan konsep yang terbuka.');
  String get fixedShortLabel =>
      _t('fixedShortLabel', en: '+4 fixed', id: '+4 tertutup');
  String get overallLabel =>
      _t('overallLabel', en: 'Overall', id: 'Keseluruhan');
  String get applicationLabel =>
      _t('applicationLabel', en: 'Application', id: 'Penerapan');
  String get analysisLabel =>
      _t('analysisLabel', en: 'Analysis', id: 'Analisis');
  String get fixedGapsLabel =>
      _t('fixedGapsLabel', en: 'Fixed gaps', id: 'Gap tertutup');
  String get remainingGapsLabel =>
      _t('remainingGapsLabel', en: 'Remaining gaps', id: 'Sisa gap');
  String get thisWeekFixedDelta =>
      _t('thisWeekFixedDelta', en: '+4 this week', id: '+4 minggu ini');
  String get thisWeekRemainingDelta =>
      _t('thisWeekRemainingDelta', en: '-2 this week', id: '-2 minggu ini');
  String get learningReportHint =>
      _t('learningReportHint', en: 'Hover or tap a week to preview growth, fixed gaps, and memory lift.', id: 'Arahkan kursor atau ketuk satu minggu untuk melihat pertumbuhan, gap yang tertutup, dan peningkatan memori.');
  String get completeLabel =>
      _t('completeLabel', en: 'Complete', id: 'Selesai');
  String get skillGrowthLabel =>
      _t('skillGrowthLabel', en: 'Skill growth', id: 'Pertumbuhan skill');
  String retentionDeltaLabel(int retention) => _tf(
    'retentionDeltaLabel',
    en: '+$retention% retention',
    id: '+$retention% retensi',
    args: [retention],
  );
  String remainingCountLabel(int count) => _tf(
    'remainingCountLabel',
    en: '$count left',
    id: '$count tersisa',
    args: [count],
  );
  String weekLabel(int weekNumber) => _tf(
    'weekLabel',
    en: 'W$weekNumber',
    id: 'M$weekNumber',
    args: [weekNumber],
  );
  String get knowledgeMapLabel =>
      _t('knowledgeMapLabel', en: 'Knowledge Map', id: 'Peta Pengetahuan');
  String get knowledgeMapDescription =>
      _t('knowledgeMapDescription', en: 'Explore subject domains and prerequisite paths.', id: 'Jelajahi domain mata pelajaran dan jalur prasyarat.');
  String get loadingCurriculumLabel =>
      _t('loadingCurriculumLabel', en: 'Loading curriculum from backend...', id: 'Memuat kurikulum dari backend...');
  String get fallbackGraphLabel =>
      _t('fallbackGraphLabel', en: 'Static fallback graph', id: 'Graf fallback statis');
  String get liveCurriculumGraphLabel =>
      _t('liveCurriculumGraphLabel', en: 'Live knowledge graph', id: 'Graf pengetahuan langsung');
  String nodeCountLabel(int count) => _tf(
    'nodeCountLabel',
    en: '$count nodes',
    id: '$count node',
    args: [count],
  );
  String get prerequisiteLayerLabel =>
      _t('prerequisiteLayerLabel', en: 'Prerequisite layer', id: 'Lapisan prasyarat');
  String combinedLayerLabel(String first, int extraCount) => _tf(
    'combinedLayerLabel',
    en: '$first + $extraCount',
    id: '$first + $extraCount lainnya',
    args: [first, extraCount],
  );
  String get masteryConfidenceLabel =>
      _t('masteryConfidenceLabel', en: 'Mastery confidence', id: 'Kepercayaan penguasaan');
  String get aboutThisConceptLabel =>
      _t('aboutThisConceptLabel', en: 'About this concept', id: 'Tentang konsep ini');
  String get prerequisitesLabel =>
      _t('prerequisitesLabel', en: 'Prerequisites', id: 'Prasyarat');
  String get relatedConceptsLabel =>
      _t('relatedConceptsLabel', en: 'Related concepts', id: 'Konsep terkait');
  String get noDirectPrerequisiteLabel =>
      _t('noDirectPrerequisiteLabel', en: 'No direct prerequisite', id: 'Tidak ada prasyarat langsung');
  String get noDirectRelatedConceptLabel =>
      _t('noDirectRelatedConceptLabel', en: 'No direct related concept', id: 'Tidak ada konsep terkait langsung');
  String get crossSubjectConnectionsLabel =>
      _t('crossSubjectConnectionsLabel', en: 'Cross-subject connections', id: 'Koneksi antar mata pelajaran');
  String get graphOfGraphsHint =>
      _t('graphOfGraphsHint', en: 'Graph of Graphs links are visible when available.', id: 'Tautan Graph of Graphs akan terlihat saat tersedia.');
  String get conceptBridgeFallbackLabel =>
      _t('conceptBridgeFallbackLabel', en: 'Concept bridge', id: 'Jembatan konsep');
  String get relatedBadgeLabel =>
      _t('relatedBadgeLabel', en: 'RELATED', id: 'TERKAIT');
  String get conceptFallbackDescription =>
      _t('conceptFallbackDescription', en: 'Concept in the prerequisite graph.', id: 'Konsep dalam graf prasyarat.');
  String get languageLabel =>
      _t('languageLabel', en: 'Language', id: 'Bahasa');
  String get appTitle => 'Wicara';
  String get getStartedLabel =>
      _t('getStartedLabel', en: 'Get started', id: 'Mulai');
  String get alreadyHaveAccountLabel =>
      _t('alreadyHaveAccountLabel', en: 'I already have an account', id: 'Saya sudah punya akun');
  String get signInTitle =>
      _t('signInTitle', en: 'Welcome back', id: 'Selamat datang kembali');
  String get signInSubtitle =>
      _t('signInSubtitle', en: 'Sign in to continue your learning', id: 'Masuk untuk melanjutkan belajarmu');
  String get registerTitle =>
      _t('registerTitle', en: 'Create your account', id: 'Buat akunmu');
  String get registerSubtitle =>
      _t('registerSubtitle', en: 'Register once, then continue with your learning path', id: 'Daftar sekali, lalu lanjutkan perjalanan belajarmu');
  String get emailOrPhoneLabel =>
      _t('emailOrPhoneLabel', en: 'Email or phone', id: 'Email atau nomor telepon');
  String get emailOrPhoneHint =>
      _t('emailOrPhoneHint', en: 'Enter your email or phone', id: 'Masukkan email atau nomor telepon');
  String get emailLabel =>
      _t('emailLabel', en: 'Email', id: 'Email');
  String get emailHint =>
      _t('emailHint', en: 'Enter your email', id: 'Masukkan emailmu');
  String get passwordLabel =>
      _t('passwordLabel', en: 'Password', id: 'Kata sandi');
  String get passwordHint =>
      _t('passwordHint', en: 'Enter your password', id: 'Masukkan kata sandi');
  String get fullNameHint =>
      _t('fullNameHint', en: 'Enter your full name', id: 'Masukkan nama lengkapmu');
  String get forgotPasswordLabel =>
      _t('forgotPasswordLabel', en: 'Forgot password?', id: 'Lupa kata sandi?');
  String get signInLabel =>
      _t('signInLabel', en: 'Sign in', id: 'Masuk');
  String get registerLabel =>
      _t('registerLabel', en: 'Register', id: 'Daftar');
  String get logInLabel =>
      _t('logInLabel', en: 'Log in', id: 'Masuk');
  String get orContinueWithLabel =>
      _t('orContinueWithLabel', en: 'or continue with', id: 'atau lanjut dengan');
  String get bypassForWebDevLabel =>
      _t('bypassForWebDevLabel', en: 'Bypass for web dev', id: 'Lewati untuk dev web');
  String get passwordResetMockedMessage =>
      _t('passwordResetMockedMessage', en: 'Password reset is mocked for now.', id: 'Reset kata sandi masih dimock untuk sekarang.');
  String get emailRequiredMessage =>
      _t('emailRequiredMessage', en: 'Enter your email', id: 'Masukkan emailmu');
  String get fullNameRequiredMessage =>
      _t('fullNameRequiredMessage', en: 'Enter your full name', id: 'Masukkan nama lengkapmu');
  String get registrationEmailValidationMessage =>
      _t('registrationEmailValidationMessage', en: 'Use an email address for registration', id: 'Gunakan alamat email untuk pendaftaran');
  String get passwordMinLengthMessage =>
      _t('passwordMinLengthMessage', en: 'Password must be at least 6 characters', id: 'Kata sandi minimal 6 karakter');
  String get securityNoteLabel =>
      _t('securityNoteLabel', en: 'Your data is private and secure.', id: 'Datamu aman dan bersifat pribadi.');
  String get learningGoalTitle =>
      _t('learningGoalTitle', en: 'What would you like to learn?', id: 'Apa yang ingin kamu pelajari?');
  String get learningGoalSubtitle =>
      _t('learningGoalSubtitle', en: 'Type your goal first. WICARA will find the matching material node, then the pretest starts after you confirm it.', id: 'Tulis tujuanmu dulu. WICARA akan mencari node materi yang cocok, lalu pretest baru mulai setelah kamu setuju.');
  String get learningTopicLabel =>
      _t('learningTopicLabel', en: 'Learning topic', id: 'Topik belajar');
  String get generatePretestLabel =>
      _t('generatePretestLabel', en: 'Generate Pretest', id: 'Buat Pretest');
  String get typeATopicHint =>
      _t('typeATopicHint', en: 'Type a topic', id: 'Ketik topik');
  String get adaptivePretestReadyNextLabel =>
      _t('adaptivePretestReadyNextLabel', en: 'Adaptive pretest ready next', id: 'Pretest adaptif siap berikutnya');
  String get adaptivePretestReadyDescription =>
      _t('adaptivePretestReadyDescription', en: 'A few questions will calibrate your starting point.', id: 'Beberapa pertanyaan akan mengkalibrasi titik awalmu.');
  String get pretestGeneratedCompleteLabel =>
      _t('pretestGeneratedCompleteLabel', en: 'Pretest generated complete!', id: 'Pretest berhasil dibuat!');
  String get openingAdaptivePretestLabel =>
      _t('openingAdaptivePretestLabel', en: 'Opening your adaptive pretest now.', id: 'Membuka pretest adaptifmu sekarang.');
  String get confidenceQuestionLabel =>
      _t('confidenceQuestionLabel', en: 'How confident are you?', id: 'Seberapa yakin kamu?');
  String get lowLabel =>
      _t('lowLabel', en: 'Low', id: 'Rendah');
  String get highLabel =>
      _t('highLabel', en: 'High', id: 'Tinggi');
  String get yourKnowledgeStateLabel =>
      _t('yourKnowledgeStateLabel', en: 'Your knowledge state', id: 'Kondisi pengetahuanmu');
  String get basedOnYourResponsesLabel =>
      _t('basedOnYourResponsesLabel', en: 'Based on your responses.', id: 'Berdasarkan responsmu.');
  String get whatsNextLabel =>
      _t('whatsNextLabel', en: "What's next", id: 'Selanjutnya');
  String get personalizedPathGeneratedLabel =>
      _t('personalizedPathGeneratedLabel', en: 'Personalized path generated', id: 'Jalur personal berhasil dibuat');
  String get personalizedPathDescription =>
      _t('personalizedPathDescription', en: 'Start with prerequisites, then practice root-cause questions.', id: 'Mulai dari prasyarat, lalu lanjut berlatih pertanyaan akar masalah.');
  String get continueToMyPathLabel =>
      _t('continueToMyPathLabel', en: 'Continue to my path', id: 'Lanjut ke jalur saya');
  String get retakePretestAnytimeLabel =>
      _t('retakePretestAnytimeLabel', en: 'You can retake the pretest anytime.', id: 'Kamu bisa mengulang pretest kapan saja.');
  String get missingPrerequisiteGapsLabel =>
      _t('missingPrerequisiteGapsLabel', en: 'Missing prerequisite gaps', id: 'Gap prasyarat yang belum terpenuhi');
  String get currentTopicLabel =>
      _t('currentTopicLabel', en: 'Current topic', id: 'Topik saat ini');
  String get askOrReflectHereHint =>
      _t('askOrReflectHereHint', en: 'Ask or reflect here...', id: 'Tanya atau refleksikan di sini...');
  String get learnerLabel =>
      _t('learnerLabel', en: 'Learner', id: 'Siswa');
  String get searchLabel =>
      _t('searchLabel', en: 'Search', id: 'Cari');
  String get applyLabel =>
      _t('applyLabel', en: 'Apply', id: 'Terapkan');
  String get cancelLabel =>
      _t('cancelLabel', en: 'Cancel', id: 'Batal');
  String get speechReadAloud =>
      _t('speechReadAloud', en: 'Read aloud', id: 'Bacakan');
  String get speechReadAloudHint =>
      _t('speechReadAloudHint', en: 'Read this content using speech', id: 'Bacakan konten ini dengan suara');
  String get speechStop =>
      _t('speechStop', en: 'Stop speaking', id: 'Berhenti membaca');
  String get speechStopHint =>
      _t('speechStopHint', en: 'Stop active speech or voice input', id: 'Hentikan audio atau input suara yang aktif');
  String get speechPause =>
      _t('speechPause', en: 'Pause', id: 'Jeda');
  String get speechResume =>
      _t('speechResume', en: 'Resume', id: 'Lanjutkan');
  String get speechSpeed =>
      _t('speechSpeed', en: 'Speech speed', id: 'Kecepatan suara');
  String speechSpeedValue(double value) => _tf(
    'speechSpeedValue',
    en: '${value.toStringAsFixed(2)} times',
    id: '${value.toStringAsFixed(2)} kali',
    // Pass the formatted string so translated templates keep 2 decimals.
    args: [value.toStringAsFixed(2)],
  );
  String get speechVoiceInput =>
      _t('speechVoiceInput', en: 'Voice input', id: 'Input suara');
  String get speechVoiceInputHint =>
      _t('speechVoiceInputHint', en: 'Start or stop voice recording', id: 'Mulai atau hentikan perekaman suara');
  String get speechListening =>
      _t('speechListening', en: 'Listening...', id: 'Mendengarkan...');
  String get speechProcessing =>
      _t('speechProcessing', en: 'Processing...', id: 'Memproses...');
  String get speechSpeaking =>
      _t('speechSpeaking', en: 'Speaking', id: 'Sedang membaca');
  String get speechPaused =>
      _t('speechPaused', en: 'Speech paused', id: 'Bacaan dijeda');
  String get speechError =>
      _t('speechError', en: 'Speech error', id: 'Terjadi kesalahan suara');
  String get speechMicPermissionDenied =>
      _t('speechMicPermissionDenied', en: 'Microphone permission denied', id: 'Izin mikrofon ditolak');
  String get speechMicPermissionInstructions =>
      _t('speechMicPermissionInstructions', en: 'Enable microphone permission in device settings to use voice input.', id: 'Aktifkan izin mikrofon melalui pengaturan perangkat untuk memakai input suara.');
  String get speechServiceUnavailable =>
      _t('speechServiceUnavailable', en: 'Speech service unavailable', id: 'Layanan suara tidak tersedia');

  // ── Teacher review queue ────────────────────────────────────────────────
  String get teacherReviewLabel =>
      _t('teacherReviewLabel', en: 'Teacher review', id: 'Tinjauan guru');
  String get correctionMetricsLabel =>
      _t('correctionMetricsLabel', en: 'Correction metrics', id: 'Metrik koreksi');
  String get statusLabel =>
      _t('statusLabel', en: 'Status', id: 'Status');
  String get typeLabel =>
      _t('typeLabel', en: 'Type', id: 'Jenis');
  String get triggerLabel =>
      _t('triggerLabel', en: 'Trigger', id: 'Pemicu');
  String get allFilterLabel =>
      _t('allFilterLabel', en: 'all', id: 'semua');
  String get couldNotLoadQueueLabel =>
      _t('couldNotLoadQueueLabel', en: 'Could not load the queue', id: 'Antrian gagal dimuat');
  String get nothingToReviewLabel =>
      _t('nothingToReviewLabel', en: 'Nothing to review', id: 'Tidak ada yang perlu ditinjau');
  String get noAiOutputsMatchFiltersLabel =>
      _t('noAiOutputsMatchFiltersLabel', en: 'No AI outputs match these filters right now.', id: 'Tidak ada output AI yang cocok dengan filter ini.');
  String get refreshLabel =>
      _t('refreshLabel', en: 'Refresh', id: 'Muat ulang');
  String get retryLabel =>
      _t('retryLabel', en: 'Retry', id: 'Coba lagi');
  String get noSummaryLabel =>
      _t('noSummaryLabel', en: '(no summary)', id: '(tanpa ringkasan)');
  String get reviewItemLabel =>
      _t('reviewItemLabel', en: 'Review item', id: 'Item tinjauan');
  String get itemNotFoundLabel =>
      _t('itemNotFoundLabel', en: 'Item not found.', id: 'Item tidak ditemukan.');
  String get approveThisOutputLabel =>
      _t('approveThisOutputLabel', en: 'Approve this output', id: 'Setujui output ini');
  String get rejectThisOutputLabel =>
      _t('rejectThisOutputLabel', en: 'Reject this output', id: 'Tolak output ini');
  String get optionalNoteHint =>
      _t('optionalNoteHint', en: 'Optional note', id: 'Catatan opsional');
  String get whyIsItWrongHint =>
      _t('whyIsItWrongHint', en: 'Why is it wrong? (required)', id: 'Apa yang salah? (wajib diisi)');
  String get approveLabel =>
      _t('approveLabel', en: 'Approve', id: 'Setujui');
  String get rejectLabel =>
      _t('rejectLabel', en: 'Reject', id: 'Tolak');
  String get correctLabelAction =>
      _t('correctLabelAction', en: 'Correct', id: 'Koreksi');
  String get approvedLabel =>
      _t('approvedLabel', en: 'Approved', id: 'Disetujui');
  String get rejectedLabel =>
      _t('rejectedLabel', en: 'Rejected', id: 'Ditolak');
  String get correctionSavedLabel =>
      _t('correctionSavedLabel', en: 'Correction saved', id: 'Koreksi tersimpan');
  String get correctionFailedLabel =>
      _t('correctionFailedLabel', en: 'Correction failed', id: 'Koreksi gagal');
  String resolveSuccessLabel(String action) => _tf(
    'resolveSuccessLabel',
    en: '$action · learners are unaffected in real time',
    id: '$action · siswa tidak terganggu secara real time',
    args: [action],
  );
  String resolveFailureLabel(String action) => _tf(
    'resolveFailureLabel',
    en: '$action failed',
    id: '$action gagal',
    args: [action],
  );
  String get flaggedForReviewLabel =>
      _t('flaggedForReviewLabel', en: 'Flagged for review.', id: 'Ditandai untuk ditinjau.');
  String flaggedBecauseLabel(String reasons) => _tf(
    'flaggedBecauseLabel',
    en: 'Flagged because: $reasons',
    id: 'Ditandai karena: $reasons',
    args: [reasons],
  );
  String get artifactLabel =>
      _t('artifactLabel', en: 'Artifact', id: 'Artefak');
  String get artifactUnavailableLabel =>
      _t('artifactUnavailableLabel', en: 'The underlying artifact could not be loaded (it may have been removed). The review record is still available.', id: 'Artefak aslinya tidak bisa dimuat (mungkin sudah dihapus). Catatan tinjauannya tetap tersedia.');
  String get generatedQuestionLabel =>
      _t('generatedQuestionLabel', en: 'Generated question', id: 'Soal hasil generate');
  String get promptLabel =>
      _t('promptLabel', en: 'Prompt', id: 'Prompt');
  String get helperLabel =>
      _t('helperLabel', en: 'Helper', id: 'Teks bantuan');
  String get optionsLabel =>
      _t('optionsLabel', en: 'Options', id: 'Pilihan');
  String get expectedReasoningLabel =>
      _t('expectedReasoningLabel', en: 'Expected reasoning', id: 'Penalaran yang diharapkan');
  String get generationSourceLabel =>
      _t('generationSourceLabel', en: 'Generation source', id: 'Sumber generate');
  String get learningGoalDiagnosisLabel =>
      _t('learningGoalDiagnosisLabel', en: 'Learning-goal diagnosis', id: 'Diagnosis tujuan belajar');
  String get learnerAskedLabel =>
      _t('learnerAskedLabel', en: 'Learner asked', id: 'Pertanyaan siswa');
  String get subjectSingularLabel =>
      _t('subjectSingularLabel', en: 'Subject', id: 'Mata pelajaran');
  String get suggestedConceptIdLabel =>
      _t('suggestedConceptIdLabel', en: 'Suggested concept id', id: 'ID konsep yang disarankan');
  String get confidenceLabel =>
      _t('confidenceLabel', en: 'Confidence', id: 'Keyakinan');
  String get noneLabel =>
      _t('noneLabel', en: '(none)', id: '(tidak ada)');
  String get alternativesLabel =>
      _t('alternativesLabel', en: 'Alternatives', id: 'Alternatif');
  String candidateCountLabel(int count) => _tf(
    'candidateCountLabel',
    en: '$count candidate(s)',
    id: '$count kandidat',
    args: [count],
  );
  String get modelLabel =>
      _t('modelLabel', en: 'Model', id: 'Model');
  String get reasoningEvaluationLabel =>
      _t('reasoningEvaluationLabel', en: 'Reasoning evaluation', id: 'Evaluasi penalaran');
  String get learnerReasoningLabel =>
      _t('learnerReasoningLabel', en: 'Learner reasoning', id: 'Penalaran siswa');
  String get isCorrectLabel =>
      _t('isCorrectLabel', en: 'Correct?', id: 'Benar?');
  String get yesLabel =>
      _t('yesLabel', en: 'Yes', id: 'Ya');
  String get noLabel =>
      _t('noLabel', en: 'No', id: 'Tidak');
  String get answerScoreLabel =>
      _t('answerScoreLabel', en: 'Answer score', id: 'Skor jawaban');
  String get reasoningScoreLabel =>
      _t('reasoningScoreLabel', en: 'Reasoning score', id: 'Skor penalaran');
  String get evidenceScoreLabel =>
      _t('evidenceScoreLabel', en: 'Evidence score', id: 'Skor bukti');
  String get diagnosticSignalLabel =>
      _t('diagnosticSignalLabel', en: 'Diagnostic signal', id: 'Sinyal diagnostik');
  String get historyLabel =>
      _t('historyLabel', en: 'History', id: 'Riwayat');
  String correctArtifactTitle(String artifactType) => _tf(
    'correctArtifactTitle',
    en: 'Correct $artifactType',
    id: 'Koreksi ${reviewArtifactLabel(artifactType).toLowerCase()}',
    args: [artifactType],
  );
  String get saveCorrectionLabel =>
      _t('saveCorrectionLabel', en: 'Save correction', id: 'Simpan koreksi');
  String get artifactNotCorrectableLabel =>
      _t('artifactNotCorrectableLabel', en: 'This artifact type cannot be corrected.', id: 'Jenis artefak ini tidak bisa dikoreksi.');
  String get optionsTapCorrectLabel =>
      _t('optionsTapCorrectLabel', en: 'Options (tap the circle to mark the correct one)', id: 'Pilihan (ketuk lingkaran untuk menandai yang benar)');
  String optionNumberLabel(int index) => _tf(
    'optionNumberLabel',
    en: 'Option $index',
    id: 'Pilihan $index',
    args: [index],
  );
  String get overrideConceptIdLabel =>
      _t('overrideConceptIdLabel', en: 'Override the diagnosed prerequisite concept id. Confirming sets the diagnosis status to "confirmed".', id: 'Ganti ID konsep prasyarat hasil diagnosis. Mengonfirmasi akan mengubah status diagnosis menjadi "confirmed".');
  String get teacherFeedbackLabel =>
      _t('teacherFeedbackLabel', en: 'Teacher feedback', id: 'Masukan guru');
  String get auditNoteLabel =>
      _t('auditNoteLabel', en: 'Note (audit log)', id: 'Catatan (log audit)');
  String get humanCorrectionRateLabel =>
      _t('humanCorrectionRateLabel', en: 'Human correction rate', id: 'Tingkat koreksi manusia');
  String correctedOfReviewedLabel(int corrected, int reviewed) => _tf(
    'correctedOfReviewedLabel',
    en: '$corrected corrected of $reviewed reviewed',
    id: '$corrected dikoreksi dari $reviewed ditinjau',
    args: [corrected, reviewed],
  );
  String get backlogLabel =>
      _t('backlogLabel', en: 'Backlog', id: 'Antrean');
  String oldestBacklogLabel(String days) => _tf(
    'oldestBacklogLabel',
    en: 'oldest ${days}d',
    id: 'terlama ${days}h',
    args: [days],
  );
  String get noneOpenLabel =>
      _t('noneOpenLabel', en: 'none open', id: 'tidak ada terbuka');
  String get correctionRateByTypeLabel =>
      _t('correctionRateByTypeLabel', en: 'Correction rate by type', id: 'Tingkat koreksi per jenis');
  String get noReviewedItemsLabel =>
      _t('noReviewedItemsLabel', en: 'No reviewed items yet.', id: 'Belum ada item yang ditinjau.');
  String reviewedCountLabel(int count) => _tf(
    'reviewedCountLabel',
    en: '$count reviewed',
    id: '$count ditinjau',
    args: [count],
  );
  String get triggerPrecisionLabel =>
      _t('triggerPrecisionLabel', en: 'Trigger precision', id: 'Presisi pemicu');
  String get triggerPrecisionDescription =>
      _t('triggerPrecisionDescription', en: 'Of items a trigger flagged, how many turned out to need a fix (corrected or rejected). Higher = the trigger is worth a teacher\'s time.', id: 'Dari item yang ditandai sebuah pemicu, berapa yang ternyata perlu diperbaiki (dikoreksi atau ditolak). Makin tinggi = pemicu itu layak memakan waktu guru.');
  String get noResolvedItemsLabel =>
      _t('noResolvedItemsLabel', en: 'No resolved items yet.', id: 'Belum ada item yang diselesaikan.');
  String get lastFourteenDaysLabel =>
      _t('lastFourteenDaysLabel', en: 'Last 14 days', id: '14 hari terakhir');
  String get noActivityFourteenDaysLabel =>
      _t('noActivityFourteenDaysLabel', en: 'No activity in the last 14 days.', id: 'Tidak ada aktivitas dalam 14 hari terakhir.');
  String get darkCorrectedLightReviewedLabel =>
      _t('darkCorrectedLightReviewedLabel', en: 'Dark = corrected · light = reviewed', id: 'Gelap = dikoreksi · terang = ditinjau');
  String get noMetricsYetLabel =>
      _t('noMetricsYetLabel', en: 'No metrics yet.', id: 'Belum ada metrik.');

  String reviewArtifactLabel(String raw) => switch (raw) {
    'question' => _t('reviewArtifactLabel.question', en: 'Question', id: 'Soal'),
    'diagnosis' => _t('reviewArtifactLabel.diagnosis', en: 'Diagnosis', id: 'Diagnosis'),
    'evaluation' => _t('reviewArtifactLabel.evaluation', en: 'Evaluation', id: 'Evaluasi'),
    'open' => _t('reviewArtifactLabel.open', en: 'Open', id: 'Terbuka'),
    'approved' => _t('reviewArtifactLabel.approved', en: 'Approved', id: 'Disetujui'),
    'rejected' => _t('reviewArtifactLabel.rejected', en: 'Rejected', id: 'Ditolak'),
    'corrected' => _t('reviewArtifactLabel.corrected', en: 'Corrected', id: 'Dikoreksi'),
    'all' => _t('reviewArtifactLabel.all', en: 'All', id: 'Semua'),
    'low_confidence' => _t('reviewArtifactLabel.low_confidence', en: 'Low confidence', id: 'Keyakinan rendah'),
    'risk_signal' => _t('reviewArtifactLabel.risk_signal', en: 'Risk signal', id: 'Sinyal risiko'),
    'sampled' => _t('reviewArtifactLabel.sampled', en: 'Sampled', id: 'Sampel'),
    'learner_flag' => _t('reviewArtifactLabel.learner_flag', en: 'Learner flag', id: 'Tanda dari siswa'),
    _ =>
      raw.isEmpty
          ? raw
          : (raw.replaceAll('_', ' ')[0].toUpperCase() +
                raw.replaceAll('_', ' ').substring(1)),
  };

  // ── Learner flag ────────────────────────────────────────────────────────
  String get flagForTeacherLabel =>
      _t('flagForTeacherLabel', en: 'Flag for a teacher', id: 'Laporkan ke guru');
  String get flagForTeacherDescription =>
      _t('flagForTeacherDescription', en: 'Tell us what looks wrong. A teacher will review it — your learning continues either way.', id: 'Ceritakan apa yang terlihat keliru. Guru akan meninjaunya — belajarmu tetap jalan.');
  String get flagReasonHint =>
      _t('flagReasonHint', en: 'e.g. the marked answer seems wrong', id: 'misalnya jawaban yang ditandai benar terlihat salah');
  String get sendLabel =>
      _t('sendLabel', en: 'Send', id: 'Kirim');
  String get flagSentLabel =>
      _t('flagSentLabel', en: 'Sent to a teacher for review. Thanks!', id: 'Terkirim ke guru untuk ditinjau. Terima kasih!');
  String get flagFailedLabel =>
      _t('flagFailedLabel', en: 'Could not send the flag right now.', id: 'Laporan tidak bisa dikirim sekarang.');
  String get flaggedLabel =>
      _t('flaggedLabel', en: 'Flagged', id: 'Sudah dilaporkan');
  String get looksWrongLabel =>
      _t('looksWrongLabel', en: 'Looks wrong?', id: 'Terlihat keliru?');

  // ── Insights ────────────────────────────────────────────────────────────
  String get insightsLabel =>
      _t('insightsLabel', en: 'Insights', id: 'Wawasan');
  String get insightsUnavailableLabel =>
      _t('insightsUnavailableLabel', en: 'Insights unavailable', id: 'Wawasan tidak tersedia');
  String get overallMasteryLabel =>
      _t('overallMasteryLabel', en: 'Overall mastery', id: 'Penguasaan keseluruhan');
  String insightsSummaryLabel(int subjects, int concepts, int attempts) => _tf(
    'insightsSummaryLabel',
    en: '$subjects subjects · $concepts concepts · $attempts attempts',
    id: '$subjects mata pelajaran · $concepts konsep · $attempts percobaan',
    args: [subjects, concepts, attempts],
  );
  String streakSummaryLabel(int current, int longest, int activeDays) => _tf(
    'streakSummaryLabel',
    en: '🔥 $current-day streak · best $longest · $activeDays active days',
    id: '🔥 streak $current hari · terbaik $longest · $activeDays hari aktif',
    args: [current, longest, activeDays],
  );
  String get masteryBySubjectLabel =>
      _t('masteryBySubjectLabel', en: 'Mastery by subject', id: 'Penguasaan per mata pelajaran');
  String get noSubjectDataLabel =>
      _t('noSubjectDataLabel', en: 'No subject data yet.', id: 'Belum ada data mata pelajaran.');
  String masteredCountLabel(int mastered, int tracked) => _tf(
    'masteredCountLabel',
    en: '$mastered/$tracked mastered',
    id: '$mastered/$tracked dikuasai',
    args: [mastered, tracked],
  );
  String get masteredLabel =>
      _t('masteredLabel', en: 'Mastered', id: 'Dikuasai');
  String get attemptsPerDayLabel =>
      _t('attemptsPerDayLabel', en: 'Attempts/day', id: 'Percobaan/hari');
  String streakDaysShortLabel(int days) => _tf(
    'streakDaysShortLabel',
    en: '${days}d',
    id: '${days}h',
    args: [days],
  );
  String get scoreTrendLabel =>
      _t('scoreTrendLabel', en: 'Score trend', id: 'Tren skor');
  String get periodLabel =>
      _t('periodLabel', en: 'Period:', id: 'Periode:');
  String trendPeriodLabel(String period) => switch (period) {
    'month' => _t('trendPeriodLabel.month', en: 'month', id: 'bulan'),
    'all' => _t('trendPeriodLabel.all', en: 'all', id: 'semua'),
    _ => period,
  };
  String get notEnoughHistoryLabel =>
      _t('notEnoughHistoryLabel', en: 'Not enough history yet.', id: 'Riwayatnya belum cukup.');
  String needsReviewLabel(int total) => _tf(
    'needsReviewLabel',
    en: 'Needs review ($total)',
    id: 'Perlu ditinjau ($total)',
    args: [total],
  );
  String get nothingAtRiskLabel =>
      _t('nothingAtRiskLabel', en: 'Nothing at risk — nice work!', id: 'Tidak ada yang berisiko — kerja bagus!');
  String atRiskDetailLabel(String subject, String mastery, String overdue) => _tf(
    'atRiskDetailLabel',
    en: '$subject · mastery $mastery$overdue',
    id: '$subject · penguasaan $mastery$overdue',
    args: [subject, mastery, overdue],
  );
  String overdueSuffixLabel(int days) => _tf(
    'overdueSuffixLabel',
    en: ' · ${days}d overdue',
    id: ' · telat ${days}h',
    args: [days],
  );

  // ── Edge AI (local model) ───────────────────────────────────────────────
  String get edgeAiSettingsTitle =>
      _t('edgeAiSettingsTitle', en: 'Local AI settings', id: 'Pengaturan AI Lokal');
  String get edgeAiSettingsSubtitle =>
      _t('edgeAiSettingsSubtitle', en: 'Install, initialize, and test the LiteRT-LM model in one place.', id: 'Install, initialize, dan test model LiteRT-LM dari satu tempat.');
  String get edgeAiSectionLabel => 'Edge AI (LiteRT-LM)';
  String get edgeAiHideModelUrlLabel =>
      _t('edgeAiHideModelUrlLabel', en: 'Hide model URL', id: 'Sembunyikan URL model');
  String get edgeAiShowModelUrlLabel =>
      _t('edgeAiShowModelUrlLabel', en: 'Change model URL (advanced)', id: 'Ubah URL model (lanjutan)');
  String get edgeAiModelUrlLabel =>
      _t('edgeAiModelUrlLabel', en: 'Model URL (.litertlm)', id: 'URL model (.litertlm)');
  String get edgeAiInstallingLabel =>
      _t('edgeAiInstallingLabel', en: 'Installing...', id: 'Menginstal...');
  String get edgeAiInstallModelLabel =>
      _t('edgeAiInstallModelLabel', en: 'Install model', id: 'Install model');
  String get edgeAiReinstallLabel =>
      _t('edgeAiReinstallLabel', en: 'Reinstall', id: 'Install ulang');
  String get edgeAiInitializingLabel =>
      _t('edgeAiInitializingLabel', en: 'Initializing...', id: 'Menginisialisasi...');
  String get edgeAiInitializeLabel =>
      _t('edgeAiInitializeLabel', en: 'Initialize', id: 'Inisialisasi');
  String get edgeAiUnloadLabel =>
      _t('edgeAiUnloadLabel', en: 'Unload', id: 'Lepas model');
  String get edgeAiRunningLabel =>
      _t('edgeAiRunningLabel', en: 'Running...', id: 'Menjalankan...');
  String get edgeAiRunTestPromptLabel =>
      _t('edgeAiRunTestPromptLabel', en: 'Run test prompt', id: 'Jalankan prompt uji');
  String edgeAiDownloadLabel(String status) => _tf(
    'edgeAiDownloadLabel',
    en: 'Download model: $status',
    id: 'Unduh model: $status',
    args: [status],
  );
  String edgeAiDownloadedLabel(String received) => _tf(
    'edgeAiDownloadedLabel',
    en: '$received downloaded',
    id: '$received terunduh',
    args: [received],
  );
  String get edgeAiEnterModelUrlLabel =>
      _t('edgeAiEnterModelUrlLabel', en: 'Enter the model URL first.', id: 'Isi URL model terlebih dahulu.');
  String edgeAiModelAlreadyPresentLabel(String path) => _tf(
    'edgeAiModelAlreadyPresentLabel',
    en: 'The model is already on this device ($path).',
    id: 'Model sudah ada di device ($path).',
    args: [path],
  );
  String edgeAiModelReinstalledLabel(String size, int ms) => _tf(
    'edgeAiModelReinstalledLabel',
    en: 'Model reinstalled ($size in $ms ms).',
    id: 'Model di-install ulang ($size dalam $ms ms).',
    args: [size, ms],
  );
  String edgeAiModelInstalledLabel(String size, int ms) => _tf(
    'edgeAiModelInstalledLabel',
    en: 'Model installed ($size in $ms ms).',
    id: 'Model terpasang ($size dalam $ms ms).',
    args: [size, ms],
  );
  String edgeAiInstallFailedLabel(Object error) => _tf(
    'edgeAiInstallFailedLabel',
    en: 'Model install failed: $error',
    id: 'Install model gagal: $error',
    args: [error],
  );
  String get edgeAiUnloadedLabel =>
      _t('edgeAiUnloadedLabel', en: 'Model unloaded from runtime memory.', id: 'Model dilepas dari memori runtime.');
  String edgeAiUnloadFailedLabel(Object error) => _tf(
    'edgeAiUnloadFailedLabel',
    en: 'Model unload failed: $error',
    id: 'Lepas model gagal: $error',
    args: [error],
  );
  String get edgeAiInitializeCorruptLabel =>
      _t('edgeAiInitializeCorruptLabel', en: 'Initialize failed. Usually the model file is corrupt or does not match this device\'s runtime. Try reinstalling, then initialize again.', id: 'Inisialisasi gagal. Biasanya karena file model korup atau tidak cocok dengan runtime di device ini. Coba install ulang lalu inisialisasi lagi.');
  String edgeAiInitializeFailedLabel(String raw) => _tf(
    'edgeAiInitializeFailedLabel',
    en: 'Initialize failed: $raw',
    id: 'Inisialisasi gagal: $raw',
    args: [raw],
  );
  String edgeAiStatusReadFailedLabel(Object error) => _tf(
    'edgeAiStatusReadFailedLabel',
    en: 'Failed to read edge runtime status: $error',
    id: 'Gagal membaca status runtime lokal: $error',
    args: [error],
  );
  String edgeAiGenerationFailedLabel(Object error) => _tf(
    'edgeAiGenerationFailedLabel',
    en: 'Local generation failed: $error',
    id: 'Generate lokal gagal: $error',
    args: [error],
  );
  String get edgeAiStatusChecking =>
      _t('edgeAiStatusChecking', en: 'checking', id: 'memeriksa');
  String get edgeAiStatusUnknown =>
      _t('edgeAiStatusUnknown', en: 'unknown', id: 'tidak diketahui');
  String get edgeAiStatusReady =>
      _t('edgeAiStatusReady', en: 'ready', id: 'siap');
  String get edgeAiStatusNeedsInit =>
      _t('edgeAiStatusNeedsInit', en: 'needs-init', id: 'perlu inisialisasi');
  String get edgeAiStatusNeedsInstall =>
      _t('edgeAiStatusNeedsInstall', en: 'needs-install', id: 'perlu install');
  String get edgeAiStatusUnavailable =>
      _t('edgeAiStatusUnavailable', en: 'unavailable', id: 'tidak tersedia');
  String get edgeAiModelNotReadyTitle =>
      _t('edgeAiModelNotReadyTitle', en: 'Local model is not ready', id: 'Model lokal belum siap');
  String get edgeAiModelNotReadyMessage =>
      _t('edgeAiModelNotReadyMessage', en: 'The local AI model is not ready. Install and initialize it before starting the pretest.', id: 'Model AI lokal belum siap. Install dan inisialisasi dulu sebelum mulai pretest.');
  String get edgeAiOpenSettingsLabel =>
      _t('edgeAiOpenSettingsLabel', en: 'Open local AI settings', id: 'Buka Pengaturan AI Lokal');
  String get edgeAiCheckingReadinessLabel =>
      _t('edgeAiCheckingReadinessLabel', en: 'Checking local AI model readiness...', id: 'Memeriksa kesiapan model AI lokal...');
  String get edgeAiPickTargetNodeLabel =>
      _t('edgeAiPickTargetNodeLabel', en: 'Pick a target node in Learning Goal before starting the pretest.', id: 'Pilih node target dulu di Tujuan Belajar sebelum mulai pretest.');
  String get edgeAiFinishInstallLabel =>
      _t('edgeAiFinishInstallLabel', en: 'The local model is not ready. Finish install/initialize, then start the pretest again.', id: 'Model lokal belum siap. Selesaikan install/inisialisasi dulu lalu mulai pretest lagi.');
  String get edgeAiModelMissingTitle =>
      _t('edgeAiModelMissingTitle', en: 'Local AI model is not installed', id: 'Model AI lokal belum terpasang');
  String get edgeAiModelMissingMessage =>
      _t('edgeAiModelMissingMessage', en: 'Wicara is more stable once the LiteRT model is downloaded. Open local AI settings now?', id: 'Wicara lebih stabil kalau model LiteRT sudah diunduh. Mau buka Pengaturan AI Lokal sekarang?');
  String get edgeAiDownloadModelLabel =>
      _t('edgeAiDownloadModelLabel', en: 'Download model', id: 'Unduh model');
  String get edgeAiModelNotInitializedTitle =>
      _t('edgeAiModelNotInitializedTitle', en: 'Local AI model is not ready', id: 'Model AI lokal belum siap');
  String get edgeAiModelNotInitializedMessage =>
      _t('edgeAiModelNotInitializedMessage', en: 'The model is on this device but has not been initialized. Initialize it now?', id: 'Model sudah ada di device, tapi belum diinisialisasi. Mau inisialisasi sekarang?');
  String get edgeAiOpenSettingsShortLabel =>
      _t('edgeAiOpenSettingsShortLabel', en: 'Open settings', id: 'Buka pengaturan');
  String get edgeAiInitializingModelLabel =>
      _t('edgeAiInitializingModelLabel', en: 'Initializing the local model...', id: 'Menginisialisasi model lokal...');
  String get edgeAiModelReadyLabel =>
      _t('edgeAiModelReadyLabel', en: 'The local model is ready to use.', id: 'Model lokal siap dipakai.');
  String get edgeAiInitializedNotReadyLabel =>
      _t('edgeAiInitializedNotReadyLabel', en: 'Initialize finished but the runtime is not ready. Try opening local AI settings.', id: 'Inisialisasi selesai tapi runtime belum siap. Coba buka Pengaturan AI Lokal.');
  String get edgeAiTestPrompt =>
      _t('edgeAiTestPrompt', en: 'Answer in English. Explain the derivative as a rate of change in 2 sentences, then give 1 comprehension-check question.', id: 'Jawab dalam Bahasa Indonesia. Jelaskan konsep turunan sebagai laju perubahan dalam 2 kalimat, lalu berikan 1 pertanyaan cek pemahaman.');
  String edgeAiInitializeModelFailedLabel(Object error) => _tf(
    'edgeAiInitializeModelFailedLabel',
    en: 'Model initialize failed: $error',
    id: 'Inisialisasi model gagal: $error',
    args: [error],
  );

  // ── Video preview ───────────────────────────────────────────────────────
  String get tapToOpenLabel =>
      _t('tapToOpenLabel', en: 'Tap to open', id: 'Ketuk untuk buka');
  String get resetZoomLabel =>
      _t('resetZoomLabel', en: 'Reset zoom', id: 'Atur ulang zoom');
  String get videoFailedToLoadLabel =>
      _t('videoFailedToLoadLabel', en: 'The video failed to load. Try again.', id: 'Video gagal dimuat. Coba ulang.');
  String get videoUrlMissingLabel =>
      _t('videoUrlMissingLabel', en: 'Video URL is missing for this artifact.', id: 'URL video tidak tersedia untuk artefak ini.');
  String get videoLoadFailedLabel =>
      _t('videoLoadFailedLabel', en: 'Failed to load this video.', id: 'Video ini gagal dimuat.');
  String get openFullscreenLabel =>
      _t('openFullscreenLabel', en: 'Open fullscreen', id: 'Buka layar penuh');
  String get videoPreviewWebOnlyLabel =>
      _t('videoPreviewWebOnlyLabel', en: 'Video preview is available on web demo build.', id: 'Pratinjau video hanya tersedia di build demo web.');

  // ── Canvas (fishbone) ───────────────────────────────────────────────────
  String penSizeLabel(String size) => _tf(
    'penSizeLabel',
    en: 'Pen size $size',
    id: 'Ukuran pena $size',
    args: [size],
  );
  String get penColorLabel =>
      _t('penColorLabel', en: 'Pen color', id: 'Warna pena');
  String get saveWorkLabel =>
      _t('saveWorkLabel', en: 'Save work', id: 'Simpan pekerjaan');
  String get sendToChatLabel =>
      _t('sendToChatLabel', en: 'Send to chat', id: 'Kirim ke chat');
  String canvasStatusLabel(String status) => switch (status) {
    'draftEmpty' => _t('canvasStatusLabel.draftEmpty', en: 'Draft empty', id: 'Draf kosong'),
    'unsavedSketch' => _t('canvasStatusLabel.unsavedSketch', en: 'Unsaved sketch', id: 'Sketsa belum disimpan'),
    'unsavedChanges' => _t('canvasStatusLabel.unsavedChanges', en: 'Unsaved changes', id: 'Perubahan belum disimpan'),
    'sentToChat' => _t('canvasStatusLabel.sentToChat', en: 'Sent to chat', id: 'Terkirim ke chat'),
    _ => _t('canvasStatusLabel.default', en: 'Saved, ready to send', id: 'Tersimpan, siap dikirim'),
  };
  String get canvasClearTitle =>
      _t('canvasClearTitle', en: 'Clear canvas?', id: 'Bersihkan kanvas?');
  String get canvasClearMessage =>
      _t('canvasClearMessage', en: 'This removes the current sketch and attached paper note.', id: 'Ini menghapus sketsa saat ini beserta catatan kertas yang terlampir.');
  String get canvasLabel =>
      _t('canvasLabel', en: 'Canvas', id: 'Kanvas');
  String get canvasWorkspaceLabel =>
      _t('canvasWorkspaceLabel', en: 'Canvas workspace', id: 'Ruang kerja kanvas');
  String get canvasLargeHint =>
      _t('canvasLargeHint', en: 'Use the larger workspace for diagrams and notes.', id: 'Pakai ruang yang lebih besar untuk diagram dan catatan.');
  String get canvasSmallHint =>
      _t('canvasSmallHint', en: 'Work through the reasoning before submitting.', id: 'Kerjakan penalarannya dulu sebelum mengirim.');
  String get canvasClosePanelLabel =>
      _t('canvasClosePanelLabel', en: 'Close panel', id: 'Tutup panel');
  String get canvasLargerPanelLabel =>
      _t('canvasLargerPanelLabel', en: 'Larger panel', id: 'Panel lebih besar');
  String get canvasResetViewLabel =>
      _t('canvasResetViewLabel', en: 'Reset view', id: 'Atur ulang tampilan');
  String get canvasHideGridLabel =>
      _t('canvasHideGridLabel', en: 'Hide grid', id: 'Sembunyikan grid');
  String get canvasShowGridLabel =>
      _t('canvasShowGridLabel', en: 'Show grid', id: 'Tampilkan grid');
  String get canvasClearLabel =>
      _t('canvasClearLabel', en: 'Clear canvas', id: 'Bersihkan kanvas');
  String get canvasUploadImageLabel =>
      _t('canvasUploadImageLabel', en: 'Upload image', id: 'Unggah gambar');
  String get canvasKeepLabel =>
      _t('canvasKeepLabel', en: 'Keep', id: 'Simpan saja');
  String get canvasClearShortLabel =>
      _t('canvasClearShortLabel', en: 'Clear', id: 'Bersihkan');
  String get undoLabel =>
      _t('undoLabel', en: 'Undo', id: 'Batalkan');
  String get redoLabel =>
      _t('redoLabel', en: 'Redo', id: 'Ulangi');
  String get backLabel =>
      _t('backLabel', en: 'Back', id: 'Kembali');
  String get canvasViewSectionLabel =>
      _t('canvasViewSectionLabel', en: 'View', id: 'Tampilan');
  String get canvasEditSectionLabel =>
      _t('canvasEditSectionLabel', en: 'Edit', id: 'Ubah');
  String get canvasZoomOutLabel =>
      _t('canvasZoomOutLabel', en: 'Zoom out', id: 'Perkecil');
  String get canvasZoomInLabel =>
      _t('canvasZoomInLabel', en: 'Zoom in', id: 'Perbesar');
  String get canvasPenLabel =>
      _t('canvasPenLabel', en: 'Pen', id: 'Pena');
  String get canvasPenTooltip =>
      _t('canvasPenTooltip', en: 'Pen mode', id: 'Mode pena');
  String get canvasHandLabel =>
      _t('canvasHandLabel', en: 'Hand', id: 'Geser');
  String get canvasHandTooltip =>
      _t('canvasHandTooltip', en: 'Hand mode', id: 'Mode geser');
  String get canvasEraseLabel =>
      _t('canvasEraseLabel', en: 'Erase', id: 'Hapus');
  String get canvasEraseTooltip =>
      _t('canvasEraseTooltip', en: 'Eraser mode', id: 'Mode penghapus');
  String get canvasShapeLabel =>
      _t('canvasShapeLabel', en: 'Shape', id: 'Bentuk');
  String get canvasShapeTooltip =>
      _t('canvasShapeTooltip', en: 'Shape helper', id: 'Bantuan bentuk');
  String get canvasLineShapeLabel =>
      _t('canvasLineShapeLabel', en: 'Line shape', id: 'Bentuk garis');
  String get canvasArrowShapeLabel =>
      _t('canvasArrowShapeLabel', en: 'Arrow shape', id: 'Bentuk panah');
  String get canvasRectangleShapeLabel =>
      _t('canvasRectangleShapeLabel', en: 'Rectangle shape', id: 'Bentuk persegi');
  String get canvasPaperAttachedLabel =>
      _t('canvasPaperAttachedLabel', en: 'Paper work\nattached', id: 'Pekerjaan kertas\nterlampir');
  String get canvasEmptyHintLabel =>
      _t('canvasEmptyHintLabel', en: 'Sketch formulas, diagrams, or working steps here.', id: 'Tulis rumus, diagram, atau langkah pengerjaan di sini.');

  // ── Pretest / posttest shell ────────────────────────────────────────────
  String get loadingPretestLabel =>
      _t('loadingPretestLabel', en: 'Loading pretest', id: 'Memuat pretest');
  String get preparingAdaptiveQuestionsLabel =>
      _t('preparingAdaptiveQuestionsLabel', en: 'Preparing adaptive questions...', id: 'Menyiapkan soal adaptif...');
  String get goalResolvingTitle =>
      _t('goalResolvingTitle', en: 'Finding the right concept', id: 'Mencari konsep yang tepat');
  String get goalResolvingSubtitle =>
      _t('goalResolvingSubtitle', en: 'We are matching what you typed against the\ncurriculum map.', id: 'Kami sedang mencocokkan yang kamu tulis\ndengan peta kurikulum.');
  String get goalResolvingStageRead =>
      _t('goalResolvingStageRead', en: 'Reading what you want to learn', id: 'Membaca apa yang ingin kamu pelajari');
  String get goalResolvingStageSearch =>
      _t('goalResolvingStageSearch', en: 'Searching the curriculum map', id: 'Menelusuri peta kurikulum');
  String get goalResolvingStageMatch =>
      _t('goalResolvingStageMatch', en: 'Choosing the closest concept', id: 'Memilih konsep yang paling cocok');
  String get answerCheckingTitle =>
      _t('answerCheckingTitle', en: 'Checking your answer', id: 'Memeriksa jawabanmu');
  String get answerCheckingSubtitle =>
      _t('answerCheckingSubtitle', en: 'The tutor is reading your reasoning, not just\nthe option you picked.', id: 'Tutor sedang membaca alasanmu, bukan hanya\npilihan yang kamu tandai.');
  String get answerCheckingStageRead =>
      _t('answerCheckingStageRead', en: 'Reading your reasoning', id: 'Membaca alasanmu');
  String get answerCheckingStageReason =>
      _t('answerCheckingStageReason', en: 'Weighing what you already understand', id: 'Menimbang apa yang sudah kamu pahami');
  String get answerCheckingStageNext =>
      _t('answerCheckingStageNext', en: 'Choosing what to ask next', id: 'Memilih pertanyaan berikutnya');
  String get pretestBuildingTitle =>
      _t('pretestBuildingTitle', en: 'Building your pretest', id: 'Menyiapkan pretesmu');
  String get pretestBuildingSubtitle =>
      _t('pretestBuildingSubtitle', en: 'We are writing questions that match your goal.\nThis usually takes about two minutes.', id: 'Kami sedang menyusun soal yang sesuai dengan tujuanmu.\nBiasanya butuh sekitar dua menit.');
  String get pretestBuildingStageGoal =>
      _t('pretestBuildingStageGoal', en: 'Reading your learning goal', id: 'Membaca tujuan belajarmu');
  String get pretestBuildingStageMap =>
      _t('pretestBuildingStageMap', en: 'Mapping the prerequisite concepts', id: 'Memetakan konsep prasyaratnya');
  String get pretestBuildingStageWrite =>
      _t('pretestBuildingStageWrite', en: 'Writing questions at each difficulty', id: 'Menulis soal untuk tiap tingkat kesulitan');
  String get pretestBuildingStageCheck =>
      _t('pretestBuildingStageCheck', en: 'Checking every answer and explanation', id: 'Memeriksa setiap jawaban dan pembahasan');
  String get pretestBuildingStageFinish =>
      _t('pretestBuildingStageFinish', en: 'Putting your pretest together', id: 'Merapikan pretesmu');
  String get pretestBuildingFootnote =>
      _t('pretestBuildingFootnote', en: 'Keep this screen open. Your questions are being written just for you.', id: 'Biarkan layar ini terbuka. Soalmu sedang ditulis khusus untukmu.');
  List<String> get pretestBuildingTips => _tl('pretestBuildingTips', en: const ['A pretest is not a score. It finds the gap worth fixing first.', 'Answer honestly. A wrong answer teaches the tutor more than a lucky guess.', 'Stuck on a question? Choosing "not sure" is a real answer here.', 'Your results shape the whole learning path that comes next.'], id: const ['Pretest bukan nilai. Tujuannya menemukan celah yang paling perlu ditutup.', 'Jawab sejujurnya. Jawaban salah lebih membantu tutor daripada tebakan beruntung.', 'Bingung? Memilih "belum yakin" juga jawaban yang sah di sini.', 'Hasilnya menentukan seluruh jalur belajarmu setelah ini.']);
  String get pretestUnavailableLabel =>
      _t('pretestUnavailableLabel', en: 'Pretest unavailable', id: 'Pretest tidak tersedia');
  String get noLocalQuestionLabel =>
      _t('noLocalQuestionLabel', en: 'Local pretest generator returned no question.', id: 'Generator pretest lokal tidak mengembalikan soal.');
  String get tryAgainLabel =>
      _t('tryAgainLabel', en: 'Try again', id: 'Coba lagi');
  String get chooseAnswerBeforeReasoningLabel =>
      _t('chooseAnswerBeforeReasoningLabel', en: 'Choose an answer before adding your working.', id: 'Pilih jawaban dulu sebelum menambah cara pengerjaan.');
  String get imageUnreadableLabel =>
      _t('imageUnreadableLabel', en: 'The image file could not be read.', id: 'File gambar tidak dapat dibaca.');
  String get imageTooLargeLabel =>
      _t('imageTooLargeLabel', en: 'The image must be 10 MB or smaller.', id: 'Ukuran gambar maksimal 10 MB.');
  String get adaptiveProbingLabel =>
      _t('adaptiveProbingLabel', en: 'Adaptive probing  •  Knowledge Space Theory', id: 'Penelusuran adaptif  •  Knowledge Space Theory');
  String get missingPrerequisiteSkillLabel =>
      _t('missingPrerequisiteSkillLabel', en: 'Missing prerequisite: causal drivers', id: 'Prasyarat yang kurang: pemicu sebab-akibat');
  String get missingPrerequisiteMessageLabel =>
      _t('missingPrerequisiteMessageLabel', en: 'The gap looks like choosing a tool before naming the defect driver, evidence, and likely cause chain.', id: 'Gap-nya terlihat seperti memilih alat sebelum menyebutkan pemicu masalah, buktinya, dan rantai penyebab yang mungkin.');
  String get preTestLabel =>
      _t('preTestLabel', en: 'Pre-test', id: 'Pretest');
  String get postTestLabel =>
      _t('postTestLabel', en: 'Post-test', id: 'Posttest');
  String get improvedLabel =>
      _t('improvedLabel', en: 'Improved', id: 'Meningkat');
  String get stagnantLabel =>
      _t('stagnantLabel', en: 'Stagnant', id: 'Stagnan');
  String get reviewDueConceptsLabel =>
      _t('reviewDueConceptsLabel', en: 'Review due concepts', id: 'Konsep yang jatuh tempo');
  String get dueThisWeekLabel =>
      _t('dueThisWeekLabel', en: 'Due this week', id: 'Jatuh tempo minggu ini');
  String get preVsPostTestLabel =>
      _t('preVsPostTestLabel', en: 'Pre-test vs Post-test', id: 'Pretest vs Posttest');
  String get weeklyNarrativeLabel =>
      _t('weeklyNarrativeLabel', en: 'Weekly narrative', id: 'Narasi mingguan');
  String get focusLabel =>
      _t('focusLabel', en: 'Focus', id: 'Fokus');
  String get answerScoredByAiLabel =>
      _t('answerScoredByAiLabel', en: 'Answer scored by AI.', id: 'Jawaban dinilai oleh AI.');
  String get scoringOffLabel =>
      _t('scoringOffLabel', en: 'Scoring off?', id: 'Penilaian keliru?');
  String get laterLabel =>
      _t('laterLabel', en: 'Later', id: 'Nanti');
  String get trackWithoutModuleLabel =>
      _t('trackWithoutModuleLabel', en: 'The track was created, but no workspace module is available yet.', id: 'Track sudah dibuat, tapi belum ada modul workspace yang bisa dibuka.');
  String get workspaceAutoOpenFailedLabel =>
      _t('workspaceAutoOpenFailedLabel', en: 'Could not auto-open the workspace after the pretest.', id: 'Gagal membuka workspace otomatis setelah pretest.');
  String get retentionLiftShortLabel =>
      _t('retentionLiftShortLabel', en: 'Retention Lift', id: 'Peningkatan Retensi');
  String get remainingLabel =>
      _t('remainingLabel', en: 'Remaining', id: 'Sisa');
  String get weeklyReportLabel =>
      _t('weeklyReportLabel', en: 'Weekly Report', id: 'Laporan Mingguan');
  String get retentionLabel =>
      _t('retentionLabel', en: 'Retention', id: 'Retensi');
  String get posttestMasteryCheckLabel =>
      _t('posttestMasteryCheckLabel', en: 'Posttest Mastery Check', id: 'Cek Penguasaan Posttest');

  String get noSubjectsSelectedLabel =>
      _t('noSubjectsSelectedLabel', en: 'No subjects selected', id: 'Belum ada mata pelajaran dipilih');
  String get thisWeekLabel =>
      _t('thisWeekLabel', en: 'This week', id: 'Minggu ini');
  String get consistencyCompoundingLabel =>
      _t('consistencyCompoundingLabel', en: 'Consistency is compounding.', id: 'Konsistensimu mulai berbuah.');

  // ── Network & session errors ────────────────────────────────────────────
  String get serverTimeoutLabel =>
      _t('serverTimeoutLabel', en: 'The WICARA server took too long to respond. Please try again.', id: 'Server WICARA terlalu lama merespons. Coba lagi.');
  String get uploadTimeoutLabel =>
      _t('uploadTimeoutLabel', en: 'The WICARA server took too long to upload the image. Please try again.', id: 'Server WICARA terlalu lama mengunggah gambar. Coba lagi.');
  String serverUnreachableLabel(String baseUrl, String detail) => _tf(
    'serverUnreachableLabel',
    en: 'Cannot reach the WICARA server at $baseUrl. $detail',
    id: 'Tidak bisa terhubung ke server WICARA di $baseUrl. $detail',
    args: [baseUrl, detail],
  );
  String get loginBeforeDashboardLabel =>
      _t('loginBeforeDashboardLabel', en: 'Please log in before opening dashboard.', id: 'Masuk dulu sebelum membuka dashboard.');
  String get loginBeforeOnboardingLabel =>
      _t('loginBeforeOnboardingLabel', en: 'Please log in before onboarding.', id: 'Masuk dulu sebelum onboarding.');
  String get loginBeforeWorkspaceLabel =>
      _t('loginBeforeWorkspaceLabel', en: 'Please log in before opening workspace.', id: 'Masuk dulu sebelum membuka workspace.');
  String get loginBeforeTrackLabel =>
      _t('loginBeforeTrackLabel', en: 'Please log in before creating a track.', id: 'Masuk dulu sebelum membuat track.');
  String get noMatchingGoalLabel =>
      _t('noMatchingGoalLabel', en: 'No matching learning goal was found.', id: 'Tidak ada tujuan belajar yang cocok.');
  String get noImageAssetIdLabel =>
      _t('noImageAssetIdLabel', en: 'The server did not return an image asset id.', id: 'Server tidak mengembalikan id aset gambar.');
  String activeGoalConflictLabel(String topic) => _tf(
    'activeGoalConflictLabel',
    en: 'You already have an active goal for "$topic". '
            'Continue the existing goal or go back.',
    id: 'Kamu sudah punya tujuan aktif untuk "$topic". '
            'Lanjutkan tujuan itu atau kembali.',
    args: [topic],
  );
  String signInFailedLabel(Object error) => _tf(
    'signInFailedLabel',
    en: 'Sign-in failed: $error',
    id: 'Gagal masuk: $error',
    args: [error],
  );
  String registrationFailedLabel(Object error) => _tf(
    'registrationFailedLabel',
    en: 'Registration failed: $error',
    id: 'Pendaftaran gagal: $error',
    args: [error],
  );
  String googleSignInFailedLabel(Object error) => _tf(
    'googleSignInFailedLabel',
    en: 'Google sign-in failed: $error',
    id: 'Masuk dengan Google gagal: $error',
    args: [error],
  );
  String get googleSignInCancelledLabel =>
      _t('googleSignInCancelledLabel', en: 'Google sign-in was cancelled.', id: 'Masuk dengan Google dibatalkan.');

  // ── Adaptive pretest results & errors ───────────────────────────────────
  String get createGoalBeforePretestLabel =>
      _t('createGoalBeforePretestLabel', en: 'Create a learning goal before opening the pretest.', id: 'Buat tujuan belajar dulu sebelum membuka pretest.');
  String get invalidPretestQuestionLabel =>
      _t('invalidPretestQuestionLabel', en: 'Backend returned an invalid pretest question.', id: 'Backend mengembalikan soal pretest yang tidak valid.');
  String get chooseAnswerFirstLabel =>
      _t('chooseAnswerFirstLabel', en: 'Choose an answer before continuing.', id: 'Pilih jawaban dulu sebelum lanjut.');
  String get noNextQuestionLabel =>
      _t('noNextQuestionLabel', en: 'Backend returned no next question or diagnosis.', id: 'Backend tidak mengembalikan soal berikutnya atau diagnosis.');
  String get invalidEvidenceImageLabel =>
      _t('invalidEvidenceImageLabel', en: 'Backend returned an invalid evidence image.', id: 'Backend mengembalikan gambar bukti yang tidak valid.');
  String get createGoalBeforePathLabel =>
      _t('createGoalBeforePathLabel', en: 'Create a learning goal before selecting a path.', id: 'Buat tujuan belajar dulu sebelum memilih jalur.');
  String get loginBeforePretestLabel =>
      _t('loginBeforePretestLabel', en: 'Please log in before taking the pretest.', id: 'Masuk dulu sebelum mengerjakan pretest.');
  String get openPretestBeforeSubmitLabel =>
      _t('openPretestBeforeSubmitLabel', en: 'Open a generated pretest before submitting.', id: 'Buka pretest yang sudah dibuat sebelum mengirim jawaban.');
  String get pathSelectedLabel =>
      _t('pathSelectedLabel', en: 'Path selected', id: 'Jalur dipilih');
  String get adaptivePathReadyLabel =>
      _t('adaptivePathReadyLabel', en: 'Your adaptive learning path is ready.', id: 'Jalur belajar adaptifmu sudah siap.');
  String get continueSelectedPathLabel =>
      _t('continueSelectedPathLabel', en: 'Continue with the selected path.', id: 'Lanjutkan dengan jalur yang dipilih.');
  String modulesCountLabel(int count) => _tf(
    'modulesCountLabel',
    en: '$count modules',
    id: '$count modul',
    args: [count],
  );
  String get adaptiveDiagnosisLabel =>
      _t('adaptiveDiagnosisLabel', en: 'Adaptive diagnosis', id: 'Diagnosis adaptif');
  String get adaptivePretestCompleteLabel =>
      _t('adaptivePretestCompleteLabel', en: 'Adaptive pretest complete', id: 'Pretest adaptif selesai');
  String scoreMetaLabel(int percent) => _tf(
    'scoreMetaLabel',
    en: 'Score $percent%',
    id: 'Skor $percent%',
    args: [percent],
  );
  String correctCountMetaLabel(int correct, int answered) => _tf(
    'correctCountMetaLabel',
    en: '$correct/$answered correct',
    id: '$correct/$answered benar',
    args: [correct, answered],
  );
  String pathDescriptionLabel(String option) => switch (option) {
    'review_only' => _t('pathDescriptionLabel.review_only', en: 'Start with a short review and advanced practice.', id: 'Mulai dari review singkat lalu latihan lanjutan.'),
    'target_reinforcement' => _t('pathDescriptionLabel.target_reinforcement', en: 'Practice the target concept at medium and hard levels.', id: 'Latih konsep target di level menengah dan sulit.'),
    'target_intro' => _t('pathDescriptionLabel.target_intro', en: 'Start from the target concept introduction.', id: 'Mulai dari pengenalan konsep target.'),
    'repair_prerequisites' => _t('pathDescriptionLabel.repair_prerequisites', en: 'Repair prerequisite gaps before returning to the target.', id: 'Perbaiki gap prasyarat sebelum kembali ke target.'),
    'full_foundation_path' => _t('pathDescriptionLabel.full_foundation_path', en: 'Rebuild the deeper foundation first.', id: 'Bangun ulang fondasi yang lebih dasar dulu.'),
    _ => _t('pathDescriptionLabel.default', en: 'Learn the target concept from basics.', id: 'Pelajari konsep target dari dasar.'),
  };

  // ── Offline pretest engine (LiteRT pilot) ───────────────────────────────
  String questionProgressLabel(int current, int max) => _tf(
    'questionProgressLabel',
    en: 'Question $current of $max',
    id: 'Soal $current dari $max',
    args: [current, max],
  );
  String get conceptNotFoundLabel =>
      _t('conceptNotFoundLabel', en: 'The concept was not found in the local curriculum.', id: 'Konsep tidak ditemukan di kurikulum lokal.');
  String conceptCodeNotFoundLabel(String code) => _tf(
    'conceptCodeNotFoundLabel',
    en: 'Concept "$code" was not found in the local curriculum.',
    id: 'Konsep "$code" tidak ditemukan di kurikulum lokal.',
    args: [code],
  );
  String get evidenceUploadNeedsBackendLabel =>
      _t('evidenceUploadNeedsBackendLabel', en: 'Image evidence upload requires the backend pretest mode.', id: 'Unggah bukti gambar membutuhkan mode pretest backend.');
  String get emptyPathOptionLabel =>
      _t('emptyPathOptionLabel', en: 'The path option must not be empty.', id: 'Pilihan jalur tidak boleh kosong.');
  String get localDiagnosisUnavailableLabel =>
      _t('localDiagnosisUnavailableLabel', en: 'The local diagnosis is not available yet. Finish the pretest first.', id: 'Diagnosis lokal belum tersedia. Selesaikan pretest terlebih dahulu.');
  String get localPretestStateInvalidLabel =>
      _t('localPretestStateInvalidLabel', en: 'The local pretest state is not valid.', id: 'State pretest lokal tidak valid.');
  String get localPretestSessionInvalidLabel =>
      _t('localPretestSessionInvalidLabel', en: 'The local pretest session is not valid.', id: 'Sesi pretest lokal tidak valid.');
  String get questionMismatchLabel =>
      _t('questionMismatchLabel', en: 'Question mismatch. Reload the pretest and try again.', id: 'Soal tidak cocok. Muat ulang pretest lalu coba lagi.');
  String get optionNotFoundLabel =>
      _t('optionNotFoundLabel', en: 'Selected option was not found for this question.', id: 'Pilihan jawaban tidak ditemukan untuk soal ini.');
  String get offlineCurriculumMissingLabel =>
      _t('offlineCurriculumMissingLabel', en: 'The offline curriculum is not available on this device.', id: 'Kurikulum offline belum tersedia di device.');
  String get targetConceptNotChosenLabel =>
      _t('targetConceptNotChosenLabel', en: 'No target concept selected. Open Learning Goal and pick a target node first.', id: 'Konsep target belum dipilih. Buka Tujuan Belajar dan pilih node target dulu.');
  String targetConceptNotFoundLabel(String code) => _tf(
    'targetConceptNotFoundLabel',
    en: 'Target concept "$code" was not found in the local curriculum.',
    id: 'Konsep target "$code" tidak ditemukan di kurikulum lokal.',
    args: [code],
  );
  String get backendPretestNotConfiguredLabel =>
      _t('backendPretestNotConfiguredLabel', en: 'The backend pretest repository is not configured.', id: 'Repository pretest backend belum dikonfigurasi.');
  String chooseBestAnswerLabel(String conceptTitle) => _tf(
    'chooseBestAnswerLabel',
    en: 'Choose the best answer for $conceptTitle.',
    id: 'Pilih jawaban yang paling tepat untuk $conceptTitle.',
    args: [conceptTitle],
  );
  String get reviewWorkingStepsLabel =>
      _t('reviewWorkingStepsLabel', en: 'Review your working steps to confirm your answer choice.', id: 'Tinjau langkah pengerjaan untuk memastikan pilihan jawabanmu.');
  String get emptyTopicLabel =>
      _t('emptyTopicLabel', en: 'The learning topic must not be empty.', id: 'Topik belajar tidak boleh kosong.');
  String get noMatchingConceptLabel =>
      _t('noMatchingConceptLabel', en: 'No matching concept yet. Try adding a more specific keyword.', id: 'Belum ketemu konsep yang pas. Coba tambahkan kata kunci yang lebih spesifik.');
  String get searchAllSubjectsLabel =>
      _t('searchAllSubjectsLabel', en: 'Searched across all local subjects.', id: 'Pencarian di seluruh mata pelajaran lokal.');
  String get searchLimitedSubjectLabel =>
      _t('searchLimitedSubjectLabel', en: 'Search limited to the selected subject.', id: 'Pencarian dibatasi ke mata pelajaran yang dipilih.');
  String get resolutionNotFoundLabel =>
      _t('resolutionNotFoundLabel', en: 'Resolution not found. Search for a goal node again.', id: 'Hasil pencarian tidak ditemukan. Cari node tujuan lagi.');
  String get resolutionMissingLabel =>
      _t('resolutionMissingLabel', en: 'Resolution not found.', id: 'Hasil pencarian tidak ditemukan.');
  String get noTargetNodeLabel =>
      _t('noTargetNodeLabel', en: 'No target node has been selected for the pretest.', id: 'Belum ada node target yang dipilih untuk pretest.');
  String get noMatchingConceptRetryLabel =>
      _t('noMatchingConceptRetryLabel', en: 'No matching concept found. Try another query.', id: 'Belum ketemu konsep yang tepat. Coba kata kunci lain.');
  String get localCurriculumMissingLabel =>
      _t('localCurriculumMissingLabel', en: 'The local curriculum is not available yet. Sync the curriculum first.', id: 'Kurikulum lokal belum tersedia. Sinkronkan kurikulum dulu.');
  String localNodeNotFoundLabel(String ref) => _tf(
    'localNodeNotFoundLabel',
    en: 'Node "$ref" was not found in the local curriculum.',
    id: 'Node "$ref" tidak ditemukan di kurikulum lokal.',
    args: [ref],
  );
  String get targetConceptFallbackTitle =>
      _t('targetConceptFallbackTitle', en: 'Target concept', id: 'Konsep target');

  // ── Deterministic on-device tutor fallback ──────────────────────────────
  String get tutorHintDerivativeLabel =>
      _t('tutorHintDerivativeLabel', en: 'Hint: look at how the function value changes when x shifts slightly, then compare two very close points.', id: 'Petunjuk: lihat perubahan nilai fungsi saat x berubah sedikit, lalu bandingkan dua titik yang sangat dekat.');
  String get tutorHintGenericLabel =>
      _t('tutorHintGenericLabel', en: 'Hint: break the problem into three small steps, check the assumption at each step, then work through them one by one.', id: 'Petunjuk: pecah masalah jadi tiga langkah kecil, cek asumsi setiap langkah, lalu lanjutkan satu per satu.');
  String get tutorEvaluateCloseLabel =>
      _t('tutorEvaluateCloseLabel', en: "Your steps are close. Now explain why that rule applies to this problem's form.", id: 'Langkahmu sudah mendekati benar. Sekarang jelaskan kenapa aturan itu berlaku pada bentuk soalnya.');
  String get tutorEvaluateInconsistentLabel =>
      _t('tutorEvaluateInconsistentLabel', en: 'Your answer is not consistent yet. Recheck the first step, then rewrite the reason for each transformation.', id: 'Jawabanmu belum konsisten. Cek kembali langkah pertama, lalu tulis ulang alasan untuk setiap transformasi.');
  String get reasoningTooShortLabel =>
      _t('reasoningTooShortLabel', en: 'Your reasoning is still too short; add why you chose that operation.', id: 'Penalaranmu masih terlalu singkat; tambahkan alasan kenapa memilih operasi tersebut.');
  String get reasoningClearLabel =>
      _t('reasoningClearLabel', en: 'Your reasoning is structurally clear; now back it up with one short numeric example.', id: 'Penalaranmu cukup jelas secara struktur; sekarang perkuat dengan satu contoh numerik singkat.');
  String get quizPromptLabel =>
      _t('quizPromptLabel', en: "Try this: if f(x)=x^2, what is the derivative f'(x), and why?", id: "Coba jawab: jika f(x)=x^2, berapa turunan f'(x), dan kenapa?");
  String get summaryFallbackLabel =>
      _t('summaryFallbackLabel', en: 'In short: focus on the core concept, one main rule, and one common mistake to avoid.', id: 'Ringkas: fokus ke konsep inti, satu aturan utama, dan satu kesalahan umum yang perlu dihindari.');
  String get explainDerivativeLabel =>
      _t('explainDerivativeLabel', en: 'A derivative describes how fast a function value changes with respect to x. Picture it as the slope of the tangent line at a point on the curve.', id: 'Turunan menggambarkan seberapa cepat nilai fungsi berubah terhadap perubahan x. Bayangkan sebagai kemiringan garis singgung pada kurva di satu titik.');
  String get explainGenericLabel =>
      _t('explainGenericLabel', en: 'We start from the core definition, move to a short example, then check back with a verification question.', id: 'Kita mulai dari definisi inti, lanjut ke contoh singkat, lalu cek kembali dengan pertanyaan verifikasi.');

  /// System prompt for the on-device diagnosis writer. Written in the learner's
  /// language so the generated narrative matches the rest of the app.
  String get diagnosisSystemPrompt =>
      _t('diagnosisSystemPrompt', en: "You are WICARA's on-device pretest diagnostic writer. Write a specific narrative grounded in the given questions and the learner's answers, not generalities. Output valid JSON only.", id: 'Kamu adalah pelapor diagnostik pretest WICARA on-device. Tulis narasi spesifik berdasarkan soal & jawaban siswa yang diberikan, bukan generalisasi. Output JSON valid saja.');

  /// Instruction block for the on-device diagnosis writer. The JSON keys in the
  /// payload stay in Indonesian in both variants because the payload builder
  /// emits them verbatim.
  String get diagnosisPromptInstructions =>
      _t('diagnosisPromptInstructions', en: '''
Write a diagnosis of the learner's pretest. Not a summary, not encouragement - a DIAGNOSIS.
Use ONLY the data in "nodes" below.
Tone: casual, addressed directly to the learner ("You ..."), no jargon.
If siswa_pakai_canvas=true, mention that the learner wrote or sketched while working (an effort signal).

Rules for each field:
- "summary" (2-3 sentences, roughly 80-120 words):
  name the specific target concept + 1 thing already understood (cite a correct question) + 1 thing still missing (cite a wrong question).
  Avoid motivational lines ("keep going", "you can do it").
- "strengths" (1-3 points, each 1-2 full sentences):
  format: "On the question about [core of the question], you [correct step]."
  Cite reasoning_siswa whenever it is available.
- "gaps" (1-3 points, each 2-3 full sentences):
  format: "On the question about [core of the question], you chose [siswa_pilih] when the answer was [jawaban_benar]. [Contrast reasoning_siswa with expected_reasoning or explain the error]."
- "evidence_notes" (0-2 points):
  describe concrete cross-question patterns (e.g. empty reasoning on hard questions, canvas effort appearing, etc).
- "recommended_focus" (1-3 points):
  concrete practice that directly fixes the gap (name the sub-topic, not "practice more").

FORBIDDEN: generic lines ("needs more practice", "the concept is weak").
Always reference the actual question content from the data.''', id: '''
Tulis diagnosa pretest siswa. Bukan ringkasan, bukan motivasi - DIAGNOSA.
Gunakan HANYA data di "nodes" di bawah.
Bahasa: santai, langsung ke siswa ("Kamu ..."), tanpa jargon.
Jika siswa_pakai_canvas=true, sebutkan bahwa siswa menulis/mencoret saat mengerjakan (sinyal effort).

Aturan menulis tiap field:
- "summary" (2-3 kalimat, kira-kira 80-120 kata):
  sebut konsep target spesifik + 1 hal yang sudah dipahami (rujuk soal benar) + 1 hal yang masih kurang (rujuk soal salah).
  Hindari kalimat motivasi ("semangat", "kamu pasti bisa").
- "strengths" (1-3 poin, tiap poin 1-2 kalimat penuh):
  format: "Di soal [inti pertanyaan], kamu [langkah yang benar]."
  Wajib rujuk reasoning_siswa jika tersedia.
- "gaps" (1-3 poin, tiap poin 2-3 kalimat penuh):
  format: "Di soal [inti pertanyaan], kamu pilih [siswa_pilih] padahal benar [jawaban_benar]. [Kontraskan reasoning_siswa vs expected_reasoning atau jelaskan salahnya]."
- "evidence_notes" (0-2 poin):
  tulis pola lintas-soal yang konkret (mis. reasoning kosong di soal sulit, effort canvas muncul, dst).
- "recommended_focus" (1-3 poin):
  latihan konkret yang langsung memperbaiki gap (sebut sub-topik latihan, bukan "latihan lagi").

DILARANG: kalimat generik ("perlu latihan lagi", "konsep belum kuat").
Selalu sebut konten soal dari data.''');
  String get heuristicReasoningFeedback =>
      _t('heuristicReasoningFeedback', en: 'Reasoning was scored with a local heuristic because LiteRT evaluation is unavailable.', id: 'Penalaran dinilai dengan heuristik lokal karena evaluasi LiteRT belum tersedia.');
  String get carelessMistakeFeedback =>
      _t('carelessMistakeFeedback', en: 'The multiple choice is wrong, but there is a fairly strong partial-reasoning signal.', id: 'Pilihan gandanya salah, tapi ada sinyal penalaran parsial yang cukup kuat.');
  String get partialReasoningFeedback =>
      _t('partialReasoningFeedback', en: 'Partial reasoning, but not enough to support the answer.', id: 'Penalaran parsial, tetapi belum cukup untuk mendukung jawaban.');
  String get unrelatedReasoningFeedback =>
      _t('unrelatedReasoningFeedback', en: 'The reasoning is not yet directly related to the core concept.', id: 'Penalaran belum terkait langsung dengan konsep inti soal.');

  String diagnosisSummaryLabel(String path, String title) => switch (path) {
    'review_only' => _tf('diagnosisSummaryLabel.review_only', en: "You're ready on $title; a short review is enough.", id: 'Kamu sudah siap di $title; cukup review singkat.', args: [title]),
    'target_reinforcement' => _tf('diagnosisSummaryLabel.target_reinforcement', en: 'You understand the basics of $title, but need harder practice.', id: 'Kamu paham dasar $title, tapi perlu latihan versi lebih sulit.', args: [title]),
    'target_from_basics' => _tf('diagnosisSummaryLabel.target_from_basics', en: '$title is forming, but not stable at the medium level yet.', id: '$title mulai terbentuk, tapi belum stabil di level sedang.', args: [title]),
    'target_intro' => _tf('diagnosisSummaryLabel.target_intro', en: '$title is still the main gap; start from the concept introduction.', id: '$title masih menjadi gap utama; mulai dari pengantar konsep.', args: [title]),
    'repair_prerequisites' => _tf('diagnosisSummaryLabel.repair_prerequisites', en: 'Some prerequisites for $title need strengthening first.', id: 'Beberapa prasyarat $title perlu diperkuat dulu.', args: [title]),
    'full_foundation_path' => _tf('diagnosisSummaryLabel.full_foundation_path', en: 'The foundation before $title needs rebuilding from the deepest prerequisites.', id: 'Fondasi sebelum $title perlu dibangun ulang dari prasyarat terdalam.', args: [title]),
    _ => _tf('diagnosisSummaryLabel.default', en: 'Diagnosis for $title is complete.', id: 'Diagnosis $title selesai.', args: [title]),
  };

  List<String> diagnosisFocusLabels(String path) => switch (path) {
    'review_only' => [
      _t('diagnosisFocusLabels.review_only.0', en: 'Re-summarize the target concept', id: 'Ringkas ulang konsep target'),
      _t('diagnosisFocusLabels.review_only.1', en: 'Do 1-2 light reinforcement questions', id: 'Kerjakan 1-2 soal penguatan ringan'),
    ],
    'target_reinforcement' => [
      _t('diagnosisFocusLabels.target_reinforcement.0', en: 'Practice medium-to-hard on the target', id: 'Latihan menengah menuju sulit pada target'),
      _t('diagnosisFocusLabels.target_reinforcement.1', en: 'Improve written reasoning quality', id: 'Perbaiki kualitas penalaran tertulis'),
    ],
    'target_from_basics' => [
      _t('diagnosisFocusLabels.target_from_basics.0', en: 'Redo the foundation right before the target', id: 'Ulang fondasi langsung sebelum target'),
      _t('diagnosisFocusLabels.target_from_basics.1', en: 'Practice gradually from easy to medium', id: 'Latihan bertahap mudah ke menengah'),
    ],
    'target_intro' => [
      _t('diagnosisFocusLabels.target_intro.0', en: 'Start from the target concept introduction', id: 'Mulai dari pengantar konsep target'),
      _t('diagnosisFocusLabels.target_intro.1', en: 'Use concrete examples before symbolic ones', id: 'Gunakan contoh konkret sebelum simbolik'),
    ],
    'repair_prerequisites' => [
      _t('diagnosisFocusLabels.repair_prerequisites.0', en: 'Strengthen fragile or missing prerequisite nodes', id: 'Perkuat node prasyarat yang rapuh atau gap'),
      _t('diagnosisFocusLabels.repair_prerequisites.1', en: 'Return to the target once prerequisites are stable', id: 'Kembali ke target setelah prasyarat stabil'),
    ],
    'full_foundation_path' => [
      _t('diagnosisFocusLabels.full_foundation_path.0', en: 'Rebuild from the deepest prerequisites', id: 'Bangun ulang dari prasyarat terdalam'),
      _t('diagnosisFocusLabels.full_foundation_path.1', en: 'Climb gradually by graph depth', id: 'Naik bertahap berdasarkan kedalaman graf'),
    ],
    _ => const <String>[],
  };

  String get offlineWritingNotesLabel =>
      _t('offlineWritingNotesLabel', en: 'The AI is writing your personal notes...', id: 'AI sedang menulis catatan personal...');
  String get offlineSessionNotFoundLabel =>
      _t('offlineSessionNotFoundLabel', en: 'Pretest session not found.', id: 'Sesi pretest tidak ditemukan.');
  String get offlineInvalidStateLabel =>
      _t('offlineInvalidStateLabel', en: 'The pretest state is not valid.', id: 'State pretest tidak valid.');
  String get offlineNotesReadyLabel =>
      _t('offlineNotesReadyLabel', en: 'Your personal AI notes are ready.', id: 'Catatan personal AI selesai.');
  String get offlineNotesFailedLabel =>
      _t('offlineNotesFailedLabel', en: 'The AI could not write personal notes for this session.', id: 'AI belum bisa menulis catatan personal untuk sesi ini.');
  String get offlineRuntimeNotReadyLabel =>
      _t('offlineRuntimeNotReadyLabel', en: 'The LiteRT model is not ready or not installed. Using the local fallback.', id: 'Model LiteRT belum siap atau belum terpasang. Memakai fallback lokal.');
  String offlineGeneratingAttemptLabel(
    int attempt,
    int maxAttempts,
    int timeoutSeconds,
  ) => _tf(
    'offlineGeneratingAttemptLabel',
    en: 'Generating local questions (attempt $attempt/$maxAttempts, timeout ${timeoutSeconds}s)...',
    id: 'Membuat soal lokal (percobaan $attempt/$maxAttempts, timeout ${timeoutSeconds}s)...',
    args: [attempt, maxAttempts, timeoutSeconds],
  );
  String offlineOutputInvalidLabel(int attempt, int maxAttempts) => _tf(
    'offlineOutputInvalidLabel',
    en: 'The model output is not valid yet, retrying ($attempt/$maxAttempts).',
    id: 'Output model belum valid, coba ulang ($attempt/$maxAttempts).',
    args: [attempt, maxAttempts],
  );
  String offlineValidLevelsLabel(int count, String levels) => _tf(
    'offlineValidLevelsLabel',
    en: 'The model produced $count valid levels ($levels).',
    id: 'Model menghasilkan $count level valid ($levels).',
    args: [count, levels],
  );
  String offlineAttemptTimeoutLabel(int attempt, int seconds) => _tf(
    'offlineAttemptTimeoutLabel',
    en: 'Attempt $attempt timed out (${seconds}s). Retrying...',
    id: 'Percobaan $attempt timeout (${seconds}s). Mencoba lagi...',
    args: [attempt, seconds],
  );
  String offlineAttemptFailedLabel(int attempt, Object errorType) => _tf(
    'offlineAttemptFailedLabel',
    en: 'Attempt $attempt failed: $errorType. Continuing with the next retry.',
    id: 'Percobaan $attempt gagal: $errorType. Melanjutkan percobaan berikutnya.',
    args: [attempt, errorType],
  );
  String get offlineGenerationDoneLabel =>
      _t('offlineGenerationDoneLabel', en: 'Question generation finished.', id: 'Pembuatan soal selesai.');
  String offlineGenerationPartialLabel(String dropped) => _tf(
    'offlineGenerationPartialLabel',
    en: 'Some questions are valid. Skipped: $dropped.',
    id: 'Sebagian soal valid. Dilewati: $dropped.',
    args: [dropped],
  );
  String get offlineGenerationFailedLabel =>
      _t('offlineGenerationFailedLabel', en: 'Question generation failed. Using the fallback template.', id: 'Pembuatan soal gagal. Memakai template fallback.');
  String get offlineGenerationFallbackLabel =>
      _t('offlineGenerationFallbackLabel', en: 'Local question generation failed. Using the fallback template.', id: 'Pembuatan soal lokal gagal. Memakai template fallback.');
  String get offlinePreparingModelLabel =>
      _t('offlinePreparingModelLabel', en: 'Preparing the local model...', id: 'Menyiapkan model lokal...');

  /// Instruction block for the on-device question generator. The model is
  /// prompted in the learner's language so the generated pretest matches it.
  String offlineQuestionPromptInstructions(String requiredKeys) => _tf(
    'offlineQuestionPromptInstructions',
    en: '''
Write short adaptive pretest questions in English.
Only output these difficulty keys: $requiredKeys.
Every question must have 4 unique options and exactly 1 correct answer.
Avoid long explanations. Keep it concise.
The "explanation" field MUST be concrete numbered steps (e.g. "1) ... 2) ... 3) ..."),
not a general definition of the concept.''',
    id: '''
Buat soal pretest adaptif singkat dalam Bahasa Indonesia.
Hanya keluarkan key difficulty berikut: $requiredKeys.
Setiap soal wajib punya 4 opsi unik dan 1 jawaban benar.
Hindari penjelasan panjang. Tetap ringkas.
Field "explanation" WAJIB berupa langkah konkret bernomor (mis. "1) ... 2) ... 3) ..."),
bukan definisi konsep umum.''',
    args: [requiredKeys],
  );

  // ── Sign-in developer tools ─────────────────────────────────────────────
  String get devModeLabel =>
      _t('devModeLabel', en: 'Dev Mode', id: 'Mode Dev');
  String get devBypassTitle =>
      _t('devBypassTitle', en: 'Developer Bypass', id: 'Bypass Developer');
  String get devBypassSubtitle =>
      _t('devBypassSubtitle', en: 'Skip real authentication in debug builds.', id: 'Lewati autentikasi asli di build debug.');
  String get devOnboardingIncompleteLabel =>
      _t('devOnboardingIncompleteLabel', en: 'Signed in, but onboarding not completed yet.', id: 'Sudah masuk, tapi onboarding belum selesai.');
  String get startAtOnboardingLabel =>
      _t('startAtOnboardingLabel', en: 'Start at onboarding', id: 'Mulai dari onboarding');
  String get jumpToHomeLabel =>
      _t('jumpToHomeLabel', en: 'Jump to home', id: 'Langsung ke beranda');
  String get devSignedInLabel =>
      _t('devSignedInLabel', en: 'Signed in and marked onboarding complete.', id: 'Masuk dan onboarding ditandai selesai.');

  // ── Demo tracks & queue (shown before backend data arrives) ─────────────
  String get demoLimitsFromGraphsTitle =>
      _t('demoLimitsFromGraphsTitle', en: 'Limits from graphs', id: 'Limit dari grafik');
  String get demoLimitsFromGraphsReason =>
      _t('demoLimitsFromGraphsReason', en: 'Why now? This unlocks continuity and\nfirst derivative intuition.', id: 'Kenapa sekarang? Ini membuka kontinuitas dan\nintuisi turunan pertama.');
  String get demoDerivativeRulesTitle =>
      _t('demoDerivativeRulesTitle', en: 'Derivative rules', id: 'Aturan turunan');
  String get demoFunctionCompositionTitle =>
      _t('demoFunctionCompositionTitle', en: 'Function composition review', id: 'Review komposisi fungsi');
  String get demoContinueCalculusTitle =>
      _t('demoContinueCalculusTitle', en: 'Continue Calculus I', id: 'Lanjutkan Kalkulus I');
  String get demoContinueCalculusSubtitle =>
      _t('demoContinueCalculusSubtitle', en: 'Limits, derivatives, applications', id: 'Limit, turunan, penerapan');
  String get demoLinearAlgebraTitle =>
      _t('demoLinearAlgebraTitle', en: 'Linear Algebra', id: 'Aljabar Linear');
  String get demoLinearAlgebraSubtitle =>
      _t('demoLinearAlgebraSubtitle', en: 'Vectors, matrices, transformations', id: 'Vektor, matriks, transformasi');
  String get demoDiscreteMathTitle =>
      _t('demoDiscreteMathTitle', en: 'Discrete Math', id: 'Matematika Diskret');
  String get demoDiscreteMathSubtitle =>
      _t('demoDiscreteMathSubtitle', en: 'Logic, sets, graphs, counting', id: 'Logika, himpunan, graf, kombinatorika');
  String get demoDerivativesIntuitionTitle =>
      _t('demoDerivativesIntuitionTitle', en: 'Derivatives intuition', id: 'Intuisi turunan');
  String get demoDerivativesIntuitionSubtitle =>
      _t('demoDerivativesIntuitionSubtitle', en: 'What does a derivative tell us?', id: 'Apa yang sebenarnya diberitahu oleh turunan?');
  String get demoLimitsFromGraphsSubtitle =>
      _t('demoLimitsFromGraphsSubtitle', en: 'Approaching a value without touching it', id: 'Mendekati sebuah nilai tanpa menyentuhnya');
  String get demoCalculusOneLabel =>
      _t('demoCalculusOneLabel', en: 'Calculus I', id: 'Kalkulus I');
  String get demoCalculusLabel =>
      _t('demoCalculusLabel', en: 'Calculus', id: 'Kalkulus');
  String get demoDerivativeRulesReason =>
      _t('demoDerivativeRulesReason', en: "Why now? You're ready after limits and\nslope interpretation.", id: 'Kenapa sekarang? Kamu sudah siap setelah limit dan\ninterpretasi gradien.');
  String get demoFunctionCompositionReason =>
      _t('demoFunctionCompositionReason', en: 'Why now? Needed before chain rule and\nimplicit differentiation.', id: 'Kenapa sekarang? Dibutuhkan sebelum aturan rantai dan\nturunan implisit.');
  String demoLessonMetaLabel(int minutes, String difficulty) => _tf(
    'demoLessonMetaLabel',
    en: '$minutes min   •   ${difficultyLabel(difficulty)}',
    id: '$minutes menit   •   ${difficultyLabel(difficulty)}',
    args: [minutes, difficultyLabel(difficulty)],
  );
  String get reviewNowShortLabel =>
      _t('reviewNowShortLabel', en: 'Review', id: 'Tinjau');
  String demoCurrentTrackMeta(int percent) => _tf(
    'demoCurrentTrackMeta',
    en: 'Current track   •   $percent% complete',
    id: 'Track saat ini   •   $percent% selesai',
    args: [percent],
  );
  String demoCreatedTrackMeta(int percent) => _tf(
    'demoCreatedTrackMeta',
    en: 'Created track   •   $percent% complete',
    id: 'Track buatanmu   •   $percent% selesai',
    args: [percent],
  );
  String get demoCreatedTrackReadyMeta =>
      _t('demoCreatedTrackReadyMeta', en: 'Created track   •   ready to continue', id: 'Track buatanmu   •   siap dilanjutkan');

  String gradeValue(String level) => _tf(
    'gradeValue',
    en: 'Grade $level',
    id: 'Kelas $level',
    args: [level],
  );

  String subjectLabel(String key) => switch (key) {
    'Math' => _t('subjectLabel.Math', en: 'Math', id: 'Matematika'),
    'Matematika' => _t('subjectLabel.Matematika', en: 'Math', id: 'Matematika'),
    'Physics' => _t('subjectLabel.Physics', en: 'Physics', id: 'Fisika'),
    'Fisika' => _t('subjectLabel.Fisika', en: 'Physics', id: 'Fisika'),
    'Chemistry' => _t('subjectLabel.Chemistry', en: 'Chemistry', id: 'Kimia'),
    'Kimia' => _t('subjectLabel.Kimia', en: 'Chemistry', id: 'Kimia'),
    'Biology' => _t('subjectLabel.Biology', en: 'Biology', id: 'Biologi'),
    'Biologi' => _t('subjectLabel.Biologi', en: 'Biology', id: 'Biologi'),
    'Science' => _t('subjectLabel.Science', en: 'Science', id: 'IPA'),
    'IPA' => _t('subjectLabel.IPA', en: 'Science', id: 'IPA'),
    'IPAS' => _t('subjectLabel.IPAS', en: 'Science', id: 'IPAS'),
    _ => key,
  };

  String subjectDescription(String key) => switch (key) {
    'Math' => _t('subjectDescription.Math', en: 'Algebra, Geometry, Calculus', id: 'Aljabar, Geometri, Kalkulus'),
    'Physics' => _t('subjectDescription.Physics', en: 'Mechanics, Waves, Thermo', id: 'Mekanika, Gelombang, Termodinamika'),
    'Chemistry' => _t('subjectDescription.Chemistry', en: 'Stoichiometry, Reactions', id: 'Stoikiometri, Reaksi'),
    'Biology' => _t('subjectDescription.Biology', en: 'Cell, Genetics, Ecology', id: 'Sel, Genetika, Ekologi'),
    _ => key,
  };

  String languageDisplay(String value) => value;

  String studyGoalDisplay(String value) => switch (value) {
    'Build strong foundations' => _t('studyGoalDisplay.Build strong foundations', en: 'Build strong foundations', id: 'Bangun fondasi yang kuat'),
    'Improve understanding' => _t('studyGoalDisplay.Improve understanding', en: 'Improve understanding', id: 'Perdalam pemahaman'),
    'Prepare for exams' => _t('studyGoalDisplay.Prepare for exams', en: 'Prepare for exams', id: 'Persiapan ujian'),
    'Learn faster' => _t('studyGoalDisplay.Learn faster', en: 'Learn faster', id: 'Belajar lebih cepat'),
    'Stay consistent' => _t('studyGoalDisplay.Stay consistent', en: 'Stay consistent', id: 'Tetap konsisten'),
    _ => value,
  };

  String dailyStudyTimeDisplay(String value) => switch (value) {
    '15-30 minutes' => _t('dailyStudyTimeDisplay.15-30 minutes', en: '15-30 minutes', id: '15-30 menit'),
    '30-45 minutes' => _t('dailyStudyTimeDisplay.30-45 minutes', en: '30-45 minutes', id: '30-45 menit'),
    '45-60 minutes' => _t('dailyStudyTimeDisplay.45-60 minutes', en: '45-60 minutes', id: '45-60 menit'),
    '1-2 hours' => _t('dailyStudyTimeDisplay.1-2 hours', en: '1-2 hours', id: '1-2 jam'),
    '2+ hours' => _t('dailyStudyTimeDisplay.2+ hours', en: '2+ hours', id: '2+ jam'),
    _ => value,
  };

  List<String> get localizedStudyGoalOptions =>
      onboardingStudyGoalOptions.map(studyGoalDisplay).toList();

  List<String> get localizedDailyStudyTimeOptions =>
      onboardingDailyStudyTimeOptions.map(dailyStudyTimeDisplay).toList();

  String difficultyLabel(String value) => switch (value.toLowerCase()) {
    'easy' => _t('difficultyLabel.easy', en: 'Easy', id: 'Mudah'),
    'medium' => _t('difficultyLabel.medium', en: 'Medium', id: 'Menengah'),
    'hard' => _t('difficultyLabel.hard', en: 'Hard', id: 'Sulit'),
    _ => value,
  };

  String estimatedDurationLabel(String value, String difficulty) => _tf(
    'estimatedDurationLabel',
    en: 'Estimated $value   •   ${difficultyLabel(difficulty)}',
    id: 'Estimasi $value   •   ${difficultyLabel(difficulty)}',
    args: [value, difficultyLabel(difficulty)],
  );

  String weeklyScoreDate(String value) => value;

  List<String> get weekShortLabels => _tl(
    'weekShortLabels',
    en: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    id: const ['M', 'S', 'S', 'R', 'K', 'J', 'S'],
  );

  /// Indonesian titles for the static fallback knowledge graph. The live graph
  /// arrives already localized from the backend; this map keeps the offline
  /// fallback from dropping back into English mid-session.
  static const _fallbackGraphLabelsId = <String, String>{
    'Mathematics Prerequisite Map': 'Peta Prasyarat Matematika',
    'Knowledge Map': 'Peta Pengetahuan',
    'Primary Math': 'Matematika SD',
    'Lower Secondary': 'SMP',
    'Algebra and Functions': 'Aljabar dan Fungsi',
    'Precalculus': 'Prakalkulus',
    'Limits and Continuity': 'Limit dan Kekontinuan',
    'Calculus 1': 'Kalkulus 1',
    'Calculus 2': 'Kalkulus 2',
    'Calculus 3': 'Kalkulus 3',
    'Counting': 'Membilang',
    'Place Value': 'Nilai Tempat',
    'Arithmetic Operations': 'Operasi Hitung',
    'Fractions and Decimals': 'Pecahan dan Desimal',
    'Basic Shapes and Measurement': 'Bangun Dasar dan Pengukuran',
    'Tables, Charts, and Mean': 'Tabel, Diagram, dan Rata-rata',
    'Integers and Rational Numbers': 'Bilangan Bulat dan Rasional',
    'Exponents and Roots Basics': 'Dasar Pangkat dan Akar',
    'Linear Equations': 'Persamaan Linear',
    'Coordinate Graphing': 'Menggambar pada Koordinat',
    'Slope and Intercepts': 'Gradien dan Titik Potong',
    'Pythagorean Theorem': 'Teorema Pythagoras',
    'Functions, Domain, and Range': 'Fungsi, Domain, dan Range',
    'Function Composition and Inverses': 'Komposisi Fungsi dan Invers',
    'Exponential and Logarithmic Functions': 'Fungsi Eksponen dan Logaritma',
    'Quadratic and Polynomial Functions': 'Fungsi Kuadrat dan Polinomial',
    'Rational Functions': 'Fungsi Rasional',
    'Sequences, Series, Sigma Notation': 'Barisan, Deret, Notasi Sigma',
    'Analytic Geometry and Conics': 'Geometri Analitik dan Irisan Kerucut',
    'Trigonometric Functions and Graphs': 'Fungsi Trigonometri dan Grafiknya',
    'Trigonometric Identities and Equations':
        'Identitas dan Persamaan Trigonometri',
    'Vectors, Parametric, and Polar Basics':
        'Dasar Vektor, Parametrik, dan Polar',
    'Precalculus Fluency': 'Kelancaran Prakalkulus',
    'Intuitive Limits': 'Limit secara Intuitif',
    'Limit Laws and Algebraic Techniques': 'Sifat Limit dan Teknik Aljabar',
    'Trigonometric Limits and Squeeze Theorem':
        'Limit Trigonometri dan Teorema Apit',
    'Continuity and Intermediate Value Theorem':
        'Kekontinuan dan Teorema Nilai Antara',
    'Derivative Definition': 'Definisi Turunan',
    'Derivative Rules': 'Aturan Turunan',
    'Chain Rule and Implicit Differentiation':
        'Aturan Rantai dan Turunan Implisit',
    'Related Rates, Optimization, Curve Sketching':
        'Laju Berkaitan, Optimasi, Sketsa Kurva',
    'Antiderivatives, Riemann Sums, Definite Integrals':
        'Antiturunan, Jumlah Riemann, Integral Tentu',
    'Fundamental Theorem of Calculus': 'Teorema Dasar Kalkulus',
    'Integration Techniques': 'Teknik Pengintegralan',
    'Area, Volume, Work, Fluid Force': 'Luas, Volume, Usaha, Gaya Fluida',
    'Convergence Tests and Power Series': 'Uji Kekonvergenan dan Deret Pangkat',
    'Parametric and Polar Calculus': 'Kalkulus Parametrik dan Polar',
    '3D Coordinates and Vector Operations': 'Koordinat 3D dan Operasi Vektor',
    'Partial Derivatives and Gradients': 'Turunan Parsial dan Gradien',
    'Double and Triple Integrals': 'Integral Lipat Dua dan Tiga',
    'Vector Fields, Line Integrals, Green, Stokes, Divergence':
        'Medan Vektor, Integral Garis, Green, Stokes, Divergensi',
  };

  /// Localizes a label from the static fallback knowledge graph. Unknown
  /// labels (anything backend-provided) pass through untouched.
  String knowledgeGraphLabel(String value) {
    if (languageCode == 'en') {
      return value;
    }
    if (languageCode == 'id') {
      return _fallbackGraphLabelsId[value] ?? value;
    }
    return copyTranslations[languageCode]?['knowledgeGraph.$value'] ?? value;
  }

  String layerLabel(int index) => _tf(
    'layerLabel',
    en: 'Layer $index',
    id: 'Lapisan $index',
    args: [index],
  );

  String nodeStatusLabel(String value) => switch (value) {
    'MASTERED' => _t('nodeStatusLabel.MASTERED', en: 'MASTERED', id: 'MENGUASAI'),
    'IN PROGRESS' => _t('nodeStatusLabel.IN PROGRESS', en: 'IN PROGRESS', id: 'SEDANG BELAJAR'),
    'REVIEW' => _t('nodeStatusLabel.REVIEW', en: 'REVIEW', id: 'TINJAU'),
    'READY' => _t('nodeStatusLabel.READY', en: 'READY', id: 'SIAP'),
    'GAP' => _t('nodeStatusLabel.GAP', en: 'GAP', id: 'GAP'),
    'LOCKED' => _t('nodeStatusLabel.LOCKED', en: 'LOCKED', id: 'TERKUNCI'),
    _ => value,
  };

  // ---- Extracted from inline page ternaries ----
  String get loadingPosttestLabel =>
      _t('loadingPosttestLabel', en: 'Loading Posttest', id: 'Memuat Posttest');
  String get preparingAdaptivePosttestFromBackendLabel =>
      _t('preparingAdaptivePosttestFromBackendLabel', en: 'Preparing adaptive posttest from backend.', id: 'Menyiapkan soal posttest adaptif dari backend.');
  String get posttestUnavailableLabel =>
      _t('posttestUnavailableLabel', en: 'Posttest unavailable', id: 'Posttest tidak tersedia');
  String get backendReturnedNoPosttestQuestionsLabel =>
      _t('backendReturnedNoPosttestQuestionsLabel', en: 'Backend returned no posttest questions.', id: 'Backend tidak mengembalikan soal posttest.');
  String get tryAgainLabel2 =>
      _t('tryAgainLabel2', en: 'Try again', id: 'Coba lagi');
  String get questionsMediumHardBasedWhatLabel =>
      _t('questionsMediumHardBasedWhatLabel', en: '10 questions: 3 medium and 7 hard based on what you learned.', id: '10 soal: 3 medium dan 7 hard berdasarkan materi yang kamu pelajari.');
  String get continueLabel2 =>
      _t('continueLabel2', en: 'Continue', id: 'Lanjut');
  String get finishPosttestLabel =>
      _t('finishPosttestLabel', en: 'Finish posttest', id: 'Selesai posttest');
  String get loadingDailyEvalsLabel =>
      _t('loadingDailyEvalsLabel', en: 'Loading Daily Evals', id: 'Memuat Evaluasi Harian');
  String get fetchingSpacedReviewQuestionsFromLabel =>
      _t('fetchingSpacedReviewQuestionsFromLabel', en: 'Fetching spaced-review questions from backend.', id: 'Mengambil soal spaced review dari backend.');
  String get dailyEvalsUnavailableLabel =>
      _t('dailyEvalsUnavailableLabel', en: 'Daily Evals unavailable', id: 'Evaluasi Harian tidak tersedia');
  String get backendReturnedNoReviewQuestionsLabel =>
      _t('backendReturnedNoReviewQuestionsLabel', en: 'Backend returned no review questions.', id: 'Backend tidak mengembalikan soal review.');
  String get dashboardUnavailableLabel =>
      _t('dashboardUnavailableLabel', en: 'Dashboard unavailable', id: 'Dashboard tidak tersedia');
  String get retryLabel2 =>
      _t('retryLabel2', en: 'Retry', id: 'Coba lagi');
  String get loadingDashboardLabel =>
      _t('loadingDashboardLabel', en: 'Loading dashboard', id: 'Memuat dashboard');
  String get fetchingProfileFromBackendLabel =>
      _t('fetchingProfileFromBackendLabel', en: 'Fetching your profile from backend.', id: 'Mengambil profilmu dari backend.');
  String get elementarySchoolLabel =>
      _t('elementarySchoolLabel', en: 'Elementary school', id: 'Sekolah dasar');
  String get juniorHighSchoolLabel =>
      _t('juniorHighSchoolLabel', en: 'Junior high school', id: 'SMP');
  String get seniorHighSchoolLabel =>
      _t('seniorHighSchoolLabel', en: 'Senior high school', id: 'SMA');
  String get universityLabel =>
      _t('universityLabel', en: 'University', id: 'Universitas');
  String get pretestProgressLabel =>
      _t('pretestProgressLabel', en: 'Pretest in progress', id: 'Pretest belum selesai');
  String get submittedAnswersSavedContinueFromLabel =>
      _t('submittedAnswersSavedContinueFromLabel', en: 'Your submitted answers are saved. Continue from your latest question.', id: 'Jawaban yang sudah dikirim tetap tersimpan. Lanjutkan dari soal terakhir.');
  String get continuePretestLabel =>
      _t('continuePretestLabel', en: 'Continue pretest', id: 'Lanjutkan pretest');
  String get createLearningGoalLabel =>
      _t('createLearningGoalLabel', en: 'Create learning goal', id: 'Buat goal belajar baru');
  String get createLearningGoalSoWicaraLabel =>
      _t('createLearningGoalSoWicaraLabel', en: 'Create a learning goal so WICARA can prepare a track and workspace.', id: 'Buat goal belajar baru agar WICARA bisa menyiapkan track dan workspace.');
  String get pickGoalSubjectBeforeOpeningLabel =>
      _t('pickGoalSubjectBeforeOpeningLabel', en: 'Pick a goal in this subject before opening workspace.', id: 'Pilih goal subject ini dulu sebelum masuk workspace.');
  String get nextModuleLabel =>
      _t('nextModuleLabel', en: 'Next module', id: 'Modul berikutnya');
  String get progressLabel2 =>
      _t('progressLabel2', en: 'In progress', id: 'Sedang belajar');
  String get readyLabel =>
      _t('readyLabel', en: 'Ready', id: 'Siap lanjut');
  String get completedLabel =>
      _t('completedLabel', en: 'Completed', id: 'Selesai');
  String get pausedLabel =>
      _t('pausedLabel', en: 'Paused', id: 'Dijeda');
  String get needsReviewLabel2 =>
      _t('needsReviewLabel2', en: 'Needs review', id: 'Perlu review');
  String get activeLabel =>
      _t('activeLabel', en: 'Active', id: 'Aktif');
  String get noModuleReadyYetLabel =>
      _t('noModuleReadyYetLabel', en: 'No module is ready yet', id: 'Belum ada modul yang siap');
  String get goalDoesNotHaveActiveLabel =>
      _t('goalDoesNotHaveActiveLabel', en: 'This goal does not have an active module yet.', id: 'Goal ini belum punya modul aktif.');
  String get createChooseAnotherGoalStartLabel =>
      _t('createChooseAnotherGoalStartLabel', en: 'Create or choose another goal to start learning.', id: 'Buat atau pilih goal lain untuk mulai belajar.');
  String get noGeneratedVideosReadyYetLabel =>
      _t('noGeneratedVideosReadyYetLabel', en: 'No generated videos are ready yet.', id: 'Belum ada video yang selesai dibuat.');
  String get videosFromBackendJobsSavedLabel =>
      _t('videosFromBackendJobsSavedLabel', en: 'Videos from backend jobs are saved here.', id: 'Video dari job backend tersimpan di sini.');
  String get bundledTemplatePackLabel =>
      _t('bundledTemplatePackLabel', en: 'Template pack · bundled in the app', id: 'Paket template · tersimpan di aplikasi');
  String get noDailyEvaluationAssignedYetLabel =>
      _t('noDailyEvaluationAssignedYetLabel', en: 'No daily evaluation assigned yet.', id: 'Belum ada evaluasi harian yang ditugaskan.');
  String get noEvaluationLabel =>
      _t('noEvaluationLabel', en: 'No evaluation', id: 'Belum ada evaluasi');
  String get answerConfidenceLevelLabel =>
      _t('answerConfidenceLevelLabel', en: 'Answer confidence level', id: 'Tingkat keyakinan jawaban');
  String get howConfidentAnswerLabel =>
      _t('howConfidentAnswerLabel', en: 'How confident are you in your answer?', id: 'Seberapa yakin dengan jawabanmu?');
  String get chooseNotConfidentVeryConfidentLabel =>
      _t('chooseNotConfidentVeryConfidentLabel', en: 'Choose 0 (not confident) to 10 (very confident).', id: 'Pilih 0 (tidak yakin) sampai 10 (sangat yakin).');
  String get masteryConfirmedLabel =>
      _t('masteryConfirmedLabel', en: 'Mastery confirmed', id: 'Mastery terkonfirmasi');
  String get reviewNeededFromPosttestResultsLabel =>
      _t('reviewNeededFromPosttestResultsLabel', en: 'Review needed from posttest results', id: 'Perlu review dari hasil posttest');
  String get posttestResultsLabel =>
      _t('posttestResultsLabel', en: 'Posttest Results', id: 'Hasil Posttest');
  String get scoreSummaryLearningProgressionDecisionLabel =>
      _t('scoreSummaryLearningProgressionDecisionLabel', en: 'The score summary and learning progression decision come from the backend.', id: 'Ringkasan skor dan keputusan kelanjutan belajar berasal dari backend.');
  String get correctnessLabel =>
      _t('correctnessLabel', en: 'Correctness', id: 'Correctness');
  String get correctLabel2 =>
      _t('correctLabel2', en: 'Correct', id: 'Benar');
  String get decisionLabel =>
      _t('decisionLabel', en: 'Decision', id: 'Keputusan');
  String get trackProgressLabel =>
      _t('trackProgressLabel', en: 'Track progress', id: 'Progress track');
  String get continueLearningLabel2 =>
      _t('continueLearningLabel2', en: 'Continue learning', id: 'Lanjut belajar');
  String get reviewWeakAreasLabel =>
      _t('reviewWeakAreasLabel', en: 'Review weak areas', id: 'Review area lemah');
  String get moduleCompleteNextModuleNowLabel =>
      _t('moduleCompleteNextModuleNowLabel', en: 'This module is complete and the next module is now available.', id: 'Modul ini selesai dan modul berikutnya sudah dibuka.');
  String get learningGoalCompleteLabel =>
      _t('learningGoalCompleteLabel', en: 'This learning goal is complete.', id: 'Target belajar ini sudah diselesaikan.');
  String get backendConfirmedModuleAsPassedLabel =>
      _t('backendConfirmedModuleAsPassedLabel', en: 'The backend confirmed this module as passed. Refresh Home to see the next track step.', id: 'Backend mengonfirmasi modul ini lulus. Muat ulang Beranda untuk melihat kelanjutan track.');
  String get backendRequiresReviewRemainingWeakLabel =>
      _t('backendRequiresReviewRemainingWeakLabel', en: 'The backend requires review of the remaining weak areas before another attempt.', id: 'Backend meminta review area yang masih lemah sebelum mencoba lagi.');
  String get conceptResultsLabel =>
      _t('conceptResultsLabel', en: 'Concept results', id: 'Hasil konsep');
  String get noPosttestNodesHaveBeenLabel =>
      _t('noPosttestNodesHaveBeenLabel', en: 'No posttest nodes have been evaluated yet.', id: 'Belum ada node posttest yang dinilai.');
  String get scoreLabel2 =>
      _t('scoreLabel2', en: 'Score', id: 'Skor');
  String get profileUpdatedLabel =>
      _t('profileUpdatedLabel', en: 'Profile updated.', id: 'Profil berhasil diperbarui.');
  String get localAiLitertLmLabel =>
      _t('localAiLitertLmLabel', en: 'Local AI (LiteRT-LM)', id: 'AI Lokal (LiteRT-LM)');
  String get installInitializeModelLabel =>
      _t('installInitializeModelLabel', en: 'Install & initialize model', id: 'Install & initialize model');
  String get reportUnavailableLabel =>
      _t('reportUnavailableLabel', en: 'Report unavailable', id: 'Laporan belum tersedia');
  String get openDetailsLabel =>
      _t('openDetailsLabel', en: 'Open details', id: 'Buka detail');
  String get loadingWeekLabel =>
      _t('loadingWeekLabel', en: 'Loading this week', id: 'Memuat minggu ini');
  String get syncingLabel =>
      _t('syncingLabel', en: 'Syncing', id: 'Sinkron');
  String get fetchingReportDataFromBackendLabel =>
      _t('fetchingReportDataFromBackendLabel', en: 'Fetching report data from backend.', id: 'Mengambil data laporan dari backend.');
  String get noDataYetLabel =>
      _t('noDataYetLabel', en: 'No data yet', id: 'Belum ada data');
  String get startLabel =>
      _t('startLabel', en: 'Start', id: 'Mulai');
  String get takeDailyEvaluationsFirstPopulateLabel =>
      _t('takeDailyEvaluationsFirstPopulateLabel', en: 'Take daily evaluations first to populate this chart.', id: 'Kerjakan evaluasi harian dulu supaya grafik terisi.');
  String get weekTrendLabel =>
      _t('weekTrendLabel', en: '4-week trend', id: 'Tren 4 minggu');
  String get ptsLabel =>
      _t('ptsLabel', en: 'pts', id: 'poin');
  String get averageAccuracyLabel =>
      _t('averageAccuracyLabel', en: 'Average accuracy', id: 'Rata-rata akurasi');
  String get scoresLabel =>
      _t('scoresLabel', en: 'Scores', id: 'Nilai (Score)');
  String get preTestPostTestChangeLabel =>
      _t('preTestPostTestChangeLabel', en: 'Pre-test, Post-test, and Change represent average score movement.', id: 'Pre-test, Post-test, dan Perubahan adalah perubahan nilai rata-rata.');
  String get preTestLabel2 =>
      _t('preTestLabel2', en: 'Pre-test', id: 'Pretest');
  String get postTestLabel2 =>
      _t('postTestLabel2', en: 'Post-test', id: 'Posttest');
  String get changeLabel =>
      _t('changeLabel', en: 'Change', id: 'Perubahan');
  String get learningReportUnavailableLabel =>
      _t('learningReportUnavailableLabel', en: 'Learning report is unavailable', id: 'Laporan Belajar belum tersedia');
  String get loadingLearningReportLabel =>
      _t('loadingLearningReportLabel', en: 'Loading Learning Report', id: 'Memuat Laporan Belajar');
  String get fetchingWeeklyProgressSummaryLabel =>
      _t('fetchingWeeklyProgressSummaryLabel', en: 'Fetching weekly progress summary.', id: 'Mengambil ringkasan progres mingguan.');
  String get weekSummaryLabel =>
      _t('weekSummaryLabel', en: 'This Week Summary', id: 'Ringkasan Minggu Ini');
  String get answerAccuracyLabel =>
      _t('answerAccuracyLabel', en: 'Answer Accuracy', id: 'Akurasi Jawaban');
  String get fixedGapsLabel2 =>
      _t('fixedGapsLabel2', en: 'Fixed Gaps', id: 'Gap Tertutup');
  String get remainingGapsLabel2 =>
      _t('remainingGapsLabel2', en: 'Remaining Gaps', id: 'Gap Tersisa');
  String get answerAccuracyPercentageCorrectAnswersLabel =>
      _t('answerAccuracyPercentageCorrectAnswersLabel', en: 'Answer accuracy = percentage of correct answers in the selected date range.', id: 'Akurasi jawaban = persentase jawaban benar pada rentang tanggal terpilih.');
  String get weekProgressLabel =>
      _t('weekProgressLabel', en: '4-Week Progress', id: 'Perkembangan 4 Minggu');
  String get trackAccuracyAttemptVolumeGapLabel =>
      _t('trackAccuracyAttemptVolumeGapLabel', en: 'Track accuracy, attempt volume, and gap movement per week.', id: 'Lihat akurasi, jumlah jawaban, dan pergerakan gap tiap minggu.');
  String get effortVsImpactLabel =>
      _t('effortVsImpactLabel', en: 'Effort vs impact', id: 'Usaha vs Dampak');
  String get attemptsLabel =>
      _t('attemptsLabel', en: 'Attempts', id: 'Jawaban');
  String get activeDaysLabel =>
      _t('activeDaysLabel', en: 'Active days', id: 'Hari aktif');
  String get impactLabel =>
      _t('impactLabel', en: 'Impact', id: 'Dampak');
  String get strongConceptsVsNeedsImprovementLabel =>
      _t('strongConceptsVsNeedsImprovementLabel', en: 'Strong Concepts vs Needs Improvement', id: 'Konsep Kuat vs Perlu Diperbaiki');
  String get focusConceptsBiggestLiftOnesLabel =>
      _t('focusConceptsBiggestLiftOnesLabel', en: 'Focus on concepts with the biggest lift and the ones still at risk.', id: 'Fokus pada konsep yang naik paling besar dan yang masih rawan.');
  String get numberRightShowsConceptMasteryLabel =>
      _t('numberRightShowsConceptMasteryLabel', en: 'The number on the right shows concept mastery change (%) in this range.', id: 'Angka di kanan menunjukkan perubahan mastery konsep (%) pada rentang ini.');
  String get nowStrongLabel =>
      _t('nowStrongLabel', en: 'Now Strong', id: 'Yang Sudah Kuat');
  String get noConceptsShowedSignificantImprovementLabel =>
      _t('noConceptsShowedSignificantImprovementLabel', en: 'No concepts showed significant improvement this week.', id: 'Belum ada konsep yang naik signifikan minggu ini.');
  String get needsImprovementLabel =>
      _t('needsImprovementLabel', en: 'Needs Improvement', id: 'Yang Perlu Diperbaiki');
  String get noRiskConceptsRangeLabel =>
      _t('noRiskConceptsRangeLabel', en: 'No at-risk concepts in this range.', id: 'Tidak ada konsep rawan pada rentang ini.');
  String get weekLabel2 =>
      _t('weekLabel2', en: 'This week', id: 'Minggu ini');
  String get lastWeekLabel =>
      _t('lastWeekLabel', en: 'Last week', id: 'Minggu lalu');
  String get lastWeeksLabel =>
      _t('lastWeeksLabel', en: 'Last 4 weeks', id: '4 minggu terakhir');
  String get averageScoreLabel =>
      _t('averageScoreLabel', en: 'Average Score', id: 'Rata-rata Nilai');
  String get notEnoughMatchedPreTestLabel =>
      _t('notEnoughMatchedPreTestLabel', en: 'Not enough matched pre-test and post-test data yet.', id: 'Belum cukup data pre-test dan post-test pada konsep yang sama.');
  String get reportRequestTimedOutPleaseLabel =>
      _t('reportRequestTimedOutPleaseLabel', en: 'The report request timed out. Please try again.', id: 'Permintaan laporan melewati batas waktu. Coba lagi.');
  String get reportCouldNotLoadedPleaseLabel =>
      _t('reportCouldNotLoadedPleaseLabel', en: 'The report could not be loaded. Please try again.', id: 'Laporan belum bisa dimuat. Coba lagi sebentar.');
  String get completeDataLabel =>
      _t('completeDataLabel', en: 'Complete Data', id: 'Data Lengkap');
  String get partialDataLabel =>
      _t('partialDataLabel', en: 'Partial Data', id: 'Data Sebagian');
  String get earlyDataLabel =>
      _t('earlyDataLabel', en: 'Early Data', id: 'Data Awal');
  String get highLeverageLabel =>
      _t('highLeverageLabel', en: 'High leverage', id: 'Efektif');
  String get steadyLabel =>
      _t('steadyLabel', en: 'Steady', id: 'Stabil');
  String get needsFocusLabel =>
      _t('needsFocusLabel', en: 'Needs focus', id: 'Perlu fokus');
  String get noSignalLabel =>
      _t('noSignalLabel', en: 'No signal', id: 'Belum terbaca');
  String get reportBuiltFromSufficientlyCompleteLabel =>
      _t('reportBuiltFromSufficientlyCompleteLabel', en: 'This report is built from sufficiently complete history.', id: 'Laporan disusun dari riwayat data yang sudah cukup lengkap.');
  String get dataExistsButComparisonHistoryLabel =>
      _t('dataExistsButComparisonHistoryLabel', en: 'Data exists, but comparison history is still incomplete.', id: 'Data sudah ada, tapi histori pembanding belum penuh.');
  String get dataStillThinSoSomeLabel =>
      _t('dataStillThinSoSomeLabel', en: 'Data is still thin, so some insights are early estimates.', id: 'Data masih tipis, jadi beberapa insight masih estimasi awal.');
  String get dataQualityStatusNotDefinedLabel =>
      _t('dataQualityStatusNotDefinedLabel', en: 'Data quality status is not defined yet.', id: 'Status kualitas data belum terdefinisi.');
  String get overallLabel2 =>
      _t('overallLabel2', en: 'Overall', id: 'Umum');
  String get applicationLabel2 =>
      _t('applicationLabel2', en: 'Application', id: 'Penerapan');
  String get analysisLabel2 =>
      _t('analysisLabel2', en: 'Analysis', id: 'Penalaran');
  String get weekLabel3 =>
      _t('weekLabel3', en: '0 this week', id: '0 minggu ini');
  String get learningPerformanceLabel =>
      _t('learningPerformanceLabel', en: 'Learning performance', id: 'Performa Belajar');
  String get noAssessmentAttemptsRangeYetLabel =>
      _t('noAssessmentAttemptsRangeYetLabel', en: 'No assessment attempts in this range yet. Take a daily evaluation to build this graph.', id: 'Belum ada attempt evaluasi pada rentang ini. Kerjakan evaluasi harian untuk mengisi grafik.');
  String get useAsLearningGoalLabel =>
      _t('useAsLearningGoalLabel', en: 'Use this as your learning goal?', id: 'Gunakan node ini sebagai goal?');
  String get chooseAnotherNodeLabel =>
      _t('chooseAnotherNodeLabel', en: 'Choose another node', id: 'Pilih node lain');
  String get startPretestLabel =>
      _t('startPretestLabel', en: 'Start pretest', id: 'Mulai pretest');
  String get activeGoalFoundLabel =>
      _t('activeGoalFoundLabel', en: 'Active goal found', id: 'Goal aktif ditemukan');
  String get backLabel2 =>
      _t('backLabel2', en: 'Back', id: 'Kembali');
  String get continueExistingGoalLabel =>
      _t('continueExistingGoalLabel', en: 'Continue existing goal', id: 'Lanjutkan goal ini');
  String get useAsNewGoalLabel =>
      _t('useAsNewGoalLabel', en: 'Use as new goal', id: 'Gunakan sebagai goal baru');
  String get visualizePrerequisitesGapsNextConceptsLabel =>
      _t('visualizePrerequisitesGapsNextConceptsLabel', en: 'Visualize prerequisites, gaps, and next concepts.', id: 'Visualisasikan prasyarat, gap, dan konsep berikutnya.');
  String get alreadyHaveActiveGoalNodeLabel =>
      _t('alreadyHaveActiveGoalNodeLabel', en: 'You already have an active goal for this node:', id: 'Kamu sudah punya goal aktif untuk node ini:');
  String get canContinueGoalGoBackLabel =>
      _t('canContinueGoalGoBackLabel', en: 'You can continue this goal, or go back to choose a node.', id: 'Kamu bisa lanjutkan goal ini, atau kembali memilih node.');
  String get findLearningGoalNodeLabel =>
      _t('findLearningGoalNodeLabel', en: 'Find learning goal node', id: 'Cari node goal belajar');
  String get searchAgainLabel =>
      _t('searchAgainLabel', en: 'Search again', id: 'Cari ulang dengan query baru');
  String get searchAgainNewQueryLabel =>
      _t('searchAgainNewQueryLabel', en: 'Search again with a new query', id: 'Cari ulang dengan query baru');
  String get sureWantTakeLabel =>
      _t('sureWantTakeLabel', en: 'Are you sure you want to take this?', id: 'Yakin ingin mengambil node ini?');
  String get nodeDetailLabel =>
      _t('nodeDetailLabel', en: 'Node detail', id: 'Detail node');
  String get descriptionLabel =>
      _t('descriptionLabel', en: 'Description', id: 'Deskripsi');
  String get subjectLabel2 =>
      _t('subjectLabel2', en: 'Subject', id: 'Mata pelajaran');
  String get matchLabel =>
      _t('matchLabel', en: 'Match', id: 'Kecocokan');
  String get seeGraphLabel =>
      _t('seeGraphLabel', en: 'See graph', id: 'Lihat graph');
  String get lockLabel =>
      _t('lockLabel', en: 'Lock', id: 'Kunci');
  String get findLearningGoalFirstLabel =>
      _t('findLearningGoalFirstLabel', en: 'Find the learning goal first', id: 'Cari goal belajar dulu');
  String get typeGoalThenWicaraWillLabel =>
      _t('typeGoalThenWicaraWillLabel', en: 'Type your goal, then WICARA will match it to a material node. The pretest starts only after you confirm the node.', id: 'Tulis tujuanmu, lalu WICARA akan mencocokkan ke node materi. Pretest baru mulai setelah node ini kamu setujui.');
  String get nodeNotCertainLabel =>
      _t('nodeNotCertainLabel', en: 'Node is not certain', id: 'Node belum pasti');
  String get tryAddingGradeSubjectMoreLabel =>
      _t('tryAddingGradeSubjectMoreLabel', en: 'Try adding grade, subject, or a more specific topic.', id: 'Coba tambahkan kelas, mata pelajaran, atau topik yang lebih spesifik.');
  String get pickClosestCandidateLabel =>
      _t('pickClosestCandidateLabel', en: 'Pick the closest candidate', id: 'Pilih kandidat yang paling mirip');
  String get recommendedNodeLabel =>
      _t('recommendedNodeLabel', en: 'Recommended node', id: 'Node rekomendasi');
  String get otherPossibleNodesLabel =>
      _t('otherPossibleNodesLabel', en: 'Other possible nodes', id: 'Kemungkinan node lain');
  String get editPromptLabel =>
      _t('editPromptLabel', en: 'Edit prompt', id: 'Ubah prompt');
  String get viewDetailLabel =>
      _t('viewDetailLabel', en: 'View detail', id: 'Lihat detail');
  String get descriptionNotFoundLabel =>
      _t('descriptionNotFoundLabel', en: 'Description not found.', id: 'Deskripsi tidak ditemukan.');
  String get nodeBelowGradeLevelCanLabel =>
      _t('nodeBelowGradeLevelCanLabel', en: 'This node is below your grade level; it can strengthen foundations.', id: 'Node ini lebih rendah dari level kelasmu; cocok untuk memperkuat fondasi.');
  String get nodeAboveGradeLevelMayLabel =>
      _t('nodeAboveGradeLevelMayLabel', en: 'This node is above your grade level; it may feel more challenging.', id: 'Node ini lebih tinggi dari level kelasmu; mungkin terasa lebih menantang.');
  String get nodeFitsGradeLevelLabel =>
      _t('nodeFitsGradeLevelLabel', en: 'This node fits your grade level.', id: 'Node ini sesuai dengan level kelasmu.');
  String get mathLabel =>
      _t('mathLabel', en: 'Math', id: 'Matematika');
  String get physicsLabel =>
      _t('physicsLabel', en: 'Physics', id: 'Fisika');
  String get chemistryLabel =>
      _t('chemistryLabel', en: 'Chemistry', id: 'Kimia');
  String get biologyLabel =>
      _t('biologyLabel', en: 'Biology', id: 'Biologi');
  String get uploadingWorkImageLabel =>
      _t('uploadingWorkImageLabel', en: 'Uploading your work image...', id: 'Mengupload foto pekerjaan...');
  String get answerSentEvaluatingWorkPreparingLabel =>
      _t('answerSentEvaluatingWorkPreparingLabel', en: 'Answer sent. Evaluating your work and preparing the next question...', id: 'Jawaban dikirim. Menilai langkah dan menyiapkan soal berikutnya...');
  String get submitAnswerLabel =>
      _t('submitAnswerLabel', en: 'Submit answer', id: 'Kirim jawaban');
  String get addReasoningSketchLabel =>
      _t('addReasoningSketchLabel', en: 'Add reasoning / sketch', id: 'Tambah cara / coretan');
  String get hideWorkEvidenceLabel =>
      _t('hideWorkEvidenceLabel', en: 'Hide work evidence', id: 'Tutup cara pengerjaan');
  String get workEvidenceLabel =>
      _t('workEvidenceLabel', en: 'Work evidence', id: 'Cara pengerjaan');
  String get typeStepsUploadPhotoWorkLabel =>
      _t('typeStepsUploadPhotoWorkLabel', en: 'Type your steps, upload a photo of your work, or use both. AI will read the image as solution steps.', id: 'Tulis langkahmu, upload foto pekerjaan, atau gunakan keduanya. Foto akan dibaca AI sebagai langkah pengerjaan.');
  String get writeSolutionStepsLabel =>
      _t('writeSolutionStepsLabel', en: 'Write your solution steps...', id: 'Tulis langkah pengerjaanmu...');
  String get uploadWorkImageLabel =>
      _t('uploadWorkImageLabel', en: 'Upload work image', id: 'Upload foto pekerjaan');
  String get removeImageLabel =>
      _t('removeImageLabel', en: 'Remove image', id: 'Hapus foto');
  String get submitAnswerEvidenceLabel =>
      _t('submitAnswerEvidenceLabel', en: 'Submit answer with evidence', id: 'Kirim jawaban dengan bukti');
  String get correctLabel3 =>
      _t('correctLabel3', en: 'correct', id: 'benar');
  String get noAnswersLabel =>
      _t('noAnswersLabel', en: 'No answers', id: 'Belum ada jawaban');
  String get officialMcqScoreLabel =>
      _t('officialMcqScoreLabel', en: 'Official MCQ score', id: 'Skor MCQ resmi');
  String get reportLabel =>
      _t('reportLabel', en: 'Report', id: 'Laporan');
  String get whatLooksStrongLabel =>
      _t('whatLooksStrongLabel', en: 'What looks strong', id: 'Yang sudah kuat');
  String get whatNeedsWorkLabel =>
      _t('whatNeedsWorkLabel', en: 'What needs work', id: 'Yang perlu diperbaiki');
  String get evidenceNotesLabel =>
      _t('evidenceNotesLabel', en: 'Evidence notes', id: 'Catatan evidence');
  String get checkedNodesLabel =>
      _t('checkedNodesLabel', en: 'Checked nodes', id: 'Node yang dicek');
  String get levelLabel =>
      _t('levelLabel', en: 'Level', id: 'Level');
  String get nextPathFocusLabel =>
      _t('nextPathFocusLabel', en: 'Next path focus', id: 'Fokus path berikutnya');
  String get reasoningSuggestsMisconceptionNodeLabel =>
      _t('reasoningSuggestsMisconceptionNodeLabel', en: 'Reasoning suggests a misconception on this node.', id: 'Reasoning menunjukkan miskonsepsi pada node ini.');
  String get therePossibleCarelessChoiceDespiteLabel =>
      _t('therePossibleCarelessChoiceDespiteLabel', en: 'There is a possible careless choice despite reasonable reasoning.', id: 'Ada indikasi salah pilih walau langkah cukup masuk akal.');
  String get evidenceWasStoredButNoLabel =>
      _t('evidenceWasStoredButNoLabel', en: 'Evidence was stored, but no written steps were available to analyze.', id: 'Evidence tersimpan, tetapi tidak ada langkah tertulis untuk dianalisis.');

  // ---- Templated copy extracted from inline page ternaries ----
  String noSubjectGoalsYetLabel(String subject) => _tf(
    'noSubjectGoalsYetLabel',
    en: 'No $subject goals yet',
    id: 'Belum ada goal $subject',
    args: [subject],
  );
  String subjectGoalsLabel(String subject) => _tf(
    'subjectGoalsLabel',
    en: '$subject goals',
    id: 'Goal $subject',
    args: [subject],
  );
  String percentCompleteLabel(int percent) => _tf(
    'percentCompleteLabel',
    en: '$percent% complete',
    id: '$percent% selesai',
    args: [percent],
  );
  String moduleStatusLabel(String status) => _tf(
    'moduleStatusLabel',
    en: 'Module status: $status',
    id: 'Status modul: $status',
    args: [status],
  );
  String moduleStatusWithMinutesLabel(int minutes, String status) => _tf(
    'moduleStatusWithMinutesLabel',
    en: '$minutes min - module status: $status',
    id: '$minutes menit - status modul: $status',
    args: [minutes, status],
  );
  String sessionReturnsToPhaseLabel(String phase, String detail) => _tf(
    'sessionReturnsToPhaseLabel',
    en: 'The session returns to $phase for remediation.$detail',
    id: 'Sesi dikembalikan ke fase $phase untuk remediasi.$detail',
    args: [phase, detail],
  );
  String targetPassedLabel(int correct, int total) => _tf(
    'targetPassedLabel',
    en: '$correct/$total correct. This target passed.',
    id: '$correct/$total jawaban benar. Target ini lulus.',
    args: [correct, total],
  );
  String conceptMarkedForReviewLabel(int correct, int total) => _tf(
    'conceptMarkedForReviewLabel',
    en: '$correct/$total correct. The backend marked this concept for review.',
    id: '$correct/$total jawaban benar. Backend menandai konsep ini untuk review.',
    args: [correct, total],
  );
  String accuracyPercentLabel(int score) => _tf(
    'accuracyPercentLabel',
    en: 'Accuracy $score%',
    id: 'Akurasi $score%',
    args: [score],
  );
  String fixedGapsDeltaLabel(int delta) => _tf(
    'fixedGapsDeltaLabel',
    en: '+$delta this week',
    id: '+$delta minggu ini',
    args: [delta],
  );
  String remainingGapsDeltaLabel(int delta) => _tf(
    'remainingGapsDeltaLabel',
    en: '$delta this week',
    id: '$delta minggu ini',
    args: [delta],
  );
  String weeklyPointSummaryLabel(int attempts, int fixed, int remaining) => _tf(
    'weeklyPointSummaryLabel',
    en: '$attempts attempts • $fixed fixed gaps • $remaining remaining gaps',
    id: '$attempts jawaban • $fixed gap tertutup • $remaining gap tersisa',
    args: [attempts, fixed, remaining],
  );
  String positiveDeltaThisWeekLabel(int value) => _tf(
    'positiveDeltaThisWeekLabel',
    en: '+$value this week',
    id: '+$value minggu ini',
    args: [value],
  );
  String deltaThisWeekLabel(int value) => _tf(
    'deltaThisWeekLabel',
    en: '$value this week',
    id: '$value minggu ini',
    args: [value],
  );
  String activeGoalConflictBodyLabel(String topic) => _tf(
    'activeGoalConflictBodyLabel',
    en: 'You already have an active goal for "$topic". You can continue that goal or go back to choose a node.',
    id: 'Kamu sudah punya goal aktif untuk "$topic". Kamu bisa lanjutkan goal itu atau kembali memilih node.',
    args: [topic],
  );
  String reasoningQualityLabel(String quality, String score) => _tf(
    'reasoningQualityLabel',
    en: 'Reasoning quality: $quality$score.',
    id: 'Kualitas reasoning: $quality$score.',
    args: [quality, score],
  );

  String learnConceptInGraphLabel(String label) => _tf(
    'learnConceptInGraphLabel',
    en: 'Learn $label in the prerequisite graph.',
    id: 'Pelajari konsep $label dalam graf prasyarat.',
    args: [label],
  );

  String get outputValidJsonOnlyLabel => _t(
    'outputValidJsonOnlyLabel',
    en: 'Output valid JSON only:',
    id: 'Output JSON valid saja:',
  );
}
